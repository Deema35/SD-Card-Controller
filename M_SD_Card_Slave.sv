module M_SD_Card_Slave
#(
	parameter SKIP_INIT = 'd0
)
(
	input wire clk,
	input wire rst,
	input wire [31:0] SD_SerialCount,
	
	inout tri [3:0]DATA,
	inout tri cmd
);


reg [7:0] Data_Block [8191:0];

 
initial
begin
    $readmemh("BMP_test.txt",Data_Block);
end




reg Get_DATA_En = 'd0;
wire Get_DATA_Complite;
wire Get_DATA_CRC_Fail;
wire [31:0] Out_Data;
wire Out_Data_Valid;
wire [31:0] Out_Data_Addr;

reg Send_DATA_En = 'd0;
reg [31:0] InPut_Data = 'd0;
wire InPut_Data_Valid;
wire [31:0] InPut_Data_Addr;
wire Send_DATA_Complite;
reg [31:0] BlockReadCount = 'd0;
reg [31:0] BlockWriteCount = 'd0;

reg [21:0]DeviseSize = 'd1;  //memory capacity = (C_SIZE+1) * 512K byte = 1 Mb;

M_SD_Card_DATA SD_Card_DATA
(
	.clk(clk),
	.rst(rst),
	
	.Get_DATA_En(Get_DATA_En),
	.Get_DATA_Complite(Get_DATA_Complite),
	.Get_DATA_CRC_Fail(Get_DATA_CRC_Fail),
	
	.Send_DATA_En(Send_DATA_En),
	.Send_DATA_Complite(Send_DATA_Complite),
	
	.BlockReadCount(BlockWriteCount),
	.BlockWriteCount(BlockReadCount),
	
	.InPut_Data_Valid(InPut_Data_Valid),
	.InPut_Data_Addr(InPut_Data_Addr),
	.InPut_Data(InPut_Data),
	

	.Out_Data_Addr(Out_Data_Addr),
	.Out_Data_Valid(Out_Data_Valid),
	.Out_Data(Out_Data),
	
	.DATA(DATA)
);

reg  cmd_out = 1'bz;
assign cmd = (State_main_Slave == S_RESPONSE_SEND | State_main_Slave == S_RESPONSE_CMD2_SEND |
					State_main_Slave == S_RESPONSE_SEND_AFTER_GET_DATA | State_main_Slave == S_RESPONSE_SEND_AFTER_SEND_DATA |
					State_main_Slave == S_RESPONSE_SEND_AFTER_SEND_MULTI_DATA | 
					State_main_Slave == S_RESPONSE_SEND_AFTER_GET_MULTI_DATA) ? cmd_out : 1'bz;



reg FistBit = 1'b0;

reg [47:0]  Message_Slave = 'd0;

wire [5:0] CMD_ID = Message_Slave[45:40];
wire [7:0] Arg1 = Message_Slave[39:32];
wire [7:0] Arg2 = Message_Slave[31:24];
wire [7:0] Arg3 = Message_Slave[23:16];
wire [7:0] Arg4 = Message_Slave[15: 8];

reg [3:0] Current_SD_State = 'd0;

localparam 	S_SD_IDLE = 4'd0,
				S_SD_READY  = 4'd1,
				S_SD_IDENT  = 4'd2, 
				S_SD_STBY = 4'd3, // if SD not select 
				S_SD_TRAN = 4'd4, //data transfert mode
				S_SD_DATA = 4'd5, //Card send data to host
				S_SD_RCV = 4'd6,  //Card waiting data from host
				S_SD_PRG = 4'd7, //Wraiting data to flash memory.
				S_SD_DIS = 4'd8; //You can disconnect cart when it write data to flash and for use other card by command CMD7

reg [15:0] RCA_Addr = (SKIP_INIT) ? 'd0 : 16'b1010101010101010;
reg RCA_Addr_En = 1'b0;

reg [7:0] ResiveCounter = 'd0;

reg [7:0] State_main_Slave = 'd0;

reg [7:0] Addr_Block = 'd0;

localparam 	S_INIT = 8'd0,
				S_IDLE = 8'd1,
				S_RESIVE = 8'd2,
				S_COMMAND_GET = 8'd3,
				S_RESPONSE_SEND = 8'd4,
				S_RESPONSE_CMD2_SEND = 8'd5,
				S_RESPONSE_SEND_AFTER_GET_DATA = 8'd6,
				S_RESPONSE_SEND_AFTER_GET_MULTI_DATA = 8'd7,
				S_RESPONSE_SEND_AFTER_SEND_DATA = 8'd8,
				S_RESPONSE_SEND_AFTER_SEND_MULTI_DATA = 8'd9,
				S_GET_DATA = 8'd10,
				S_GET_MULTI_DATA = 8'd11,
				S_SEND_DATA = 8'd13,
				S_SEND_MULTI_DATA = 8'd14,
				S_WRONG_RCA = 8'd254,
				S_NOT_HOST = 8'd255;




always @(posedge clk) 
begin 
	
	if (rst)
	begin
		
		State_main_Slave <= S_IDLE;
		FistBit <= 1'b0;
		ResiveCounter <= 'd0;
		
	end
	else
	begin
		case (State_main_Slave)
		
		S_INIT:
		begin
			if (SKIP_INIT) Current_SD_State <= S_SD_TRAN;
			State_main_Slave <= S_IDLE;
		end
		
		S_IDLE:
		begin
			
			
			if (!FistBit)
			begin
				if(!cmd) FistBit = 1'b1;
			end
			else 
			begin
				if(cmd)
						begin
							State_main_Slave <= S_RESIVE;
							Message_Slave[46] <= 1'b1;
						end
				else
				begin
					State_main_Slave <= S_NOT_HOST;
				end
				FistBit = 1'b0;
			end
			ResiveCounter <= 'd0;
		end
			
		S_RESIVE:
		begin
			if(ResiveCounter == 45)
			begin
				
				State_main_Slave <= S_COMMAND_GET;
				
			end
			
			Message_Slave[45 - ResiveCounter] <= cmd;
			ResiveCounter <= ResiveCounter + 1;
			
			
		end
		
		S_COMMAND_GET:
		begin
			if (CMD_ID == 'd0)
			begin
				$display("SD_Slave--> Get CMD0. Reset set state idle. No responce.");
				Current_SD_State <= S_SD_IDLE;
				Message_Slave <= 'd0;
				
				State_main_Slave <= S_IDLE;
			end
			else if (CMD_ID == 'd2)
			begin
				if(Current_SD_State == S_SD_READY)
				begin
					$display("SD_Slave--> Get CMD2. Get SID regist and set state ident. R2 responce.");
					Current_SD_State <= S_SD_IDENT;
					Response_R2_Slave[135:128] <= 'b00111111;
					Response_R2_Slave[0] <= 1'b0;
					State_main_Slave <= S_RESPONSE_CMD2_SEND;
				end
				else
				begin
					State_main_Slave <= S_IDLE;
					$display("SD_Slave--> CMD2. Wrong state need ready.");
				end
			end
			else if (CMD_ID == 'd3)
			begin
				if (Current_SD_State == S_SD_IDENT | Current_SD_State == S_SD_STBY)
				begin
					$display("SD_Slave--> Get CMD3. Get SD card RCA addr = %b and set state stby. R6 responce.", RCA_Addr);
					Current_SD_State <= S_SD_STBY;
					Message_Slave[39:24] <= RCA_Addr;
					RCA_Addr_En <= 1'b1;
					State_main_Slave <= S_RESPONSE_SEND;
				end
				else
				begin
					State_main_Slave <= S_IDLE;
					$display("SD_Slave--> CMD3. Wrong state need ident or stby.");
				end
			end
			else if (CMD_ID == 'd6)
			begin
				if (Current_SD_State == S_SD_TRAN)
				begin
					$display("SD_Slave--> Get ACMD6. Set 4 data lines. R1 response.");
					Message_Slave[20:17] <= Current_SD_State;
					Message_Slave[16:8] <= 9'b100100000;
					State_main_Slave <= S_RESPONSE_SEND;
				end
				else
				begin
					State_main_Slave <= S_IDLE;
					$display("SD_Slave--> ACMD6. Wrong state need tran.");
				end
			end
			else if (CMD_ID == 'd7)
			begin
				if (Current_SD_State == S_SD_STBY)
				begin
					$display("SD_Slave--> CMD7. Set new state tran. R6 response.");
					Current_SD_State <= S_SD_TRAN;
					
					if (Message_Slave[39:24] == RCA_Addr) State_main_Slave <= S_RESPONSE_SEND;
					else
					begin
						$display("SD_Slave--> Wrong RCA Addr = %b", Message_Slave[39:24]);
						State_main_Slave <= S_WRONG_RCA;
					end
				end
				else
				begin
					State_main_Slave <= S_IDLE;
					$display("SD_Slave--> CMD7. Wrong state need stby.");
				end
				
			end
			else if (CMD_ID == 'd8)
			begin
				if (Current_SD_State == S_SD_IDLE)
				begin
					$display("SD_Slave--> CMD8. Set voltage %b R7 responce.", Arg3);
					State_main_Slave <= S_RESPONSE_SEND;
				end
				else
				begin
					State_main_Slave <= S_IDLE;
					$display("SD_Slave--> CMD8. Wrong state need idle.");
				end
			end
			
			else if (CMD_ID == 'd9)
			begin
				if (Current_SD_State == S_SD_STBY)
				begin
					$display("SD_Slave--> CMD9. Get CSD register. R2 Response ");
					
					if (Message_Slave[39:24] == RCA_Addr) 
					begin
						State_main_Slave <= S_RESPONSE_CMD2_SEND;
						Response_R2_Slave[69:48] <= DeviseSize;
						
					end
					else
					begin
						$display("SD_Slave--> Wrong RCA Addr = %b", Message_Slave[39:24]);
						State_main_Slave <= S_WRONG_RCA;
					end
					
				end
				else
				begin
					State_main_Slave <= S_IDLE;
					$display("SD_Slave--> CMD9. Wrong state need stby.");
					
				end
			end
			else if (CMD_ID == 'd12)
			begin
				if (Current_SD_State == S_SD_DATA | Current_SD_State == S_SD_RCV)
				begin
					
					if (Current_SD_State == S_SD_DATA)
					begin
						$display("SD_Slave--> CMD12. Stop transmit data. New state tran. R1 rsponse");
						Current_SD_State <= S_SD_TRAN;
						Message_Slave[20:17] <= S_SD_TRAN;
						State_main_Slave <= S_RESPONSE_SEND;
					end
					else if (Current_SD_State == S_SD_RCV)
					begin
						$display("SD_Slave--> CMD12. Stop resive data. New state prg. R1 rsponse");
						Current_SD_State <= S_SD_TRAN;
						Message_Slave[20:17] <= S_SD_PRG;
						State_main_Slave <= S_RESPONSE_SEND;
					end
					
				end
				else
				begin
					State_main_Slave <= S_IDLE;
					$display("SD_Slave--> CMD12. Wrong state. State can be data or rcv.State = %d", Current_SD_State);
					
				end
			end
			else if (CMD_ID == 'd13)
			begin
				if (Current_SD_State != S_SD_IDLE & Current_SD_State != S_SD_READY & Current_SD_State != S_SD_IDENT)
				begin
					$display("SD_Slave--> CMD13. Get Status. R1 rsponse");
					Message_Slave[20:17] <= Current_SD_State;
					if (Message_Slave[39:24] == RCA_Addr)
					begin
						
						if (BlockWriteCount)
						begin
							
							if (BlockWriteCount > SD_SerialCount) State_main_Slave <= S_RESPONSE_SEND;
							else State_main_Slave <= S_RESPONSE_SEND_AFTER_GET_MULTI_DATA;
						end
						
						else State_main_Slave <= S_RESPONSE_SEND;
					end
					else
					begin
						$display("SD_Slave--> Wrong RCA Addr = %b", Message_Slave[39:24]);
						State_main_Slave <= S_WRONG_RCA;
					end
				end
				else
				begin
					State_main_Slave <= S_IDLE;
					$display("SD_Slave--> CMD13. Wrong state can't be idle, ready or ident.State = %d", Current_SD_State);
					
				end
			end
			else if (CMD_ID == 'd17)
			begin
				if (Current_SD_State == S_SD_TRAN)
				begin
					$display("SD_Slave--> Get CMD17. Send %d data block to host and set state data. R1 rsponse", Arg4);
					Addr_Block <= Arg4;
					Current_SD_State <= S_SD_DATA;
					Message_Slave[20:17] <= S_SD_DATA;
					State_main_Slave <= S_RESPONSE_SEND_AFTER_SEND_DATA;
					
				end
				else
				begin
					State_main_Slave <= S_IDLE;
					$display("SD_Slave--> CMD17. Wrong state can't be idle, ready or ident.State = %d", Current_SD_State);
					
				end
			end
			else if (CMD_ID == 'd18)
			begin
				if (Current_SD_State == S_SD_TRAN)
				begin
					$display("SD_Slave--> Get CMD18. Send multi data block %d to host and set state data. R1 rsponse", Arg4);
					Addr_Block <= Arg4;
					Current_SD_State <= S_SD_DATA;
					Message_Slave[20:17] <= S_SD_DATA;
					State_main_Slave <= S_RESPONSE_SEND_AFTER_SEND_MULTI_DATA;
					
				end
				else
				begin
					State_main_Slave <= S_IDLE;
					$display("SD_Slave--> CMD18. Wrong state can't be idle, ready or ident.State = %d", Current_SD_State);
					
				end
			end
			else if (CMD_ID == 'd24)
			begin
				if (Current_SD_State == S_SD_TRAN)
				begin
					$display("SD_Slave--> CMD24. Get data block from host and set state rcv. R1 rsponse. ");
					Current_SD_State <= S_SD_RCV;
					Message_Slave[20:17] <= S_SD_RCV;
					State_main_Slave <= S_RESPONSE_SEND_AFTER_GET_DATA;
					
					
				end
				else
				begin
					State_main_Slave <= S_IDLE;
					$display("SD_Slave--> CMD24. Wrong state need tran.State = %d", Current_SD_State);
					
				end
			end
			else if (CMD_ID == 'd25)
			begin
				if (Current_SD_State == S_SD_TRAN)
				begin
					$display("SD_Slave--> CMD25. Get data block from host and set state rcv. R1 rsponse. ");
					Current_SD_State <= S_SD_RCV;
					Message_Slave[20:17] <= S_SD_RCV;
					State_main_Slave <= S_RESPONSE_SEND_AFTER_GET_MULTI_DATA;
					
					
				end
				else
				begin
					State_main_Slave <= S_IDLE;
					$display("SD_Slave--> CMD24. Wrong state need tran.State = %d", Current_SD_State);
					
				end
			end
			else if (CMD_ID == 'd55)
			begin
				if (Current_SD_State != S_SD_READY & Current_SD_State != S_SD_IDENT)
				begin
					$display("SD_Slave--> Get CMD55. Next Application-Specific Command. R1 response.");
					Message_Slave[20:17] <= Current_SD_State;
					if (Message_Slave[39:24] == RCA_Addr | !RCA_Addr_En) State_main_Slave <= S_RESPONSE_SEND;
					else
					begin
						$display("SD_Slave--> Wrong RCA Addr = %b", Message_Slave[39:24]);
						State_main_Slave <= S_WRONG_RCA;
					end
				end
				else
				begin
					State_main_Slave <= S_IDLE;
					$display("SD_Slave--> CMD55. Wrong state can't be ready or ident.State = %d", Current_SD_State);
				end
			end
			else if (CMD_ID == 'd41)
			begin
				if (Current_SD_State == S_SD_IDLE)
				begin
					$display("SD_Slave--> ACMD41. Set state ready. R3 response OCR registr. Busy bit 1. ");
					Current_SD_State <= S_SD_READY;
					Message_Slave[39] <= 1'b1;
					State_main_Slave <= S_RESPONSE_SEND;
				end
				else
				begin
					State_main_Slave <= S_IDLE;
					$display("SD_Slave--> ACMD41. Wrong state need idle.State = %d", Current_SD_State);
				end
			end
			else 
			begin
				$display("SD_Slave--> Unknown command = %d", CMD_ID);
				State_main_Slave <= S_IDLE;
			end
			
		end
		S_GET_DATA:
		begin
			
			if (Get_DATA_Complite)
			begin
				$display("SD_Slave--> Get data. New state tran");
				Get_DATA_En <= 1'b0;
				Current_SD_State <= S_SD_TRAN;
				State_main_Slave <= S_IDLE;
			end
			else
			begin
				if(Out_Data_Valid)
				begin
					Data_Block[Out_Data_Addr] <= Out_Data[7:0];
					Data_Block[Out_Data_Addr + 1] <= Out_Data[15:8];
					Data_Block[Out_Data_Addr + 2] <= Out_Data[23:16];
					Data_Block[Out_Data_Addr + 3] <= Out_Data[31:24];
					
				end
			end
		end
		S_GET_MULTI_DATA:
		begin
			
			
			if (Get_DATA_Complite)
			begin
				$display("SD_Slave--> Get data block N = %d. New state rcv.", BlockWriteCount);
				BlockWriteCount <= BlockWriteCount + 1'b1;
				Get_DATA_En <= 1'b0;
				Current_SD_State <= S_SD_RCV;
				State_main_Slave <= S_IDLE;
				
			end
			else
			begin
				if(Out_Data_Valid)
				begin
					Data_Block[Out_Data_Addr] <= Out_Data[7:0];
					Data_Block[Out_Data_Addr + 1] <= Out_Data[15:8];
					Data_Block[Out_Data_Addr + 2] <= Out_Data[23:16];
					Data_Block[Out_Data_Addr + 3] <= Out_Data[31:24];
					
				end
				Get_DATA_En <= 1'b1;
			end
		end
		
		
		S_SEND_DATA:
		begin
			
			
			if (Send_DATA_Complite)
			begin
				$display("SD_Slave--> Send data. New state tran");
				
				Send_DATA_En <= 1'b0;
				Current_SD_State <= S_SD_TRAN;
				State_main_Slave <= S_IDLE;
			end
			else 
			begin
				Send_DATA_En <= 1'b1;
				if(InPut_Data_Valid)
				begin
					
					
					InPut_Data[7:0] <= Data_Block[(Addr_Block * 'd512) + InPut_Data_Addr];
					InPut_Data[15:8] <= Data_Block[(Addr_Block * 'd512) + InPut_Data_Addr + 1];
					InPut_Data[23:16] <= Data_Block[(Addr_Block * 'd512) + InPut_Data_Addr + 2];
					InPut_Data[31:24] <= Data_Block[(Addr_Block * 'd512) + InPut_Data_Addr + 3];
					
					
				end
			end
		end
		S_SEND_MULTI_DATA:
		begin
			
			if (Send_DATA_Complite)
			begin
				$display("SD_Slave--> Send block N = %d data.", (Addr_Block + BlockReadCount));
				Send_DATA_En <= 1'b0;
				
				if (SD_SerialCount == BlockReadCount)
				begin
					State_main_Slave <= S_IDLE;
					BlockReadCount <= 'd0;
				end
				else
				begin
					BlockReadCount <= BlockReadCount + 'd1;
					
				end
			end
			else 
			begin
				Send_DATA_En <= 1'b1;
				if(InPut_Data_Valid)
				begin
					
					InPut_Data[7:0] <= Data_Block[(Addr_Block * 'd512) + InPut_Data_Addr];
					InPut_Data[15:8] <= Data_Block[(Addr_Block * 'd512) + InPut_Data_Addr + 1];
					InPut_Data[23:16] <= Data_Block[(Addr_Block * 'd512) + InPut_Data_Addr + 2];
					InPut_Data[31:24] <= Data_Block[(Addr_Block * 'd512) + InPut_Data_Addr + 3];
					
				end
				
			end
		end
		endcase	
		
			
		
	end
	
end
reg [7:0] TransmitCount = 'd0;
reg CRC_En = 1'b0;
wire CRC_Valid;
wire [47:0]  Response_Slave;
reg [135:0]  Response_R2_Slave = 'd0;

reg IsHost = 1'b0;
wire [6:0]CRC;

assign Response_Slave[47] = 1'b0;
assign Response_Slave[46] = IsHost;
assign Response_Slave[45:40] = CMD_ID;
assign Response_Slave[39:32] = Arg1;
assign Response_Slave[31:24] = Arg2;
assign Response_Slave[23:16] = Arg3;
assign Response_Slave[15: 8] = Arg4;
assign Response_Slave[7: 1] = CRC;
assign Response_Slave[0] = 1'b1;

M_CRC7 CRC7
(
	.clk(clk),
	.Enable(CRC_En),
	.Message(Response_Slave),
	.Valid(CRC_Valid),
	.CRC(CRC)
);

always @(negedge clk) 
begin 
	
	if (rst)
	begin
		
	end
	else
	begin
		case (State_main_Slave)
		S_IDLE:
		begin
				CRC_En <= 1'b0;
				TransmitCount <= 'd0;
		end
		S_RESPONSE_SEND_AFTER_SEND_DATA,
		S_RESPONSE_SEND_AFTER_GET_DATA,
		S_RESPONSE_SEND_AFTER_SEND_MULTI_DATA,
		S_RESPONSE_SEND_AFTER_GET_MULTI_DATA,
		S_RESPONSE_SEND:
		begin
			if ( TransmitCount == 48)
			begin
				if(State_main_Slave == S_RESPONSE_SEND_AFTER_GET_DATA)
				begin
					State_main_Slave <= S_GET_DATA;
					Get_DATA_En <= 1'b1;
				end
				else if (State_main_Slave == S_RESPONSE_SEND_AFTER_GET_MULTI_DATA)
				begin
					State_main_Slave <= S_GET_MULTI_DATA;
					Get_DATA_En <= 1'b1;
				end
				else if (State_main_Slave == S_RESPONSE_SEND_AFTER_SEND_DATA)
				begin
					State_main_Slave <= S_SEND_DATA;
					
					InPut_Data[7:0] <= Data_Block[0];
					InPut_Data[15:8] <= Data_Block[1];
					InPut_Data[23:16] <= Data_Block[2];
					InPut_Data[31:24] <= Data_Block[3];
				end
				else if (State_main_Slave == S_RESPONSE_SEND_AFTER_SEND_MULTI_DATA)
				begin
					State_main_Slave <= S_SEND_MULTI_DATA;
					
					InPut_Data[7:0] <= Data_Block[0];
					InPut_Data[15:8] <= Data_Block[1];
					InPut_Data[23:16] <= Data_Block[2];
					InPut_Data[31:24] <= Data_Block[3];
				end
				else State_main_Slave <= S_IDLE;
				Message_Slave <= 'd0;

			end
			
			CRC_En <= 1'b1;
			cmd_out <= Response_Slave[47 - TransmitCount];
			TransmitCount <= TransmitCount + 1;
			
		end
		
		
		S_RESPONSE_CMD2_SEND:
		begin
			if ( TransmitCount == 136)
			begin
				State_main_Slave <= S_IDLE;
				Message_Slave <= 'd0;

			end
			
			CRC_En <= 1'b1;
			cmd_out <= Response_R2_Slave[135 - TransmitCount];
			TransmitCount <= TransmitCount + 1;
		end
		endcase
	end
end

endmodule