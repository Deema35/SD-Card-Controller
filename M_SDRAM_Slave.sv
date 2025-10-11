module M_SDRAM_Slave 
(
	
	input wire [12:0] sd_addr_slave, //SDRAM address
   input wire [1:0] sd_bank_slave, //SDRAM bank address
   input wire sd_cke_slave, //SDRAM clock enable
   input wire sd_clk_slave,	//SDRAM clock
   input wire sd_cs_n_slave,//SDRAM Chip Selects
   inout  tri [15:0]	sd_data_slave,  //SDRAM data bus
	input wire sd_dqmh_slave, //SDRAM data mask lines
   input wire sd_dqml_slave, //SDRAM data mask lines
   input wire sd_ras_n_slave, //SDRAM Row address Strobe
	input wire sd_cas_n_slave,  //SDRAM Column address Strobe
   input wire sd_we_n_slave //SDRAM write enable

);

reg [2:0] cl = 'd0;
reg [12:0]addr_temp;


reg [15:0] DATA [1023:0];
reg [12:0] ROW = 'd0;
reg [8:0] COLUMM = 'd0;

wire [23:0] Cell_Addr;
assign Cell_Addr = {sd_bank_slave, ROW, COLUMM};  //2bit BANK, 13bit ROW, 9bit COLUMM

assign  sd_data_slave = (State_main_Slave == S_READ) ? Read_Data : 16'hzzzz;
reg [15:0] Read_Data = 'd0;
wire clk;
assign clk =  sd_clk_slave;

reg[7:0] Waite_count = 'd0;

reg [7:0] State_main_Slave = S_IDLE;


localparam 	S_IDLE = 8'd0,
				S_READY = 8'd1,
				S_PRECHARGE = 8'd3,
				S_AUTO_REFRESH = 8'd4,
				S_LOAD_MODE = 8'd5,
				S_ACTIVATE_ROW =  8'd6,
				S_WRITE = 8'd7,
				S_READ = 8'd8;
				
	
always@(posedge clk)
begin
	case(State_main_Slave)
	S_IDLE: if (!sd_cs_n_slave) State_main_Slave <= S_READY;
	
	S_READY:
	begin
		if (sd_cas_n_slave & !sd_ras_n_slave & sd_we_n_slave)
		begin
			
			State_main_Slave <= S_ACTIVATE_ROW;
			ROW <= sd_addr_slave;
		end
		else if (sd_cas_n_slave & !sd_ras_n_slave & !sd_we_n_slave)
		begin
			if(sd_addr_slave == {2'b0, 1'b1, 10'b0}) State_main_Slave <= S_PRECHARGE;
		end
		else if (!sd_cas_n_slave & !sd_ras_n_slave & sd_we_n_slave)
		begin
			State_main_Slave <= S_AUTO_REFRESH;
		end
		else if (!sd_cas_n_slave & !sd_ras_n_slave & !sd_we_n_slave)
		begin
			State_main_Slave <= S_LOAD_MODE;
			cl <= sd_addr_slave[6:4];
		end
		else if (!sd_cas_n_slave & sd_ras_n_slave & !sd_we_n_slave)
		begin
			State_main_Slave <= S_WRITE;
			COLUMM <= sd_addr_slave;
			DATA[{sd_bank_slave, ROW, sd_addr_slave}] <= sd_data_slave;
		end
		else if (!sd_cas_n_slave & sd_ras_n_slave & sd_we_n_slave)
		begin
			State_main_Slave <= S_READ;
			COLUMM <= sd_addr_slave;
		end
		
	end
	
	S_PRECHARGE:
	begin
		//$display("SDRAM_Slave--> Prechrge. ROW = 0");
		ROW <= 'd0;
		State_main_Slave <= S_READY;
	end
	S_AUTO_REFRESH:
	begin
		
		//$display("SDRAM_Slave--> Refresh");
		State_main_Slave <= S_READY;
		
	end
	S_LOAD_MODE:
	begin
		$display("SDRAM_Slave--> Load mode CL = %d", cl);
		State_main_Slave <= S_READY;
	end
	S_ACTIVATE_ROW:
	begin
		//$display("SDRAM_Slave--> Active row ROW = %d", ROW);
		State_main_Slave <= S_READY;
	end
	S_WRITE:
	begin
		//$display("SDRAM_Slave--> Write Addr = %h, Data = %h", Cell_Addr, DATA[Cell_Addr]);
		
		State_main_Slave <= S_READY;
	end
	S_READ:
	begin
		if (Waite_count == cl + 1)
		begin
			//$display("SDRAM_Slave--> Read Addr = %h, Data = %h", Cell_Addr, DATA[Cell_Addr]);
			
			State_main_Slave <= S_READY;
		end
		
		else	Waite_count <= Waite_count + 1;
		Read_Data <= DATA[Cell_Addr];
	end
	endcase
end

endmodule 