module GBAROM (
	input IwClk,
	input IwGBACartVCCActive,
	input IwGBACartPHI,
	input IwGBACartWRn,
	input IwGBACartRDn,
	input IwGBACartCSn,
	inout[15:0] BbGBACartALD,
	input[7:0] IbGBACartAH,
	input IwGBACartCS2n,
	output OwGBACartIRQ,
	input [15:0] IbFBData,
	output [15:0] ObFBAddress,
	output [15:0] ObGBAKeys,
	
	output OwNextAudioSamples,
	input [15:0] IbAudioSamples
);

reg [15:0] gbakeys = 16'hFFFF;

assign ObGBAKeys = gbakeys;

always @(negedge IwGBACartWRn)
begin
	if (!IwGBACartCS2n)
	begin
		if (BbGBACartALD == 16'h0000)
		begin
			gbakeys[7:0] <= ~IbGBACartAH;
		end
		else if (BbGBACartALD == 16'h0001)
		begin
			gbakeys[15:8] <= ~IbGBACartAH;
		end
	end
end

assign OwGBACartIRQ = 0;

reg [15:0] rAddrLowBuf = 0;
reg [15:0] rAddrOffset = 0;
wire [15:0] rAddrLow = rAddrLowBuf + rAddrOffset;
reg [7:0] rAddrHigh = 0;

wire [23:0] rAddr = {rAddrHigh, rAddrLow};

assign ObFBAddress = rAddrLow;

wire [15:0] ROMdata;


PROGMEM ROM(
	.addra (rAddrLow[9:0]),
	.clka (IwClk),
	.douta (ROMdata)
);


reg [15:0] DOUT;

reg rNextAudioSamples = 0;
assign OwNextAudioSamples = rNextAudioSamples;

reg [23:0] rLastAddr = 0;

assign BbGBACartALD = (IwGBACartCSn || IwGBACartRDn || (!IwGBACartVCCActive) || (!IwGBACartWRn)) ? 16'bZZZZZZZZ_ZZZZZZZZ : DOUT;

always @(posedge IwClk)
begin
	rLastAddr <= rAddr;
	if (rAddr[23]) // display data
	begin
		DOUT <= IbFBData;
	end
	else if (rAddr[23:3] == 21'h0FFFF0) // audio data
	begin
		rNextAudioSamples <= rLastAddr != rAddr;
		DOUT <= IbAudioSamples;
	end
	else
	begin // other data (program)
		DOUT <= ROMdata;
	end
end

always @(posedge IwClk)
begin
	if (IwGBACartCSn)
	begin
		rAddrLowBuf = BbGBACartALD;
		rAddrHigh = IbGBACartAH;
	end
end
/*
reg _IwGBACartRDn = 0;

always @(posedge IwClk)
begin
	_IwGBACartRDn = IwGBACartRDn;
	
	if (IwGBACartRDn && !_IwGBACartRDn)
	begin
		if (IwGBACartCSn)
		begin
			rAddrOffset <= 0;
		end
		else
		begin
			rAddrOffset <= rAddrOffset + 16'd1;
		end
	end
end
*/

always @(posedge IwGBACartRDn or posedge IwGBACartCSn)
begin
	if (IwGBACartCSn)
	begin
		rAddrOffset <= 0;
	end
	else
	begin
		rAddrOffset <= rAddrOffset + 16'd1;
	end
end

endmodule
