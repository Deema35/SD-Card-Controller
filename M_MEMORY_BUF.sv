module M_MEMORY_BUF
#(
	parameter FILE_END_BUF_ADDR = 'd1023,
	parameter ADDR_LEN = 'd9
)

( 
	input wire clk,
	input wire we,
	
	input wire [ADDR_LEN:0] read_addr,
	input wire [ADDR_LEN:0] write_addr,
	input wire [31:0] write_data,
	
	output wire [7:0]  read_data
);


reg [7:0]   string_buf [FILE_END_BUF_ADDR : 0]; 


assign read_data = string_buf[read_addr];


always @ (posedge clk)
begin
	if (we)
	begin
		string_buf[write_addr]<= write_data [7:0];
		string_buf[write_addr + 'd1]<= write_data [15:8];
		string_buf[write_addr + 'd2]<= write_data [23:16];
		string_buf[write_addr + 'd3]<= write_data [31:24];
	end
	
end


endmodule
