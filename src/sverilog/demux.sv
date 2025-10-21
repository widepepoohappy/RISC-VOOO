module demux #(
    parameter BITWIDTH = 16,
    parameter T = logic,
    parameter NOUTPUTS = 2
)(
    input T [BITWIDTH-1:0] In,
    input wire [$clog2(NOUTPUTS)-1:0] Sel,
    output T [BITWIDTH-1:0] Out [NOUTPUTS-1:0]
);

    always_comb begin
        for( int i = 0; i < NOUTPUTS; i ++ ) begin
    	    Out[i] = (i == Sel) ? In : '0;
        end
    end

endmodule

