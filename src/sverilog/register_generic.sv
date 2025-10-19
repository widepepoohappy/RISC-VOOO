module register_generic #(
    parameter BITWIDTH = 16,
    parameter NINPUTS = 1    
)(
    input wire [BITWIDTH-1:0] D [NINPUTS-1:0],
    output reg [BITWIDTH-1:0] Q [NINPUTS-1:0], Qn [NINPUTS-1:0],
    input wire clk, en, rst, clr
);

    always_ff @(posedge clk or posedge rst) begin
        if( rst ) begin
            for (int i = 0; i < NINPUTS; i ++) begin
                Q[i] <= '0;
                Qn[i] <= '1;
            end
        end else if( en ) begin
	    if ( clr ) begin
		for (int i = 0; i < NINPUTS; i++) begin
		    Q[i] <= '0;
		    Qn[i] <= '1;
		end
	    end else begin
		for (int i = 0; i < NINPUTS; i++) begin
		    Q[i] <= D[i];
		    Qn[i] <= ~D[i];
		end
	    end
        end
    end
endmodule

