module M_SD_CMD_GET
(
	input wire clk,
	input wire rst,
	input wire Enable,
	input wire [5:0] Command,
	inout wire cmd,
	
	output reg [47:0]Responce_R1_R3 = 'd0,
	output reg [135:0]Responce_R2 = 'd0,
	output reg Complite = 'd0,
	
	output reg CRC_Check_En = 'd0,
	inout CRC_Check_Valid,
	inout wire [6:0]CRC
);


reg [7:0]GetCounter  = 'd0;



reg [7:0] State_Get = 'd0;


localparam 	S_IDLE = 8'd0,
				S_GET_START_BIT = 8'd1,
				S_GET_COMMAND = 8'd2,
				S_GET_R1 = 8'd3,
				S_GET_R2 = 8'd4,
				S_GET_R3 = 8'd5,
				S_GET_R6 = 8'd6,
				S_GET_R7 = 8'd7,
				S_CHECK_CRC = 8'd8,
				S_GET_COMLITE = 8'd253,
				S_CRC_CHECK_FAIL = 8'd254,
				S_UNKNOWN_RESPONCE = 8'd255;
				


always @(posedge clk) 
begin

	if (rst)
	begin
		
		GetCounter <= 'd0;
		Complite <= 1'b0;
		CRC_Check_En <= 1'b0;
		State_Get <= S_IDLE;
		
	end
	else
	begin
		case (State_Get) 
		S_IDLE:
		begin
			GetCounter <= 'd0;
			if (Enable)
			begin
				if (!cmd)
				begin
					State_Get <= S_GET_START_BIT;
					GetCounter <= GetCounter + 1'd1;
					
					case (Command)
					'd2: State_Get <= S_GET_R2;
					'd3: State_Get <= S_GET_R6;
					'd6: State_Get <= S_GET_R1;
					'd7: State_Get <= S_GET_R6;
					'd8: State_Get <= S_GET_R7;
					'd9: State_Get <= S_GET_R2;
					'd12: State_Get <= S_GET_R1;
					'd13: State_Get <= S_GET_R1;
					'd17: State_Get <= S_GET_R1;
					'd18: State_Get <= S_GET_R1;
					'd24: State_Get <= S_GET_R1;
					'd25: State_Get <= S_GET_R1;
					'd55: State_Get <= S_GET_R1;
					'd41: State_Get <= S_GET_R3;
					default: State_Get <= S_UNKNOWN_RESPONCE;
					endcase
				end
				
			end
		end
		
		S_GET_R2:
		
		begin
						
			Responce_R2[135 - GetCounter] <= cmd;
			if (GetCounter != 'd136) GetCounter <= GetCounter + 1'd1;
			else State_Get <= S_GET_COMLITE;
							
		end
		
		S_GET_R3:
		
		begin
						
			Responce_R1_R3[47 - GetCounter] <= cmd;
			if (GetCounter != 'd48) GetCounter <= GetCounter + 1'd1;
			else State_Get <= S_GET_COMLITE;
							
		end
		
		S_GET_R1,
		S_GET_R6,
		S_GET_R7:
		
		begin
						
			Responce_R1_R3[47 - GetCounter] <= cmd;
			if (GetCounter != 'd48) GetCounter <= GetCounter + 1'd1;
			else State_Get <= S_CHECK_CRC;
						
		end
		
		S_CHECK_CRC:
		begin
			CRC_Check_En <= 1'b1;
					
			if (CRC_Check_Valid)
			begin
				CRC_Check_En <= 1'b0;
				
				if(Responce_R1_R3[7: 1] == CRC) State_Get <= S_GET_COMLITE;
				
				else State_Get <= S_CRC_CHECK_FAIL;
			end
			
		end
		
		
		S_CRC_CHECK_FAIL:
		begin
			$display("SD_CMD_GET--> CRC Check fail.");
			State_Get <= S_IDLE;
		end
		
		S_UNKNOWN_RESPONCE:
		begin
			$display("SD_CMD_GET--> Unknown responce.");
			State_Get <= S_IDLE;
		end
		
		S_GET_COMLITE:
		begin
			if (Enable) Complite <= 1'b1;
			else 
			begin
				Complite <= 1'b0;
				State_Get <= S_IDLE;
			end
		end
		
		
		endcase
	end
end	

endmodule 