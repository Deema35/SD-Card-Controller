module M_BITMAP_HEADER
#(
	parameter ADDR_LEN = 'd9,
	parameter ADDR_LOCAL_LEN = 'd5
)
(
	input wire clk,
	input wire rst,
	input wire CheckBMPEn,
	
	output reg CheckBMPComplite = 1'b0,
	output reg CheckBMPFail = 1'b0,
	output reg [31:0] FileSize = 'd0,
	output reg [15:0] PixArrayOffset = 'd0,
	output reg [15:0] PixWidth = 'd0,
	output reg [15:0] PixHeight = 'd0,
	
	input wire DB_WE,
	
	input wire [ADDR_LEN:0] DB_write_addr,
	input wire [31:0] DB_write_data
	
);

wire we;

assign we = (DB_write_addr < 'd64) ? DB_WE : 1'b0;

wire [ADDR_LOCAL_LEN : 0] write_addr;

assign write_addr = (DB_write_addr < 'd64) ? DB_write_addr : 'd0;

reg [ADDR_LOCAL_LEN : 0] read_addr = 'd0;

wire [7:0] read_data;

M_MEMORY_BUF 
#(
	.FILE_END_BUF_ADDR('d63),
	.ADDR_LEN(ADDR_LOCAL_LEN)
)
Memory_buf_head
(
	.clk(clk),
	.we(we),
	
	.read_addr(read_addr),
	.write_addr(write_addr),
	.write_data(DB_write_data),
	
	.read_data(read_data)
	
);



reg [7:0] BitmapState = 'd0;


localparam 	S_IDLE = 8'd0, 
				S_CHECK_SIG = 8'd1,
				S_CHECK_SIG_02 = 8'd2,
				S_GET_FILE_SIZE_01 = 8'd3,
				S_GET_FILE_SIZE_02 = 8'd4,
				S_GET_FILE_SIZE_03 = 8'd5,
				S_GET_FILE_SIZE_04 = 8'd6,
				S_CHECK_FILE_SIZE = 8'd7,
				S_GET_PIX_OFFSET_01 = 8'd8,
				S_GET_PIX_OFFSET_02 = 8'd9,
				S_GET_WIDTH_01 = 8'd10,
				S_GET_WIDTH_02 = 8'd11,
				S_GET_HEIGHT_01 = 8'd12,
				S_GET_HEIGHT_02 = 8'd13,
				S_PIX_SIZE_CHECK = 8'd14,
				S_CHECK_PIX_BIT_COUNT = 8'd15,
				S_FAIL = 8'd254,
				S_COMPLITE = 8'd255;

always @ (posedge clk)
begin

	if (rst)
	begin
		
		CheckBMPComplite <= 1'b0;
		CheckBMPFail <= 1'b0;
		FileSize <= 'd0;
		PixArrayOffset <= 'd0;
		PixWidth <= 'd0;
		PixHeight <= 'd0;
		read_addr <= 'd0;
		BitmapState <= S_IDLE;
		
	end
	else
	begin
		case (BitmapState)
		
		S_IDLE: if (CheckBMPEn) BitmapState <= S_CHECK_SIG;
		
		S_CHECK_SIG:
		begin
			if (read_data == 'h42)
			begin
				read_addr <= 'd01;
				BitmapState <= S_CHECK_SIG_02;
			end
			else BitmapState <= S_FAIL;
		end
		
		S_CHECK_SIG_02:
		begin
			if (read_data == 'h4d)
			begin
				read_addr <= 'd02;
				BitmapState <= S_GET_FILE_SIZE_01;
			end
			else BitmapState <= S_FAIL;
		end
		
		S_GET_FILE_SIZE_01:
		begin
			FileSize[7:0] <= read_data;
			read_addr <= 'd03;
			BitmapState <= S_GET_FILE_SIZE_02;
		end
		
		S_GET_FILE_SIZE_02:
		begin
			FileSize[15:8] <= read_data;
			read_addr <= 'd04;
			BitmapState <= S_GET_FILE_SIZE_03;
		end
		
		S_GET_FILE_SIZE_03:
		begin
			FileSize[23:16] <= read_data;
			read_addr <= 'd05;
			BitmapState <= S_GET_FILE_SIZE_04;
		end
		
		S_GET_FILE_SIZE_04:
		begin
			FileSize[31:24] <= read_data;
			BitmapState <= S_CHECK_FILE_SIZE;
		end
		
		S_CHECK_FILE_SIZE:
		begin
			if (FileSize < 'hffffff) // If file size less than 8Mb
			begin
				read_addr <= 'h0a;
				BitmapState <= S_GET_PIX_OFFSET_01;
			end
			else BitmapState <= S_FAIL;
		end
		
		S_GET_PIX_OFFSET_01:
		begin
			PixArrayOffset[7:0] <= read_data;
			read_addr <= 'h0b;
			BitmapState <= S_GET_PIX_OFFSET_02;
		end
		
		S_GET_PIX_OFFSET_02:
		begin
			PixArrayOffset[15:8] <= read_data;
			read_addr <= 'h12;
			BitmapState <= S_GET_WIDTH_01;
		end
		
		S_GET_WIDTH_01:
		begin
			PixWidth[7:0] <= read_data;
			read_addr <= 'h13;
			BitmapState <= S_GET_WIDTH_02;
		end
		
		S_GET_WIDTH_02:
		begin
			PixWidth[15:8] <= read_data;
			read_addr <= 'h16;
			BitmapState <= S_GET_HEIGHT_01;
		end
		
		S_GET_HEIGHT_01:
		begin
			PixHeight[7:0] <= read_data;
			read_addr <= 'h17;
			BitmapState <= S_GET_HEIGHT_02;
		end
		
		S_GET_HEIGHT_02:
		begin
			PixHeight[15:8] <= read_data;
			read_addr <= 'h1c;
			BitmapState <= S_CHECK_PIX_BIT_COUNT;
		end
		
		S_CHECK_PIX_BIT_COUNT:
		begin
			if (read_data == 'd24) BitmapState <= S_COMPLITE;
			else BitmapState <= S_FAIL;
		end
		
		S_FAIL:
		begin
			if (CheckBMPEn) CheckBMPFail <= 1'b1;
			else 
			begin
				BitmapState <= S_IDLE;
				CheckBMPFail <= 1'b0;
			end
		end
		
		S_COMPLITE:
		begin
			if (CheckBMPEn) CheckBMPComplite <= 1'b1;
			else 
			begin
				BitmapState <= S_IDLE;
				CheckBMPComplite <= 1'b0;
			end
		end
		
		endcase
	end


	
end


endmodule 



