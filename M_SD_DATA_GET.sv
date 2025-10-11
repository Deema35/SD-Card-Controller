module M_SD_DATA_GET
#(
	parameter DATA_STRING = 'd128
)
(
	input wire clk,
	input wire rst,
	input wire Get_DATA_En,
	input tri [3:0] DATA,
	
	output reg Get_DATA_Complite = 'd0,
	output reg Get_DATA_CRC_Fail = 'd0,
	
	output reg[31:0] Out_Data_Addr = 'd0,
	output reg Out_Data_Valid = 'd0,
	output wire [31:0] Out_Data,
	
	output reg CRC_En = 'd0,
	input wire CRC_Valid,
	output reg CRC_Data_Get = 'd0,
	
	output reg [7:0] Temp_Byte_0 = 'd0,
	output reg [7:0] Temp_Byte_1 = 'd0,
	output reg [7:0] Temp_Byte_2 = 'd0,
	output reg [7:0] Temp_Byte_3 = 'd0,
	
	input wire [31:0] BlockReadCount,


	input wire [15:0] CRC_0,
	input wire [15:0] CRC_1,
	input wire [15:0] CRC_2,
	input wire [15:0] CRC_3
);

reg [7:0] Part_Byte_0 = 'd0;
reg [7:0] Part_Byte_1 = 'd0;
reg [7:0] Part_Byte_2 = 'd0;
reg [7:0] Part_Byte_3 = 'd0;





assign Out_Data = {Temp_Byte_3[1], Temp_Byte_2[1], Temp_Byte_1[1], Temp_Byte_0[1],Temp_Byte_3[0], Temp_Byte_2[0], Temp_Byte_1[0], Temp_Byte_0[0],
							Temp_Byte_3[3], Temp_Byte_2[3], Temp_Byte_1[3], Temp_Byte_0[3],Temp_Byte_3[2], Temp_Byte_2[2], Temp_Byte_1[2], Temp_Byte_0[2],
							Temp_Byte_3[5], Temp_Byte_2[5], Temp_Byte_1[5], Temp_Byte_0[5],Temp_Byte_3[4], Temp_Byte_2[4], Temp_Byte_1[4], Temp_Byte_0[4],
							Temp_Byte_3[7], Temp_Byte_2[7], Temp_Byte_1[7], Temp_Byte_0[7],Temp_Byte_3[6], Temp_Byte_2[6], Temp_Byte_1[6], Temp_Byte_0[6]};
							



reg [7:0] Data_Count = 'd0;

reg [15:0]CRC16_Get_0 ='d0;
reg [15:0]CRC16_Get_1 ='d0;
reg [15:0]CRC16_Get_2 ='d0;
reg [15:0]CRC16_Get_3 ='d0;

reg [7:0] State_DATA_Get ='d0;

reg [15:0] Get_Count = 'd0;
reg [19:0] WaitCounter = 'd0;

localparam 	S_IDLE = 'd0,
				S_DATA_GET = 'd1,
				S_CRC_GET = 'd2,
				S_CRC_CALK = 'd3,
				S_CRC_CHECK = 'd4,
				S_COMLITE = 'd5;
				
				
always @(posedge clk)
begin

	if (rst)
	begin
		Out_Data_Addr <= 'd0;
		Out_Data_Valid <= 'd0;
		State_DATA_Get <= S_IDLE;
		
		Get_DATA_Complite <= 'd0;
		Get_DATA_CRC_Fail <= 'd0;
		
		CRC_En <= 'd0;
		CRC_Data_Get <= 'd0;
		
		WaitCounter <= 'd0;

	end
	else
	begin
		case(State_DATA_Get)
		S_IDLE:
		begin
			CRC_Data_Get <= 1'b0;
			if(Get_DATA_En)
			begin
				if (!DATA[0]) 
				begin
					State_DATA_Get<= S_DATA_GET;
					Out_Data_Addr <= BlockReadCount * 'd512; // if we have multi block read
					CRC_En <= 1'b1;
					WaitCounter <= 'd0;
				end
				else if (&WaitCounter)
				begin
					WaitCounter <= 'd0;
					Get_DATA_CRC_Fail <= 1'b1;
					State_DATA_Get <= S_COMLITE;
				end
				else WaitCounter <= WaitCounter + 1'b1;
			end
		end
		S_DATA_GET:
		begin
			Part_Byte_0['d7 - Data_Count] <= DATA[0];
			Part_Byte_1['d7 - Data_Count] <= DATA[1];
			Part_Byte_2['d7 - Data_Count] <= DATA[2];
			Part_Byte_3['d7 - Data_Count] <= DATA[3];
			
			if (Data_Count == 'd7)
			begin
				Data_Count <= 'd0;
				Temp_Byte_0 <= { Part_Byte_0[7:1],DATA[0]};
				Temp_Byte_1 <= { Part_Byte_1[7:1],DATA[1]};
				Temp_Byte_2 <= { Part_Byte_2[7:1],DATA[2]};
				Temp_Byte_3 <= { Part_Byte_3[7:1],DATA[3]};
				if (Out_Data_Valid) Out_Data_Addr <= Out_Data_Addr + 'd4;
				Out_Data_Valid <= 1'b1;
				CRC_Data_Get <= 1'b1;
			end
			else
			begin
				Data_Count <= Data_Count + 1'b1;
				CRC_Data_Get <= 1'b0;
			end
			
			if (Get_Count == DATA_STRING * 'd8 - 'd1)
			begin
				
				Get_Count <= 'd0;
				
				State_DATA_Get <= S_CRC_GET;
			end
			else Get_Count <= Get_Count + 1'b1;
			
		end
		S_CRC_GET:
		begin
			
			CRC16_Get_0['d15 - Get_Count] <= DATA[0];
			CRC16_Get_1['d15 - Get_Count] <= DATA[1];
			CRC16_Get_2['d15 - Get_Count] <= DATA[2];
			CRC16_Get_3['d15 - Get_Count] <= DATA[3];
			if (Get_Count == 15)
			begin
				Out_Data_Addr <= 0; //It is necessary that the last block does not disappear immediately.
				Out_Data_Valid <= 1'b0;
				Temp_Byte_0 <= 'd0;
				Temp_Byte_1 <= 'd0;
				Temp_Byte_2 <= 'd0;
				Temp_Byte_3 <= 'd0;
				
				
				State_DATA_Get <= S_CRC_CALK;
				Get_Count <= 'd0;
			end
			else Get_Count <= Get_Count + 1'b1;
		end
		
		
		S_CRC_CALK:
		begin
			
			if (CRC_Valid)
			begin
				State_DATA_Get <= S_CRC_CHECK;
				CRC_En <= 1'b0;
			end
		end
		
		S_CRC_CHECK:
		begin
			if (CRC16_Get_0 == CRC_0 & CRC16_Get_1 == CRC_1 &
					CRC16_Get_2 == CRC_2 & CRC16_Get_3 == CRC_3)
			begin
				$display("SD_DATA_GET--> Data get. CRC Check passed.");
			end
			else
			begin
				$display("SD_DATA_GET--> Data get. CRC Check fail");
				Get_DATA_CRC_Fail <= 1'b1;
			end
			
			State_DATA_Get <= S_COMLITE;
		end
		
		
		
		S_COMLITE:
		begin
			if (Get_DATA_En) Get_DATA_Complite <= 1'b1;
			else
			begin
				 Get_DATA_Complite <= 1'b0;
				 Get_DATA_CRC_Fail <= 1'b0;
				 State_DATA_Get = S_IDLE;
			end
		end
		
		endcase
	end
	
end

endmodule 