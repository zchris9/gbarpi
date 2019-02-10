`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    00:28:12 11/15/2016 
// Design Name: 
// Module Name:    TbSRAMController 
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
module TbSRAMController(
    );

reg rClk = 0;

wire [15:0] bRAMDataOut;
reg [15:0] bRAMDataIn = 0;

reg [16:0] bRAMReadAddress = 0;
reg [16:0] bRAMWriteAddress = 10;

SRAMController SRAMController (

	.IbReadAddress(bRAMReadAddress),
	.IbWriteAddress(bRAMWriteAddress),
	.ObData(bRAMDataOut),
	.IbData(bRAMDataIn),
	
	.IwWrite(1),
	
	.IwClk (rClk)
);

always
begin
	#1 rClk = !rClk;
end


always
begin
	#20 bRAMDataIn = bRAMDataIn + 1;
end

always
begin
	#20
	bRAMReadAddress <= bRAMReadAddress + 1;
	bRAMWriteAddress <= bRAMWriteAddress + 1;
end

endmodule
