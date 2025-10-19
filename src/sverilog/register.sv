module register #(
    parameter BITWIDTH = 16    
)(
    input wire [BITWIDTH-1:0] D,
    output reg [BITWIDTH-1:0] Q, Qn,
    input wire clk, en, rst
);

    always_ff @(posedge clk or posedge rst) begin
        if( rst ) begin
            Q <= '0;
            Qn <= '1;
        end else if( en ) begin
            Q <= D;
            Qn <= ~D;
        end
    end
endmodule
