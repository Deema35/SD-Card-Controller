module M_SD_Card_Check_State
(
	input wire clk,
	input wire rst,
	input wire CheckState_En,
	output reg CheckState_Complite = 1'b0,
	output reg CheckState_Fail = 1'b0,
	
	input wire Busy_Bit,
	
	input wire [15:0] RCA_Addr,
	input wire [47:0]Responce_R1_R3,
	
	output reg [5:0] CMD_ID = 'd0,
	output reg [7:0] Arg1 = 'd0,
	output reg [7:0] Arg2 = 'd0,
	output reg [7:0] Arg3 = 'd0,
	output reg [7:0] Arg4 = 'd0,
	
	output reg Send_CMD_En = 1'b0,
	output reg Get_CMD_En = 1'b0,
	
	input wire Send_CMD_Complite,
	input wire Get_CMD_Complite
);

localparam 	S_SD_IDLE = 4'd0,
				S_SD_READY  = 4'd1,
				S_SD_IDENT  = 4'd2, 
				S_SD_STBY = 4'd3, // if SD not select 
				S_SD_TRAN = 4'd4, //data transfert mode
				S_SD_DATA = 4'd5, //Card send data to host
				S_SD_RCV = 4'd6,  //Card waiting data from host
				S_SD_PRG = 4'd7, //Wraiting data to flash memory.
				S_SD_DIS = 4'd8; //You can disconnect cart when it write data to flash and for use other card by command CMD7
				
reg [7:0] State_CheckState = 'd0;
reg[7:0] WaitCounter = 'd0;


localparam 	S_IDLE = 8'd0,
				S_DELAY = 8'd1,
				S_BUSY_WAITE = 8'd2,
				S_SEND_CMD13 = 8'd3,
				S_GET_RESP_CMD13 = 8'd4,
				S_SEND_CMD7 = 8'd5,
				S_GET_RESP_CMD7 = 8'd6,
				S_CHECK_FAIL = 8'd254,
				S_CHECK_PASSED = 8'd255;
				
				
				

always @(posedge clk) 
begin 

	if (rst)
	begin
		
		State_CheckState = S_IDLE;
		CheckState_Complite <= 1'b0;
		CheckState_Fail <= 1'b0;
		
		Send_CMD_En <= 1'b0;
		Get_CMD_En <= 1'b0;
		WaitCounter <= 'd0;

	end
	else
	begin
	
		case (State_CheckState)
		
		S_IDLE : if (CheckState_En) State_CheckState <= S_DELAY;
		
		S_DELAY:
		begin
			if (WaitCounter == 'd30)
			begin
				State_CheckState <= S_BUSY_WAITE;
				WaitCounter <= 'd0;
			end
			else WaitCounter <= WaitCounter + 1'b1;
		end
		
		S_BUSY_WAITE:
		begin
			if (Busy_Bit ) State_CheckState <= S_SEND_CMD13;
			
		end
		
		S_SEND_CMD13:
		begin
			
			if (!Send_CMD_Complite)
			begin
				
				CMD_ID <= 'd13;
				{Arg1, Arg2} <= RCA_Addr;
				Arg3 <= 'd0;
				Arg4 <= 'd0;
				
				Send_CMD_En <= 1'b1;
			end
			else
			begin
				Send_CMD_En <= 1'b0;
				State_CheckState <= S_GET_RESP_CMD13;
				Get_CMD_En <= 1'b1;
			end
			
		end
		
		S_GET_RESP_CMD13:
		begin
			if(Get_CMD_Complite)
			begin
				Get_CMD_En <= 1'b0;
				WaitCounter <= 'd0;
				if ( Responce_R1_R3[20: 17] == S_SD_TRAN) State_CheckState <= S_CHECK_PASSED;
				else if ( Responce_R1_R3[20: 17] == S_SD_STBY) State_CheckState <= S_SEND_CMD7;
				else State_CheckState <= S_CHECK_FAIL;
				
			end
			else
			begin
				WaitCounter <= WaitCounter + 1'd1;
				if (WaitCounter == 'd255) State_CheckState <= S_CHECK_FAIL;
			end	
		end
		
		
		S_SEND_CMD7:
		begin
			
			if (!Send_CMD_Complite)
			begin
				
				CMD_ID <= 'd7;
				
				{Arg1, Arg2} <= RCA_Addr;
				
				Arg3 <= 'd0;
				Arg4 <= 'd0;
				
				Send_CMD_En <= 1'b1;
			end
			else
			begin
			
				Send_CMD_En <= 1'b0;
				State_CheckState <= S_GET_RESP_CMD7;
				Get_CMD_En <= 1'b1;
			end
		end
		
		S_GET_RESP_CMD7:
		begin
			
			if(Get_CMD_Complite)
			begin
				Get_CMD_En <= 1'b0;
				WaitCounter <= 'd0;
				State_CheckState <= S_CHECK_PASSED;
			end
			else
			begin
				WaitCounter <= WaitCounter + 1'd1;
				if (WaitCounter == 'd255) State_CheckState <= S_CHECK_FAIL;
			end
		end
		
		
		S_CHECK_FAIL:
		begin
			if (CheckState_En) CheckState_Fail <= 1'b1;
			else
			begin
				$display("SD_Card_Check_State--> Check fail. Current state %d", Responce_R1_R3[20: 17]);
				CheckState_Fail <= 1'b0;
				State_CheckState = S_IDLE;
			end
			
		end
		S_CHECK_PASSED:
		begin
			
			if (CheckState_En) CheckState_Complite <= 1'b1;
			else
			begin
				
				CheckState_Complite <= 1'b0;
				State_CheckState = S_IDLE;
			end
			
		end
		endcase
		
	end
end

endmodule 