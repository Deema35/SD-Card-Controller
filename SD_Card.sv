module SD_Card
#(
	parameter ENDFRAME = 11'd627,
	parameter FILE_END_BUF_ADDR = 'd1023,
	parameter ADDR_LEN = 'd9
)
(
	input wire clk_50,
	input reg RESET_N,
	input reg KEY_N,
	output wire LEDR,
	
	//SDRAM
	output wire   [12:0]	DRAM_ADDR, //SDRAM address
   output wire   [1:0] 	DRAM_BA, //SDRAM bank address
   output wire        DRAM_CKE, //SDRAM clock enable
   output wire           DRAM_CLK,	//SDRAM clock
   output wire    		DRAM_CS_N,//SDRAM Chip Selects
   inout  tri   [15:0]	DRAM_DQ,  //SDRAM data bus
	output wire           DRAM_UDQM, //SDRAM data mask lines
   output wire           DRAM_LDQM, //SDRAM data mask lines
   output wire        DRAM_RAS_N, //SDRAM Row address Strobe
	output wire        DRAM_CAS_N,  //SDRAM Column address Strobe
   output wire        DRAM_WE_N, //SDRAM write enable
	
	//Video interfase
	output wire Hsync,
	output wire Vsync,
	output wire [3:0]  Red,
	output wire [3:0]  Green,
	output wire [3:0]  Blue,
	
	//SD interface
	input wire wp_n,    //pmod_0[0]
	inout wire SD_clk_Out, //pmod_0[1]
	input wire cd_n,    //pmod_0[2]
	inout tri d0_MISO, //pmod_0[3]
	inout tri d2,      //pmod_0[4]
	inout tri cmd_MOSI,//pmod_0[5]
	inout tri d1,      //pmod_0[6]
	inout tri d3_cs    //pmod_0[7]
	
//	output reg Analiz_SD_clk = 1'b0,
//	output reg Analiz_cmd = 1'b0,
//	output reg [3:0] Analiz_DATA = 'd0

);
assign LEDR = (BMPCopy_Complite | BMPCopy_Fail) ? 1'b0 : 1'b1;

//assign Analiz_SD_clk = SD_clk_Out;
//assign Analiz_cmd = cmd_MOSI;
//assign Analiz_DATA = {d3_cs, d2, d1, d0_MISO};


wire clk_400k;
wire clk_25;
wire clk_120;
wire clk_40;

pll pll_clk
(
	.inclk0(clk_50),
	.c0(clk_400k),
	.c1(clk_25),
	.c2(clk_120),
	.c3(clk_40)
);

//..............................................................

//Video


wire [15:0]Pix_color;
wire [10:0] H_count;
wire [10:0] V_count;
wire Hblank;

M_VideoAdapter 
#(
	.ENDFRAME(ENDFRAME)
	
)
Video
(
	.clk(clk_40),
	.rst(!RESET_N),
	.Pix_color(Pix_color),
	.Hsync(Hsync),
	.Vsync(Vsync),
	.Red(Red),
	.Green(Green),
	.Blue(Blue),
	.H_count(H_count),
	.V_count(V_count),
	.Hblank(Hblank)
	
);

//SDRAM.......................
wire m_ready_read;
wire m_ready_write;
wire[15:0] m_in_data;
wire[15:0] m_out_data;
wire m_valid_write;
wire m_valid_read; 
wire  [23:0] m_addr_write;
wire  [23:0] m_addr_read;
wire  Serial_access_write;
wire  Serial_access_read;

M_String_Buffer
#(
	.ENDFRAME(ENDFRAME)
)
Video_Buffer
(
	.clk(clk_120),
	.rst(!RESET_N),
	.DATA(m_out_data),
	.DATA_valid(m_ready_read),
	.H_count(H_count),
	.V_count(V_count),
	.Hblank(Hblank),
	.Pix_color(Pix_color),
	.DATA_addr(m_addr_read),
	.DATA_in_ready(m_valid_read),
	.Serial_access(Serial_access_read)

);

M_sdram_control SDRAM_Controller
(
	.clk_ref(clk_120),
	.rst(!RESET_N),
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








//SD Modules.....................................................

wire [31:0]SD_Addr_Block;
wire SD_Enable;
wire SD_WE;
wire SD_Complite;
wire SD_Fail;
wire SD_Init_Complite;
wire SD_Init_Fail;

wire SD_Out_Data_Valid;
wire [15:0] SD_Out_Data_Addr;
wire [31:0] SD_Out_Data;

wire SD_InPut_Data_Valid;
wire [15:0] SD_InPut_Data_Addr;
wire [31:0] SD_InPut_Data;
wire [31:0] SD_SerialCount;
wire [21:0] SD_DeviseSize;

M_SD_Card SD_Card
(
	.clk_400k(clk_400k),
	.clk_Write(clk_400k),
	.clk_Read(clk_25),
	.rst(!RESET_N),
	
	//SD Command interface
	.SD_Addr_Block(SD_Addr_Block),
	.SD_Enable(SD_Enable),
	.SD_we(SD_WE),
	.SD_Complite(SD_Complite),
	.SD_Fail(SD_Fail),
	.SD_Init_Complite(SD_Init_Complite),
	.SD_Init_Fail(SD_Init_Fail),
	.SD_SerialCount(SD_SerialCount),
	.SD_DeviseSize(SD_DeviseSize),
	
	//SD DATA interface
	.SD_Out_Data_Valid(SD_Out_Data_Valid),
	.SD_Out_Data_Addr(SD_Out_Data_Addr),
	.SD_Out_Data(SD_Out_Data),
	.SD_InPut_Data_Valid(SD_InPut_Data_Valid),
	.SD_InPut_Data_Addr(SD_InPut_Data_Addr),
	.SD_InPut_Data(SD_InPut_Data),
	
	//SD Card interface
	.DATA({d3_cs, d2, d1, d0_MISO}),
	.cd_n(cd_n),
	.SD_clk_Out(SD_clk_Out),
	.cmd(cmd_MOSI)
);

reg BMPCopy_En = 1'b1;
wire BMPCopy_Complite;
wire BMPCopy_Fail;


wire DB_WE;

wire [ADDR_LEN:0] DB_write_addr;
wire [31:0] DB_write_data;

wire [ADDR_LEN:0] DB_read_addr;
wire [7:0] DB_read_data;

M_MEMORY_BUF 
#(
	.FILE_END_BUF_ADDR(FILE_END_BUF_ADDR),
	.ADDR_LEN(ADDR_LEN)
)
Memory_buf
(
	.clk(clk_120),
	.we(DB_WE),
	
	.read_addr(DB_read_addr),
	.write_addr(DB_write_addr),
	.write_data(DB_write_data),
	
	.read_data(DB_read_data)
	
);






M_BMP_Copire 
#(
	.FILE_END_BUF_ADDR(FILE_END_BUF_ADDR),
	.ADDR_LEN(ADDR_LEN)
)
BMP_Copire
(
	.clk(clk_120),
	.rst(!RESET_N),
	.BMPCopy_En(BMPCopy_En),
	
	.BMPCopy_Complite(BMPCopy_Complite),
	.BMPCopy_Fail(BMPCopy_Fail),
	
	//SD card
	
	.SD_Init_Complite(SD_Init_Complite),
	.SD_Addr_Block(SD_Addr_Block),
	.SD_Complite(SD_Complite),
	.SD_Enable(SD_Enable),
	.SD_Fail(SD_Fail),
	
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
	.m_in_data(m_in_data),
	
	
	//Memory buffer
	.DB_WE(DB_WE),

	.DB_write_addr(DB_write_addr),
	.DB_write_data(DB_write_data),

	.DB_read_addr(DB_read_addr),
	.DB_read_data(DB_read_data)

);





endmodule 



