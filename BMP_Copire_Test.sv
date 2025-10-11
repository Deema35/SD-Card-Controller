module BMP_Copire_Test
#(
	parameter SKIP_INIT = 'd1,
	parameter FILE_END_BUF_ADDR = 'd1023
);

reg clk_400k = 1'b0;
reg clk_120 = 1'b0; 
reg clk_25 = 1'b0; 
reg rst = 1'b0;


always #1 clk_120 = ~clk_120;
always #1 clk_25 = ~clk_25;
always #1 clk_400k = ~clk_400k;

reg BMPCopy_En = 1'b1;
wire BMPCopy_Complite;
wire BMPCopy_Fail;





M_BMP_Copire 
#(
	.FILE_END_BUF_ADDR(FILE_END_BUF_ADDR)
)
BMP_Copire
(
	.clk(clk_120),
	.rst(rst),
	.BMPCopy_En(BMPCopy_En),
	
	.BMPCopy_Complite(BMPCopy_Complite),
	.BMPCopy_Fail(BMPCopy_Fail),
	
	.SD_Init_Complite(SD_Init_Complite),
	.SD_Addr_Block(SD_Addr_Block),
	.SD_Complite(SD_Complite),
	.SD_Enable(SD_Enable),
	.SD_Fail(SD_Fail),
	
	//SD card
	
	.SD_SerialCount(SD_SerialCount),
	
	.SD_Out_Data_Valid(SD_Out_Data_Valid),
	.SD_Out_Data_Addr(SD_Out_Data_Addr),
	.SD_Out_Data(SD_Out_Data),

	.SD_InPut_Data_Valid(SD_InPut_Data_Valid),
	.SD_InPut_Data_Addr(SD_InPut_Data_Addr),
	.SD_InPut_Data(SD_InPut_Data),
	
	//SDRAM
	
	.Serial_access_write(Serial_access_write),
	.m_ready_write(m_ready_write),
	.m_valid_write(m_valid_write),
	.m_addr_write(m_addr_write),
	.m_in_data(m_in_data)

	
);
// SD Card
reg cd_n = 1'b0;


wire [3:0]DATA;
pullup(DATA[0]);
pullup(DATA[1]);
pullup(DATA[2]);
pullup(DATA[3]);

wire cmd;

wire SD_Enable;
reg SD_we = 1'b0;
wire [31:0] SD_Addr_Block;
reg SD_WE = 1'b0;

wire SD_Complite;
wire SD_Fail;
wire SD_Init_Complite;
wire SD_Init_Fail;

wire SD_Out_Data_Valid;
wire [31:0] SD_Out_Data_Addr;
wire [31:0]SD_Out_Data;

wire SD_InPut_Data_Valid;
wire [31:0]SD_InPut_Data_Addr;
wire [31:0]SD_InPut_Data;
wire [31:0] SD_SerialCount;

wire SD_clk_Out;


M_SD_Card
#(
	.POWER_RISE('d1),
	.DELAY('d1),
	.SKIP_INIT(SKIP_INIT)
)
SD_Card
(
	.clk_400k(clk_400k),
	.clk_Write(clk_400k),
	.clk_Read(clk_25),
	.rst(rst),
	
	//SD Command interface
	.SD_Addr_Block(SD_Addr_Block),
	.SD_Enable(SD_Enable),
	.SD_we(SD_we),
	.SD_Complite(SD_Complite),
	.SD_Fail(SD_Fail),
	.SD_Init_Complite(SD_Init_Complite),
	.SD_Init_Fail(SD_Init_Fail),
	.SD_SerialCount(SD_SerialCount),
	
	//SD DATA interface
	.SD_Out_Data_Valid(SD_Out_Data_Valid),
	.SD_Out_Data_Addr(SD_Out_Data_Addr),
	.SD_Out_Data(SD_Out_Data),
	.SD_InPut_Data_Valid(SD_InPut_Data_Valid),
	.SD_InPut_Data_Addr(SD_InPut_Data_Addr),
	.SD_InPut_Data(SD_InPut_Data),
	
	//SD Card interface
	.DATA(DATA),
	.cd_n(cd_n),
	.SD_clk_Out(SD_clk_Out),
	.cmd(cmd)
);




M_SD_Card_Slave 
#(
	.SKIP_INIT(SKIP_INIT)
)
SD_Card_Slave
(
	.clk(SD_clk_Out),
	.rst(rst),
	.SD_SerialCount(SD_SerialCount),
	.DATA(DATA),
	.cmd(cmd)
);

//SDRAM

wire [15:0] m_in_data;
wire [23:0] m_addr_write;
wire [23:0] m_addr_read;
wire m_valid_write;
wire m_valid_read;
wire Serial_access_write;
wire Serial_access_read;

wire m_ready_write;
wire m_ready_read;

wire [15:0] m_out_data;

//SDRAM interface
wire [12:0] DRAM_ADDR; //SDRAM address
wire [1:0] DRAM_BA; //SDRAM bank address
wire DRAM_CKE; //SDRAM clock enable
wire  DRAM_CLK;	//SDRAM clock
wire DRAM_CS_N;//SDRAM Chip Selects
wire [15:0] DRAM_DQ;  //SDRAM data bus
wire DRAM_UDQM; //SDRAM data mask lines
wire DRAM_LDQM; //SDRAM data mask lines
wire DRAM_RAS_N; //SDRAM Row address Strobe
wire DRAM_CAS_N;  //SDRAM Column address Strobe
wire DRAM_WE_N; //SDRAM write enable

pullup(DRAM_CS_N);
pullup(DRAM_RAS_N);
pullup(DRAM_CAS_N);	
pullup(DRAM_WE_N);

M_sdram_control
#(
	.INIT_PER('d1), 
	.NOP_WAITE('d1)
) 
SDRAM_Controller
(
	.clk_ref(clk_120),
	.rst(rst),
	.in_data(m_in_data),
	.m_addr_read(m_addr_read),
	.m_addr_write(m_addr_write),
	.m_valid_read(m_valid_read),
	.m_valid_write(m_valid_write),
	.Serial_access_write(Serial_access_write),
	.Serial_access_read(Serial_access_read),
	
	.m_ready_write(m_ready_write),
	.m_ready_read(m_ready_read),
	
	.out_data(m_out_data),
	
	.sd_cke(DRAM_CKE),
	.sd_clk(DRAM_CLK),
	.sd_dqml(DRAM_LDQM),
	.sd_dqmh(DRAM_UDQM),
	.sd_cas_n(DRAM_CAS_N),
	.sd_ras_n(DRAM_RAS_N),
	.sd_we_n(DRAM_WE_N),
	.sd_cs_n(DRAM_CS_N),
	.sd_addr({DRAM_BA, DRAM_ADDR}),
	.sd_data(DRAM_DQ)
	
);

M_SDRAM_Slave SDRAM_Slave
(
	.sd_addr_slave(DRAM_ADDR),
   .sd_bank_slave(DRAM_BA), 
   .sd_cke_slave(DRAM_CKE),
   .sd_clk_slave(DRAM_CLK),
   .sd_cs_n_slave(DRAM_CS_N),
   .sd_data_slave(DRAM_DQ), 
	.sd_dqmh_slave(DRAM_UDQM),
   .sd_dqml_slave(DRAM_LDQM),
   .sd_ras_n_slave(DRAM_RAS_N), 
	.sd_cas_n_slave(DRAM_CAS_N), 
   .sd_we_n_slave(DRAM_WE_N)
);

reg [15:0] data_read = 'd0;

reg [7:0] State_main = S_IDLE;

localparam 	S_IDLE = 8'd0,
				S_START = 8'd1,
				S_END = 8'd253,
				S_COMPLITE = 8'd254,
				S_FAIL = 8'd255;

always @(posedge clk_120) 
begin
	case(State_main)
	S_IDLE:
	begin
		$write("%c[1;34m",27);
		$display("");
		$display("*********** BMP copire test start. ***********");
		$write("%c[0m",27);
		
		State_main <= S_START;
	end
	S_START:
	begin
		
		if (BMPCopy_Complite) State_main <= S_COMPLITE;
		else if (BMPCopy_Fail) State_main <= S_FAIL;
		else BMPCopy_En <= 1'b1;
	end
	S_COMPLITE:
	begin
		$write("%c[1;32m",27);
		$display("SD Complite, time =", $stime);
		$display("%c[0m",27);
		
		State_main <= S_END;;
	end
	S_FAIL: 
	begin
		$write("%c[1;31m",27);
		$display("SD Fail, time =", $stime);
		$display("%c[0m",27);
		
		State_main <= S_END;
	end
	endcase
end

initial  #110500 $finish;

initial
begin
  $dumpfile("out.vcd");
  $dumpvars(0,BMP_Copire);
  $dumpvars(0,SDRAM_Controller);
  $dumpvars(0,SD_Card);
  $dumpvars(0,SD_Card_Slave);
  
end

endmodule 