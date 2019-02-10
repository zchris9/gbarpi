`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    00:04:14 11/15/2016 
// Design Name: 
// Module Name:    SRAMController 
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
module SRAMController(
	output reg [16:0] RAM_ADDRESS,
	inout [15:0] RAM_DATA,
	output reg RAM_WEn,
	output reg RAM_CEn,
	output reg RAM_OEn,
	
	input [16:0] IbReadAddress,
	input [16:0] IbWriteAddress,
	output reg [15:0] ObData,
	input [15:0] IbData,
	input IwWrite,
	
	
	input IwClk
	
	);

reg [15:0] bWriteBuffer = 0;

reg [16:0] bReadAddressBuffer;
reg [16:0] bWriteAddressBuffer;

(* FSM_ENCODING="ONE-HOT", SAFE_IMPLEMENTATION="NO" *) reg [2:0] bState = 0;

reg rWriteStrobeBuffer = 0;

reg rEnableOutput = 0;

assign RAM_DATA = rEnableOutput ? bWriteBuffer : 16'bZZZZ_ZZZZ_ZZZZ_ZZZZ;


always @(posedge IwClk)
begin
	RAM_CEn <= 0;
	(* FULL_CASE, PARALLEL_CASE *) case (bState)
		0: 
		begin
			RAM_WEn <= 1;
			RAM_OEn <= 0;
			rEnableOutput <= 0;
			
			RAM_ADDRESS <= bReadAddressBuffer;
			
			bState <= 1;
		end
		
		1: 
		begin
			RAM_WEn <= 1;
			RAM_OEn <= 1;
			rEnableOutput <= 0;
			
			RAM_ADDRESS <= bReadAddressBuffer;
			
			ObData <= RAM_DATA;
			
			bState <= 2;
		end
		
		2:
		begin
			RAM_WEn <= 1;
			RAM_OEn <= 1;
			rEnableOutput <= 1;
			
			RAM_ADDRESS <= bWriteAddressBuffer;
			
			bState <= 3;
		end
		
		3:
		begin
			RAM_WEn <= !rWriteStrobeBuffer;
			RAM_OEn <= 1;
			rEnableOutput <= 1;
			
			RAM_ADDRESS <= bWriteAddressBuffer;
			
			bState <= 4;
		end
		
		4:
		begin
			RAM_WEn <= 1;
			RAM_OEn <= 0;
			rEnableOutput <= 0;
			
			RAM_ADDRESS <= IbReadAddress;
			
			bReadAddressBuffer <= IbReadAddress;
			bWriteAddressBuffer <= IbWriteAddress;
			rWriteStrobeBuffer <= IwWrite;
			bWriteBuffer <= IbData;
			
			bState <= 0;
		end
		
		default:
		begin
			bState <= 0;
		end
	endcase
end

endmodule
