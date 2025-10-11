module CRC7_Test;

reg clk = 1'b0;

always #1 clk = ~clk;

reg CRC_En = 'd0;
wire CRC_Valid;
reg [5:0] CMD_ID = 'd0;
reg [7:0] Arg1 = 'd0;
reg [7:0] Arg2 = 'd0;
reg [7:0] Arg3 = 'd0;
reg [7:0] Arg4 = 'd0;
wire [47:0]Message;

reg [47:0]CMD0 = {2'b01, 6'd0, 32'd0, 7'b1001010, 1'b1}; 

reg [47:0]CMD8 = {2'b01, 6'd8, 16'd0, 8'b00000001, 8'b10101010, 7'b1000011, 1'b1}; 

reg [47:0]CMD55 = {2'b01, 6'd55, 32'd0, 7'b0110010, 1'b1};

wire [6:0]CRC;

reg IsHost = 1'b1;

assign Message[47] = 1'b0;
assign Message[46] = IsHost;
assign Message[45:40] = CMD_ID;
assign Message[39:32] = Arg1;
assign Message[31:24] = Arg2;
assign Message[23:16] = Arg3;
assign Message[15: 8] = Arg4;
assign Message[7: 1] = CRC;
assign Message[0] = 1'b1;

M_CRC7 CRC7
(
	.clk(clk),
	.Enable(CRC_En),
	.Message(Message),
	.Valid(CRC_Valid),
	.CRC(CRC)
);


reg [7:0] State ='d0;

localparam 	S_CMD0 = 'd0,
				S_CMD0_CHECK = 'd1,
				S_CMD8 = 'd2,
				S_CMD8_CHECK = 'd3,
				S_CMD55 = 'd4,
				S_CMD55_CHECK = 'd5,
				S_PASS = 'd6,
				S_FAILL = 'd7,
				S_END = 'd8;

always @(posedge clk)
begin

	
	
	
	case(State)
	S_CMD0:
	begin
		
		CRC_En <= 1'b1;
		CMD_ID <= 'd0;
		Arg1 <= 'd0;
		Arg2 <= 'd0;
		Arg3 <= 'd0;
		Arg4 <= 'd0;
		
		if (CRC_Valid) State <= S_CMD0_CHECK;
	end
	
	S_CMD0_CHECK:
	begin
		CRC_En <= 1'b0;
		if (Message ^ CMD0) State <= S_FAILL;
		else
		begin
			$display("CRC CMD8 Check passed. CRC7 = %b time =%d", CRC,$stime);
			State <= S_CMD8;
		end
		
	end
	
	S_CMD8:
	begin
		
		CRC_En <= 1'b1;
		CMD_ID <= 'd8;
		Arg1 <= 'd0;
		Arg2 <= 'd0;
		Arg3 <= 'd1;
		Arg4 <= 8'b10101010;
		
		if (CRC_Valid) State <= S_CMD8_CHECK;
	end
	
	S_CMD8_CHECK:
	begin
		CRC_En <= 1'b0;
		if (Message ^ CMD8) State <= S_FAILL;
		else
		begin
			$display("CRC CMD8 Check passed. CRC7 = %b time =%d", CRC,$stime);
			State <= S_CMD55;
		end
	end
	
	S_CMD55:
	begin
		
		CRC_En <= 1'b1;
		CMD_ID <= 'd55;
		Arg1 <= 'd0;
		Arg2 <= 'd0;
		Arg3 <= 'd0;
		Arg4 <= 'd0;
		
		if (CRC_Valid) State <= S_CMD55_CHECK;
	end
	
	S_CMD55_CHECK:
	begin
		CRC_En <= 1'b0;
		if (Message ^ CMD55) State <= S_FAILL;
		else
		begin
			$display("CRC CMD55 Check passed. CRC7 = %b time =%d", CRC,$stime);
			State <= S_PASS;
		end
	end
	
	S_PASS:
	begin
		
		State <= S_END;
	end
	
	S_FAILL:
	begin
		 $display("CRC Check fail. CRC7 = %b time =%d", CRC, $stime);
		 State <= S_END;
	end
	endcase
	
	
end

initial  #150 $finish;

initial
begin
  $dumpfile("out.vcd");
  $dumpvars(0,CRC7);
end

//initial $monitor($stime,,, clk,, State,, CRC_Valid,, CRC_En);

endmodule 