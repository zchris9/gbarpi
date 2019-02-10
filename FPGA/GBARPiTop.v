`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:23:47 09/17/2016 
// Design Name: 
// Module Name:    GBARPiTop 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module GBARPiTop(
	inout [15:0] GBA_ADDRESS,
	inout [7:0] GBA_DATA,
	input GBA_VCC,
	input GBA_CLK,
	input GBA_WRn,
	input GBA_RDn,
	input GBA_CSn,
	input GBA_CS2n,
	
	output [16:0] RAM_ADDRESS,
	inout [15:0] RAM_DATA,
	output RAM_WEn,
	output RAM_CEn,
	output RAM_OEn,
	
	output AD1895_CLK,
	output AD1895_RESET,
	output I2S_CLK,
	output I2S_LRCLK,
	input I2S_DATA,
	
	output ClkLoopOut1,
	output ClkLoopOut2,
	
	input ClkLoopIn1,
	input ClkLoopIn2,
	
	input SPI0_MOSI,
	input SPI0_SCLK,
	input SPI0_CSn,
	input SPI0_DC,
	
	input RPI_PIN7,
	input RPI_PIN13,
	output RPI_PIN16,
	
	input CLK50MHZ
	);

wire [15:0] bGBAKeys;

reg dout = 0;
reg [3:0] doutcount = 0;

wire reset;
wire clk;

assign RPI_PIN16 = bGBAKeys[doutcount]; // data

assign reset = RPI_PIN7;
assign clk = RPI_PIN13;

always @(posedge clk)
begin
	if (reset)
		doutcount <= 0;
	else
		doutcount <= doutcount + 1;
end
	
assign GBA_DATA = 8'bZZZZZZZZ;
	
wire wClk;
wire wClk2;

reg [1:0] rClkDiv = 0;

always @(posedge wClk)
begin
	rClkDiv <= rClkDiv + 1;
end

assign AD1895_CLK = rClkDiv[1];


assign ClkLoopOut1 = CLK50MHZ;
assign ClkLoopOut2 = 0;
/*
IBUFG IBUFG_CLK (
	.O(wClk2), // Clock buffer output
	.I(SPI0_SCLK)  // Clock buffer input (connect directly to top-level port)
);
*/

wire [15:0] bFBAddress;
wire [15:0] bFBData;

wire wNextAudioSamples;
wire [15:0] bAudioSamples;

reg [26:0] rInitReset = 0;

assign AD1895_RESET = rInitReset[26];

always @(posedge wClk)
begin
	if (!rInitReset[26])
		rInitReset <= rInitReset + 1;
end

GBAROM GBAROM (
	.IwClk(wClk),
	.IwGBACartVCCActive(1),
	.IwGBACartPHI(GBA_CLK),
	.IwGBACartWRn(GBA_WRn),
	.IwGBACartRDn(GBA_RDn),
	.IwGBACartCSn(GBA_CSn),
	.BbGBACartALD(GBA_ADDRESS),
	.IbGBACartAH(GBA_DATA),
	.IwGBACartCS2n(GBA_CS2n),
	.OwGBACartIRQ(),
	.IbFBData(bFBData),
	.ObFBAddress(bFBAddress),
	.ObGBAKeys(bGBAKeys),
	
	.OwNextAudioSamples(wNextAudioSamples),
	.IbAudioSamples(bAudioSamples)
);

wire wClkSRAM;

DCM_SRAM DCM_SRAM (
	.CLKIN_IN (ClkLoopIn1),
	.CLK0_OUT (wClk),
	.CLKFX_OUT (wClkSRAM)
);

wire [16:0] bFBWriteAddr;
wire [15:0] bFBWriteData;
wire bFBWriteEnable;

SRAMController SRAMController (
	.RAM_ADDRESS(RAM_ADDRESS),
	.RAM_DATA(RAM_DATA),
	.RAM_WEn(RAM_WEn),
	.RAM_CEn(RAM_CEn),
	.RAM_OEn(RAM_OEn),
	
	.IbReadAddress(bFBAddress),
	.ObData(bFBData),
	/*
	.IbWriteAddress(bFBAddress),
	.IbData({bGBAKeys[0], bGBAKeys[1], bGBAKeys[2], 2'h0, bGBAKeys[3], bGBAKeys[4], bGBAKeys[5], 2'h0, bGBAKeys[6], bGBAKeys[7], bGBAKeys[8], bGBAKeys[9], 1'h0}),
	.IwWrite(1),
	*/
	
	.IbWriteAddress(bFBWriteAddr),
	.IbData(bFBWriteData),
	.IwWrite(bFBWriteEnable),
	
	
	.IwClk(wClkSRAM)
);

SPIFrameReceiver SPIFrameReceiver (
	.IwClk(wClk),
	
	.IwCSn(SPI0_CSn),
	.IwSCLK(SPI0_SCLK),
	.IwSDI(SPI0_MOSI),
	.IwDC(SPI0_DC),
	
	.ObFrameMemWriteAddr(bFBWriteAddr),
	.ObFrameMemWriteData(bFBWriteData),
	.OwFrameMemWE(bFBWriteEnable)
);


reg [6:0] rI2SCounter = 0;

wire wI2SClk;
wire wI2SLRClk;

assign wI2SClk = rI2SCounter[1];
assign wI2SLRClk = rI2SCounter[6];

assign I2S_CLK = wI2SClk;
assign I2S_LRCLK = wI2SLRClk;

always @(posedge GBA_CLK)
begin
	rI2SCounter <= rI2SCounter + 1;
end

SoundFIFO SoundFIFO(
	.IwClk(wClk),
	
	.IwNextAudioSamples(wNextAudioSamples),
	.ObAudioSamples(bAudioSamples),
	
	.IwI2SClk(wI2SClk),
	.IwI2SLRClk(wI2SLRClk),
	.IwI2SData(I2S_DATA)
);

endmodule
