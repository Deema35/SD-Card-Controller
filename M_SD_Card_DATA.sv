module M_SD_Card_DATA
#(
	parameter DATA_STRING = 'd128
)
(
	input wire clk,
	input wire rst,
	
	input wire Get_DATA_En,
	output wire Get_DATA_Complite,
	output wire Get_DATA_CRC_Fail,
	
	input wire Send_DATA_En,
	output wire Send_DATA_Complite,
	
	input wire [31:0] BlockReadCount,
	input wire [31:0] BlockWriteCount,
	
	//In data interface
	output wire InPut_Data_Valid,
	output wire [31:0] InPut_Data_Addr,
	input wire [31:0]InPut_Data,
	
	//Out data interface
	output wire [31:0] Out_Data_Addr,
	output wire Out_Data_Valid,
	output wire [31:0]Out_Data,
	
	//SD Card interface
	inout tri [3:0]DATA
);

wire CRC_En;
wire CRC_En_Get;
wire CRC_En_Send;
assign CRC_En = (Get_DATA_En) ? CRC_En_Get : (Send_DATA_En) ? CRC_En_Send : 1'b0;

wire CRC_Data_Get;
wire CRC_Data_Get_Get;
wire CRC_Data_Get_Send;
assign CRC_Data_Get = (Get_DATA_En) ? CRC_Data_Get_Get : (Send_DATA_En) ? CRC_Data_Get_Send : 1'b0;

wire CRC_Valid;


wire [7:0] CRC_Data_0;
wire [7:0] CRC_Data_0_Get;
wire [7:0] CRC_Data_0_Send;
assign CRC_Data_0 = (Get_DATA_En) ? CRC_Data_0_Get : (Send_DATA_En) ? CRC_Data_0_Send : 1'b0;

wire [7:0] CRC_Data_1;
wire [7:0] CRC_Data_1_Get;
wire [7:0] CRC_Data_1_Send;
assign CRC_Data_1 = (Get_DATA_En) ? CRC_Data_1_Get : (Send_DATA_En) ? CRC_Data_1_Send : 1'b0;

wire [7:0] CRC_Data_2;
wire [7:0] CRC_Data_2_Get;
wire [7:0] CRC_Data_2_Send;
assign CRC_Data_2 = (Get_DATA_En) ? CRC_Data_2_Get : (Send_DATA_En) ? CRC_Data_2_Send : 1'b0;

wire [7:0] CRC_Data_3;
wire [7:0] CRC_Data_3_Get;
wire [7:0] CRC_Data_3_Send;
assign CRC_Data_3 = (Get_DATA_En) ? CRC_Data_3_Get : (Send_DATA_En) ? CRC_Data_3_Send : 1'b0;

wire [15:0] CRC_0;
wire [15:0] CRC_1;
wire [15:0] CRC_2;
wire [15:0] CRC_3;

wire [15:0]Index_0;
wire [15:0]Index_1;
wire [15:0]Index_2;
wire [15:0]Index_3;

wire [15:0]ROM_Data_0;
wire [15:0]ROM_Data_1;
wire [15:0]ROM_Data_2;
wire [15:0]ROM_Data_3;

M_CRC16 
#(
	.DATA_STRING(DATA_STRING)
)
CRC16_0
(
	.clk(clk),
	.Enable(CRC_En),
	.GetData(CRC_Data_Get),
	.Data(CRC_Data_0),
	.Valid(CRC_Valid),
	.CRC(CRC_0),
	
	.Index(Index_0),
	.ROM_Data(ROM_Data_0)
);


M_CRC16 
#(
	.DATA_STRING(DATA_STRING)
)
CRC16_1
(
	.clk(clk),
	.Enable(CRC_En),
	.GetData(CRC_Data_Get),
	.Data(CRC_Data_1),
	.CRC(CRC_1),
	
	.Index(Index_1),
	.ROM_Data(ROM_Data_1)
);


M_CRC16 
#(
	.DATA_STRING(DATA_STRING)
)
CRC16_2
(
	.clk(clk),
	.Enable(CRC_En),
	.GetData(CRC_Data_Get),
	.Data(CRC_Data_2),
	.CRC(CRC_2),
	
	.Index(Index_2),
	.ROM_Data(ROM_Data_2)
);

M_CRC16 
#(
	.DATA_STRING(DATA_STRING)
)
CRC16_3
(
	.clk(clk),
	.Enable(CRC_En),
	.GetData(CRC_Data_Get),
	.Data(CRC_Data_3),
	.CRC(CRC_3),
	
	.Index(Index_3),
	.ROM_Data(ROM_Data_3)
);

M_CRC16_ROM CRC_Table
(
	.Index_0(Index_0),
	.Index_1(Index_1),
	.Index_2(Index_2),
	.Index_3(Index_3),
	
	.ROM_Data_0(ROM_Data_0),
	.ROM_Data_1(ROM_Data_1),
	.ROM_Data_2(ROM_Data_2),
	.ROM_Data_3(ROM_Data_3)
);


M_SD_DATA_GET 
#(
	.DATA_STRING(DATA_STRING)
)
	SD_DATA_GET
(
	.clk(clk),
	.rst(rst),
	.Get_DATA_En(Get_DATA_En),
	.DATA(DATA),
	
	.Get_DATA_Complite(Get_DATA_Complite),
	.Get_DATA_CRC_Fail(Get_DATA_CRC_Fail),
	
	.Out_Data_Addr(Out_Data_Addr),
	.Out_Data_Valid(Out_Data_Valid),
	.Out_Data(Out_Data),
	
	.CRC_En(CRC_En_Get),
	.CRC_Valid(CRC_Valid),
	.CRC_Data_Get(CRC_Data_Get_Get),

	.Temp_Byte_0(CRC_Data_0_Get),
	.Temp_Byte_1(CRC_Data_1_Get),
	.Temp_Byte_2(CRC_Data_2_Get),
	.Temp_Byte_3(CRC_Data_3_Get),
	
	.BlockReadCount(BlockReadCount),

	.CRC_0(CRC_0),
	.CRC_1(CRC_1),
	.CRC_2(CRC_2),
	.CRC_3(CRC_3)
);



M_SD_DATA_SEND 
#(
	.DATA_STRING(DATA_STRING)
)
	SD_DATA_SEND
(
	.clk(clk),
	.rst(rst),
	.Send_DATA_En(Send_DATA_En),
	
	.InPut_Data(InPut_Data),
	.InPut_Data_Valid(InPut_Data_Valid),
	.InPut_Data_Addr(InPut_Data_Addr),
	
	.Send_DATA_Complite(Send_DATA_Complite),
	.DATA(DATA),
	
	.CRC_En(CRC_En_Send),
	.CRC_Data_Get(CRC_Data_Get_Send),
	
	.Part_Byte_0(CRC_Data_0_Send),
	.Part_Byte_1(CRC_Data_1_Send),
	.Part_Byte_2(CRC_Data_2_Send),
	.Part_Byte_3(CRC_Data_3_Send),

	.BlockWriteCount(BlockWriteCount),

	.CRC_0(CRC_0),
	.CRC_1(CRC_1),
	.CRC_2(CRC_2),
	.CRC_3(CRC_3)
	
);
endmodule 