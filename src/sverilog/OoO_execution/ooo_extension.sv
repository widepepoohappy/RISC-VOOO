`include  "OoO_packages.pkg"

module ooo_extension #(
    parameter BITWIDTH = 32,
	parameter NRSOURCEREG = 2,
	parameter NRDESTREG = NRSOURCEREG/2,
    parameter NRALUOP = 8,
    parameter RF_DEPTH = 32,
    parameter RS_DEPTH = 8,
	parameter RS_WIDTH_DIM = 2

) (
    input logic [BITWIDTH-1:0] Rsx [NRSOURCEREG-1:0], 				// INFORMATION COMING FROM RF AND INSTRUCTION
	input logic [BITWIDTH-1:0] Rdx [NRDESTREG-1:0],
    input logic [$clog2(NRALUOP)-1:0] ALUControl,
	input logic [BITWIDTH-1:0] ResultW, RdW,
	input logic RegWriteW,
    output rs_entry_t RS_to_ALU [NRALUOP-1:0],
	output logic Entry_readyHz [NRALUOP-1:0]
);
	
	RAT_t RAT_out [NRSOURCEREG-1:0];			//Array of RAT_t data type
    rs_entry_t RS_out [NRALUOP-1:0]; 			//rs_entry already contains 2 values
    rs_entry_t RS_in [NRALUOP-1:0];
    wire Entry_ready;

	//############# START HAZARD SIGNALS #################
	always_comb begin
		for(int i = 0; i < NRALUOP-1; i++) begin
			Entry_readyHz[i] = Entry_ready[i];	// This signal needs to be checked with the operation that the CPU is trying to perform
												// If the needed ALU for the current operation is not available then we stall (or skip this operartion for now?) 
		end
	end
	//############# END HAZARD SIGNALS #################
	
	//############# START DEMUX TO DISPATCH OPERANDS TO CORRECT ALU #################
	RAT_t RS_demux_in [NRSOURCEREG-1:0];
	RAT_t RS_demux_out [NRALUOP-1:0];
	genvar i;
	generate begin
		for(i = 0; i < NRSOURCEREG; i++) begin
			assign RS_demux_in[i] = RAT_out[i];
		end
	endgenerate

	genvar i
	generate begin
		for(i = 0; i < NRSOURCEREG: i++) begin	// If NRSOURCE = 2 (2 rf_reg being sourced at a time) we will have 2 demux with eachone having NRALUOP outputs
												// and each one taking one source reg as input
			demux #(
				.BITWIDTH(1),					// Directing only 1 rs_entry_t to an output
				.T(rs_entry_t),
				.NOUTPUTS(NRALUOP)
			)	RS_demux_i (
				.In(RS_demux_in[i]),
				.Sel(ALUControl),				// This will steer the data to the correct RS_u
				.Out(RS_demux_out[i])
			);
		end
	endgenerate
	//############# STOP DEMUX TO DISPATCH OEPRANDS TO CORRECT ALU #################
 	
	//############# START RESERVE STATION INSTANTIATION ###################
    genvar i;
	genvar j;
    generate begin
		for( i = 0; i < NRALUOP; i++) begin
			for ( j = 0; j < NRSOURCEREG; j++) begin
				assign RS_in[i][j] = RS_demux_out[j]		// Will assign RS[i] inputs to RS_demux
			end
			RS #(					// ASSIGNING A RESERVE STATION TO EACH PROCESSING ELEMENT
				.ID(i),
				.BITWIDTH(BITWIDTH),
				.DEPTH(RS_DEPTH),
				.RF_DEPTH(RF_DEPTH),
				.RS_WIDTH_DIM(RS_WIDTH_DIM)
			) reserve_station_i (
				.In(RS_in[i]),
				.Out(RS_out[i]),
				.Entry_ready,		// IF not ready it means that the RS is full and we have to STALL, 
				.Entry_Idx_slot,	// This value will be fed into TAG_IN and corresponds to row tag of RS
				.clk,
				.en,
				.rst
			);
		end
    endgenerate
	//############# END RESERVE STATION INSTANTIATION ###################

	//############# START REGISTER ALIAS TABLE (RF) INSTANTIATION ###################
	wire [BITWIDTH-1:0] RAT_entry [NRSOURCEREG-1:0];
	genvar i;
	generate begin
		for( i = 0; i < NRSOURCEREG; i++) begin
			assign RAT_entry[i] = Rsx[i];
		end
	endgenerate

    RAT #(
		.BITWIDTH(BITWIDTH),
		.RS_DEPTH(RS_DEPTH),
		.NRWORD(NRSOURCEREG),
		.NRALUOP(NRALUOP)
    ) RF_renaming_u (
		.clk,
		.rst,
		.wr(RegWriteW),
		.wd(RegWriteW),
		.rd(1'b1),
		.rr(1'b1),
		.write_reg(RdW),
		.write_data(ResultW),
		.read_reg(RAT_entry),
		.read_data(RAT_out),
    );
	//############# END REGISTER ALIAS TABLE (RF) INSTANTIATION ###################


endmodule
