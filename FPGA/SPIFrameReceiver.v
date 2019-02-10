module SPIFrameReceiver (
	input IwClk,
	
	input IwCSn,
	input IwSCLK,
	input IwSDI,
	input IwDC,
	
	output [15:0] ObFrameMemWriteAddr,
	output [15:0] ObFrameMemWriteData,
	output OwFrameMemWE
);

reg [7:0] rCurrentCommand = 0;

reg [15:0] rColumnStart = 0;
reg [15:0] rColumnEnd = 239;
reg [15:0] rRowStart = 0;
reg [15:0] rRowEnd = 159;


reg [19:0] rCounter = 0;
reg [19:0] rCounter2 = 0;

localparam CAS = 8'h2A;
localparam RAS = 8'h2B;
localparam MWR = 8'h2C;

wire [2:0] wCounterNeg8 = 3'd7-rCounter[2:0];
wire [3:0] wCounterNeg16 = 4'd15-rCounter[3:0];

reg [15:0] rPixelData0 = 0;
reg [15:0] rPixelData1 = 0;
reg rCurrentPixelReg = 0;
reg rLCurrentPixelReg = 0;

reg rFrameMemWEBuf = 0;

assign OwFrameMemWE = rFrameMemWEBuf;

wire [15:0] bFrameMemWriteDataBuf;

assign bFrameMemWriteDataBuf = rCurrentPixelReg ? rPixelData0 : rPixelData1;

assign ObFrameMemWriteData[15] = 0;
assign ObFrameMemWriteData[4:0] = bFrameMemWriteDataBuf[15:11];
assign ObFrameMemWriteData[9:5] = bFrameMemWriteDataBuf[10:6];
assign ObFrameMemWriteData[14:10] = bFrameMemWriteDataBuf[4:0];

reg [15:0] ObFrameMemWriteAddrBuf;
assign ObFrameMemWriteAddr[15:0] = ObFrameMemWriteAddrBuf;


always @(posedge IwSCLK)
begin
	ObFrameMemWriteAddrBuf <= (rCounter2[19:4] + (rRowStart[15:0]*240))-16'd1;
end

always @(posedge IwSCLK or posedge IwCSn)
begin
	if (IwCSn)
		rCounter <= 0;
	else
		rCounter <= rCounter + 20'd1;
end


always @(posedge IwSCLK)
begin
	if (!IwCSn)
		rCounter2 <= rCounter2 + 20'd1;
		
	if (IwDC)
	begin // Data
		if (rCurrentCommand == CAS)
		begin
			if (rCounter[4])
			begin
				rColumnEnd[wCounterNeg16] <= IwSDI;
			end
			else
			begin
				rColumnStart[wCounterNeg16] <= IwSDI;
			end
			rCounter2 <= 0;
		end
		else if (rCurrentCommand == RAS)
		begin
			if (rCounter[4])
			begin
				rRowEnd[wCounterNeg16] <= IwSDI;
			end
			else
			begin
				rRowStart[wCounterNeg16] <= IwSDI;
			end
			rCounter2 <= 0;
		end
		else if (rCurrentCommand == MWR)
		begin
			if (rCounter[4])
			begin
				rPixelData1[wCounterNeg16] <= IwSDI;
				rCurrentPixelReg <= 1;
			end
			else
			begin
				rPixelData0[wCounterNeg16] <= IwSDI;
				rCurrentPixelReg <= 0;
			end
		end
	end
	else
	begin // Command
		rCurrentCommand[wCounterNeg8] <= IwSDI;
	end
end

reg [2:0] rWriteCount = 0;


always @(posedge IwSCLK)
begin
	rLCurrentPixelReg <= rCurrentPixelReg;
	
	if (rCurrentPixelReg != rLCurrentPixelReg)
		rWriteCount <= rWriteCount + 1;
	else if (rWriteCount != 0)
		rWriteCount <= rWriteCount + 1;
	
	if (rWriteCount < 5 && rWriteCount > 0)
		rFrameMemWEBuf <= 1;
	else
		rFrameMemWEBuf <= 0;
end

endmodule
