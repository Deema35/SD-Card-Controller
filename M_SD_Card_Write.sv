module M_SD_Card_Write
(

	input wire clk,
	input wire rst,
	input wire Write_Enable,
	
	input wire [47:0]Responce_R1_R3,
	
	input wire [15:0] RCA_Addr,
	input wire [31:0] SD_Addr_Block,
	
	
	output reg [5:0] CMD_ID = 'd0,
	output reg [7:0] Arg1 = 'd0,
	output reg [7:0] Arg2 = 'd0,
	output reg [7:0] Arg3 = 'd0,
	output reg [7:0] Arg4 = 'd0,
	
	output reg  Send_CMD_En = 'd0,
	output reg  Get_CMD_En = 'd0,
	output reg Send_DATA_En = 'd0,
	input wire Send_CMD_Complite,
	input wire Get_CMD_Complite,
	input wire Send_DATA_Complite,
	
	input wire [31:0] SerialCount,
	output reg [31:0] BlockWriteCount = 'd0,
	
	input wire Busy_Bit,
	
	
	output reg Write_complite = 1'b0,
	output reg Write_Fail = 1'b0
	
);

reg [7:0] State_main_Write = 'd0;
reg [7:0] NoResponce_Count = 'd0;
reg[7:0] WaitCounter = 'd0;


localparam 	S_IDLE = 8'd0,
				S_SEND_CMD24 = 8'd1,
				S_GET_RESP_CMD24 = 8'd2,
				S_SEND_CMD25 = 8'd3,
				S_GET_RESP_CMD25 = 8'd4,
				S_SEND_DATA = 8'd5,
				S_DELAY = 8'd6,
				S_BUSY_WAITE = 8'd7,
				S_SEND_CMD13 = 8'd8,
				S_GET_RESP_CMD13 = 8'd9,
				S_SEND_CMD12 = 8'd10,
				S_GET_RESP_CMD12 = 8'd11,
				S_WRITE_COMLITE= 8'd254,
				S_WRITE_FAIL= 8'd255;
				
				

always @(posedge clk) 
begin 

	if (rst)
	begin
		
		State_main_Write = S_IDLE;
		NoResponce_Count <= 'd0;
		WaitCounter <= 'd0;
		BlockWriteCount <= 'd0;
		
		Write_complite <= 1'b0;
		Write_Fail <= 1'b0;
	end
	else
	begin
	
		case (State_main_Write)
		
		S_IDLE :
		begin
			if (Write_Enable)
			begin
				if (SerialCount) State_main_Write <= S_SEND_CMD25;
				else State_main_Write <= S_SEND_CMD24;
			end
		end
		
		
		S_SEND_CMD24:
		begin
			
			if (!Send_CMD_Complite)
			begin
				
				CMD_ID <= 'd24;
				{Arg1, Arg2, Arg3, Arg4} <= SD_Addr_Block;
				Send_CMD_En <= 1'b1;
				
			end
			else
			begin
				Send_CMD_En <= 1'b0;
				State_main_Write <= S_GET_RESP_CMD24;
				Get_CMD_En <= 1'b1;
				
			end
		
		
		end
		S_GET_RESP_CMD24:
		begin
			if(Get_CMD_Complite)
			begin
				Get_CMD_En <= 1'b0;
				WaitCounter <= 'd0;
				State_main_Write <= S_SEND_DATA;
				
			end
			else
			begin
				WaitCounter <= WaitCounter + 1'd1;
				if (WaitCounter == 'd255) State_main_Write <= S_WRITE_FAIL;
			end	
		end
		
		
		
		S_SEND_CMD25:
		begin
			
			if (!Send_CMD_Complite)
			begin
				
				CMD_ID <= 'd25;
				{Arg1, Arg2, Arg3, Arg4} <= SD_Addr_Block;
				Send_CMD_En <= 1'b1;
				
			end
			else
			begin
				Send_CMD_En <= 1'b0;
				State_main_Write <= S_GET_RESP_CMD25;
				Get_CMD_En <= 1'b1;
				
			end
		
		
		end
		S_GET_RESP_CMD25:
		begin
			if(Get_CMD_Complite)
			begin
				Get_CMD_En <= 1'b0;
				WaitCounter <= 'd0;
				State_main_Write <= S_SEND_DATA;
				
			end
			else
			begin
				WaitCounter <= WaitCounter + 1'd1;
				if (WaitCounter == 'd255) State_main_Write <= S_WRITE_FAIL;
			end	
		end
		
		S_SEND_DATA:
		begin
			
			if (Send_DATA_Complite)
			begin
				Send_DATA_En  <= 1'b0;
				State_main_Write <= S_DELAY;
			end
			else Send_DATA_En  <= 1'b1;
		end
		
		S_DELAY:
		begin
			if (WaitCounter == 'd30)
			begin
				State_main_Write <= S_BUSY_WAITE;
				WaitCounter <= 'd0;
			end
			else WaitCounter <= WaitCounter + 1'b1;
		end
		
		S_BUSY_WAITE:
		begin
			if (Busy_Bit ) State_main_Write <= S_SEND_CMD13;
			
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
				State_main_Write <= S_GET_RESP_CMD13;
				Get_CMD_En <= 1'b1;
			end
			
		end
		
		S_GET_RESP_CMD13:
		begin
			if(Get_CMD_Complite)
			begin
				Get_CMD_En <= 1'b0;
				
				if ( Responce_R1_R3[20: 17] == 4'd4) //SD card change status to TRAN itself after CMD24
				begin
					
					State_main_Write <= S_WRITE_COMLITE;
					
				end
				else if ( Responce_R1_R3[20: 17] == 4'd6) //But after CMD25 it will will remain in RCV until received CMD12
				begin
					
					if (BlockWriteCount == SerialCount) 
					begin
						BlockWriteCount <= 'd0;
						State_main_Write <=  S_SEND_CMD12;
					end
					else
					begin
						BlockWriteCount <= BlockWriteCount + 1'b1;
						State_main_Write <= S_SEND_DATA;
					end
				end
				else 
				begin
					if (NoResponce_Count == 'd100)
					begin
						
						NoResponce_Count <= 'd0;
						State_main_Write <= S_WRITE_FAIL;
					end
					else
					begin
						
						NoResponce_Count <= NoResponce_Count + 1'd1;
						State_main_Write <= S_SEND_CMD13;
					end
				end
				
			end
			else
			begin
				WaitCounter <= WaitCounter + 1'd1;
				if (WaitCounter == 'd255) State_main_Write <= S_WRITE_FAIL;
			end	
		end
		
		S_SEND_CMD12:
		begin
		if (!Send_CMD_Complite)
			begin
				
				CMD_ID <= 'd12;
				Arg1 <= 'haa;
				Arg2 <= 'haa;
				Arg3 <= 'haa;
				Arg4 <= 'haa;
				Send_CMD_En <= 1'b1;
				
			end
			else
			begin
				Send_CMD_En <= 1'b0;
				State_main_Write <= S_GET_RESP_CMD12;
				Get_CMD_En <= 1'b1;
			end
		
		end
		
		S_GET_RESP_CMD12:
		begin
			if(Get_CMD_Complite)
			begin
				Get_CMD_En <= 1'b0;
				WaitCounter <= 'd0;
				State_main_Write <= S_WRITE_COMLITE;
				
			end
			else
			begin
				WaitCounter <= WaitCounter + 1'd1;
				if (WaitCounter == 'd255) State_main_Write <= S_WRITE_FAIL;
			end	
		end
		
		S_WRITE_COMLITE:
		begin
			if (Write_Enable) Write_complite = 1'b1;
			else
			begin
				State_main_Write = S_IDLE;
				Write_complite = 1'b0;
			end
		end
		
		S_WRITE_FAIL:
		begin
			if (Write_Enable) Write_Fail = 1'b1;
			else
			begin
				State_main_Write = S_IDLE;
				Write_Fail = 1'b0;
			end
		end
		
		endcase
	end
end
endmodule