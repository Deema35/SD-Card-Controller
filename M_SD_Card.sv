module M_SD_Card
#(
	parameter POWER_RISE = 'd100000,
	parameter DELAY = 'd100,
	parameter SKIP_INIT = 'd0
)
(
	input wire clk_400k,
	input wire clk_Write,
	input wire clk_Read,
	input wire rst,
	
	
	
	//SD Command interface
	input wire [31:0]SD_Addr_Block,
	input wire SD_Enable,
	input wire SD_we,
	output wire SD_Complite,
	output wire SD_Fail,
	output wire SD_Init_Complite,
	output wire SD_Init_Fail,
	input wire [31:0] SD_SerialCount,
	output wire [21:0] SD_DeviseSize,
	
	//SD DATA interface
	output wire SD_Out_Data_Valid,
	output wire [31:0] SD_Out_Data_Addr,
	output wire [31:0] SD_Out_Data,
	output wire SD_InPut_Data_Valid,
	output wire [31:0] SD_InPut_Data_Addr,
	input wire [31:0] SD_InPut_Data,
	
	
	//SD Card interface
	inout tri [3:0]DATA,
	input wire cd_n,
	output wire SD_clk_Out,
	inout tri cmd
);

wire StandBy;

wire SD_clk = (!SD_Init_Complite) ? clk_400k : 
					(SD_we) ? clk_Write : clk_Read;
					
assign SD_clk_Out = (cd_n | StandBy) ? 1'bz :  SD_clk;

wire Get_DATA_En;
wire Get_DATA_Complite;
wire Get_DATA_CRC_Fail;
	
wire Send_DATA_En;
wire Send_DATA_Complite;

wire Send_CMD_En;
wire Get_CMD_En;
	
wire Send_CMD_Complite;
wire Get_CMD_Complite;
	
wire [5:0] CMD_ID;
wire [7:0] Arg1;
wire [7:0] Arg2;
wire [7:0] Arg3;
wire [7:0] Arg4;
	
wire [135:0]Responce_R2;
wire [47:0]Responce_R1_R3_Get;


wire [31:0] BlockReadCount;
wire [31:0] BlockWriteCount;


M_SD_Card_Control 
#(
	.POWER_RISE(POWER_RISE),
	.DELAY(DELAY),
	.SKIP_INIT(SKIP_INIT)
)
SD_Card_Control
(
	.clk(SD_clk),
	.rst(rst),
	.SD_Enable(SD_Enable),
	.SD_Addr_Block(SD_Addr_Block),
	.SD_we(SD_we),
	.Busy_Bit(DATA[0]),
	.StandBy(StandBy),
	
	.DeviseSize(SD_DeviseSize),
	
	.Get_DATA_En(Get_DATA_En),
	.Get_DATA_Complite(Get_DATA_Complite),
	.Get_DATA_CRC_Fail(Get_DATA_CRC_Fail),
	
	.Send_DATA_En(Send_DATA_En),
	.Send_DATA_Complite(Send_DATA_Complite),
	
	.SD_Complite(SD_Complite),
	.SD_Fail(SD_Fail),
	.SD_Init_Complite(SD_Init_Complite),
	.SD_Init_Fail(SD_Init_Fail),
	
	.Send_CMD_En(Send_CMD_En),
	.Get_CMD_En(Get_CMD_En),
	
	.Send_CMD_Complite(Send_CMD_Complite),
	.Get_CMD_Complite(Get_CMD_Complite),
	
	.CMD_ID(CMD_ID),
	.Arg1(Arg1),
	.Arg2(Arg2),
	.Arg3(Arg3),
	.Arg4(Arg4),
	
	.Responce_R1_R3_Get(Responce_R1_R3_Get),
	.Responce_R2(Responce_R2),
	
	.SerialCount(SD_SerialCount),
	.BlockReadCount(BlockReadCount),
	.BlockWriteCount(BlockWriteCount),
	
	.cd_n(cd_n)
);



M_SD_Card_CMD SD_Card_CMD
(
	.clk(SD_clk),
	.rst(rst),
	
	.Send_CMD_En(Send_CMD_En),
	.Get_CMD_En(Get_CMD_En),
	
	.Send_CMD_Complite(Send_CMD_Complite),
	.Get_CMD_Complite(Get_CMD_Complite),
	
	.CMD_ID(CMD_ID),
	.Arg1(Arg1),
	.Arg2(Arg2),
	.Arg3(Arg3),
	.Arg4(Arg4),
	
	.Responce_R1_R3_Get(Responce_R1_R3_Get),
	.Responce_R2(Responce_R2),
	
	.cmd(cmd)
);

M_SD_Card_DATA SD_Card_DATA
(
	.clk(SD_clk),
	.rst(rst),
	
	.Get_DATA_En(Get_DATA_En),
	.Get_DATA_Complite(Get_DATA_Complite),
	.Get_DATA_CRC_Fail(Get_DATA_CRC_Fail),
	
	.Send_DATA_En(Send_DATA_En),
	.Send_DATA_Complite(Send_DATA_Complite),
	
	.BlockReadCount(BlockReadCount),
	.BlockWriteCount(BlockWriteCount),
	
	.InPut_Data_Valid(SD_InPut_Data_Valid),
	.InPut_Data_Addr(SD_InPut_Data_Addr),
	.InPut_Data(SD_InPut_Data),
	

	.Out_Data_Addr(SD_Out_Data_Addr),
	.Out_Data_Valid(SD_Out_Data_Valid),
	.Out_Data(SD_Out_Data),
	
	.DATA(DATA)
);
endmodule 