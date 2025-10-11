module M_String_Buffer
#(
	parameter ENDFRAME = 11'd1055,
	parameter SDRAM_BANK = 2'd0
)
(
	input wire clk,
	input wire rst,
	input wire [15:0] DATA,
	input wire DATA_valid,
	input wire [10:0] V_count,
	input wire [10:0] H_count,
	input wire Hblank,
	
	output wire [15:0]  Pix_color,
	output wire [23:0]   DATA_addr,
	output reg	DATA_in_ready = 1'b0,
	output reg	Serial_access = 1'b0

	
	
);

assign Pix_color = string_buf[H_count[10:0]];


reg [15:0]   string_buf [800:0];

reg [10:0]DATA_Counter = 0;
reg [10:0]DATA_String_Counter = 0;

assign DATA_addr[10:0] = DATA_Counter[10:0];
assign DATA_addr[21:11] = DATA_String_Counter[10:0];
assign DATA_addr[23:22] = SDRAM_BANK;

reg [3:0]BufferState;

localparam   S_READBEGIN = 4'd0,
				S_READSTRING = 4'd1,
				S_READREADY = 4'd2;



always @(posedge clk)
begin
	if (rst)
	begin
	DATA_Counter <= 0;
	DATA_String_Counter <= 0;
	BufferState <= S_READBEGIN;
	
	end
	
	else 
	begin
	
		case(BufferState)
			S_READBEGIN:
			begin
				BufferState <= S_READSTRING;
				DATA_Counter <= 'd0;
				Serial_access <= 'b1;
			end
			
			S_READSTRING:
			begin
				
				if (DATA_valid)
				begin
					string_buf[DATA_Counter] <= DATA;
					DATA_Counter <= DATA_Counter + 11'd1;
					DATA_in_ready <= 1'b0;
					
				end
				else DATA_in_ready <= 1'b1;
				
			if (DATA_Counter == 'd800) BufferState <= S_READREADY;
					
			end
			
			S_READREADY:
			begin
				Serial_access <= 'b0;
				if (Hblank)
				begin
					
					
					if (V_count < 'd599)
					begin 
						DATA_String_Counter <= V_count + 1'b1;
						BufferState <= S_READBEGIN;
					end

					else if (V_count == (ENDFRAME - 1'b1))
					begin
						DATA_String_Counter <= 0;
						BufferState <= S_READBEGIN;
					end
				end
			
			end
		endcase
		
	end
	
end



endmodule 
