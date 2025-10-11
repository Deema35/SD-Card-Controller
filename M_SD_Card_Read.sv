module M_SD_Card_Read
(

	input wire clk,
	input wire rst,
	input wire Read_Enable,
	
	input wire [47:0]Responce_R1_R3,
	
	input wire [15:0] RCA_Addr,
	input wire [31:0] SD_Addr_Block,
	
	input wire [3:0] DATA,
	
	output reg [5:0] CMD_ID = 'd0,
	output reg [7:0] Arg1 = 'd0,
	output reg [7:0] Arg2 = 'd0,
	output reg [7:0] Arg3 = 'd0,
	output reg [7:0] Arg4 = 'd0,
	
	output reg  Send_CMD_En = 'd0,
	output reg  Get_CMD_En = 'd0,
	output reg Get_DATA_En = 'd0,
	input wire Send_CMD_Complite,
	input wire Get_CMD_Complite,
	input wire Get_DATA_Complite,
	input wire Get_DATA_CRC_Fail,
	
	input wire [31:0] SerialCount,
	output reg [31:0] BlockReadCount = 'd0,
	
	output reg Read_complite = 1'b0,
	output reg Read_Fail = 1'b0
);



reg [7:0] State_main_Read = 'd0;
reg[7:0] WaitCounter = 'd0;

localparam 	S_IDLE = 8'd0,
				S_SEND_CMD13 = 8'd1,
				S_GET_RESP_CMD13 = 8'd2,
				S_SEND_CMD17 = 8'd3,
				S_GET_RESP_CMD17 = 8'd4,
				S_GET_DATA = 8'd5,
				S_SEND_CMD18 = 8'd6,
				S_GET_RESP_CMD18 = 8'd7,
				S_GET_MULTI_BLOCK_DATA = 8'd8,
				S_SEND_CMD12 = 8'd9,
				S_GET_RESP_CMD12 = 8'd10,
				S_READ_FAIL = 8'd254,
				S_READ_COMPLITE = 8'd255;
				

always @(posedge clk) 
begin 

	if (rst)
	begin
		
		State_main_Read = S_IDLE;
		
		Send_CMD_En <= 'd0;
		Get_CMD_En <= 'd0;
		Get_DATA_En <= 'd0;
		BlockReadCount <= 'd0;
		WaitCounter <= 'd0;
		Read_complite <= 1'b0;
		Read_Fail <= 1'b0;

		
	end
	else
	begin
	
		case (State_main_Read)
		
		S_IDLE : 
		begin
			if (Read_Enable)
			begin
				if (SerialCount) State_main_Read <= S_SEND_CMD18;
				
				else State_main_Read <= S_SEND_CMD17;
			end
		end
		S_SEND_CMD17:
		begin
		if (!Send_CMD_Complite)
			begin
				
				CMD_ID <= 'd17;
				{Arg1, Arg2, Arg3, Arg4} <= SD_Addr_Block;
				Send_CMD_En <= 1'b1;
				
			end
			else
			begin
				Send_CMD_En <= 1'b0;
				State_main_Read <= S_GET_RESP_CMD17;
				Get_CMD_En <= 1'b1;
				Get_DATA_En  <= 1'b1;
			end
		
		end
		
		S_GET_RESP_CMD17:
		begin
			if(Get_CMD_Complite)
			begin
				Get_CMD_En <= 1'b0;
				WaitCounter <= 'd0;
				State_main_Read <= S_GET_DATA;
				
			end
			else
			begin
				WaitCounter <= WaitCounter + 1'd1;
				if (WaitCounter == 'd255) State_main_Read <= S_READ_FAIL;
			end	
		end
		S_GET_DATA:
		begin
			if (Get_DATA_Complite)
			begin
				Get_DATA_En  <= 1'b0;
				if (Get_DATA_CRC_Fail) State_main_Read <= S_READ_FAIL;
				else
				begin
					if (SerialCount == 0) State_main_Read <= S_READ_COMPLITE; //Complite read if we read only one block by CMD17
					
					else if (BlockReadCount == SerialCount) 
					begin
						State_main_Read <= S_SEND_CMD12; //But if we use CMD18 we need send CMD12 after end reading
						BlockReadCount <= 'd0;
					end
					else
					begin
						BlockReadCount <= BlockReadCount + 1'b1;
						State_main_Read <= S_GET_MULTI_BLOCK_DATA;
						if (Get_DATA_CRC_Fail) State_main_Read <= S_READ_FAIL;
						
					end
				end
			end
		end
		
		S_GET_MULTI_BLOCK_DATA:
		begin
			State_main_Read <= S_GET_DATA;
			Get_DATA_En  <= 1'b1;
		end
		
		S_SEND_CMD18:
		begin
		if (!Send_CMD_Complite)
			begin
				
				CMD_ID <= 'd18;
				{Arg1, Arg2, Arg3, Arg4} <= SD_Addr_Block;
				Send_CMD_En <= 1'b1;
				
			end
			else
			begin
				Send_CMD_En <= 1'b0;
				State_main_Read <= S_GET_RESP_CMD18;
				Get_CMD_En <= 1'b1;
				Get_DATA_En  <= 1'b1;
			end
		
		end
		
		S_GET_RESP_CMD18:
		begin
			if(Get_CMD_Complite)
			begin
				Get_CMD_En <= 1'b0;
				WaitCounter <= 'd0;
				State_main_Read <= S_GET_DATA;
				
			end
			else
			begin
				WaitCounter <= WaitCounter + 1'd1;
				if (WaitCounter == 'd255) State_main_Read <= S_READ_FAIL;
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
				State_main_Read <= S_GET_RESP_CMD12;
				Get_CMD_En <= 1'b1;
			end
		
		end
		
		S_GET_RESP_CMD12:
		begin
			if(Get_CMD_Complite)
			begin
				Get_CMD_En <= 1'b0;
				WaitCounter <= 'd0;
				State_main_Read <= S_READ_COMPLITE;
				
			end
			else
			begin
				WaitCounter <= WaitCounter + 1'd1;
				if (WaitCounter == 'd255) State_main_Read <= S_READ_FAIL;
			end	
		end
		
		
		S_READ_FAIL:
		begin
			if (Read_Enable) Read_Fail = 1'b1;
			else
			begin
				$display("Read fail.");
				Read_Fail = 1'b0;
				State_main_Read = S_IDLE;
			end
			
		end
		
		S_READ_COMPLITE:
		begin
			if (Read_Enable) Read_complite = 1'b1;
			else
			begin
				Read_complite = 1'b0;
				State_main_Read = S_IDLE;
			end
			
		end
		
		
		
		endcase
	end
end
endmodule