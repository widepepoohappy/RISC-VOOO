module exec_stage #(
    parameter BITWIDTH = 32,
    parameter NRALUOP = 8,
    parameter ENABLE_OOO = 1
    parameter NRSOURCEREG = 2,
	parameter NRDESTREG = NRSOURCEREG/2,
    parameter RF_DEPTH = 32,
    parameter RS_DEPTH = 8,
	parameter RS_WIDTH_DIM = 2
) (

    input logic [BITWIDTH-1:0] Rsx [NRSOURCEREG-:0], 				// INFORMATION COMING FROM RF AND INSTRUCTION
	input logic [BITWIDTH-1:0] Rdx [NRDESTREG-1:0],
    input logic [$clog2(NRALUOP)-1:0] ALUControl,
	input logic [BITWIDTH-1:0] ResultW, RdW,
	input logic RegWriteW,
	output logic Entry_readyHz [NRALUOP-1:0]
);


    rs_entry_t RS_to_ALU [NRALUOP-1:0],
    ooo_extension #(
        .BITWIDTH(BITWIDTH),
        .NRSOURCEREG(NRSOURCEREG),
        .NRDESTREG(NRDESTREG),
        .NRALUOP(NRALUOP),
        .RF_DEPTH(RF_DEPTH),
        .RS_DEPTH(RS_DEPTH),
        .RS_WIDTH_DIM(RS_WIDTH_DIM),
    ) ooo_issue_u (
        .Rsx,
        .Rdx,
        .ALUControl,
        .ResultW,
        .RdW,
        .RegWriteW,
        .RS_to_ALU,
        .Entry_readHz
    );

    //HERE WE CAN INSTANTIATE A MODULAR ALU, BASED ON A CERTAIN ID WE CAN MAKE IT PERFORM
    //A CERTAIN OPERATION
    wire [BITWIDTH-1:0] ALUResult [NRALUOP-1:0];
    wire Cout_do_not_connect [NRALUOP-1:0];
    wire Zero [NRALUOP-1:0];
    wire [2:0] ALUControl_do_not_connect;
    genvar i;
    generate begin
        for(i = 0; i < NRALUOP; i++) begin
            //BASED ON THE ID (i) THE ALU PROCESSING ELEMENT WILL PERFORM A CERTAIN OPERATION
            //THIS HAS TO AGREE WITH THE ALUCONTROL SIGNAL THAT DETERMINES WHAT OPERATION NEEDS TO BE DONE
            //I DID THIS INTERNALLY TO THE ALU
            ALU #(
                .BITWIDTH(BITWIDTH),
                .NRALUOP(1)
                .SINGLE_UNIT(1'b1),
                .OP_TYPE(i)
            ) ALU_u (
                .A(RS_to_ALU[i].RAT_Entry[0]),
                .B(RS_to_ALU[i].RAT_Entry[1]),
                .ALUResult(ALUResult[i]),
                .Cout(Cout_do_not_connect[i]),
                .Zero(Zero[i]),
                .en,
                .ALUControl(ALUControl_do_not_connect)
            );
        end
    endgenerate




endmodule