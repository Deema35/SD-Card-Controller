module M_SD_CMD_SEND
(
	input wire clk,
	input wire rst,
	input wire Enable,
	input wire [5:0] CMD_ID,
	input wire [7:0] Arg1,
	input wire [7:0] Arg2,
	input wire [7:0] Arg3,
	input wire [7:0] Arg4,
	
	output reg Complite = 1'b0,
	output reg cmd_w = 1'bz,
	
	output reg CRC_En = 1'b0,
	input wire CRC_Valid,
	output wire [47:0]  Message,
	input wire [6:0]CRC
);

reg [7:0]SendCounter  = 'd0;


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


reg [7:0] State_Send = 'd0;


localparam 	S_IDLE = 8'd0,
				S_SEND = 8'd1,
				S_COMPLITE = 8'd2;

always @(negedge clk) 
begin 

	if (rst)
	begin
		
		SendCounter <= 'd0;
		Complite <= 1'b0;
		CRC_En <= 1'b0;
		State_Send <= S_IDLE;
		
	end
	else
	begin
		case (State_Send)
		S_IDLE:
		begin
			if (Enable) State_Send <= S_SEND;
		end
		
		S_SEND:
		begin
			if (SendCounter == 47) State_Send <= S_COMPLITE;
		
			cmd_w <= Message[47 - SendCounter];
			SendCounter <= SendCounter + 1'd1;
			CRC_En <= 1'b1;
		end	
		
			
		S_COMPLITE:
		begin
			SendCounter <= 'd0;
			cmd_w <= 1'bz;
			CRC_En <= 1'b0;
			
			if (Enable) Complite <= 1'b1;
			else
			begin
				Complite <= 1'b0;
				State_Send <= S_IDLE;
			end
		end
		endcase
	end
end
endmodule