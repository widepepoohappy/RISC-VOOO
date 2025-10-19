module registers_rv #(
    parameter NRWORD = 2,
    parameter BITWIDTH = 32,
    parameter MEMSIZE = 128,     // this indicate the number of kB 128kB = 1,024,000 bits
    parameter MEMSIZE_NORM = MEMSIZE*8,
    parameter MEMLINES = MEMSIZE_NORM/BITWIDTH
)(
    input wire wr, wd, rd, rr, clk, rst,
    input wire [BITWIDTH-1:0] write_reg,
    input wire [BITWIDTH-1:0] write_data,
    input wire [BITWIDTH-1:0] read_reg [NRWORD-1:0],
    output reg [BITWIDTH-1:0] read_data [NRWORD-1:0]
);

    reg [BITWIDTH-1:0] mem_registers [MEMLINES-1:0];

// ONLY ONE WRITING PER CYCLE IS PERMITTED
    always_ff @(posedge clk or posedge rst) begin : write_env
        if ( rst ) begin
            for( int i = 0; i < MEMLINES; i ++ ) begin
                mem_registers[i] <= 0;
            end 
        end else if ( wr & wd ) begin
            mem_registers[write_reg] <= write_data;
        end 
    end
// CE BISOGNO DI IMPLEMENTARE IL READ-WRITE-BYPASS (SCRITTURA DURANTE LA LETTURA) ALTRIMENTI CI SONO CASI DOVE NON FUNZIONE

// MULTIPLE READS PER CYCLE ARE PERMITTED
    wire bypass [NRWORD-1:0];
    genvar i;
    generate
	for (i = 0; i < NRWORD; i++) begin
	    assign bypass[i] = (read_reg[i] == write_reg);
	    assign read_data[i] = (read_reg[i] != 0) ? 
			     	  (bypass[i] ? write_data : mem_registers[read_reg[i]]) : 0;
	end
    endgenerate
    
endmodule

