/**
 * timer device file
 * 
 * author: Daniel Wygant
 * date: 11/18/2019
 */

module timer_dev (clk, reset, ld, sw, addrbus, databus, TIMERIRQ);
	
	parameter DBITS;
	
	parameter CTRLBITS;
	
	parameter CTRL_RDY;
	parameter CTRL_OVR;
	parameter CTRL_IE;
	
	parameter TIMERCNTADDR  = 32'hFFFFF100;
	parameter TIMERLIMADDR  = 32'hFFFFF104;
	parameter TIMERCTRLADDR = 32'hFFFFF108;
	
	input clk;
	input reset;
	input ld;
	input sw;
	input [DBITS-1:0] addrbus;
	inout [DBITS-1:0] databus;
	
	output TIMERIRQ = TIMERCTRL[CTRL_RDY] & TIMERCTRL[CTRL_IE];
	
	reg [DBITS-1:0]    TIMERCNT;
	reg [DBITS-1:0]    TIMERLIM;
	reg [CTRLBITS-1:0] TIMERCTRL;
	
	
	assign databus = (ld == 1'b1 && addrbus == TIMERCNTADDR)  ? TIMERCNT  :
					     (ld == 1'b1 && addrbus == TIMERLIMADDR)  ? TIMERLIM  :
						  (ld == 1'b1 && addrbus == TIMERCTRLADDR) ? TIMERCTRL :
																				   {DBITS{1'bz}};
																					
	parameter CYCLES_PER_MS = 50000;
																
	reg [DBITS-1:0] count;						
	
	always @ (posedge clk or posedge reset) begin
		if (reset) begin
			TIMERCNT  <= {DBITS{1'b0}};
			TIMERLIM  <= {DBITS{1'b0}};
			TIMERCTRL <= {CTRLBITS{1'b0}};
			count     <= {DBITS{1'b0}};
		end
		else if (sw == 1'b1 && addrbus == TIMERCNTADDR && databus <= TIMERLIM - 1) begin
			TIMERCNT <= databus;
			count <= {DBITS{1'b0}};
		end
		else if (sw == 1'b1 && addrbus == TIMERLIMADDR) begin
			TIMERLIM <= databus;
			TIMERCNT <= {DBITS{1'b0}};
			count    <= {DBITS{1'b0}};
		end
		else if (sw == 1'b1 && addrbus == TIMERCTRLADDR) begin
			TIMERCTRL[CTRL_RDY] <= (databus[CTRL_RDY] == 1'b1) ? TIMERCTRL[CTRL_RDY] : 1'b0;
			TIMERCTRL[CTRL_OVR] <= (databus[CTRL_OVR] == 1'b1) ? TIMERCTRL[CTRL_OVR] : 1'b0;
			TIMERCTRL[CTRL_IE]  <= databus[CTRL_IE];
		end
		else if (count == CYCLES_PER_MS - 1) begin
			count <= {DBITS{1'b0}};
			
			if (TIMERCNT == TIMERLIM - 1) begin
				TIMERCNT <= {DBITS{1'b0}};
				
				TIMERCTRL[CTRL_RDY] <= 1'b1;
				TIMERCTRL[CTRL_OVR] <= (TIMERCTRL[CTRL_RDY] == 1'b1) ? 1'b1 : TIMERCTRL[CTRL_OVR];
			end
			else
				TIMERCNT <= TIMERCNT + 1;
		
		end
		else
			count <= count + 1;
	end

endmodule


















	

	
	
	
	
																											
	
	
	