module RV_wrapper (
    input logic clk, rst, en,
    output logic [31:0] WriteDataM, DataAdrM,
    output logic MemWriteM
);
    logic [31:0] PCF, InstrF, ReadDataM;
    // instantiate processor and memories
    RiscV riscv_u(
	.clk, 
	.rst, 
	.en, 
	.PCF, 
	.InstrF, 
	.MemWriteM, 
	.ALUResultM(DataAdrM),
	.WriteDataM, 
	.ReadDataM
    );
    imem imem_u(PCF, InstrF);
    dmem dmem_u(clk, MemWriteM, DataAdrM, WriteDataM, ReadDataM);
endmodule   
