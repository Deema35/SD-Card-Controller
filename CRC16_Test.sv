module CRC16_Test
#(
	parameter DATA_STRING = 'd512
);

reg clk = 1'b0;

always #1 clk = ~clk;

reg CRC_En = 'd0;
wire CRC_Valid;
wire [15:0]CRC;

reg [7:0] Write_data = 'd0;

reg GetData = 'd0;

M_CRC16 
#(
	.DATA_STRING(DATA_STRING)
)
CRC16
(
	.clk(clk),
	.Enable(CRC_En),
	.GetData(GetData),
	.Data(Write_data),
	.Valid(CRC_Valid),
	.CRC(CRC)
);

reg [7:0] Data_Count = 'd0;
reg [15:0] BuyteCount = 'd0;

reg [7:0] State ='d0;

localparam 	S_DATA_IDLE = 'd0,
				S_DATA_INIT = 'd1,
				S_CRC_CALK = 'd2,
				S_DATA_CHECK = 'd3,
				S_CRC_PASS = 'd4,
				S_CRC_FAIL = 'd5,
				S_END = 'd6;
				

always @(posedge clk)
begin

	
	
	
	case(State)
	S_DATA_IDLE:
	begin
		CRC_En <= 1'b1;
		State <= S_DATA_INIT;
	end
	
	S_DATA_INIT:
	begin
		GetData <= 1'b1;
		Write_data <= 'hff;
		State <= S_CRC_CALK;
		
	end

	S_CRC_CALK:
	begin
		GetData <= 1'b0;
		
		if (Data_Count == 'd7)
		begin
			Data_Count <= 'd0;
			BuyteCount <= BuyteCount + 1'b1;
			if (BuyteCount == DATA_STRING - 1) State <= S_DATA_CHECK;
			else State <= S_DATA_INIT;
		end
		else Data_Count <= Data_Count + 1'b1;
		
	end
	
	S_DATA_CHECK:
	begin
		if (CRC_Valid)
		begin
			CRC_En <= 1'b0;
			if (CRC == 16'h7fa1) State <= S_CRC_PASS;
			else State <= S_CRC_FAIL;
		end
		
	end
	
	S_CRC_PASS:
	begin
		$display("CRC Check passed. CRC16 = %h time =%d", CRC,$stime);
		State <= S_END;
	end
	
	S_CRC_FAIL:
	begin
		 $display("CRC Check fail. CRC16 = %h time =%d", CRC, $stime);
		 State <= S_END;
	end
	
	endcase
	
	
end

initial  #15000 $finish;

initial
begin
  $dumpfile("out.vcd");
  $dumpvars(0,CRC16);
end

//initial $monitor($stime,,, clk,, State,, CRC_Valid,, CRC_En);

endmodule 