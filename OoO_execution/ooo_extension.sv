`include  "OoO_packages.pkg"

module ooo_extension #(
    parameter BITWIDTH = 32,
    parameter NRALUOP = 8,
    parameter RF_DEPTH = 32,
    parameter RS_DEPTH = 8
) (
    input logic [BITWIDTH-1:0] Rd, Rs1, Rs2,
    input logic [$clog2(NRALUOP)-1:0] ALUControl,
    output rs_entry_t RS_to_ALU [NRALUOP-1:0]
);

    wire rs_entry_t RS_out [NRALUOP-1:0];
    wire rs_entry_t RS_in [NRALUOP-1:0];
    wire Entry_ready;

    genvar i;
    generate begin
	for( i = 0; i < NRALUOP; i++) begin
	    RS #(				// ASSIGNING A RESERV STATION TO EACH PROCESSING ELEMENT
		.ID(i),
		.BITWIDTH(BITWIDTH),
		.DEPTH(RS_DEPTH),
		.RF_DEPTH(RF_DEPTH)
	    ) reserve_station_i (
		.In(),
		.Out(RS_out[i]),
		.Entry_ready,
		.Entry_Idx_slot,
		.clk,
		.en,
		.rst
	    );
	end
    endgenerate

    RAT #(
	.BITWIDTH(BITWIDTH),
	.RF_DEPTH(RF_DEPTH),
	.RS_DEPTH(RS_DEPTH),
	.NRALUOP(8)
    ) register_renaming_u (
	.en,
	.clk,
	.rst,
	.Rd,
	.Valid_in(Valid_in_RAT),
	.Tag_in(Entry_Idx_slot),			// THIS VALUE WILL CORRESPOND TO A SLOT OF A CERTAIN RS
	.Value_in(RAT_Value)
    );


endmodule
