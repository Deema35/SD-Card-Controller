module M_SD_Card_Control

#(
	parameter POWER_RISE = 'd100000,
	parameter DELAY = 'd100,
	parameter SKIP_INIT = 'd0
)
(
	input wire clk,
	input wire rst,
	input wire SD_Enable,
	input wire [31:0] SD_Addr_Block,
	input wire SD_we,
	
	input wire Busy_Bit,
	output reg StandBy = 1'b0,
	
	output wire [21:0]DeviseSize,
	
	output wire Get_DATA_En,
	input wire Get_DATA_Complite,
	input wire Get_DATA_CRC_Fail,
	
	output wire Send_DATA_En,
	input wire Send_DATA_Complite,
	
	output reg SD_Complite = 1'b0,
	output reg SD_Fail = 1'b0,
	output reg SD_Init_Complite = 1'b0,
	output reg SD_Init_Fail = 1'b0,
	
	output wire Send_CMD_En,
	output wire Get_CMD_En,
	
	input wire Send_CMD_Complite,
	input wire Get_CMD_Complite,
	
	output wire [5:0] CMD_ID,
	output wire [7:0] Arg1,
	output wire [7:0] Arg2,
	output wire [7:0] Arg3,
	output wire [7:0] Arg4,
	
	input wire [135:0]Responce_R2,
	input wire [47:0]Responce_R1_R3_Get,
	
	input wire [31:0] SerialCount,
	output wire [31:0] BlockReadCount,
	output wire [31:0] BlockWriteCount,
	
	input wire cd_n

);

wire [7:0] PNM[4:0];
wire [15:0] RCA_Addr;


reg Init_Enable = 1'b0;
reg Read_Enable = 1'b0;
reg Write_Enable = 1'b0;

wire Init_complite;
wire Init_Fail;



wire Send_CMD_En_Init;
wire Send_CMD_En_Read;
wire Send_CMD_En_Write;
wire Send_CMD_En_Check;
assign Send_CMD_En = (Init_Enable) ? Send_CMD_En_Init : 
							(Read_Enable) ? Send_CMD_En_Read :
							(Write_Enable) ? Send_CMD_En_Write :
							(CheckState_En) ? Send_CMD_En_Check : 1'b0; 



wire Get_CMD_En_Init;
wire Get_CMD_En_Read;
wire Get_CMD_En_Write;
wire Get_CMD_En_Check;
assign Get_CMD_En = (Init_Enable) ? Get_CMD_En_Init : 
							(Read_Enable) ? Get_CMD_En_Read : 
							(Write_Enable) ? Get_CMD_En_Write :
							(CheckState_En) ? Get_CMD_En_Check : 1'b0;
							







wire [5:0] CMD_ID_Init;
wire [5:0] CMD_ID_Read;
wire [5:0] CMD_ID_Write;
wire [5:0] CMD_ID_Check;
assign CMD_ID = (Init_Enable) ? CMD_ID_Init : 
					(Read_Enable) ? CMD_ID_Read :
					(Write_Enable) ? CMD_ID_Write :
					(CheckState_En) ? CMD_ID_Check : 6'd0;


wire [7:0] Arg1_Init;
wire [7:0] Arg1_Read;
wire [7:0] Arg1_Write;
wire [7:0] Arg1_Check;
assign Arg1 = (Init_Enable) ? Arg1_Init : 
					(Read_Enable) ? Arg1_Read :
					(Write_Enable) ? Arg1_Write :
					(CheckState_En) ? Arg1_Check : 8'd0;

wire [7:0] Arg2_Init;
wire [7:0] Arg2_Read;
wire [7:0] Arg2_Write;
wire [7:0] Arg2_Check;
assign Arg2 = (Init_Enable) ? Arg2_Init : 
					(Read_Enable) ? Arg2_Read :
					(Write_Enable) ? Arg2_Write :
					(CheckState_En) ? Arg2_Check : 8'd0;
					
wire [7:0] Arg3_Init;
wire [7:0] Arg3_Read;
wire [7:0] Arg3_Write;
wire [7:0] Arg3_Check;
assign Arg3 = (Init_Enable) ? Arg3_Init : 
					(Read_Enable) ? Arg3_Read :
					(Write_Enable) ? Arg3_Write :
					(CheckState_En) ? Arg3_Check : 8'd0;
					
wire [7:0] Arg4_Init;
wire [7:0] Arg4_Read;
wire [7:0] Arg4_Write;
wire [7:0] Arg4_Check;
assign Arg4 = (Init_Enable) ? Arg4_Init : 
					(Read_Enable) ? Arg4_Read :
					(Write_Enable) ? Arg4_Write :
					(CheckState_En) ? Arg4_Check : 8'd0;



M_SD_Card_Init SD_Card_Init
(

	.clk_400k(clk),
	.rst(rst), 
	.Init_Enable(Init_Enable),
	.Responce_R1_R3(Responce_R1_R3_Get),
	.Responce_R2(Responce_R2),
	
	.CMD_ID(CMD_ID_Init),
	.Arg1(Arg1_Init),
	.Arg2(Arg2_Init),
	.Arg3(Arg3_Init),
	.Arg4(Arg4_Init),
	
	.Send_CMD_En(Send_CMD_En_Init),
	.Get_CMD_En(Get_CMD_En_Init),
	.Send_CMD_Complite(Send_CMD_Complite),
	.Get_CMD_Complite(Get_CMD_Complite),
	
	.PNM(PNM),
	.RCA_Addr(RCA_Addr),
	.DeviseSize(DeviseSize),
	.Init_complite(Init_complite),
	.Init_Fail
);


wire Read_complite;
wire Read_Fail;

M_SD_Card_Read SD_Card_Read
(

	.clk(clk),
	.rst(rst),
	.Read_Enable(Read_Enable),
	
	.Responce_R1_R3(Responce_R1_R3_Get),
	
	.RCA_Addr(RCA_Addr),
	.SD_Addr_Block(SD_Addr_Block),
		
	.CMD_ID(CMD_ID_Read),
	.Arg1(Arg1_Read),
	.Arg2(Arg2_Read),
	.Arg3(Arg3_Read),
	.Arg4(Arg4_Read),
	
	.Send_CMD_En(Send_CMD_En_Read),
	.Get_CMD_En(Get_CMD_En_Read),
	.Get_DATA_En(Get_DATA_En),
	.Send_CMD_Complite(Send_CMD_Complite),
	.Get_CMD_Complite(Get_CMD_Complite),
	.Get_DATA_Complite(Get_DATA_Complite),
	.Get_DATA_CRC_Fail(Get_DATA_CRC_Fail),
	
	.SerialCount(SerialCount),
	.BlockReadCount(BlockReadCount),
	
	.Read_complite(Read_complite),
	.Read_Fail(Read_Fail)
);


wire Write_complite;
wire Write_Fail;


M_SD_Card_Write SD_Card_Write
(

	.clk(clk),
	.rst(rst),
	.Write_Enable(Write_Enable),
	
	.Responce_R1_R3(Responce_R1_R3_Get),
	
	.RCA_Addr(RCA_Addr),
	.SD_Addr_Block(SD_Addr_Block),
	
	.CMD_ID(CMD_ID_Write),
	.Arg1(Arg1_Write),
	.Arg2(Arg2_Write),
	.Arg3(Arg3_Write),
	.Arg4(Arg4_Write),
	
	.Send_CMD_En(Send_CMD_En_Write),
	.Get_CMD_En(Get_CMD_En_Write),
	.Send_DATA_En(Send_DATA_En),
	.Send_CMD_Complite(Send_CMD_Complite),
	.Get_CMD_Complite(Get_CMD_Complite),
	.Send_DATA_Complite(Send_DATA_Complite),
	
	.SerialCount(SerialCount),
	.BlockWriteCount(BlockWriteCount), 
	
	.Busy_Bit(Busy_Bit),
	
	.Write_complite(Write_complite),
	.Write_Fail(Write_Fail)
);

reg CheckState_En = 1'b0;
wire CheckState_Complite;
wire CheckState_Fail;

M_SD_Card_Check_State SD_Card_Check_State
(

	.clk(clk),
	.rst(rst),
	.CheckState_En(CheckState_En),
	.CheckState_Complite(CheckState_Complite),
	.CheckState_Fail(CheckState_Fail),
	
	.Busy_Bit(Busy_Bit),
	
	.RCA_Addr(RCA_Addr),
	.Responce_R1_R3(Responce_R1_R3_Get),
	
	.CMD_ID(CMD_ID_Check),
	.Arg1(Arg1_Check),
	.Arg2(Arg2_Check),
	.Arg3(Arg3_Check),
	.Arg4(Arg4_Check),
	
	.Send_CMD_En(Send_CMD_En_Check),
	.Get_CMD_En(Get_CMD_En_Check),
	
	.Send_CMD_Complite(Send_CMD_Complite),
	.Get_CMD_Complite(Get_CMD_Complite)
);


reg [17:0]DelayCounter = 'd0;

reg [7:0] State_main = S_IDLE;


localparam 	S_IDLE = 8'd0,
				S_POWER_RISE  = 8'd1,
				S_DELAY  = 8'd2,
				S_INIT = 8'd3, 
				S_STAND_BY = 8'd4,
				S_CHECK_ADDR = 8'd5,
				S_CHECK_STATE = 8'd6,
				S_READ = 8'd7,
				S_WRITE = 8'd8,
				S_FAIL = 8'd253,
				S_COMPLITE = 8'd254,
				S_INIT_FAIL = 8'd255;
				
always @(posedge clk) 
begin 

	if (rst)
	begin
		
		State_main <= S_IDLE;
		DelayCounter <= 'd0;
		Init_Enable <= 1'b0;
		Read_Enable <= 1'b0;
		Write_Enable <= 1'b0;
		SD_Init_Complite <= 1'b0;
		SD_Complite <= 1'b0;
		SD_Fail <= 1'b0;
		SD_Init_Fail <= 1'b0;
		StandBy <= 1'b0;
	end
	else
	begin
	
		case (State_main)
		
		S_IDLE: if (!cd_n) State_main <= S_POWER_RISE;
		
		S_POWER_RISE:
		begin
			if (DelayCounter != POWER_RISE) DelayCounter <= DelayCounter + 1'b1;
			else 
			begin
				State_main <= S_DELAY;
				DelayCounter <= 'd0;
			end
		end
		
		
		S_DELAY: 
		begin
			if (DelayCounter != DELAY) DelayCounter <= DelayCounter + 1'b1;
			else 
			begin
				State_main <= S_INIT;
				DelayCounter <= 'd0;
			end
		end
		
		S_INIT:
		begin
			if (Init_complite | SKIP_INIT)
			begin
				Init_Enable <= 1'b0;
				SD_Init_Complite <= 1'b1;
				State_main <= S_STAND_BY;
				
			end
			else if (Init_Fail)
			begin
				Init_Enable <= 1'b0;
				State_main <= S_INIT_FAIL;
			end
			else Init_Enable <= 1'b1;
			
		end
		
		S_STAND_BY:
		begin
			
			if (SD_Enable)
			begin
				State_main <= S_CHECK_ADDR;
				StandBy <= 1'b0;
			end
			else StandBy <= 1'b1;
		end
		S_CHECK_ADDR:
		begin
			if (SD_Addr_Block[31:10] > DeviseSize) State_main <= S_FAIL;
			else  State_main <= S_CHECK_STATE;
		end
		
		S_CHECK_STATE:
		begin
			if (CheckState_Complite)
			begin
				CheckState_En <= 1'b0;
				if (SD_we) State_main <= S_WRITE;
				else State_main <= S_READ;
			end
			else if (CheckState_Fail)
			begin
				CheckState_En <= 1'b0;
				State_main <= S_INIT_FAIL;
			end
			else CheckState_En <= 1'b1;
			
			
		end
			
		S_READ:
		begin
			
			if (Read_complite)
			begin
				Read_Enable <= 1'b0;
				State_main <= S_COMPLITE;
			end
			else if (Read_Fail)
			begin
				Read_Enable <= 1'b0;
				State_main <= S_FAIL;
			end
			else Read_Enable <= 1'b1;
		end
		
		S_WRITE:
		begin
			
			if (Write_complite)
			begin
				Write_Enable <= 1'b0;
				State_main <= S_COMPLITE;
			end
			else if (Write_Fail)
			begin
				Write_Enable <= 1'b0;
				State_main <= S_FAIL;
			end
			else Write_Enable <= 1'b1;
		end
		
		S_FAIL:
		begin
			if (SD_Enable) SD_Fail <= 1'b1;
			else 
			begin
				SD_Fail <= 1'b0;
				State_main <= S_STAND_BY;
			end
			
		end
		
		S_COMPLITE:
		begin
			if (SD_Enable)SD_Complite <= 1'b1;
			else
			begin
				SD_Complite <= 1'b0;
				State_main <= S_STAND_BY;
			end
		end
		
		
			
		S_INIT_FAIL:
		begin 
			SD_Init_Fail <= 1'b1;
			SD_Fail <= 1'b1;
			if (cd_n)
			begin
				$display("SD_CARD_M--> SD_Init fail.");
				SD_Fail <= 1'b0;
				SD_Init_Fail <= 1'b0;
				State_main <= S_IDLE;
			end
				
		end
		
		endcase
	end
	
end

endmodule 