module M_BITMAP_HEADER
#(
	parameter ADDR_LEN = 'd9
)
(
	input wire clk,
	input wire rst,
	input wire CheckBMPEn,
	
	output reg CheckBMPComplite = 1'b0,
	output reg CheckBMPFail = 1'b0,
	output reg [31:0] FileSize = 'd0,
	output reg [31:0] PixArrayOffset = 'd0,
	output reg [31:0] PixWidth = 'd0,
	output reg [31:0] PixHeight = 'd0,
	
	input wire DB_WE,
	
	input wire [ADDR_LEN:0] DB_write_addr,
	input wire [31:0] DB_write_data
	
);

reg [15:0] BMP_Sign = 'd0;

reg [15:0] BMP_PixCount = 'd0;

reg [7:0] BitmapState = 'd0;


localparam 	S_IDLE = 8'd0, 
				S_CHECK_SIG = 8'd1,
				S_CHECK_FILE_SIZE = 8'd2,
				S_CHECK_PIX_BIT_COUNT = 8'd3,
				S_DATA_SAVE = 8'd4,
				
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
		BitmapState <= S_IDLE;
		
	end
	else
	begin
		case (BitmapState)
		
		S_IDLE:
		begin
			if (CheckBMPEn) BitmapState <= S_CHECK_SIG;
			
			else if (DB_WE) 
			begin
				case(DB_write_addr)
			
				'd0: 
					begin
						BMP_Sign[15:8] <= DB_write_data[7:0];
						BMP_Sign[7:0] <= DB_write_data[15:8];
						
						FileSize[15:0] <= DB_write_data[31:16];
						
					end
				'd4:
					begin
						FileSize[31:16] <= DB_write_data[15:0];
					end
				'd8:
					begin
						PixArrayOffset[15:0]<= DB_write_data[31:16];
					end
				'd12:
					begin
						PixArrayOffset[31:16] <= DB_write_data[15:0];
					end
				'd16:
					begin
						PixWidth[15:0]<= DB_write_data[31:16];

					end
				'd20:
					begin
						PixWidth[31:16] <= DB_write_data[15:0];
						PixHeight[15:0]<= DB_write_data[31:16];
						
					end
				'd24:
					begin
						PixHeight[31:16] <= DB_write_data[15:0];
					end
				'd28:
					begin
						BMP_PixCount <= DB_write_data[15:0];
					end
				endcase
			end
			
		end
		
		S_CHECK_SIG:
		begin
			if (BMP_Sign == 'h424d)
			begin
				BitmapState <= S_CHECK_FILE_SIZE;
			end
			else BitmapState <= S_FAIL;
		end
		
		S_CHECK_FILE_SIZE:
		begin
			if (FileSize < 'hffffff) // If file size less than 8Mb
			begin
				BitmapState <= S_CHECK_PIX_BIT_COUNT;
			end
			else BitmapState <= S_FAIL;
		end
		
		S_CHECK_PIX_BIT_COUNT:
		begin
			if (BMP_PixCount == 'd24) BitmapState <= S_COMPLITE;
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
				BitmapState <= S_DATA_SAVE;
				CheckBMPComplite <= 1'b0;
			end
		end
		
		
		endcase
		
		
		
	end


	
end


endmodule 



