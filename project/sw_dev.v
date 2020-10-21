/**
 * switch device file
 * 
 * author: Daniel Wygant
 * date: 11/18/2019
 */

module sw_dev (clk, reset, ld, sw, addrbus, databus, SW, SWIRQ);
	
	parameter DBITS;
	
	parameter CTRLBITS;
	
	parameter CTRL_RDY;
	parameter CTRL_OVR;
	parameter CTRL_IE;
	
	parameter SWDATAADDR = 32'hFFFFF090;
	parameter SWDATABITS = 10;
	parameter SWCTRLADDR = 32'hFFFFF094;
	
	input clk;
	input reset;
	input ld;
	input sw;
	input [DBITS-1:0] addrbus;
	inout [DBITS-1:0] databus;
	
	input [SWDATABITS-1:0] SW;
	
	output SWIRQ = SWCTRL[CTRL_RDY] & SWCTRL[CTRL_IE];
	
	reg [SWDATABITS-1:0] SWDATA;
	reg [CTRLBITS-1:0]   SWCTRL;
	
	assign databus = (ld == 1'b1 && addrbus == SWDATAADDR) ? {{(DBITS-SWDATABITS){1'b0}}, SWDATA} :
					     (ld == 1'b1 && addrbus == SWCTRLADDR) ? {{(DBITS-CTRLBITS){1'b0}}, SWCTRL}   :
																				{DBITS{1'bz}};
																
	reg [SWDATABITS-1:0] SWREG;
	
	wire [SWDATABITS-1:0] SW_TRIGGERED = SW & ~SWREG;										
	
	always @ (posedge clk or posedge reset) begin
		if (reset) begin
			SWDATA <= {SWDATABITS{1'b0}};  
			SWCTRL <= {CTRLBITS{1'b0}};
	   end
		else begin
		
			SWREG <= SW;
			
			if (SW_TRIGGERED != {SWDATABITS{1'b0}}) begin
				SWDATA <= SW_TRIGGERED;
				SWCTRL[CTRL_RDY] <= 1'b1;
				SWCTRL[CTRL_OVR] <= (SWCTRL[CTRL_RDY] == 1'b1) ? 1'b1 : SWCTRL[CTRL_OVR];
			end
			
			if (ld == 1'b1 && addrbus == SWDATAADDR)
				SWCTRL[CTRL_RDY] <= 1'b0;
			else if (sw == 1'b1 && addrbus == SWCTRLADDR) begin
				SWCTRL[CTRL_OVR] <= (databus[CTRL_OVR] == 1'b1) ? SWCTRL[CTRL_OVR] : 1'b0;
				SWCTRL[CTRL_IE]  <= databus[CTRL_IE];
			end
		end
	end

endmodule


	
	
	