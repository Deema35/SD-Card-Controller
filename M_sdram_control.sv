module M_sdram_control
#(
	parameter CL = 3,
	parameter	INIT_PER	=	12000,
	parameter NOP_WAITE = 2000
)
(
   input wire clk_ref,
	input wire rst,
	input wire [15:0] in_data, 
	input wire [23:0] m_addr_write, //2bit BANK, 13bit ROW, 9bit COLUMM
	input wire [23:0] m_addr_read,
	
	input wire m_valid_write,
	input wire m_valid_read, 
	 
	input wire Serial_access_write,
	input wire Serial_access_read,
	 
	output reg m_ready_write = 1'b0,
	output reg m_ready_read = 1'b0,
	
	output reg[15:0] out_data = 'd0,  //Data read

	 	 
	 //SDRAM interface
	output reg sd_cke,
	output wire sd_clk,
	output wire sd_dqml,
	output wire sd_dqmh,
	output reg  sd_cas_n = 1'b0,
	output reg sd_ras_n = 1'b0,
	output reg sd_we_n = 1'b0,
	output reg sd_cs_n = 1'b0,
	output reg [14:0] sd_addr = 'd0,
	inout  tri [15:0] sd_data
);

assign sd_dqml	= 1'b0;
assign sd_dqmh	= 1'b0;

assign  sd_data = (state_main == S_WRITE) ? in_data : 16'hzzzz;


reg [3:0] state_main = S_WAIT;
reg [23:0] m_addr_set;
reg flg_first_cmd = 1'b1;
reg [15:0] cnt_wait = 'd0;
reg [10:0] cnt_refresh_sdram = 'd0;


assign sd_clk = clk_ref;

localparam     S_WAIT = 4'd0,    
					S_NOP = 4'd1,    
					S_PRECHARGE_ALL = 4'd2,   
					S_AUTO_REFRESH = 4'd3,
					S_LOAD_MODE = 4'd4,
					S_IDLE = 4'd5,
					S_NOT_PRECHARGE_IDLE_READ = 4'd6,
					S_NOT_PRECHARGE_IDLE_WRITE = 4'd7,
					S_ACTIVATE_ROW_READ = 4'd8,
					S_ACTIVATE_ROW_WRITE = 4'd9,
					S_WRITE = 4'd10,
					S_PRECHARGE_AFTER = 4'd11,
					S_READ = 4'd12,
					S_READING_DATA = 4'd13;

					 
always@(posedge clk_ref)
begin
	if(rst)
	begin
		state_main <= S_WAIT;
		out_data <= 'd0;
		cnt_refresh_sdram <= 'd0;
		flg_first_cmd <= 1'b1;
		cnt_wait <= 1'b0;
		m_ready_write <= 1'b0;
		m_ready_read <= 1'b0;
		
	end
	else
	begin
		case(state_main)
		
			S_WAIT: 
			
			begin 
			
				if(cnt_wait != INIT_PER) cnt_wait <= cnt_wait + 1'b1; 
				
				else 
				begin
					state_main<= S_NOP;
					cnt_wait <= 0;
				end 
				
			end
			
			S_NOP: 
			
			begin 
			
				if(cnt_wait != NOP_WAITE) cnt_wait <= cnt_wait + 1'b1;
				
				else
				begin 
					state_main<= S_PRECHARGE_ALL;
					cnt_wait <= 0;
				end 
				
			end
			
			S_PRECHARGE_ALL: 
			
			begin 
				if(cnt_wait != 1) cnt_wait <= cnt_wait + 1'b1;
				
				else 
				begin 
					cnt_wait <= 0;
					state_main <= S_AUTO_REFRESH;
				end 
				
			end
			
			S_AUTO_REFRESH: 
			
			begin 
				if(cnt_wait[14:0] != 6) cnt_wait <= cnt_wait + 1'b1;
				
				else 
				begin 
					cnt_wait[14:0] <= 0;
					
					if(cnt_wait[15]) 
					begin
					state_main <= S_LOAD_MODE;
					cnt_wait[15] <= 0;
					end 
					
					else cnt_wait[15] <= 1;
				end 
				
				
			end
			
			S_LOAD_MODE: 
			
			begin 
				if(cnt_wait != 1) cnt_wait <= cnt_wait + 1'b1;
				
				else
				begin 
					cnt_wait <= 0;
					state_main <= S_IDLE;
				end 
				 
			end
			
			S_IDLE:  
			begin 
				if(m_valid_write)
				begin
					cnt_refresh_sdram <= 0;
					state_main <= S_ACTIVATE_ROW_WRITE;
					m_addr_set <= m_addr_write;
				end
				else if (m_valid_read)
				begin
					cnt_refresh_sdram <= 0;
					state_main <= S_ACTIVATE_ROW_READ;
					m_addr_set <= m_addr_read;
				end
				else
				begin
					if(&cnt_refresh_sdram) 
					begin
						state_main <= S_PRECHARGE_AFTER;
						cnt_refresh_sdram <= 0;
					end 
					else cnt_refresh_sdram <= cnt_refresh_sdram + 1'b1;
				end
			
			end
			
			S_NOT_PRECHARGE_IDLE_READ:
			begin
				if (!Serial_access_read) state_main <= S_PRECHARGE_AFTER;
				else
				begin
					if (m_valid_read)
					begin
						if (m_addr_set[21:9] == m_addr_read[21:9])
						begin
							flg_first_cmd <= 1;
							m_addr_set <= m_addr_read;
							state_main <= S_READ;
						end
						else  state_main <= S_PRECHARGE_AFTER;
					end
					
				end
			end
			
			S_NOT_PRECHARGE_IDLE_WRITE:
			begin
				if (!Serial_access_write) state_main <= S_PRECHARGE_AFTER;
				else
				begin
					if (m_valid_write)
					begin
						if (m_addr_set[21:9] == m_addr_write[21:9])
						begin
							flg_first_cmd <= 1;
							m_addr_set <= m_addr_write;
							state_main <= S_WRITE;
						end
						else  state_main <= S_PRECHARGE_AFTER;
					end
				end
			end
			
			S_ACTIVATE_ROW_READ:
			begin 
				if(cnt_wait != CL) cnt_wait <= cnt_wait + 1'b1;
				
				else
				
				begin 
					cnt_wait <= 0;
					flg_first_cmd <= 1;
					
					state_main <= S_READ;
				end 
			end
			
			S_ACTIVATE_ROW_WRITE:
			begin 
				if(cnt_wait != CL) cnt_wait <= cnt_wait + 1'b1;
				
				else
				
				begin 
					cnt_wait <= 0;
					flg_first_cmd <= 1;
					
					state_main <= S_WRITE;
					
				end 
			end
			
			S_WRITE: 
			
			begin
				if(flg_first_cmd) flg_first_cmd <= 0;
				
				else 
				begin 
				
					if(!m_valid_write) 
					begin
						m_ready_write<= 1'b0;
						
						if (Serial_access_write) state_main <= S_NOT_PRECHARGE_IDLE_WRITE;
						else  state_main <= S_PRECHARGE_AFTER;
						
					end
					else m_ready_write<= 1'b1;
					
				end
			end
						
			S_PRECHARGE_AFTER: 
			
			begin 
				
			begin
				if(cnt_wait != 3) cnt_wait <= cnt_wait + 1'b1;
				
				else 
				begin 
					cnt_wait <= 0;
					state_main <= S_IDLE;
				end
			end
				
			end
			
			S_READ:
			
			begin 
			
				if(flg_first_cmd) flg_first_cmd <= 0;
				
				else 
				begin
					
					if(!m_valid_read) 
					begin
					
						m_ready_read<= 1'b0;
					
						cnt_wait <= 0;
						
						if (Serial_access_read) state_main <= S_NOT_PRECHARGE_IDLE_READ;
						else  state_main <= S_PRECHARGE_AFTER;
						

					end
					
					else
					begin
						if (cnt_wait > CL) 
						begin
							m_ready_read<= 1'b1;
							out_data <= sd_data;
						end
						else cnt_wait <= cnt_wait + 1'b1;
					end
				end
				
				
			end
			
			
		endcase
	end
end


					  


always@(posedge clk_ref)
begin

	

	sd_cke <= (state_main == S_WAIT) ?  1'b0: 1'b1;

	sd_cs_n <= rst;

	sd_addr[14:13] <= m_addr_set[23:22]; //Set bunk number
	
	case(state_main)

		
		S_PRECHARGE_ALL, S_PRECHARGE_AFTER:  //precharge then NOP
		begin
			sd_cas_n <=	1'b1;
			sd_ras_n <= (cnt_wait == 0) ? 1'b0 : 1'b1;
			sd_we_n <= (cnt_wait == 0) ? 1'b0 : 1'b1;
			sd_addr[12:0] <= (cnt_wait == 0) ? {2'b0, 1'b1, 10'b0} : 13'd0;
			
		end
		
		S_AUTO_REFRESH: //autorefresh  then NOP
		begin
			sd_cas_n <= (cnt_wait[14:0] == 0) ? 1'b0 : 1'b1;
			sd_ras_n <= (cnt_wait[14:0] == 0) ? 1'b0 : 1'b1;
			sd_we_n	<= 1'b1;
			sd_addr[12:0] <= 'd0;
		end
		
		S_LOAD_MODE: //load mode then NOP
		begin
			sd_cas_n <= (cnt_wait == 0) ? 1'b0 : 1'b1;
			sd_ras_n <= (cnt_wait == 0) ? 1'b0 : 1'b1;
			sd_we_n <= (cnt_wait == 0) ? 1'b0 : 1'b1;
			sd_addr[12:0] <= (cnt_wait == 0)  ? {3'b000,1'b1,2'b00,CL[2:0],1'b0,3'b000} : 13'd0; 
			//BA[1:0]==0,A[12:10]==0,WRITE_BURST_MODE = 0,OP_MODE = 'd0, CL = 3, TYPE_BURST = 0, BURST_LENGTH = 1
		end
		
		S_ACTIVATE_ROW_WRITE,
		S_ACTIVATE_ROW_READ: //activate then NOP
		begin
			sd_cas_n <= 1'b1;
			sd_ras_n <= (cnt_wait==0) ? 1'b0 : 1'b1;
			sd_we_n <= 1'b1;
			sd_addr[12:0] <= (cnt_wait==0)  ? m_addr_set[21:9] : 13'd0;
		end
		
		S_WRITE: //WRITE or NOP
		begin
			sd_cas_n <= (m_valid_write == 1 && m_ready_write == 1) ? 1'b0 : 1'b1;
			sd_ras_n <= 1'b1;
			sd_we_n <= (m_valid_write == 1 && m_ready_write == 1) ? 1'b0 : 1'b1;
			sd_addr[12:0] <= {4'd0, m_addr_set[8:0]};
		end
		
		S_READ: //Read then NOP
		begin
			sd_cas_n <= (cnt_wait == 0) ? 1'b0 : 1'b1;
			sd_ras_n <=  1;
			sd_we_n <=  1;
			sd_addr[12:0] <= {4'd0,m_addr_set[8:0]};
		end
		
		
		default: //NOP
		begin
			sd_cas_n <=	1; 
			sd_ras_n<= 1;
			sd_we_n	<= 1;
			sd_addr[12:0] <= 0;
		
		end
	endcase

end







endmodule 