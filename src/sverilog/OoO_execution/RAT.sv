module RAT #(
    parameter BITWIDTH = 32,
    parameter RF_DEPTH = 32,
    parameter RS_DEPTH = 32,
    parameter NRALUOP = 8
)(
    input logic en, clk, rst,
    input logic [BITWIDTH-1:0] Rd,
    input logic Valid_in, 
    input logic [$clog2(RS_DEPTH)-1:0] Tag_in,
    inout logic [BITWIDTH-1:0] Value_in,
);

    typedef struct packed {
	logic Valid;
	logic [$clog2(RS_DEPTH)-1:0] Tag;	
	logic [BITWIDTH-1:0] Value;
    } RAT_t;

    RAT_t RAT_Entry [RF_DEPTH-1:0];

    always_ff @(posedge clk or posedge rst) begin
	if( rst ) begin
	    for (int i = 0; i < RF_DEPTH; i++) begin
		RAT_Entry[i].Valid <= 0;
		RAT_Entry[i].Tag <= '0;
		RAT_Entry[i].Value <= '0;
	    end
	end else if ( en ) begin
	    RAT_Entry[Rd].Valid <= Valid_in;
	    RAT_Entry[Rd].Tag <= Tag_in;	
	    RAT_Entry[Rd].Value <= Value_in;	
	end
    end
    

endmodule
