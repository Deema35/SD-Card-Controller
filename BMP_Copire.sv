module M_BMP_Copire
#(
	parameter FILE_END_BUF_ADDR = 'd1023,
	parameter ADDR_LEN = 'd9
)

(
	input wire clk,
	input wire rst,
	input wire BMPCopy_En,
	
	output reg BMPCopy_Complite = 1'b0,
	output reg BMPCopy_Fail = 1'b0,
	
	//SD card
	
	input wire SD_Init_Complite,
	output reg [31:0]SD_Addr_Block = 'd0,
	input wire SD_Complite,
	output reg SD_Enable = 1'b0,
	input wire SD_Fail,
	
	output reg [31:0] SD_SerialCount = 'd0,
	
	input wire SD_Out_Data_Valid,
	input wire [31:0] SD_Out_Data_Addr,
	input wire [31:0] SD_Out_Data,

	input wire SD_InPut_Data_Valid,
	input wire [31:0] SD_InPut_Data_Addr,
	output reg [31:0] SD_InPut_Data = 'd0,
	
	//SDRAM
	
	output reg  Serial_access_write = 'd0,
	input wire m_ready_write,
	output reg m_valid_write = 'd0,
	output wire  [23:0] m_addr_write,
	output reg[15:0] m_in_data = 'd0,
	
	//Memory buffer
	output reg DB_WE = 1'b0,

	output reg [ADDR_LEN:0] DB_write_addr = 'd0,
	output reg [31:0] DB_write_data = 'd0,

	output reg [ADDR_LEN:0] DB_read_addr = 'd0,
	input wire [7:0] DB_read_data

	
);

reg CheckBMPEn = 1'b0;
	
wire CheckBMPComplite;
wire CheckBMPFail;




wire [31:0] FileSize;
wire [15:0] PixArrayOffset;

wire [15:0] PixWidth;
wire [15:0] PixHeight;



M_BITMAP_HEADER
#(
	.ADDR_LEN(ADDR_LEN)
)
 Bitmap_Header
(
	.clk(clk),
	.rst(rst),
	.CheckBMPEn(CheckBMPEn),
	
	.CheckBMPComplite(CheckBMPComplite),
	.CheckBMPFail(CheckBMPFail),
	.FileSize(FileSize),
	.PixArrayOffset(PixArrayOffset),
	
	.PixWidth(PixWidth),
	.PixHeight(PixHeight),
	
	.DB_WE(DB_WE),
	
	.DB_write_addr(DB_write_addr),
	.DB_write_data(DB_write_data)
);


reg [10:0] H_count = 'd0;
reg [10:0] V_count = 'd0;

assign m_addr_write[10:0] = H_count;
assign m_addr_write[21:11] = V_count;
assign m_addr_write[23:22] = 'd0;

reg [4:0] Read_Fail_Count = 'd0;

reg [31:0] StringLen = 'd0;

wire [31:0] PixelOffset;

assign PixelOffset = PixArrayOffset + (PixHeight  - 1'b1 - V_count) * StringLen + H_count * 'd3;

wire [31:0] LoadFileOffset;

assign LoadFileOffset = SD_Addr_Block * 'd512;

reg [7:0] Return_Statate = 8'd0;

reg [7:0] Main_Statate = 8'd0;




localparam 	S_IDLE = 8'd0,
				S_READ_DATA = 8'd1,
				S_BMP_CHECK = 8'd2,
				S_READ_NEXT_DATA = 8'd3,
				S_READ_NEXT_DATA_02 = 8'd4,
				S_INICIATE_VAR_01 = 8'd5,
				S_INICIATE_VAR_02 = 8'd6,
				S_GET_PIX_BLUE = 8'd7,
				S_GET_PIX_GREEN = 8'd8,
				S_WRITE_TO_SDRAM = 8'd9,
				S_SET_PIX_NUMBER = 8'd10,
				
				S_FAIL = 8'd254,
				S_COMPLITE = 8'd255;
				
				

always @(posedge clk) 
begin
	if (rst)
	begin
		Main_Statate <= S_IDLE;
		
		BMPCopy_Fail <= 1'b0;
		BMPCopy_Complite <= 1'b0;
		
		StringLen <= 'd0;
		SD_Addr_Block <= 'd0;
		SD_Enable <= 1'b0;
		
		SD_SerialCount <= 'd0;
		SD_InPut_Data <= 'd0;
		
		
		m_valid_write <= 'd0;
		m_in_data <= 'd0;
		
		CheckBMPEn <= 1'b0;
		
		DB_WE <= 1'b0;

		DB_write_addr <= 'd0;
		DB_write_data <= 'd0;
		
		
	end
	else
	begin
		case(Main_Statate)
		
		S_IDLE:
		begin
			if (BMPCopy_En & SD_Init_Complite)
			begin
			
				
				SD_Addr_Block <= 'd0;
				Main_Statate <= S_READ_DATA;
			end
		end

		S_READ_DATA:
		begin
			
			if (SD_Complite)
			begin
				
				SD_Enable <= 1'b0;
				Main_Statate <= S_BMP_CHECK;
				DB_WE <= 1'b0;
			end
			else if (SD_Fail)
			begin
				SD_Enable <= 1'b0;
				Main_Statate <= S_FAIL;
				DB_WE <= 1'b0;
			end
			else
			begin
				
				SD_Enable <= 1'b1;
				if (SD_Out_Data_Valid)
				begin
					DB_write_addr <= SD_Out_Data_Addr[ADDR_LEN:0];
					DB_write_data <= SD_Out_Data;
					DB_WE <= 1'b1;
				end
				else DB_WE <= 1'b0;
			end
		end
		S_BMP_CHECK:
		begin
			if (CheckBMPComplite)
			begin
				CheckBMPEn <= 1'b0;
				Main_Statate <= S_INICIATE_VAR_01;
			end
			else if (CheckBMPFail)
			begin
				CheckBMPEn <= 1'b0;
				Main_Statate <= S_FAIL;
				
			end
			else CheckBMPEn <= 1'b1;
		end
		
		S_READ_NEXT_DATA:
		begin
			SD_Addr_Block <= SD_Addr_Block + SD_SerialCount + 1'b1;
			Main_Statate <= S_READ_NEXT_DATA_02;
			Read_Fail_Count <= 'd0;
		end
		
		S_READ_NEXT_DATA_02:
		begin
			if (SD_Complite)
			begin
				SD_Enable <= 1'b0;
				DB_WE <= 1'b0;
				Main_Statate <= Return_Statate;
				DB_read_addr <= 'd0;
				
			end
			else if (SD_Fail)
			begin
				SD_Enable <= 1'b0; 
				
				if (&Read_Fail_Count) Main_Statate <= S_FAIL;
				else if(SD_Enable) Read_Fail_Count <= Read_Fail_Count + 1'b1;
				
				
				DB_WE <= 1'b0;
			end
			else
			begin
				
				SD_Enable <= 1'b1;
				if (SD_Out_Data_Valid)
				begin
					DB_write_addr <= SD_Out_Data_Addr[ADDR_LEN:0];
					DB_write_data <= SD_Out_Data;
					DB_WE <= 1'b1;
				end
				else DB_WE <= 1'b0;
			end
		end
		
		S_INICIATE_VAR_01:
		begin
			H_count <= 'd0;
			V_count <= PixHeight - 1'b1;
			SD_SerialCount <= ((FILE_END_BUF_ADDR + 1) / 'd512) -'d1;
			StringLen <= (PixWidth * 'd3) + ((PixWidth * 'd3) % 'd4); //Bitmap strings has aligment 4 bytes.
			
			Main_Statate <= S_INICIATE_VAR_02;
			
		end
		
		S_INICIATE_VAR_02: 
		begin
			if (DB_read_addr >= FILE_END_BUF_ADDR)
			begin
				Main_Statate <= S_READ_NEXT_DATA;
				Return_Statate <= S_GET_PIX_BLUE;
			end
			else 
			begin
				DB_read_addr <= PixelOffset - LoadFileOffset;
				Main_Statate <= S_GET_PIX_BLUE;
			end
			Main_Statate <= S_GET_PIX_BLUE;
		end
		
		S_GET_PIX_BLUE:
		begin
			m_in_data[11:8] <= DB_read_data[7:4];
			
			if (DB_read_addr >= FILE_END_BUF_ADDR)
			begin
				Main_Statate <= S_READ_NEXT_DATA;
				Return_Statate <= S_GET_PIX_GREEN;
			end
			else 
			begin
				DB_read_addr <= PixelOffset - LoadFileOffset + 'd1;
				Main_Statate <= S_GET_PIX_GREEN;
			end
		end
		
		S_GET_PIX_GREEN:
		begin
			m_in_data[7:4] <= DB_read_data[7:4];
			if (DB_read_addr >= FILE_END_BUF_ADDR)
			begin
				Main_Statate <= S_READ_NEXT_DATA;
				Return_Statate <= S_WRITE_TO_SDRAM;
			end
			else 
			begin
				DB_read_addr <= PixelOffset - LoadFileOffset + 'd2;
				Main_Statate <= S_WRITE_TO_SDRAM;
			end
		end
		
		S_WRITE_TO_SDRAM:
		begin
		if (m_ready_write)
			begin
				m_valid_write <= 1'b0;
				if(!m_valid_write) Main_Statate <= S_SET_PIX_NUMBER;
			end
			else
			begin
				m_in_data[3:0] <= DB_read_data[7:4];
				m_valid_write <= 1'b1;
			end
		end
		
		S_SET_PIX_NUMBER:
		begin
			
			if (V_count != 0)
			begin 
				if (H_count != (PixWidth - 'd1))
				begin
					H_count <= H_count + 1'b1;
				end
				else 
				begin
					H_count <= 'd0;
					V_count <= V_count - 1'b1;
				end
				Main_Statate <= S_INICIATE_VAR_02;
			end
			else Main_Statate <= S_COMPLITE;
			
		end

		
		
		S_FAIL:
		begin
			
			BMPCopy_Fail <= 1'b1;
		end
		
		
		S_COMPLITE:
		begin
			BMPCopy_Complite <= 1'b1;
		end
		
		
		endcase
	end
end


endmodule 

