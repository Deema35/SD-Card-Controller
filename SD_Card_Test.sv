module SD_Card_Test
#(
	parameter SKIP_INIT = 'd0
);

reg [7:0] Data_Block_Send [1023:0];
reg [7:0] Data_Block_Get [1023:0];


reg clk_400k = 1'b0;
reg clk_50 = 1'b0;

always #2 clk_400k = ~clk_400k;
always #1 clk_50 = ~clk_50;

reg rst = 1'b0;
reg cd_n = 1'b1;


wire [3:0]DATA;
pullup(DATA[0]);
pullup(DATA[1]);
pullup(DATA[2]);
pullup(DATA[3]);

wire cmd;

reg SD_Enable = 1'b0;
reg [31:0] SD_Addr_Block = 'd0;
reg SD_we = 1'b0;

wire SD_Complite;
wire SD_Fail;
wire SD_Init_Complite;
wire SD_Init_Fail;

wire SD_Out_Data_Valid;
wire [31:0] SD_Out_Data_Addr;
wire [31:0]SD_Out_Data;

wire SD_InPut_Data_Valid;
wire [31:0]SD_InPut_Data_Addr;
reg [31:0]SD_InPut_Data = 'd0;
reg [31:0] SD_SerialCount = 'd0;

wire SD_clk_Out;


M_SD_Card
#(
	.POWER_RISE('d1),
	.DELAY('d1),
	.SKIP_INIT('d0)
)
SD_Card
(
	.clk_400k(clk_400k),
	.clk_Write(clk_400k),
	.clk_Read(clk_50),
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
reg [15:0] Data_Block_count = 'd0;
reg [7:0] State_main = 'd0;
wire SD_clk = (!SD_Init_Complite) ? clk_400k : 
					(SD_we) ? clk_400k :
					clk_50;


localparam 	S_START_TEST = 8'd0,
				S_IDLE = 8'd1,
				S_DATA_BLOCK_INIT = 8'd2,
				S_WRITE_DATA = 8'd3,
				S_WAITE = 8'd4,
				S_READ_DATA = 8'd5,
				S_COMPER =  8'd6,
				S_WRITE_DATA_SERIAL = 8'd7,
				S_WAITE_SERIAL = 8'd8,
				S_READ_DATA_SERIAL = 8'd9,
				S_COMPER_SERIAL =  8'd10,
				S_COMPLITE = 8'd253,
				S_FAIL = 8'd254,
				S_END = 8'd255;

always @(posedge SD_clk) 
begin
	case(State_main)
	S_START_TEST:
	begin
		$write("%c[1;34m",27);
		$display("");
		$display("*********** Test start. ***********");
		$write("%c[0m",27);
		State_main <= S_IDLE;
	end
	S_IDLE:
	begin
		
		cd_n = 1'b0;
		if (SD_Init_Complite) State_main <= S_DATA_BLOCK_INIT;
	end
	S_DATA_BLOCK_INIT:
	begin
		Data_Block_Send[Data_Block_count] <= Data_Block_count;
		
		Data_Block_count <= Data_Block_count + 1'b1;
		
		if (Data_Block_count == 'd1023)
		begin
			Data_Block_count <= 'd0;
			SD_SerialCount <= 'd0;
			State_main <= S_WRITE_DATA;
		end
	end
	S_WRITE_DATA:
	begin
		
		if (SD_Complite)
		begin
			
			SD_we <= 1'b0;
			SD_Enable <= 1'b0;
			State_main <= S_WAITE;
		end
		else if (SD_Fail)
		begin
			SD_we <= 1'b0;
			SD_Enable <= 1'b0;
			State_main <= S_FAIL;
		end
		else
		begin
			SD_we <= 1'b1;
			SD_Enable <= 1'b1;
			if (SD_InPut_Data_Valid)
			begin
				SD_InPut_Data[7:0] <= Data_Block_Send[SD_InPut_Data_Addr];
				SD_InPut_Data[15:8] <= Data_Block_Send[SD_InPut_Data_Addr + 1];
				SD_InPut_Data[23:16] <= Data_Block_Send[SD_InPut_Data_Addr + 2];
				SD_InPut_Data[31:24] <= Data_Block_Send[SD_InPut_Data_Addr + 3];
			end
		end
	end
	S_WAITE:
		if (!SD_Complite) State_main <= S_READ_DATA;
	S_READ_DATA:
	begin
		if (SD_Complite)
		begin
			SD_Enable <= 1'b0;
			State_main <= S_COMPER;
		end
		else if (SD_Fail)
		begin
			SD_Enable <= 1'b0;
			State_main <= S_FAIL;
		end
		else
		begin
			SD_Enable <= 1'b1;
			if (SD_Out_Data_Valid)
			begin
				Data_Block_Get[SD_Out_Data_Addr] <= SD_Out_Data[7:0];
				Data_Block_Get[SD_Out_Data_Addr + 1] <= SD_Out_Data[15:8];
				Data_Block_Get[SD_Out_Data_Addr + 2] <= SD_Out_Data[23:16];
				Data_Block_Get[SD_Out_Data_Addr + 3] <= SD_Out_Data[31:24];
			end
		end
	end
	
	S_COMPER:
	begin
		if (Data_Block_Get[Data_Block_count] != Data_Block_Send[Data_Block_count])
		begin
			$display("Block fail number %d, Get %b, Send  %b",
			Data_Block_count, Data_Block_Get[Data_Block_count], Data_Block_Send[Data_Block_count]);
			State_main <= S_FAIL;
		end
		else
		begin
			
			if (Data_Block_count == 'd511)
			begin
				SD_SerialCount <= 'd1;
				State_main <= S_WRITE_DATA_SERIAL;
			end
			
			else Data_Block_count <= Data_Block_count + 1'b1;
		end
		
	end
	
	S_WRITE_DATA_SERIAL:
	begin
		
		if (SD_Complite)
		begin
			
			SD_we <= 1'b0;
			SD_Enable <= 1'b0;
			State_main <= S_WAITE_SERIAL;
		end
		else if (SD_Fail)
		begin
			SD_we <= 1'b0;
			SD_Enable <= 1'b0;
			State_main <= S_FAIL;
		end
		else
		begin
			SD_we <= 1'b1;
			SD_Enable <= 1'b1;
			if (SD_InPut_Data_Valid)
			begin
				SD_InPut_Data[7:0] <= Data_Block_Send[SD_InPut_Data_Addr];
				SD_InPut_Data[15:8] <= Data_Block_Send[SD_InPut_Data_Addr + 1];
				SD_InPut_Data[23:16] <= Data_Block_Send[SD_InPut_Data_Addr + 2];
				SD_InPut_Data[31:24] <= Data_Block_Send[SD_InPut_Data_Addr + 3];
			end
		end
	end
	S_WAITE_SERIAL:
		if (!SD_Complite) State_main <= S_READ_DATA_SERIAL;
	S_READ_DATA_SERIAL:
	begin
		if (SD_Complite)
		begin
			SD_Enable <= 1'b0;
			State_main <= S_COMPER_SERIAL;
		end
		else if (SD_Fail)
		begin
			SD_Enable <= 1'b0;
			State_main <= S_FAIL;
		end
		else
		begin
			SD_Enable <= 1'b1;
			if (SD_Out_Data_Valid)
			begin
				Data_Block_Get[SD_Out_Data_Addr] <= SD_Out_Data[7:0];
				Data_Block_Get[SD_Out_Data_Addr + 1] <= SD_Out_Data[15:8];
				Data_Block_Get[SD_Out_Data_Addr + 2] <= SD_Out_Data[23:16];
				Data_Block_Get[SD_Out_Data_Addr + 3] <= SD_Out_Data[31:24];
			end
		end
	end
	S_COMPER_SERIAL:
	begin
		if (Data_Block_Get[Data_Block_count] != Data_Block_Send[Data_Block_count])
		begin
			$display("Block fail number %d, Get %b, Send  %b",
			Data_Block_count, Data_Block_Get[Data_Block_count], Data_Block_Send[Data_Block_count]);
			State_main <= S_FAIL;
		end
		else
		begin
			
			if (Data_Block_count == 'd1023)State_main <= S_COMPLITE;
			
			else Data_Block_count <= Data_Block_count + 1'b1;
		end
		
	end
	
	S_COMPLITE:
	begin
		$write("%c[1;32m",27);
		$display("SD Complite, time =", $stime);
		$display("%c[0m",27);
		
		State_main <= S_END;
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


initial  #35000 $finish;

initial
begin
  $dumpfile("out.vcd");
  $dumpvars(0,SD_Card);
  
  $dumpvars(0,SD_Card_Slave);
end

//initial $monitor($stime,,Data_Block_count);

endmodule