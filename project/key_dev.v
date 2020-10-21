/**
 * key device file
 * 
 * author: Daniel Wygant
 * date: 11/18/2019
 */

module key_dev (clk, reset, ld, sw, addrbus, databus, KEY, KEYIRQ);
	
	parameter DBITS;
	
	parameter CTRLBITS;
	
	parameter CTRL_RDY;
	parameter CTRL_OVR;
	parameter CTRL_IE;
	
	parameter KEYDATAADDR = 32'hFFFFF080;
	parameter KEYDATABITS = 4;
	parameter KEYCTRLADDR = 32'hFFFFF084;
	
	input clk;
	input reset;
	input ld;
	input sw;
	input [DBITS-1:0] addrbus;
	inout [DBITS-1:0] databus;
	
	input [KEYDATABITS-1:0] KEY;
	
	output KEYIRQ = KEYCTRL[CTRL_RDY] & KEYCTRL[CTRL_IE];
	
	reg [KEYDATABITS-1:0]  KEYDATA;
	reg [CTRLBITS-1:0]     KEYCTRL;
	
	assign databus = (ld == 1'b1 && addrbus == KEYDATAADDR) ? {{(DBITS-KEYDATABITS){1'b0}}, KEYDATA} :
					     (ld == 1'b1 && addrbus == KEYCTRLADDR) ? {{(DBITS-CTRLBITS){1'b0}}, KEYCTRL}    :
																				 {DBITS{1'bz}};
																
	reg [KEYDATABITS-1:0] KEYREG;
																										 
	wire [KEYDATABITS-1:0] KEY_TRIGGERED = ~KEY & ~KEYREG;										
	
	always @ (posedge clk or posedge reset) begin
		if (reset) begin
			KEYDATA <= {KEYDATABITS{1'b0}};
			KEYCTRL <= {CTRLBITS{1'b0}};
			KEYREG  <= {KEYDATABITS{1'b0}};
	   end
		else begin
		
			KEYREG <= ~KEY;
			
			if (KEY_TRIGGERED != {KEYDATABITS{1'b0}}) begin
				KEYDATA <= KEY_TRIGGERED;
				KEYCTRL[CTRL_RDY] <= 1'b1;
				KEYCTRL[CTRL_OVR] <= (KEYCTRL[CTRL_RDY] == 1'b1) ? 1'b1 : KEYCTRL[CTRL_OVR];
			end
			
			if (ld == 1'b1 && addrbus == KEYDATAADDR) begin
				KEYDATA <= {KEYDATABITS{1'b0}};
				KEYCTRL[CTRL_RDY] <= 1'b0;
			end
			else if (sw == 1'b1 && addrbus == KEYCTRLADDR) begin
				KEYCTRL[CTRL_OVR] <= (databus[CTRL_OVR] == 1'b1) ? KEYCTRL[CTRL_OVR] : 1'b0;
				KEYCTRL[CTRL_IE]  <= databus[CTRL_IE];
			end
		end
	end

endmodule




	
	
	
	
	
	
	
	
	
																										 
	