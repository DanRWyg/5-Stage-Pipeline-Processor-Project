/**
 * seven seg device file
 * 
 * date: 11/18/2019
 */

module SevenSeg(output [6:0] OUT, input [3:0] IN, input OFF);
assign OUT =
  (OFF)        ? 7'b1111111 :
  (IN == 4'h0) ? 7'b1000000 :
  (IN == 4'h1) ? 7'b1111001 :
  (IN == 4'h2) ? 7'b0100100 :
  (IN == 4'h3) ? 7'b0110000 :
  (IN == 4'h4) ? 7'b0011001 :
  (IN == 4'h5) ? 7'b0010010 :
  (IN == 4'h6) ? 7'b0000010 :
  (IN == 4'h7) ? 7'b1111000 :
  (IN == 4'h8) ? 7'b0000000 :
  (IN == 4'h9) ? 7'b0010000 :
  (IN == 4'hA) ? 7'b0001000 :
  (IN == 4'hb) ? 7'b0000011 :
  (IN == 4'hc) ? 7'b1000110 :
  (IN == 4'hd) ? 7'b0100001 :
  (IN == 4'he) ? 7'b0000110 :
  /*IN == 4'hf*/ 7'b0001110 ;
endmodule