module priority_encoder #(
    parameter N = 64, // Numero di bit, deve essere potenza di 2
    parameter OUT_W = $clog2(N)
) (
    input  logic [N-1:0] in,
    output logic [OUT_W-1:0] out,
    output logic            valid
);

    // Caso base: encoder a 2 bit
    generate
        if (N == 2) begin
            always_comb begin
                valid = |in;
                if (in[1])
                    out = 1;
                else
                    out = 0;
            end
        end else begin
            // Divide l'input in due metà
            localparam HALF = N/2;
            logic [OUT_W-2:0] out_low, out_high;
            logic valid_low, valid_high;

            priority_encoder #(.N(HALF), .OUT_W(OUT_W-1)) enc_low  (
                .in(in[HALF-1:0]),
                .out(out_low),
                .valid(valid_low)
            );
            priority_encoder #(.N(HALF), .OUT_W(OUT_W-1)) enc_high (
                .in(in[N-1:HALF]),
                .out(out_high),
                .valid(valid_high)
            );

            always_comb begin
                valid = valid_high | valid_low;
                if (valid_high)
                    out = {1'b1, out_high};
                else
                    out = {1'b0, out_low};
            end
        end
    endgenerate

endmodule
