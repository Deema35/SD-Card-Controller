module M_SD_Card_CMD

(
	input wire clk,
	input wire rst,
	
	input wire Send_CMD_En,
	input wire Get_CMD_En,
	
	output wire Send_CMD_Complite,
	output wire Get_CMD_Complite,
	
	input wire [5:0] CMD_ID,
	input wire [7:0] Arg1,
	input wire [7:0] Arg2,
	input wire [7:0] Arg3,
	input wire [7:0] Arg4,
	
	
	output wire [47:0]Responce_R1_R3_Get,
	output wire [135:0]Responce_R2,

	inout tri cmd
);

wire cmd_w;
assign cmd = (Send_CMD_En) ? cmd_w : 1'bz;


wire [47:0]Responce_R1_R3;
wire [47:0]Responce_R1_R3_Send;
assign Responce_R1_R3 = (Send_CMD_En) ? Responce_R1_R3_Send : (Get_CMD_En) ? Responce_R1_R3_Get : 'd0;

wire CRC_Check_En_Send;
wire CRC_Check_En_Get;
wire CRC_Check_En;
assign CRC_Check_En = (Send_CMD_En) ? CRC_Check_En_Send : (Get_CMD_En) ? CRC_Check_En_Get : 1'b0;


wire CRC_Check_Valid;
wire [6:0]CRC;

M_CRC7 CRC7
(
	.clk(clk),
	.Enable(CRC_Check_En),
	.Message(Responce_R1_R3),
	.Valid(CRC_Check_Valid),
	.CRC(CRC)
);


M_SD_CMD_SEND SD_Cmd_Send
(
	.clk(clk),
	.rst(rst),
	.Enable(Send_CMD_En),
	.CMD_ID(CMD_ID),
	.Arg1(Arg1),
	.Arg2(Arg2),
	.Arg3(Arg3),
	.Arg4(Arg4),
	
	.Complite(Send_CMD_Complite),
	.cmd_w(cmd_w),
	
	.CRC_En(CRC_Check_En_Send),
	.CRC_Valid(CRC_Check_Valid),
	.Message(Responce_R1_R3_Send),
	.CRC(CRC)
);

M_SD_CMD_GET SD_CMD_GET
(
	.clk(clk),
	.rst(rst),
	.Enable(Get_CMD_En),
	.Command(CMD_ID),
	.cmd(cmd),
	
	.Responce_R1_R3(Responce_R1_R3_Get),
	.Responce_R2(Responce_R2),
	.Complite(Get_CMD_Complite),
	
	.CRC_Check_En(CRC_Check_En_Get),
	.CRC_Check_Valid(CRC_Check_Valid),
	.CRC(CRC)
);



endmodule 