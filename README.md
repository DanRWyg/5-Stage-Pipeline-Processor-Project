# Georgia Tech CS 3220 Processor Project
This repository contains the main verilog code files that implement the final project for my CS 3220 Processor Design class at Georgia Tech.
The project was designed and compiled in Quartus II to be implemented on an FPGA board.
### Brief Description:
The main purpose of the project was to design a 5-stage pipeline that could execute a list of provided assembly instructions (the ISA).
Additionally, the project was required to support interrupts via timer, key press, and switch (inputs found on the FPGA board) and be able to appropriately respond to them.
The [project](/project) folder contains all of the verilog code that implements this processor.
The [tests](/tests) folder contains and assembler.py script that was given to us to convert .asm files into program files readable by the processor. Additionally this folder contains a few test .asm files that were used to verify the functionality of the processor.

### The ISA:
![ISA](/resources/isa.png)