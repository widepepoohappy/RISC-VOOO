module ALU #(
    parameter BITWIDTH = 32,
    parameter NRALUOP = 8,		//Numbero of possible operations that ALU can perform
    parameter NRALUOPOUT = NRALUOP-1	//2 operations are being performed by RCA
)(
    input wire [BITWIDTH-1:0] A, B,
    output wire [BITWIDTH-1:0] ALUResult,
    output wire Cout, Zero,
    input wire en,
    input wire [2:0] ALUControl);

wire [BITWIDTH:0] Intermediate_carries;
wire [BITWIDTH-1:0] internal_B;
wire [BITWIDTH-1:0] Internal_ALUResult;
wire [BITWIDTH-1:0] A_to_add;
wire [BITWIDTH-1:0] A_to_sub;
wire [BITWIDTH-1:0] A_to_add_sub;
wire [BITWIDTH-1:0] A_to_xor;
wire [BITWIDTH-1:0] A_to_or;
wire [BITWIDTH-1:0] A_to_and;
wire [BITWIDTH-1:0] A_to_slt;
wire [BITWIDTH-1:0] A_to_sra;
wire [BITWIDTH-1:0] A_to_srl;
wire [BITWIDTH-1:0] B_to_add;
wire [BITWIDTH-1:0] B_to_sub;
wire [BITWIDTH-1:0] B_to_add_sub;
wire [BITWIDTH-1:0] B_to_xor;
wire [BITWIDTH-1:0] B_to_or;
wire [BITWIDTH-1:0] B_to_and;
wire [BITWIDTH-1:0] B_to_slt;
wire [BITWIDTH-1:0] B_to_sra;
wire [BITWIDTH-1:0] B_to_srl;
wire [BITWIDTH-1:0] RCAResult;
wire [BITWIDTH-1:0] XORResult;
wire [BITWIDTH-1:0] ORResult;
wire [BITWIDTH-1:0] ANDResult;
wire [BITWIDTH-1:0] SLTResult;
wire [BITWIDTH-1:0] SRAResult;
wire [BITWIDTH-1:0] SRLResult;
wire op = ALUControl[0];

//INPUT DEMUX STAGE
////INPUT DEMUX_A STAGE 
wire [BITWIDTH-1:0] out_demux_A [NRALUOP-1:0]; // NRALUOP is number of output from ALUs
demux #(
    .NOUTPUTS(NRALUOP),
    .BITWIDTH(BITWIDTH)
) demux_A (
        .In(A),
        .Out(out_demux_A),
        .Sel(ALUControl)
);

// MUXES TO MERGE SUB AND ADD TO SINGLE RCA
wire [BITWIDTH-1:0] in_muxRCA_A [2-1:0];	//working only to merge add and sub to RCA
assign in_muxRCA_A[0] = out_demux_A[0];
assign in_muxRCA_A[1] = out_demux_A[1];
mux #(
    .NINPUTS(2),
    .BITWIDTH(BITWIDTH)
) mux_RCA_A (
    .In(in_muxRCA_A),
    .Sel(op),
    .Out(A_to_add_sub)
);

assign A_to_xor = out_demux_A[7];
assign A_to_or = out_demux_A[3];
assign A_to_and = out_demux_A[2];
assign A_to_slt = out_demux_A[5];
assign A_to_srl = out_demux_A[6];
assign A_to_sra = out_demux_A[4];
//END DEMUX_A STAGE

//INPUT DEMUX_B STBGE 
wire [BITWIDTH-1:0] out_demux_B [NRALUOP-1:0]; // NRALUOP is number of output from ALUs
demux #(
    .NOUTPUTS(NRALUOP),
    .BITWIDTH(BITWIDTH)
) demux_B (
        .In(B),
        .Out(out_demux_B),
        .Sel(ALUControl)
);

wire [BITWIDTH-1:0] in_muxRCB_B [2-1:0];	//working only to merge add and sub to RCB
assign in_muxRCB_B[0] = out_demux_B[0];
assign in_muxRCB_B[1] = out_demux_B[1];
mux #(
    .NINPUTS(2),
    .BITWIDTH(BITWIDTH)
) mux_RCB_B (
    .In(in_muxRCB_B),
    .Sel(op),
    .Out(B_to_add_sub)
);

assign B_to_xor = out_demux_B[7];
assign B_to_or = out_demux_B[3];
assign B_to_and = out_demux_B[2];
assign B_to_slt = out_demux_B[5];
assign B_to_srl = out_demux_B[6];
assign B_to_sra = out_demux_B[4];
//END DEMUX_B STBGE
//END DEMUX STAGE


//START COMPUTATIONAL STAGES
//START RCA STAGE
assign internal_B = B_to_add_sub ^ {BITWIDTH{op}};	//this could be optimized by not making it switch when it is not used 

assign Cout = Intermediate_carries[BITWIDTH];

genvar i;
generate
    for (i = 0; i <= BITWIDTH -1; i ++) begin: gen_FA_chain
        if (i == 0)
            // IF op == 1 it's a subtraction
            fulladder FA_i (.en(en),
                            .A(A_to_add_sub[i]),
                            .B(internal_B[i]),
                            .Cin(op),
                            .Sout(RCAResult[i]),
                            .Cout(Intermediate_carries[i+1])
                            );
        else begin
            fulladder FA_i (.en(en),
                            .A(A_to_add_sub[i]),
                            .B(internal_B[i]),
                            .Cin(Intermediate_carries[i]),
                            .Sout(RCAResult[i]),
                            .Cout(Intermediate_carries[i+1])
                            );
        end
    end
endgenerate
//END RCA STAGE

//START XOR STAGE
assign XORResult = A_to_xor ^ B_to_xor;
//END XOR STAGE

//START OR STAGE
assign ORResult = A_to_or | B_to_or;
//END OR STAGE

//START AND STAGE
assign ANDResult = A_to_and & B_to_and;
//END AND STAGE

//START SLT STAGE
assign SLTResult = A_to_slt < B_to_slt;
//END SLT STAGE

//START SRL STAGE
assign SRLResult = A_to_srl > B_to_slt; 
//END SRL STAGE

//START SRA STAGE
assign SRAResult = A_to_sra >>> B_to_sra; // this is a signed shift
//END SRA STAGE
//END COMPUTATIONAL STAGES

//START OUTPUT MUX STAGE
wire [BITWIDTH-1:0] In_mux_ALUResult [NRALUOP-1:0];
assign In_mux_ALUResult[0] = RCAResult;	    //ALUControl 000 for add, but both of these op are performed by RCA
assign In_mux_ALUResult[1] = RCAResult;	    //ALUControl 001 for sub, but both of these op are performed by RCA
assign In_mux_ALUResult[3] = ORResult;
assign In_mux_ALUResult[2] = ANDResult;
assign In_mux_ALUResult[5] = SLTResult;
assign In_mux_ALUResult[4] = SRAResult;
assign In_mux_ALUResult[6] = SRLResult;
assign In_mux_ALUResult[7] = XORResult;

mux #(
    .BITWIDTH(BITWIDTH),
    .NINPUTS(NRALUOP)
) mux_ALUResult (
    .In(In_mux_ALUResult),
    .Out(ALUResult),
    .Sel(ALUControl)
);
//END OUTPUT MUX STAGE

//ZERO SIGNAL
assign Zero = ~|ALUResult;




endmodule
