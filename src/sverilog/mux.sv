module mux #(
    parameter BITWIDTH = 16,
    parameter NINPUTS = 2
)(
    input wire [BITWIDTH-1:0] In[NINPUTS-1:0],
    output wire [BITWIDTH-1:0] Out,
    input wire [$clog2(NINPUTS)-1:0] Sel
);

    assign Out = In[Sel];

endmodule
