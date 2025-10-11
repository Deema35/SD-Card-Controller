module M_SD_DATA_SEND
#(
	parameter DATA_STRING = 'd128
)
(
	input wire clk,
	input wire rst,
	input wire Send_DATA_En,
	
	input wire [31:0] InPut_Data,
	output reg InPut_Data_Valid = 'd0,
	output reg [31:0] InPut_Data_Addr = 'd0,
	
	output reg Send_DATA_Complite = 'd0,
	output tri [3:0] DATA,
	
	output reg CRC_En = 'd0,
	output reg CRC_Data_Get = 'd0,
	
	output wire [7:0] Part_Byte_0,
	output wire [7:0] Part_Byte_1,
	output wire [7:0] Part_Byte_2,
	output wire [7:0] Part_Byte_3,

	input wire [31:0] BlockWriteCount,

	input wire [15:0] CRC_0,
	input wire [15:0] CRC_1,
	input wire [15:0] CRC_2,
	input wire [15:0] CRC_3
);

assign DATA = (State_DATA_Send == S_START_BIT | State_DATA_Send == S_DATA |
					State_DATA_Send == S_CRC | State_DATA_Send == S_END_BIT| State_DATA_Send == S_END_BIT_2) ? DATA_wr : 4'bzzzz;

reg [3:0]DATA_wr = 'hf;




assign Part_Byte_0 = {InPut_Data[4],InPut_Data[0],InPut_Data[12],InPut_Data[8],InPut_Data[20],InPut_Data[16],InPut_Data[28],InPut_Data[24]};
assign Part_Byte_1 = {InPut_Data[5],InPut_Data[1],InPut_Data[13],InPut_Data[9],InPut_Data[21],InPut_Data[17],InPut_Data[29],InPut_Data[25]};
assign Part_Byte_2 = {InPut_Data[6],InPut_Data[2],InPut_Data[14],InPut_Data[10],InPut_Data[22],InPut_Data[18],InPut_Data[30],InPut_Data[26]};
assign Part_Byte_3 = {InPut_Data[7],InPut_Data[3],InPut_Data[15],InPut_Data[11],InPut_Data[23],InPut_Data[19],InPut_Data[31],InPut_Data[27]};


reg [7:0] CRC_Count = 'd0;
reg [7:0] Data_Count = 'd0;
reg [15:0] Send_Count = 'd0;
reg [7:0] State_DATA_Send ='d0;


localparam 	S_IDLE = 'd0,
				S_START_BIT = 'd1,
				S_DATA = 'd2,
				S_CRC = 'd3,
				S_END_BIT = 'd4,
				S_END_BIT_2 = 'd5,
				S_SEND_COMPLITE = 'd6;
				
				
				
always @(negedge clk)
begin

	if (rst)
	begin
		
		State_DATA_Send <= S_IDLE;
		InPut_Data_Valid <= 'd0;
		InPut_Data_Addr <= 'd0;
		CRC_Count <= 'd0;
		Data_Count <= 'd0;
		Send_Count <= 'd0;
		
		CRC_En <= 'd0;
		CRC_Data_Get <= 'd0;
	
	
		Send_DATA_Complite <= 'd0;

	end
	else
	begin
		case(State_DATA_Send)
		S_IDLE:
		begin
			if(Send_DATA_En) 
			begin
				State_DATA_Send<= S_START_BIT;
				InPut_Data_Valid <= 1'b1;
				InPut_Data_Addr <= BlockWriteCount  * 'd512;
			end
			
		end
		
		
		S_START_BIT:
		begin
			DATA_wr <= 4'b0000;
			
			CRC_En <= 1'b1;
			CRC_Data_Get <= 1'b1;
			
			State_DATA_Send <= S_DATA;
		end
		S_DATA:
		begin
			
			DATA_wr[0] <= Part_Byte_0['d7 - Data_Count];
			DATA_wr[1] <= Part_Byte_1['d7 - Data_Count];
			DATA_wr[2] <= Part_Byte_2['d7 - Data_Count];
			DATA_wr[3] <= Part_Byte_3['d7 - Data_Count];
			
			
			if (Data_Count == 'd7)
			begin
				CRC_Data_Get <= 1'b1;
				Data_Count <= 'd0;
				InPut_Data_Addr <= InPut_Data_Addr + 'd4;
			end
			
			else
			begin 
				CRC_Data_Get <= 1'b0;
				Data_Count <= Data_Count + 1'b1;
			end
			
			if (Send_Count == DATA_STRING * 'd8 - 'd1)
			begin
				State_DATA_Send <= S_CRC;
				Send_Count <= 'd0;
			end
			else Send_Count <= Send_Count + 1'b1;
		end
		S_CRC:
		begin
			InPut_Data_Valid <= 1'b0;
			InPut_Data_Addr <= 'd0;
			
			DATA_wr[0] <= CRC_0['d15 - CRC_Count];
			DATA_wr[1] <= CRC_1['d15 - CRC_Count];
			DATA_wr[2] <= CRC_2['d15 - CRC_Count];
			DATA_wr[3] <= CRC_3['d15 - CRC_Count];
			
			if (CRC_Count == 'd15)
			begin
				State_DATA_Send <= S_END_BIT;
				CRC_Count <= 'd0;
				CRC_En <= 1'b0;
			end
			else CRC_Count <= CRC_Count + 1'd1;
		end
		
		S_END_BIT:
		begin
			
			DATA_wr <= 4'b1111;
			State_DATA_Send <= S_END_BIT_2;
				
			
		end
		S_END_BIT_2:
		begin
			State_DATA_Send <= S_SEND_COMPLITE;
		end
		
		S_SEND_COMPLITE:
		begin
			if (Send_DATA_En) Send_DATA_Complite <= 'd1;
			else
			begin 
				Send_DATA_Complite <= 'd0;
				DATA_wr <= 'd1;
				State_DATA_Send <= S_IDLE;
			end
		end
		
		endcase
	end
	
end

endmodule 