module RiscV #(
    parameter BITWIDTH = 32
    )(
    input logic clk, rst, en,
    input logic [31:0] ReadDataM,
    input logic [31:0] InstrF,
    output logic [31:0] PCF,
    output logic MemWriteM,
    output logic [31:0] ALUResultM, WriteDataM
    );

wire [2:0] ALUControlD;
wire ALUSrcD;
wire BranchD;
wire BranchE;
wire FlushD;
wire FlushE;
wire [1:0] ForwardAE;
wire [1:0] ForwardBE;
wire [1:0] ImmSrcD;
wire JumpD;
wire JumpE;
wire MemWriteD;

wire PCSrcE;
wire PCSrcEHz;
wire [4:0] RdE;
wire [4:0] RdM;
wire [4:0] RdW;
wire RegWriteM;
wire RegWriteW;
wire [1:0] ResultSrcD;
wire ResultSrcE;
wire [4:0] Rs1D;
wire [4:0] Rs1E;
wire [4:0] Rs2D;
wire [4:0] Rs2E;
wire StallD;
wire StallF;
wire ZeroE;
wire [2:0] funct3D;
wire funct7b5D;
wire [6:0] opD;

assign PCSrcE = BranchE & ZeroE | JumpE;

    CU_rv cu_(
        .op(opD),
        .funct3(funct3D),
        .funct7b5(funct7b5D),
        .ResultSrc(ResultSrcD),
        .MemWrite(MemWriteD),
        .Branch(BranchD),
        .ALUSrc(ALUSrcD),
        .RegWrite(RegWriteD),
        .Jump(JumpD),
        .ImmSrc(ImmSrcD),
        .ALUControl(ALUControlD)
    );

    datapath #(
        .BITWIDTH(32)
    ) rv_datapath (
    //Main Signals
        .clk,
        .rst,
        .en,
        //CU SIGNALS INPUT
        .PCSrcE,
        .ALUSrcD,
        .JumpD,
        .RegWriteD,
        .MemWriteD,
        .ImmSrcD,
        .ResultSrcD,
        .ALUControlD,
        .BranchD,
        .InstrF,
        .ReadDataM,        // coming from data memory, outside of datapath 
        //CU SIGNALS OUTPUT
        .JumpE,
        .BranchE,
        .ZeroE,
        .PCF,
        .WriteDataM,
        .ALUResultMout(ALUResultM),
        .funct3D,
        .funct7b5D,
        .opD,
	.MemWriteM,

        //Hazard control signals output
        //Decode stage hazards
        .Rs1DHz(Rs1D),
        .Rs2DHz(Rs2D),
        //Execute stage hazards
        .RdEHz(RdE),
        .Rs2EHz(Rs2E),
        .Rs1EHz(Rs1E),
        .PCSrcEHz(PCSrcEHz),
        .ResultSrcEHz(ResultSrcE),
        //MEM stage hazards
        .RdMHz(RdM),
        .RegWriteMHz(RegWriteM), 
        //WB stage hazards
        .RdWHz(RdW),
        .RegWriteWHz(RegWriteW),
        //Hazard control signals input
        .ForwardAE,
        .ForwardBE,
        .StallD,
        .FlushD,
        .StallF,
        .FlushE
    );

    hazard_u_rv hazard_unit_rv(
        // Decode stage hazards
        .Rs1D,
        .Rs2D,
        // Execute stage hazards
        .RdE, 
        .Rs2E, 
        .Rs1E,
        .PCSrcE(PCSrcEHz), 
        .ResultSrcE,
        // MEM stage hazards
        .RdM,
        .RegWriteM,
        // WB stage hazards
        .RdW,
        .RegWriteW,
        // Hazard control signals output
        .ForwardAE,
        .ForwardBE,
        .StallD,
        .FlushD,
        .StallF,
        .FlushE
    );

endmodule
