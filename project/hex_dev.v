/**
 * hex device file
 * 
 * author: Daniel Wygant
 * date: 11/18/2019
 */


module hex_dev (clk, reset, ld, sw, addrbus, databus, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5);
	
	parameter DBITS;
	
	parameter HEXADDR = 32'hFFFFF000;
	parameter HEXBITS = 24;
	
	input clk;
	input reset;
	input ld;
	input sw;
	input [DBITS-1:0] addrbus;
	inout [DBITS-1:0] databus;
	
	output [6:0] HEX0;
	output [6:0] HEX1;
	output [6:0] HEX2;
	output [6:0] HEX3;
	output [6:0] HEX4;
	output [6:0] HEX5;

	reg [HEXBITS-1:0] HEXDATA;
	
	assign databus = (ld == 1'b1 && addrbus == HEXADDR) ? {{(DBITS-HEXBITS){1'b0}}, HEXDATA} : {DBITS{1'bz}};
	
	always @ (posedge clk or posedge reset) begin
		if (reset)
			HEXDATA <= {HEXBITS{1'b0}};	  
		else if (sw == 1'b1 && addrbus == HEXADDR)
			HEXDATA <= databus[HEXBITS-1:0];
	end

	SevenSeg ss5(.OUT(HEX5), .IN(HEXDATA[23:20]), .OFF(1'b0));
   SevenSeg ss4(.OUT(HEX4), .IN(HEXDATA[19:16]), .OFF(1'b0));
   SevenSeg ss3(.OUT(HEX3), .IN(HEXDATA[15:12]), .OFF(1'b0));
   SevenSeg ss2(.OUT(HEX2), .IN(HEXDATA[11:8]), .OFF(1'b0));
   SevenSeg ss1(.OUT(HEX1), .IN(HEXDATA[7:4]), .OFF(1'b0));
   SevenSeg ss0(.OUT(HEX0), .IN(HEXDATA[3:0]), .OFF(1'b0));

endmodule