/**
 * led device file
 * 
 * author: Daniel Wygant
 * date: 11/18/2019
 */

module ledr_dev (clk, reset, ld, sw, addrbus, databus, LEDR);
	
	parameter DBITS;
	
	parameter LEDRADDR = 32'hFFFFF020;
	parameter LEDRBITS = 10;
	
	input clk;
	input reset;
	input ld;
	input sw;
	input [DBITS-1:0] addrbus;
	inout [DBITS-1:0] databus;
	
	output [LEDRBITS-1:0] LEDR;

	reg [LEDRBITS-1:0] LEDRDATA;
	
	assign databus = (ld == 1'b1 && addrbus == LEDRADDR) ? {{(DBITS-LEDRBITS){1'b0}}, LEDRDATA} : {DBITS{1'bz}};
	
	always @ (posedge clk or posedge reset) begin
		if (reset)
			LEDRDATA <= {LEDRBITS{1'b0}};	  
		else if (sw == 1'b1 && addrbus == LEDRADDR)
			LEDRDATA <= databus[LEDRBITS-1:0];
	end
	
	assign LEDR = LEDRDATA;

endmodule