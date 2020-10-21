/**
 * main project file.
 * implementation of CS 3220 5 stage pipeline processor to be uploaded and run on an FPGA
 * features class-assigned ISA support alongside interrupts
 * input and output include push buttons, switches, led lights, and hex displays
 * 
 * author: Daniel Wygant
 * date: 11/18/2019
 */

module project3_frame(
  input        CLOCK_50,
  input        RESET_N,
  input  [3:0] KEY,
  input  [9:0] SW,
  output [6:0] HEX0,
  output [6:0] HEX1,
  output [6:0] HEX2,
  output [6:0] HEX3,
  output [6:0] HEX4,
  output [6:0] HEX5,
  output [9:0] LEDR
);

  parameter DBITS    = 32;
  parameter INSTSIZE = 32'd4;
  parameter INSTBITS = 32;
  parameter REGNOBITS = 4;
  parameter REGWORDS = (1 << REGNOBITS);
  parameter IMMBITS  = 16;
  parameter STARTPC  = 32'h100;
  parameter STARTDEV = 32'hFFFFF000;

  // test file location
  parameter IMEMINITFILE = "tests/xmax.mif";
  
  parameter IMEMADDRBITS = 16;
  parameter IMEMWORDBITS = 2;
  parameter IMEMWORDS	 = (1 << (IMEMADDRBITS - IMEMWORDBITS));
  parameter DMEMADDRBITS = 16;
  parameter DMEMWORDBITS = 2;
  parameter DMEMWORDS	 = (1 << (DMEMADDRBITS - DMEMWORDBITS));
  parameter TYPEBITS     = 7;
   
  parameter OP1BITS  = 6;
  parameter OP1_ALUR = 6'b000000;
  parameter OP1_BEQ  = 6'b001000;
  parameter OP1_BLT  = 6'b001001;
  parameter OP1_BLE  = 6'b001010;
  parameter OP1_BNE  = 6'b001011;
  parameter OP1_JAL  = 6'b001100;
  parameter OP1_LW   = 6'b010010;
  parameter OP1_SW   = 6'b011010;
  parameter OP1_ADDI = 6'b100000;
  parameter OP1_ANDI = 6'b100100;
  parameter OP1_ORI  = 6'b100101;
  parameter OP1_XORI = 6'b100110;
  parameter OP1_SYS  = 6'b111111;
  
  // Add parameters for secondary opcode values 
  /* OP2 */
  parameter OP2BITS  = 8;
  parameter OP2_EQ   = 8'b00001000;
  parameter OP2_LT   = 8'b00001001;
  parameter OP2_LE   = 8'b00001010;
  parameter OP2_NE   = 8'b00001011;
  parameter OP2_ADD  = 8'b00100000;
  parameter OP2_AND  = 8'b00100100;
  parameter OP2_OR   = 8'b00100101;
  parameter OP2_XOR  = 8'b00100110;
  parameter OP2_SUB  = 8'b00101000;
  parameter OP2_NAND = 8'b00101100;
  parameter OP2_NOR  = 8'b00101101;
  parameter OP2_NXOR = 8'b00101110;
  parameter OP2_RSHF = 8'b00110000;
  parameter OP2_LSHF = 8'b00110001;
  parameter OP2_RETI = 8'b00000001;
  parameter OP2_RSR  = 8'b00000010;
  parameter OP2_WSR  = 8'b00000011;
  
  /* TYPE */
  parameter TYPE_BR   = 0;
  parameter TYPE_JAL  = 1;
  parameter TYPE_LD	 = 2;
  parameter TYPE_SW   = 3;
  parameter TYPE_RSR  = 4;
  parameter TYPE_WSR  = 5;
  parameter TYPE_RETI = 6;
  
  /* INTR */
  parameter CTRLBITS = 5;
	
  parameter CTRL_RDY = 0;
  parameter CTRL_OVR = 1;
  parameter CTRL_IE  = 4;
	
  parameter IHA = 32'h00000000;
  
  parameter KEYIDN   = 32'd0;
  parameter SWIDN	   = 32'd1;
  parameter TIMERIDN = 32'd2;
  
  /* DEVICES */
  
  hex_dev #(.DBITS(DBITS)) dev0 (.clk(clk),
											.reset(reset),
											.ld(LD_MEM_w),
											.sw(SW_MEM_w),
											.addrbus(ADDRBUS_MEM_w),
											.databus(DATABUS_MEM_w),
											.HEX0(HEX0),
											.HEX1(HEX1),
											.HEX2(HEX2),
											.HEX3(HEX3),
											.HEX4(HEX4),
											.HEX5(HEX5)
										  );
											
  ledr_dev #(.DBITS(DBITS)) dev1 (.clk(clk),
										    .reset(reset),
										    .ld(LD_MEM_w),
										    .sw(SW_MEM_w),
										    .addrbus(ADDRBUS_MEM_w),
										    .databus(DATABUS_MEM_w),
										    .LEDR(LEDR)
										   );
											
  wire KEYIRQ;
	
  key_dev #(.DBITS(DBITS), .CTRLBITS(CTRLBITS), .CTRL_RDY(CTRL_RDY), .CTRL_OVR(CTRL_OVR), .CTRL_IE(CTRL_IE)) dev2 (.clk(clk),
																																						 .reset(reset),
																																						 .ld(LD_MEM_w),
																																						 .sw(SW_MEM_w),
																																						 .addrbus(ADDRBUS_MEM_w),
																																						 .databus(DATABUS_MEM_w),
																																						 .KEY(KEY),
																																						 .KEYIRQ(KEYIRQ)
																																					   );
  wire SWIRQ;
	
  sw_dev #(.DBITS(DBITS), .CTRLBITS(CTRLBITS), .CTRL_RDY(CTRL_RDY), .CTRL_OVR(CTRL_OVR), .CTRL_IE(CTRL_IE)) dev3  (.clk(clk),
																																					   .reset(reset),
																																					   .ld(LD_MEM_w),
																																					   .sw(SW_MEM_w),
																																					   .addrbus(ADDRBUS_MEM_w),
																																					   .databus(DATABUS_MEM_w),
																																					   .SW(SW),
																																					   .SWIRQ(SWIRQ)
																																					   );
																																					  
  wire TIMERIRQ;
	
  timer_dev #(.DBITS(DBITS), .CTRLBITS(CTRLBITS), .CTRL_RDY(CTRL_RDY), .CTRL_OVR(CTRL_OVR), .CTRL_IE(CTRL_IE)) dev4 (.clk(clk),
																																						   .reset(reset),
																																					 	   .ld(LD_MEM_w),
																																						   .sw(SW_MEM_w),
																																						   .addrbus(ADDRBUS_MEM_w),
																																						   .databus(DATABUS_MEM_w),
																																						   .TIMERIRQ(TIMERIRQ)
																																					     );
  
  //*** PLL ***//
  // The reset signal comes from the reset button on the DE0-CV board
  // RESET_N is active-low, so we flip its value ("reset" is active-high)
  // The PLL is wired to produce clk and locked signals for our logic
  
  wire clk;
  wire locked;
  wire reset;

  Pll myPll(
    .refclk	(CLOCK_50),
    .rst     	(!RESET_N),
    .outclk_0 	(clk),
    .locked   	(locked)
  );

  assign reset = !locked;
  
  //*** MEMORY SYMBOLS ***//
  
  reg [DBITS-1:0] REGS [REGWORDS-1:0];			// register file
  
  reg [DBITS-1:0] SREGS [REGWORDS-1:0];		// system register file
															// 0=PCS, 1=IHA, 2=IRA, 3=IDN
  
  (* ram_init_file = IMEMINITFILE *)
  reg [DBITS-1:0] IMEM[IMEMWORDS-1:0];			// instruction memory

  (* ram_init_file = IMEMINITFILE *)
  reg [DBITS-1:0] DMEM[DMEMWORDS-1:0];  		// data memory
  

  /*
  initial begin
    $readmemh("tests/test.hex", IMEM);
	 $readmemh("tests/test.hex", DMEM);
  end
  */
  //*** CONTROL SIGNALS ***//
  
  wire DATA_STALL; // stall due to data dependency on a ld inst
  wire CTRL_STALL; // stall due to unresolved branch/jump
  wire JUMP;       // indicates the need to load a new PC
  
  wire 				 IRQ = SREGS[0][0] & (KEYIRQ | SWIRQ | TIMERIRQ) & ~TYPE_EX[TYPE_WSR];
														    
  //*** FETCH STAGE ***//
  
  reg  [DBITS-1:0] PC; 																// current program counter
  wire [DBITS-1:0] PC_NEW;															// new pc address from a branch calculated in the EX stage
  
  wire [DBITS-1:0] IMEM_VAL = IMEM[PC[IMEMADDRBITS-1:IMEMWORDBITS]];	// IMEM[PC]
  
  // FE BUFFER
  reg  [DBITS-1:0] PC_FE;				
  reg  [DBITS-1:0] INST_FE;	
  // end FE BUFFER  
  
  always @ (posedge clk or posedge reset) begin
    if (reset) begin
	   PC      <= STARTPC;		
		PC_FE   <= {DBITS{1'b0}};
		INST_FE <= {DBITS{1'b0}};
	 end
	 else if (DATA_STALL) begin		// pause program progression until data dependency has been resolved
	   PC      <= PC;
		PC_FE   <= PC_FE;
		INST_FE <= INST_FE;
	 end
	 else if (CTRL_STALL) begin		// pause program progression and send nops until branch has been resolved
	   PC      <= PC;
		PC_FE   <= {DBITS{1'b0}};
		INST_FE <= {DBITS{1'b0}};
	 end
	 else if (IRQ) begin					// take interupt; look in MEM stage for the other actions taken on this clk cycle
		PC      <= IHA;
		PC_FE   <= {DBITS{1'b0}};
		INST_FE <= {DBITS{1'b0}};	 
	 end
	 else if (JUMP) begin				// update pc from the new calculated pc from a branch
	   PC      <= PC_NEW;
		PC_FE   <= {DBITS{1'b0}};
		INST_FE <= {DBITS{1'b0}};
	 end
	 else begin								// increment pc and update FE BUFFER
	   PC      <= PC + INSTSIZE;
		PC_FE   <= PC;
		INST_FE <= IMEM_VAL;
	 end
  end
    
  
  //*** DECODE STAGE ***//
  
  // decoded instruction
  wire [OP1BITS-1:0]     OP1_DE_w = INST_FE[31:26];
  wire [OP2BITS-1:0]     OP2_DE_w = INST_FE[25:18];
  wire [IMMBITS-1:0]     IMM_DE_w = INST_FE[23:8];
  wire [REGNOBITS-1:0]   RD_DE_w  = INST_FE[11:8];
  wire [REGNOBITS-1:0]   RS_DE_w  = INST_FE[7:4];
  wire [REGNOBITS-1:0]   RT_DE_w  = INST_FE[3:0];
  // end decoded instruction
  
  wire [DBITS-1:0]    SXT_IMM_DE_w; 	// sign extended immediate value
  wire [TYPEBITS-1:0] TYPE_DE_w;    	// inst type { is_reti, is_wsr, is_rsr, is_st, is_ld, is_jal, is_br }
  wire 					 HAS_DEST_DE_w;	// 1 if inst writes to register in WB
  reg  [DBITS-1:0]    RS_VAL_DE_r; // value from (data-forwarded) RS operand 
  reg  [DBITS-1:0]    RT_VAL_DE_r; // value from (data-forwarded) RT operand
  
  assign SXT_IMM_DE_w         = {{(DBITS-IMMBITS){IMM_DE_w[IMMBITS-1]}}, IMM_DE_w};
  
  assign TYPE_DE_w[TYPE_BR]   = (OP1_DE_w == OP1_BEQ || OP1_DE_w == OP1_BLT || OP1_DE_w == OP1_BLE || OP1_DE_w == OP1_BNE) ? 1'b1 : 1'b0;
  assign TYPE_DE_w[TYPE_JAL]  = (OP1_DE_w == OP1_JAL) ? 1'b1 : 1'b0;
  assign TYPE_DE_w[TYPE_LD]   = (OP1_DE_w == OP1_LW)  ? 1'b1 : 1'b0;
  assign TYPE_DE_w[TYPE_SW]   = (OP1_DE_w == OP1_SW)  ? 1'b1 : 1'b0;
  assign TYPE_DE_w[TYPE_RSR]  = (OP1_DE_w == OP1_SYS && OP2_DE_w == OP2_RSR) ? 1'b1 : 1'b0;
  assign TYPE_DE_w[TYPE_WSR]  = (OP1_DE_w == OP1_SYS && OP2_DE_w == OP2_WSR) ? 1'b1 : 1'b0;
  assign TYPE_DE_w[TYPE_RETI] = (OP1_DE_w == OP1_SYS && OP2_DE_w == OP2_RETI) ? 1'b1 : 1'b0;
  
  assign HAS_DEST_DE_w        = ~(TYPE_DE_w[TYPE_BR] | TYPE_DE_w[TYPE_SW] | TYPE_DE_w[TYPE_WSR] | TYPE_DE_w[TYPE_RETI]);						 
  
  always @ (*) begin
	 if (HAS_DEST_DE == 1'b1 && RS_DE_w == DEST_DE && TYPE_DE[TYPE_LD] != 1'b1 && TYPE_DE[TYPE_RSR] != 1'b1)											 // data forward if dependent upon inst in EX stage & EX inst is not a ld/rsr
	   RS_VAL_DE_r <= RES_EX_w;
	 else if (HAS_DEST_EX == 1'b1 && RS_DE_w == DEST_EX)					    																						 // data forward if dependent upon inst in MEM stage
		RS_VAL_DE_r <= RES_MEM_w;
	 else																														                                           // get from register
	   RS_VAL_DE_r <= REGS[RS_DE_w];
		  
    if (HAS_DEST_DE == 1'b1 && RT_DE_w == DEST_DE && TYPE_DE[TYPE_LD] != 1'b1 && TYPE_DE[TYPE_RSR] != 1'b1)											 // data forward if dependent upon inst in EX stage & EX inst is not a ld/rsr
	   RT_VAL_DE_r <= RES_EX_w;
	 else if (HAS_DEST_EX == 1'b1 && RT_DE_w == DEST_EX)					    																						 // data forward if dependent upon inst in MEM stage
	   RT_VAL_DE_r <= RES_MEM_w;
	 else																														                                           // get from register
	   RT_VAL_DE_r <= REGS[RT_DE_w];
  end
  
  
  
  assign CTRL_STALL = TYPE_DE_w[TYPE_BR] | TYPE_DE_w[TYPE_JAL] | TYPE_DE_w[TYPE_RETI]; 																	 // if inst is a branch/jal/reti we need to stall until resolved in EX
  
  wire RSRT_DEP     = (OP1_DE_w == OP1_ALUR || TYPE_DE_w[TYPE_BR] == 1'b1 || TYPE_DE_w[TYPE_SW] == 1'b1) ? 1'b1 : 1'b0;							 // if this inst depends on both RS and RT
  
  wire RS_DEP		  = (OP1_DE_w == OP1_JAL  || OP1_DE_w == OP1_LW  || OP1_DE_w == OP1_ADDI || 
							  OP1_DE_w == OP1_ANDI || OP1_DE_w == OP1_ORI || OP1_DE_w == OP1_XORI) ? 1'b1 : 1'b0;											 // if this inst depends only on RS

  wire NO_DEP		  = (TYPE_DE_w[TYPE_RSR] == 1'b1 || TYPE_DE_w[TYPE_WSR] == 1'b1 || TYPE_DE_w[TYPE_RETI] == 1'b1) ? 1'b1 : 1'b0;			 // if this inst doesn't depend on anything
							  
  wire RS_AVAIL     = (RS_DE_w == DEST_DE && (TYPE_DE[TYPE_LD] == 1'b1 || TYPE_DE[TYPE_RSR] == 1'b1)) ? 1'b0 : 1'b1;								 // for checking if the EX stage holds a ld/rsr dependency
  wire RT_AVAIL     = (RT_DE_w == DEST_DE && (TYPE_DE[TYPE_LD] == 1'b1 || TYPE_DE[TYPE_RSR] == 1'b1)) ? 1'b0 : 1'b1;								

  assign DATA_STALL = (NO_DEP == 1'b1)                                           ? 1'b0 :
                      (RS_DEP == 1'b1 && RS_AVAIL == 1'b1)                       ? 1'b0 :
							 (RSRT_DEP == 1'b1 && RS_AVAIL == 1'b1 && RT_AVAIL == 1'b1) ? 1'b0 :
																											  1'b1;
   
  // DE BUFFER  
  reg  [OP1BITS-1:0]     OP1_DE;		
  reg  [OP2BITS-1:0]     OP2_DE;
  reg							 HAS_DEST_DE;
  reg  [REGNOBITS-1:0]   DEST_DE;
  reg  [REGNOBITS-1:0]   SREG_DE;
  reg signed [DBITS-1:0] SXT_IMM_DE;
  reg signed [DBITS-1:0] RS_VAL_DE;
  reg signed [DBITS-1:0] RT_VAL_DE;
  reg  [DBITS-1:0]       PC_DE;
  reg  [TYPEBITS-1:0]    TYPE_DE; 
  //end DE BUFFER
   
  always @ (posedge clk or posedge reset) begin
    if (reset) begin
	   OP1_DE      <= {OP1BITS{1'b0}};
		OP2_DE      <= {OP2BITS{1'b0}};
		HAS_DEST_DE <= 1'b0;
		DEST_DE     <= {REGNOBITS{1'b0}};
		SREG_DE     <= {REGNOBITS{1'b0}};
		SXT_IMM_DE  <= {DBITS{1'b0}};
		RS_VAL_DE   <= {DBITS{1'b0}};
		RT_VAL_DE   <= {DBITS{1'b0}};
		PC_DE       <= {DBITS{1'b0}};
		TYPE_DE     <= {TYPEBITS{1'b0}};	 
	 end
	 else if (JUMP | DATA_STALL) begin // send a nop on a taken branch / data dependency stall
	   OP1_DE      <= {OP1BITS{1'b0}};
		OP2_DE      <= {OP2BITS{1'b0}};
		HAS_DEST_DE <= 1'b0;
		DEST_DE     <= {REGNOBITS{1'b0}};
		SREG_DE     <= {REGNOBITS{1'b0}};
		SXT_IMM_DE  <= {DBITS{1'b0}};
		RS_VAL_DE   <= {DBITS{1'b0}};
		RT_VAL_DE   <= {DBITS{1'b0}};
		PC_DE       <= {DBITS{1'b0}};
		TYPE_DE     <= {TYPEBITS{1'b0}};
	 end
	 else begin									// update DE BUFFER
	   OP1_DE      <= OP1_DE_w;
		OP2_DE      <= OP2_DE_w;
		HAS_DEST_DE <= HAS_DEST_DE_w;
		DEST_DE     <= RS_DEP ? RT_DE_w : RD_DE_w;	// choose the destination register
		SREG_DE     <= RS_DE_w;
		SXT_IMM_DE  <= SXT_IMM_DE_w;
		RS_VAL_DE   <= RS_VAL_DE_r;
		RT_VAL_DE   <= RT_VAL_DE_r;
		PC_DE       <= PC_FE;
		TYPE_DE     <= TYPE_DE_w;
	 end
  end
	     
  
  //*** EXECUTE STAGE ***// 
  
  wire signed [DBITS-1:0] ALU_OP0_w;
  wire signed [DBITS-1:0] ALU_OP1_w;
  wire signed [DBITS-1:0] ALU_OUT_w;
  
  wire        [DBITS-1:0] RES_EX_w;
  
  assign ALU_OP0_w = RS_VAL_DE;
  assign ALU_OP1_w = (OP1_DE == OP1_ALUR || TYPE_DE[0] == 1'b1) ? RT_VAL_DE : SXT_IMM_DE;
  
  assign ALU_OUT_w = (OP1_DE == OP1_BEQ)  ? ((ALU_OP0_w == ALU_OP1_w) ? {{(DBITS-1){1'b0}}, 1'b1} : {DBITS{1'b0}}) :
							(OP1_DE == OP1_BLT)  ? ((ALU_OP0_w <  ALU_OP1_w) ? {{(DBITS-1){1'b0}}, 1'b1} : {DBITS{1'b0}}) :
							(OP1_DE == OP1_BLE)  ? ((ALU_OP0_w <= ALU_OP1_w) ? {{(DBITS-1){1'b0}}, 1'b1} : {DBITS{1'b0}}) :
							(OP1_DE == OP1_BNE)  ? ((ALU_OP0_w != ALU_OP1_w) ? {{(DBITS-1){1'b0}}, 1'b1} : {DBITS{1'b0}}) :
							(OP1_DE == OP1_JAL)  ? {DBITS{1'b0}}																			 :
							(OP1_DE == OP1_LW)   ? ALU_OP0_w + ALU_OP1_w																	 :
							(OP1_DE == OP1_SW)   ? ALU_OP0_w + ALU_OP1_w															 		 :
							(OP1_DE == OP1_ADDI) ? ALU_OP0_w + ALU_OP1_w																	 :
							(OP1_DE == OP1_ANDI) ? ALU_OP0_w & ALU_OP1_w																    :
							(OP1_DE == OP1_ORI)  ? ALU_OP0_w | ALU_OP1_w																	 :
							(OP1_DE == OP1_XORI) ? ALU_OP0_w ^ ALU_OP1_w																	 :
							(OP2_DE == OP2_EQ)   ? (ALU_OP0_w == ALU_OP1_w) ? {{(DBITS-1){1'b0}}, 1'b1} : {DBITS{1'b0}}   :
							(OP2_DE == OP2_LT)   ? (ALU_OP0_w <  ALU_OP1_w) ? {{(DBITS-1){1'b0}}, 1'b1} : {DBITS{1'b0}}   :
							(OP2_DE == OP2_LE)   ? (ALU_OP0_w <= ALU_OP1_w) ? {{(DBITS-1){1'b0}}, 1'b1} : {DBITS{1'b0}}   :
							(OP2_DE == OP2_NE)   ? (ALU_OP0_w != ALU_OP1_w) ? {{(DBITS-1){1'b0}}, 1'b1} : {DBITS{1'b0}}   :
							(OP2_DE == OP2_ADD)  ? ALU_OP0_w + ALU_OP1_w																	 :
							(OP2_DE == OP2_AND)  ? ALU_OP0_w & ALU_OP1_w																	 :
							(OP2_DE == OP2_OR)   ? ALU_OP0_w | ALU_OP1_w																	 :
							(OP2_DE == OP2_XOR)  ? ALU_OP0_w ^ ALU_OP1_w																	 :
							(OP2_DE == OP2_SUB)  ? ALU_OP0_w - ALU_OP1_w																	 :
							(OP2_DE == OP2_NAND) ? ~(ALU_OP0_w & ALU_OP1_w)																 :
							(OP2_DE == OP2_NOR)  ? ~(ALU_OP0_w | ALU_OP1_w)																 :
							(OP2_DE == OP2_NXOR) ? ~(ALU_OP0_w ^ ALU_OP1_w)																 :
							(OP2_DE == OP2_RSHF) ? ALU_OP0_w >> ALU_OP1_w														       :
							(OP2_DE == OP2_LSHF) ? ALU_OP0_w << ALU_OP1_w																 :
														  {DBITS{1'b0}};
							
  assign RES_EX_w = (TYPE_DE[TYPE_JAL] == 1'b1) ? PC_DE + INSTSIZE : ALU_OUT_w;
						
  // compute the new pc for a taken branch or jal
  assign PC_NEW = (TYPE_DE[TYPE_JAL] == 1'b1)                      ? (SXT_IMM_DE << 2) + RS_VAL_DE          :
						(TYPE_DE[TYPE_BR] == 1'b1 && ALU_OUT_w == 32'b1) ? (SXT_IMM_DE << 2) + (PC_DE + INSTSIZE) :
						(TYPE_DE[TYPE_RETI] == 1'b1)							 ? SREGS[2]											:
																					      {DBITS{1'b0}};
	
  // accept a new pc if inst is a taken branch or jal
  assign JUMP = (TYPE_DE[TYPE_JAL] == 1'b1)                      ? 1'b1 :
					 (TYPE_DE[TYPE_BR] == 1'b1 && ALU_OUT_w == 32'b1) ? 1'b1 :
					 (TYPE_DE[TYPE_RETI] == 1'b1)							  ? 1'b1 :
					                                                    1'b0;
																				  
  // EX BUFFER
  reg							 HAS_DEST_EX;
  reg [REGNOBITS-1:0]    DEST_EX;	
  reg [REGNOBITS-1:0]	 SREG_EX;
  reg [DBITS-1:0]        RES_EX;
  reg [DBITS-1:0]        SW_EX;
  reg [TYPEBITS-1:0]     TYPE_EX;			
  // end EX BUFFER
  
  always @ (posedge clk or posedge reset) begin
    if (reset) begin
		HAS_DEST_EX <= 1'b0;
		DEST_EX     <= {REGNOBITS{1'b0}};
		SREG_EX     <= {REGNOBITS{1'b0}};
		RES_EX      <= {DBITS{1'b0}};
		SW_EX       <= {DBITS{1'b0}};
		TYPE_EX     <= {TYPEBITS{1'b0}};
	 end
	 else begin								 	// update EX BUFFER
		HAS_DEST_EX <= HAS_DEST_DE;
		DEST_EX     <= DEST_DE;
		SREG_EX	   <= SREG_DE;
		RES_EX      <= RES_EX_w;
		SW_EX       <= RT_VAL_DE;
		TYPE_EX     <= TYPE_DE;
    end
  end
  
  
  //*** MEMORY STAGE ***//

  wire LD_MEM_w   = TYPE_EX[2];
  wire SW_MEM_w   = TYPE_EX[3];
  
  wire [DBITS-1:0] ADDRBUS_MEM_w;
  wire [DBITS-1:0] DATABUS_MEM_w;
  wire [DBITS-1:0] RES_MEM_w;
 
  
  assign ADDRBUS_MEM_w = RES_EX;
  
  assign DATABUS_MEM_w = (LD_MEM_w == 1'b1 && ADDRBUS_MEM_w < STARTDEV) ? DMEM[ADDRBUS_MEM_w[DMEMADDRBITS-1:DMEMWORDBITS]] : {DBITS{1'bz}};
  assign DATABUS_MEM_w = (SW_MEM_w == 1'b1) ? SW_EX : {DBITS{1'bz}};
  assign DATABUS_MEM_w = (TYPE_EX[TYPE_RSR] == 1'b1) ? SREGS[SREG_EX] : {DBITS{1'bz}};
  
  assign RES_MEM_w = (LD_MEM_w == 1'b1 || TYPE_EX[TYPE_RSR] == 1'b1) ? DATABUS_MEM_w : RES_EX;
  
  // MEM BUFFER
  reg 					 HAS_DEST_MEM;
  reg [REGNOBITS-1:0] DEST_MEM;		
  reg [DBITS-1:0]     RES_MEM;
  reg [TYPEBITS-1:0]  TYPE_MEM;
  // end MEM BUFFER
  
  always @ (posedge clk or posedge reset) begin
    if (reset) begin
		HAS_DEST_MEM <= 1'b0;
		DEST_MEM <= {REGNOBITS{1'b0}};
		RES_MEM  <= {DBITS{1'b0}};
		TYPE_MEM <= 6'b0;
		
		SREGS[0] <= {DBITS{1'b0}};
		SREGS[1] <= {DBITS{1'b0}};
		SREGS[2] <= {DBITS{1'b0}};
		SREGS[3] <= {DBITS{1'b0}};
		SREGS[4] <= {DBITS{1'b0}};
		SREGS[5] <= {DBITS{1'b0}};
		SREGS[6] <= {DBITS{1'b0}};
		SREGS[7] <= {DBITS{1'b0}};
		SREGS[8] <= {DBITS{1'b0}};
		SREGS[9] <= {DBITS{1'b0}};
		SREGS[10] <= {DBITS{1'b0}};
		SREGS[11] <= {DBITS{1'b0}};
		SREGS[12] <= {DBITS{1'b0}};
		SREGS[13] <= {DBITS{1'b0}};
		SREGS[14] <= {DBITS{1'b0}};
		SREGS[15] <= {DBITS{1'b0}};
	 end
	 else begin					 // update MEM BUFFER
	   HAS_DEST_MEM <= HAS_DEST_EX;
		DEST_MEM     <= DEST_EX;
		RES_MEM      <= RES_MEM_w;
		TYPE_MEM     <= TYPE_EX;
		
		if (TYPE_EX[TYPE_SW] == 1'b1 && ADDRBUS_MEM_w < STARTDEV)
			DMEM[ADDRBUS_MEM_w[DMEMADDRBITS-1:DMEMWORDBITS]] <= DATABUS_MEM_w;	
		else if (TYPE_EX[TYPE_RETI] == 1'b1)
			SREGS[0][0] <= SREGS[0][1];
		else if (TYPE_EX[TYPE_WSR] == 1'b1)
			SREGS[SREG_EX] <= REGS[DEST_MEM];
		else if (DATA_STALL == 1'b0 && CTRL_STALL == 1'b0 && IRQ == 1'b1) begin
			SREGS[0][1:0] <= { SREGS[0][0], 1'b0 };
			SREGS[1] <= IHA;
			SREGS[2] <= (JUMP == 1'b1) ? PC_NEW : PC;
			SREGS[3] <= (TIMERIRQ == 1'b1) ? TIMERIDN :
							(KEYIRQ == 1'b1)   ? KEYIDN   :
							(SWIRQ == 1'b1)    ? SWIDN    :
													   {DBITS{1'b0}};
		end
			
	 end
  end
 
 
  //*** WRITE BACK STAGE ***//  
  
  always @ (negedge clk or posedge reset) begin
    if (reset) begin
	   REGS[0] <= {DBITS{1'b0}};
		REGS[1] <= {DBITS{1'b0}};
		REGS[2] <= {DBITS{1'b0}};
		REGS[3] <= {DBITS{1'b0}};
		REGS[4] <= {DBITS{1'b0}};
		REGS[5] <= {DBITS{1'b0}};
		REGS[6] <= {DBITS{1'b0}};
		REGS[7] <= {DBITS{1'b0}};
		REGS[8] <= {DBITS{1'b0}};
		REGS[9] <= {DBITS{1'b0}};
		REGS[10] <= {DBITS{1'b0}};
		REGS[11] <= {DBITS{1'b0}};
		REGS[12] <= {DBITS{1'b0}};
		REGS[13] <= {DBITS{1'b0}};
		REGS[14] <= {DBITS{1'b0}};
		REGS[15] <= {DBITS{1'b0}};
    end
	 else begin
	 
		if (HAS_DEST_MEM == 1'b1)
		  REGS[DEST_MEM] <= RES_MEM;
	 end
  end

endmodule