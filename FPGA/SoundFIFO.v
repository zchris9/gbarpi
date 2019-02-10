module SoundFIFO(
	input IwClk,
	
	input IwNextAudioSamples,
	output [15:0] ObAudioSamples,
	
	input IwI2SClk,
	input IwI2SLRClk,
	input IwI2SData
);

localparam FIFODEPTH = 32;
localparam FIFOPOINTERWIDTH = 5;

reg [15:0] FIFO [FIFODEPTH-1:0];

reg [FIFOPOINTERWIDTH-1:0] FIFOCurrentOut = 0;
reg [FIFOPOINTERWIDTH-1:0] FIFOCurrentIn = 0;
reg FIFOInByteSel = 0;

wire [FIFOPOINTERWIDTH-1:0] FIFONextOut = FIFOCurrentOut + 1;
wire [FIFOPOINTERWIDTH-1:0] FIFONextIn = FIFOCurrentIn + 1;

reg rI2SLRClkDelay = 0;

reg [15:0] I2SSampleIn = 0;
reg [3:0] I2SInCounter = 0;

reg [15:0] I2SSamplesIn = 0;
reg rFIFOWrite;

reg rI2SClk = 0;
reg rI2SLRClk = 0;
reg rI2SData = 0;
reg _rI2SClk = 0;

always @(posedge IwClk)
begin
	rI2SClk <= IwI2SClk;
	rI2SLRClk <= IwI2SLRClk;
	rI2SData <= IwI2SData;
	_rI2SClk <= rI2SClk;
end

always @(posedge IwClk)
begin
	if (rI2SClk && (!_rI2SClk))
	begin
		rI2SLRClkDelay <= rI2SLRClk;
		
		if (rI2SLRClkDelay)
		begin
			I2SInCounter <= I2SInCounter - 1;
			I2SSampleIn[I2SInCounter] <= IwI2SData;
			if (I2SInCounter == 0)
			begin
				FIFOInByteSel <= !FIFOInByteSel;
				if (FIFOInByteSel) // high byte
				begin
					I2SSamplesIn[15:8] <= I2SSampleIn[15:8];
				end
				else // low byte
				begin
					I2SSamplesIn[7:0] <= I2SSampleIn[15:8];
				end
			end
		end
		else
		begin
			I2SInCounter <= 15;
		end
	end
end

reg _FIFOInByteSel = 0;

always @(posedge IwClk)
begin
	_FIFOInByteSel <= FIFOInByteSel;
	rFIFOWrite <= (FIFOInByteSel) && (!_FIFOInByteSel);
end


assign ObAudioSamples = FIFO[FIFOCurrentOut];



reg _rFIFOWrite = 0;

always @(posedge IwClk)
begin
	if (rFIFOWrite)
	begin
		if (FIFONextIn != FIFOCurrentOut)
		begin
			FIFOCurrentIn <= FIFOCurrentIn + 1;
			FIFO[FIFOCurrentIn] <= I2SSamplesIn;
		end
	end
end

reg _IwNextAudioSamples = 0;

always @(posedge IwClk)
begin
	_IwNextAudioSamples <= IwNextAudioSamples;
	if (IwNextAudioSamples && (!_IwNextAudioSamples))
		if (FIFONextOut != FIFOCurrentIn)
			FIFOCurrentOut <= FIFOCurrentOut + 1;
			
end


endmodule
