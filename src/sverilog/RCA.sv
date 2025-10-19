module RCA #(
    parameter BITWIDTH = 16
)(
    input wire [BITWIDTH-1:0] A, B,
    output wire [BITWIDTH-1:0] Sum,
    output wire Cout,
    input wire en,
    input wire op);

wire [BITWIDTH:0] Intermediate_carries;
wire [BITWIDTH-1:0] internal_B;

assign internal_B = B ^ {BITWIDTH{op}}; 
assign Cout = Intermediate_carries[BITWIDTH];

genvar i;
generate
    for (i = 0; i <= BITWIDTH -1; i ++) begin: gen_FA_chain
        if (i == 0)
            // IF op == 1 it's a subtraction
            fulladder FA_i (.en(en),
                            .A(A[i]),
                            .B(internal_B[i]),
                            .Cin(op),
                            .Sout(Sum[i]),
                            .Cout(Intermediate_carries[i+1])
                            );
        else begin
            fulladder FA_i (.en(en),
                            .A(A[i]),
                            .B(internal_B[i]),
                            .Cin(Intermediate_carries[i]),
                            .Sout(Sum[i]),
                            .Cout(Intermediate_carries[i+1])
                            );
        end
    end
endgenerate
endmodule
