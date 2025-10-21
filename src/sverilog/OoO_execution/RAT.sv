`include "OoO_packages.sv"

// Register File modified to be adapted to OOO execution
module RAT #(
    parameter NRWORD = 2,
    parameter BITWIDTH = 32,
    parameter RF_DEPTH = 32,
    parameter MEMSIZE = 128,     // this indicate the number of kB 128kB = 1,024,000 bits
    parameter MEMSIZE_NORM = MEMSIZE*8,
    parameter MEMLINES = MEMSIZE_NORM/BITWIDTH
    parameter NRALUOP = 8
)(
    input wire wr, wd, rd, rr, clk, rst,
    input wire [BITWIDTH-1:0] write_reg,
    input RAT_t [BITWIDTH-1:0] write_entry,     // equivalent of write_data
    input wire [BITWIDTH-1:0] read_reg [NRWORD-1:0],
    output RAT_t read_data [NRWORD-1:0]
);

    RAT_t RAT_Entry [MEMLINES-1:0];

    //############ START MEMORY COMPONENT ##################
    always_ff @(posedge clk or posedge rst) begin
	if( rst ) begin
	    for (int i = 0; i < MEMLINES; i++) begin
		RAT_Entry[i].Valid <= 0;
		RAT_Entry[i].Tag <= '0;
		RAT_Entry[i].Value <= '0;
	    end
	end else if ( wr & wd ) begin
	    RAT_Entry[Rd].Valid <= write_entry.Valid;
	    RAT_Entry[Rd].Tag <= write_entry.Tag;
	    RAT_Entry[Rd].Value <= write_entry.Value;	
	end
    end
    //############ END MEMORY COMPONENT ##################
    
    //############ START COMBO (OUTPUT) COMPONENT ##################
    // MULTIPLE READS PER CYCLE ARE PERMITTED
    wire bypass [NRWORD-1:0];
    genvar i;
    generate
	for (i = 0; i < NRWORD; i++) begin
	    assign bypass[i] = (read_reg[i] == write_reg);
	    assign read_data[i] = (read_reg[i] != 0) ?
			     	  (bypass[i] ? write_data : RAT_Entry[read_reg[i]]) : 0;
	end
    endgenerate
    //############ END COMBO (OUTPUT) COMPONENT ##################

endmodule
