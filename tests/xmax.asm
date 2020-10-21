.NAME	HEX  =0xFFFFF000

.NAME   LEDR =0xFFFFF020

.NAME   KEY      =0xFFFFF080
.NAME   KCTRL    =0xFFFFF084
.NAME	KEYDEVNUM=0

.NAME   SW      =0xFFFFF090
.NAME   SCTRL   =0xFFFFF094
.NAME	SWDEVNUM=1

.NAME   TCNT       =0xFFFFF100
.NAME   TLIM       =0xFFFFF104
.NAME   TCTRL      =0xFFFFF108
.NAME	TIMERDEVNUM=2

.NAME   SSTACK=0x800

.NAME   UPPERLEDR=0x3E0
.NAME   LOWERLEDR=0x1F

	.ORG 0x0
	
	SUBI		SSP,SSP,0xC
	SW		A0,8(SSP)
	SW		A1,4(SSP)
	SW		RA,0(SSP)	; push A0, A1, RA

	RSR		A0,IDN		; get the interrupting device number
	
KeyIntr:
	ADDI		zero,A1,KEYDEVNUM
	BNE		A0,A1,SwIntr
	CALL		KeyHandler(zero)
	BEQ		zero,zero,FinishIntr

SwIntr:
	ADDI		zero,A1,SWDEVNUM
	BNE		A0,A1,TimerIntr
	CALL		SwHandler(zero)
	BEQ		zero,zero,FinishIntr

TimerIntr:
	ADDI		zero,A1,TIMERDEVNUM
	BNE		A0,A1,FinishIntr
	CALL		TimerHandler(zero)
	BEQ		zero,zero,FinishIntr

FinishIntr:

	LW		RA,0(SSP)
	LW		A1,4(SSP)
	LW		A0,8(SSP)
	ADDI		SSP,SSP,0xC	; pop A0, A1, RA

	RETI


	.ORG 0x100
	XOR		zero,zero,zero

	ADDI		zero,SSP,SSTACK			; initialize system stack pointer

	ADDI		zero,A0,2
	SW		A0,SpeedState(zero)
	SW		A0,HEX(zero)			; initialize SpeedState in memory/HEX

	SW		zero,HexShift(zero)
	SW		zero,SwitchLastIntr(zero)
	SW		zero,CurrBlinkState(zero)	; initialize other important memory locations
	
	ADDI		zero,A0,500
	SW		A0,TLIM(zero)			; initialize timer limit to 500ms

	ADDI		zero,A0,0x10
	SW		A0,KCTRL(zero)			
	SW		A0,SCTRL(zero)				
	SW		A0,TCTRL(zero)			; enable interrupts for key, sw, and timer

	ADDI		zero,A0,0x1
	WSR		A0,PCS				; enable processor interrupts
	
Forever:
	JMP		Forever(zero)			






KeyHandler:
	LW		A0,KEY(zero)			; get the key state

CheckKey0:
	ANDI		A0,A1,0x1
	BEQ		A1,zero,CheckKey1		; check if key0 is pressed
	
	LW		A0,SpeedState(zero)
	ADDI		zero,A1,0x8
	BLT		A0,A1,IncrementSpeedState	; check if SpeedState can be incremented

	ADDI		zero,A0,0x8			; else, set SpeedState to max
	ADDI		zero,A1,2000			; set timer limit to 2000ms
	
	BEQ		zero,zero,SpeedStateUpdate

IncrementSpeedState:
	ADDI		A0,A0,0x1			; increment SpeedState
	LW		A1,TLIM(zero)
	ADDI		A1,A1,250			; increment timer limit by 250ms

	BEQ		zero,zero,SpeedStateUpdate

CheckKey1:	
	ANDI		A0,A1,0x2
	BEQ		A1,zero,KeyHandlerFinish	; check if key1 is pressed

	LW		A0,SpeedState(zero)
	ADDI		zero,A1,0x1
	BGT		A0,A1,DecrementSpeedState	; check if SpeedState can be decremented

	ADDI		zero,A0,0x1			; else, set SpeedState to min
	ADDI		zero,A1,250			; set timer limit to 250ms
	
	BEQ		zero,zero,SpeedStateUpdate

DecrementSpeedState:
	SUBI		A0,A0,0x1			; decrement SpeedState
	LW		A1,TLIM(zero)
	SUBI		A1,A1,250			; decrement timer limit by 250ms

SpeedStateUpdate:
	SW		A1,TLIM(zero)			; update timer limit
	SW		A0,SpeedState(zero)		; update speed state
	
	LW		A1,HexShift(zero)		
	LSHF		A0,A0,A1
	SW		A0,HEX(zero)			; make sure speed state is displayed on the correct HEX

KeyHandlerFinish:
	
	RET






SwHandler:
	LW		A0,SwitchLastIntr(zero)		; get the timer cnt for last sw interrupt
	LW		A1,TCNT(zero)			; get the current timer cnt

	SUB		A0,A0,A1
	BGE		A0,zero,SwPositive		
	NOT		A0,A0
	ADDI		A0,A0,1
SwPositive:						; A0 = | curr - last |
	SUBI		A0,A1,10
	BGE		A1,zero,SwBegin			; BR if >10ms since last sw interrupt
	LW		A1,TLIM(zero)			
	SUB		A1,A1,A0			; A1 = TimerLimit - | curr - last |
	SUBI		A1,A1,10			
	BLT		A1,zero,SwHandlerFinish		; BR if 10ms< since last sw interrupt
SwBegin:
	LW		A0,SW(zero)			; get switch responsible for interrupt

	ADDI		zero,A1,0x3F
	AND		A0,A0,A1
	BEQ		zero,A0,SwHandlerFinish		; make sure interrupt was caused by one of switches[5:0]

SW0:							; find the switch responsible and set the appropriate HEX shift
	ADDI		zero,A1,0x1
	BNE		A0,A1,SW1
	ADDI		zero,A0,0
	BEQ		zero,zero,SwStateUpdate		
SW1:
	ADDI		zero,A1,0x2
	BNE		A0,A1,SW2
	ADDI		zero,A0,4
	BEQ		zero,zero,SwStateUpdate	
SW2:
	ADDI		zero,A1,0x4
	BNE		A0,A1,SW3
	ADDI		zero,A0,8
	BEQ		zero,zero,SwStateUpdate
SW3:
	ADDI		zero,A1,0x8
	BNE		A0,A1,SW4
	ADDI		zero,A0,12
	BEQ		zero,zero,SwStateUpdate
SW4:	
	ADDI		zero,A1,0x10
	BNE		A0,A1,SW5
	ADDI		zero,A0,16
	BEQ		zero,zero,SwStateUpdate
SW5:
	ADDI		zero,A1,0x20
	BNE		A0,A1,SwHandlerFinish
	ADDI		zero,A0,20

SwStateUpdate:
	SW		A0,HexShift(zero)		; save the current HEX shift

	LW		A1,SpeedState(zero)
	LSHF		A1,A1,A0
	SW		A1,HEX(zero)			; make sure speed state is displayed on the correct HEX

	LW		A0,TCNT(zero)
	SW		A0,SwitchLastIntr(zero)		; save this interrupts time

SwHandlerFinish:
	LW		A0,SW(zero)			; even if the interrupt fails due to 10ms<, we need to remove the rdy bit

	RET






TimerHandler:
	LW		A0,CurrBlinkState(zero)	    	; get current blinking state

	LW		A1,BlinkStates(A0)		; get the blinking state's ledr
	SW		A1,LEDR(zero)			; update the ledr

	ADDI		A0,A0,4		
	ADDI		zero,A1,72
	BLT		A0,A1,TimerHandlerFinish	; CurrBlinkState = (CurrBlinkState + 4) mod 72
	XOR		A0,A0,A0		
	
TimerHandlerFinish:
	SW		A0,CurrBlinkState(zero)		; update current blinking state
	
	ADDI		zero,A0,0x10		
	SW		A0,TCTRL(zero)			; clear the ready bit

	RET



SpeedState:
	.WORD 0
HexShift:
	.WORD 0
SwitchLastIntr:
	.WORD 0
CurrBlinkState:
	.WORD 0
BlinkStates:
	.WORD UPPERLEDR
	.WORD 0
	.WORD UPPERLEDR
	.WORD 0
	.WORD UPPERLEDR
	.WORD 0
	.WORD LOWERLEDR
	.WORD 0
	.WORD LOWERLEDR
	.WORD 0
	.WORD LOWERLEDR
	.WORD 0
	.WORD UPPERLEDR
	.WORD LOWERLEDR
	.WORD UPPERLEDR
	.WORD LOWERLEDR
	.WORD UPPERLEDR
	.WORD LOWERLEDR














