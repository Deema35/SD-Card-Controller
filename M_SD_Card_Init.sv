module M_SD_Card_Init
(

	input wire clk_400k,
	input wire rst,
	input wire Init_Enable,
	
	input wire [47:0]Responce_R1_R3,
	input wire [135:0]Responce_R2,
	
	output reg [5:0] CMD_ID = 'd0,
	output reg [7:0] Arg1 = 'd0,
	output reg [7:0] Arg2 = 'd0,
	output reg [7:0] Arg3 = 'd0,
	output reg [7:0] Arg4 = 'd0,
	
	output reg  Send_CMD_En = 'd0,
	output reg  Get_CMD_En = 'd0,
	input wire Send_CMD_Complite,
	input wire Get_CMD_Complite,
	
	output reg [7:0] PNM[4:0],
	output reg [15:0] RCA_Addr = 'd0,
	output reg [21:0]DeviseSize = 'd0, //memory capacity = (C_SIZE+1) * 512K byte 
	
	output reg Init_complite = 1'b0,
	output reg Init_Fail = 1'b0
	
);

reg [7:0]WaitMessageCounter  = 'd0;


reg [7:0] State_main_Init = 'd0;


localparam 	S_IDLE = 8'd0,
				
				S_SEND_CMD0 = 8'd1, //Reset SD card
				
				S_SEND_CMD8 = 8'd2, //1 We want voltage from 2.7 to 3.6 and test pattern
				S_GET_RESP_CMD8 = 8'd3,
				
				S_SEND_CMD55 = 8'd4, //Next command will be ACMD
				S_GET_RESP_CMD55 = 8'd5,
				S_SEND_ACMD41 = 8'd6,
				S_GET_RESP_ACMD41 = 8'd7,
				
				S_SEND_CMD2 = 8'd8, //Get CID register
				S_GET_RESP_CMD2 = 8'd9,
				
				S_SEND_CMD3 = 8'd10, //Get RCA_Addr
				S_GET_RESP_CMD3 = 8'd11,
			
				S_SEND_CMD9 = 8'd12,
				S_GET_RESP_CMD9 = 8'd13,
				
				S_SEND_CMD7 = 8'd14, //Set Transfer State (Read state)
				S_GET_RESP_CMD7 = 8'd15, 
				
				S_SEND_CMD55_RCA = 8'd16, //Next command will be ACMD
				S_GET_RESP_CMD55_RCA = 8'd17,
				S_SEND_ACMD6 = 8'd18, //Set four data lines
				S_GET_RESP_ACMD6 = 8'd19,
				
				
				S_INIT_PASSED = 8'd250,
				
				S_RESP_TIME_OUT = 8'd251,
				S_CMD8_RESPONSE_FAIL = 8'd253,
				S_ACMD6_RESPONSE_FAIL = 8'd254,
				S_FAIL = 8'd255;
				

always @(posedge clk_400k) 
begin 

	if (rst)
	begin
		
		State_main_Init = S_IDLE;
		Send_CMD_En <= 'd0;
		Get_CMD_En <= 'd0;
		Init_complite <= 1'b0;
		Init_Fail <= 1'b0;
		WaitMessageCounter <= 'd0;

		
	end
	else
	begin
	
		case (State_main_Init)
	
		S_IDLE: if (Init_Enable) State_main_Init <= S_SEND_CMD0;
		
		
		S_SEND_CMD0:
		begin
			if (!Send_CMD_Complite)
			begin
				
				CMD_ID <= 'd0;
				Arg1 <= 'd0;
				Arg2 <= 'd0;
				Arg3 <= 'd0;
				Arg4 <= 'd0;
				
				Send_CMD_En <= 1'b1;
			end
			else
			begin
				Send_CMD_En <= 1'b0;
				State_main_Init <= S_SEND_CMD8;
				
			end
			
		end
		
		S_SEND_CMD8:
		begin
			if (!Send_CMD_Complite)
			begin
				
				CMD_ID <= 'd8;
				Arg1 <= 'd0;
				Arg2 <= 'd0;
				Arg3 <= 8'b00000001;
				Arg4 <= 8'b10101010;
				
				Send_CMD_En <= 1'b1;
			end
			else
			begin
				Send_CMD_En <= 1'b0;
				State_main_Init <= S_GET_RESP_CMD8;
				Get_CMD_En <= 1'b1;
			end
		end
		
		S_GET_RESP_CMD8:
		begin
			if(Get_CMD_Complite)
			begin
				Get_CMD_En <= 1'b0;
				WaitMessageCounter <= 'd0;
				if (Responce_R1_R3[15: 8] ^ Arg4) State_main_Init <= S_CMD8_RESPONSE_FAIL;
				else
				begin
					State_main_Init <= S_SEND_CMD55;
				end
			end
			else
			begin
				WaitMessageCounter <= WaitMessageCounter + 1'd1;
				if (WaitMessageCounter == 'd255) State_main_Init <= S_FAIL;
			end	
		end
		
		S_SEND_CMD55:
		begin
			if (!Send_CMD_Complite)
			begin
				
				CMD_ID <= 'd55;
				Arg1 <= 'd0;
				Arg2 <= 'd0;
				Arg3 <= 'd0;
				Arg4 <= 'd0;
				
				Send_CMD_En <= 1'b1;
			end
			else
			begin
				Send_CMD_En <= 1'b0;
				State_main_Init <= S_GET_RESP_CMD55;
				Get_CMD_En <= 1'b1;
			end
		end
		
		S_GET_RESP_CMD55:
		begin
			
			
			
			if(Get_CMD_Complite)
			begin
				Get_CMD_En <= 1'b0;
				WaitMessageCounter <= 'd0;
				State_main_Init <= S_SEND_ACMD41;
			end
			else
			begin
				WaitMessageCounter <= WaitMessageCounter + 1'd1;
				if (WaitMessageCounter == 'd255) State_main_Init <= S_RESP_TIME_OUT;
			end
							
		end
		
		S_SEND_ACMD41:
		begin
			
			if (!Send_CMD_Complite)
			begin
				
				CMD_ID <= 'd41;
				Arg1 <= 8'b01000000;
				Arg2 <= 8'b00000010;
				Arg3 <= 'd0;
				Arg4 <= 'd0;
				
				Send_CMD_En <= 1'b1;
			end
			else
			begin
				Send_CMD_En <= 1'b0;
				State_main_Init <= S_GET_RESP_ACMD41;
				Get_CMD_En <= 1'b1;
			end
		end
		
		S_GET_RESP_ACMD41:
		
		begin
			
			
			
			if(Get_CMD_Complite)
			begin
				Get_CMD_En <= 1'b0;
				WaitMessageCounter <= 'd0;
				if (Responce_R1_R3[39]) State_main_Init <= S_SEND_CMD2;
				else  State_main_Init <= S_SEND_CMD55;
			end
			else
			begin
				WaitMessageCounter <= WaitMessageCounter + 1'd1;
				if (WaitMessageCounter == 'd255) State_main_Init <= S_RESP_TIME_OUT;
			end
			
		end
		
		S_SEND_CMD2:
		begin
			
			if (!Send_CMD_Complite)
			begin
				
				CMD_ID <= 'd2;
				Arg1 <= 'd0;
				Arg2 <= 'd0;
				Arg3 <= 'd0;
				Arg4 <= 'd0;
				
				Send_CMD_En <= 1'b1;
			end
			else
			begin
				Send_CMD_En <= 1'b0;
				State_main_Init <= S_GET_RESP_CMD2;
				Get_CMD_En <= 1'b1;
			end
		end
		
		S_GET_RESP_CMD2:
		begin
			
			
			if(Get_CMD_Complite)
			begin
				Get_CMD_En <= 1'b0;
				WaitMessageCounter <= 'd0;
				
				PNM[0]= Responce_R2[104:97];
				PNM[1]= Responce_R2[96:89];
				PNM[2]= Responce_R2[88:81];
				PNM[3]= Responce_R2[80:73];
				PNM[4]= Responce_R2[72:65];
				
				State_main_Init <= S_SEND_CMD3;
			end
			else
			begin
				WaitMessageCounter <= WaitMessageCounter + 1'd1;
				if (WaitMessageCounter == 'd255) State_main_Init <= S_RESP_TIME_OUT;
			end
			
		end
		
		S_SEND_CMD3:
		begin
			
			if (!Send_CMD_Complite)
			begin
				
				CMD_ID <= 'd3;
				Arg1 <= 'd0;
				Arg2 <= 'd0;
				Arg3 <= 'd0;
				Arg4 <= 'd0;
				
				Send_CMD_En <= 1'b1;
			end
			else
			begin
				Send_CMD_En <= 1'b0;
				State_main_Init <= S_GET_RESP_CMD3;
				Get_CMD_En <= 1'b1;
			end
		end
		
		S_GET_RESP_CMD3:
		begin
			
			if(Get_CMD_Complite)
			begin
				Get_CMD_En <= 1'b0;
				WaitMessageCounter <= 'd0;
				
				RCA_Addr <= Responce_R1_R3[39:24];
				State_main_Init <= S_SEND_CMD9;
				
				
			end
			else
			begin
				WaitMessageCounter <= WaitMessageCounter + 1'd1;
				if (WaitMessageCounter == 'd255) State_main_Init <= S_RESP_TIME_OUT;
			end
			
		end
		
		S_SEND_CMD9:
		begin
			if (!Send_CMD_Complite)
			begin
				
				CMD_ID <= 'd9;
				{Arg1, Arg2} <= RCA_Addr;
				Arg3 <= 'd0;
				Arg4 <= 'd2;
				
				Send_CMD_En <= 1'b1;
			end
			else
			begin
				Send_CMD_En <= 1'b0;
				State_main_Init <= S_GET_RESP_CMD9;
				Get_CMD_En <= 1'b1;
			end
		end
		S_GET_RESP_CMD9:
		begin
			if(Get_CMD_Complite)
				begin
					Get_CMD_En <= 1'b0;
					WaitMessageCounter <= 'd0;
					State_main_Init <= S_SEND_CMD7;
					DeviseSize <= Responce_R2[69:48];
					
				end
			else
				begin
					WaitMessageCounter <= WaitMessageCounter + 1'd1;
					if (WaitMessageCounter == 'd255) State_main_Init <= S_RESP_TIME_OUT;
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
				State_main_Init <= S_GET_RESP_CMD7;
				Get_CMD_En <= 1'b1;
			end
		end
		
		S_GET_RESP_CMD7:
		begin
			
			if(Get_CMD_Complite)
			begin
				Get_CMD_En <= 1'b0;
				WaitMessageCounter <= 'd0;
				State_main_Init <= S_SEND_CMD55_RCA;
			end
			else
			begin
				WaitMessageCounter <= WaitMessageCounter + 1'd1;
				if (WaitMessageCounter == 'd255) State_main_Init <= S_RESP_TIME_OUT;
			end
			
			
							
		end
		
		S_SEND_CMD55_RCA:
		begin
			if (!Send_CMD_Complite)
			begin
				
				CMD_ID <= 'd55;
				{Arg1, Arg2} <= RCA_Addr;
				Arg3 <= 'd0;
				Arg4 <= 'd0;
				
				Send_CMD_En <= 1'b1;
			end
			else
			begin
				Send_CMD_En <= 1'b0;
				State_main_Init <= S_GET_RESP_CMD55_RCA;
				Get_CMD_En <= 1'b1;
			end
		end
		
		
		
		S_GET_RESP_CMD55_RCA:
		begin
			
			if(Get_CMD_Complite)
			begin
				Get_CMD_En <= 1'b0;
				WaitMessageCounter <= 'd0;
				State_main_Init <= S_SEND_ACMD6;
			end
			else
			begin
				WaitMessageCounter <= WaitMessageCounter + 1'd1;
				if (WaitMessageCounter == 'd255) State_main_Init <= S_RESP_TIME_OUT;
			end
			
							
		end
		
		S_SEND_ACMD6:
		begin
			if (!Send_CMD_Complite)
			begin
				
				CMD_ID <= 'd6;
				Arg1 <= 'd0;
				Arg2 <= 'd0;
				Arg3 <= 'd0;
				Arg4 <= 'd2;
				
				Send_CMD_En <= 1'b1;
			end
			else
			begin
				Send_CMD_En <= 1'b0;
				State_main_Init <= S_GET_RESP_ACMD6;
				Get_CMD_En <= 1'b1;
			end
		end
		
		S_GET_RESP_ACMD6:
		begin
			
			if(Get_CMD_Complite)
			begin
				Get_CMD_En <= 1'b0;
				WaitMessageCounter <= 'd0;
				
				if(Responce_R1_R3[23:8] == 16'b0000100100100000) State_main_Init <= S_INIT_PASSED;
				else State_main_Init <= S_ACMD6_RESPONSE_FAIL;
			end
			else
			begin
				WaitMessageCounter <= WaitMessageCounter + 1'd1;
				if (WaitMessageCounter == 'd255) State_main_Init <= S_RESP_TIME_OUT;
			end
			
		end
		
		
		
		S_INIT_PASSED:
		begin
			if (Init_Enable) Init_complite <= 1'b1;
			else
			begin
				State_main_Init <= S_IDLE;
				Init_complite <= 1'b0;
				$display("SD_CARD_INIT--> SD init complite");
			end
			
		end
		
		S_RESP_TIME_OUT:
		begin
			$display("SD_CARD_INIT--> SD respond time Out");
			State_main_Init <= S_FAIL;
		end
		
		S_CMD8_RESPONSE_FAIL:
		begin	
			$display("SD_CARD_INIT--> CMD8 Respond fail");
			State_main_Init <= S_FAIL;
		end
		S_ACMD6_RESPONSE_FAIL:
		begin
			$display("SD_CARD_INIT--> ACMD6 Respond fail");
			State_main_Init <= S_FAIL;
		end
		
		S_FAIL:
		begin
			if (Init_Enable) Init_Fail <= 1'b1;
			else
			begin
				State_main_Init <= S_IDLE;
				Init_Fail <= 1'b0;
				$display("SD_CARD_INIT--> SD init fail");
			end
			
		end
	
	endcase
	end
	
end


endmodule 