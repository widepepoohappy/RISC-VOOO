module datapath #(
	parameter BITWIDTH = 32,
	parameter NINPUTS_MEMPIPE = 6,
	parameter NINPUTS_FETCHPIPE = 6,
	parameter NINPUTS_EXECUTEPIPE = 7,
	parameter NINPUTS_DECODEPIPE = 15,
	parameter NRWORD = 2

)(
	//Main Signals
	input logic clk, rst, en,
	//CU SIGNALS INPUT
	input logic PCSrcE, ALUSrcD, JumpD,
	input logic RegWriteD, MemWriteD, BranchD,
	input logic [1:0] ImmSrcD, ResultSrcD,
	input logic [2:0] ALUControlD,
	input logic [BITWIDTH-1:0] InstrF,
	input logic [BITWIDTH-1:0] ReadDataM,		// coming from data memory, outside of datapath 
	//CU SIGNALS OUTPUT
	output logic ZeroE,
	output logic JumpE,
	output logic BranchE,
	output logic [BITWIDTH-1:0] PCF,
	output logic [BITWIDTH-1:0] WriteDataM, ALUResultMout,
	output logic [2:0] funct3D,
	output logic funct7b5D,
	output logic [6:0] opD,
	output logic MemWriteM,

	//Hazard control signals output
	//Decode stage hazards
	output logic [4:0] Rs1DHz, 
	output logic [4:0] Rs2DHz,
	//Execute stage hazards
	output logic [4:0] RdEHz,
	output logic [4:0] Rs2EHz,
	output logic [4:0] Rs1EHz,
	output logic ResultSrcEHz, PCSrcEHz,
	//MEM stage hazards
	output logic [4:0] RdMHz,
	output logic RegWriteMHz, 
	//WB stage hazards
	output logic [4:0] RdWHz,
	output logic RegWriteWHz,
	//Hazard control signals input
	input logic [1:0] ForwardAE, ForwardBE,
	input logic StallD, FlushD, StallF, FlushE

);
	
	///######################///
	/// START DATAPATH STAGE ///
	///######################///
	///###################///
	/// START FETCH STAGE ///
	///###################///
	wire [BITWIDTH-1:0] PCPlus4F;    
	wire [BITWIDTH-1:0] Qn_not_connected_pcreg;
	wire [BITWIDTH-1:0] PCTargetE;    
	wire [BITWIDTH-1:0] pcmux_in [2-1:0];
	wire [BITWIDTH-1:0] PCNext;
	wire [BITWIDTH-1:0] PCFint;
	assign PCF = PCFint;
	assign pcmux_in[0] = PCPlus4F;
	assign pcmux_in[1] = PCTargetE;	 //coming from execute stage
	mux #(
		.BITWIDTH(BITWIDTH),
		.NINPUTS(2)
		) pcmux (
			.In(pcmux_in),
			.Sel(PCSrcE),		   //coming from execute stage
			.Out(PCNext)
		);
 
	register #(
				.BITWIDTH(32)
	)   pcreg   (
				.clk(clk),
				.rst(rst), 
				.en(en & ~StallF),
				.D(PCNext),
				.Q(PCFint),
				.Qn(Qn_not_connected_pcreg)
	);

	RCA #(
		.BITWIDTH(32)
	) pcadd4 (
			.A(PCFint),
			.B(32'd4),
			.Sum(PCPlus4F),
			.en(en),
			.op(1'b0),
			.Cout(Cout_do_not_connect_fetch)
			);

	///#######################///
	///   FETCH PIPE STAGE	///
	///#######################///
	logic [BITWIDTH-1:0] fetch_pipe_inputs [NINPUTS_FETCHPIPE-1:0];
	logic [BITWIDTH-1:0] fetch_pipe_outputs [NINPUTS_FETCHPIPE-1:0];
	logic [BITWIDTH-1:0] Qn_do_not_connect_fetch_pipe [NINPUTS_FETCHPIPE-1:0];
	assign fetch_pipe_inputs[0] = InstrF;
	assign fetch_pipe_inputs[1] = PCFint;
	assign fetch_pipe_inputs[2] = PCPlus4F;
	register_generic #(
		.BITWIDTH(BITWIDTH),
		.NINPUTS(NINPUTS_FETCHPIPE)
	) fetch_pipe (
		.D(fetch_pipe_inputs),
		.Q(fetch_pipe_outputs),
		.Qn(Qn_do_not_connect_fetch_pipe),
		.clk,
		.en(en & ~StallD),
		.clr(FlushD),
		.rst
	);

	///#################///
	/// END FETCH STAGE ///
	///#################///

	///####################///
	/// START DECODE STAGE ///
	///####################///
	wire RegWriteW;
	wire [BITWIDTH-1:0] ResultW;
	wire [BITWIDTH-1:0] RdW;
	logic [BITWIDTH-1:0] ImmExtD;
	wire [BITWIDTH-1:0] InstrD = fetch_pipe_outputs[0];
	wire [BITWIDTH-1:0] PCD = fetch_pipe_outputs[1]; //== PC
	wire [BITWIDTH-1:0] PCPlus4D = fetch_pipe_outputs[2];
	wire [BITWIDTH-1:0] Rs1D = InstrD[19:15];
	wire [BITWIDTH-1:0] Rs2D = InstrD[24:20];
	wire [BITWIDTH-1:0] RdD = InstrD[11:7];
	assign opD = InstrD[6:0];
	assign funct3D = InstrD[14:12];
	assign funct7b5D = InstrD[30];

	// register file logic
	wire [BITWIDTH-1:0] rf_in [NRWORD-1:0];
	logic [BITWIDTH-1:0] rf_out [NRWORD-1:0];
	assign rf_in[0] = InstrD[19:15];
	assign rf_in[1] = InstrD[24:20];
	
	registers_rv #(
		.BITWIDTH(BITWIDTH),
		.NRWORD(NRWORD),
		.MEMSIZE(128)		   // This is 128 *Byte*, corresponds to 32 regs of 32 bits = 32*32 = 1024/8 = 128
	) rf (
		.clk(clk),
		.rst(rst),
		.wr(RegWriteW),
		.wd(RegWriteW),
		.rr(1'b1),
		.rd(1'b1),
		.read_reg(rf_in),	   // corresponds to A1/A2
		.read_data(rf_out),	 // corresponds to output form RF
		.write_reg(RdW),		
		.write_data(ResultW)
	);

	extend ext(InstrD[BITWIDTH-1:7], ImmSrcD, ImmExtD);

	///########################///
	///   DECODE PIPE STAGE	///
	///########################///
	logic [BITWIDTH-1:0] decode_pipe_inputs [NINPUTS_DECODEPIPE-1:0];
	logic [BITWIDTH-1:0] decode_pipe_outputs [NINPUTS_DECODEPIPE-1:0];
	logic [BITWIDTH-1:0] Qn_do_not_connect_decode [NINPUTS_DECODEPIPE-1:0];
	wire [BITWIDTH-1:0] read_data1 = rf_out[0]; 
	wire [BITWIDTH-1:0] read_data2 = rf_out[1]; 
	assign decode_pipe_inputs[0] = read_data1;
	assign decode_pipe_inputs[1] = read_data2;
	assign decode_pipe_inputs[2] = PCD;
	assign decode_pipe_inputs[3] = Rs1D;
	assign decode_pipe_inputs[4] = Rs2D;
	assign decode_pipe_inputs[5] = RdD;
	assign decode_pipe_inputs[6] = ImmExtD;
	assign decode_pipe_inputs[7] = PCPlus4D;
	assign decode_pipe_inputs[8] = RegWriteD;
	assign decode_pipe_inputs[9] = ResultSrcD;
	assign decode_pipe_inputs[10] = MemWriteD;
	assign decode_pipe_inputs[11] = JumpD;
	assign decode_pipe_inputs[12] = BranchD;
	assign decode_pipe_inputs[13] = ALUControlD;
	assign decode_pipe_inputs[14] = ALUSrcD;

	register_generic #(
		.BITWIDTH(BITWIDTH),
		.NINPUTS(NINPUTS_DECODEPIPE)
	) decode_pipe (
		.D(decode_pipe_inputs),
		.Q(decode_pipe_outputs),
		.Qn(Qn_do_not_connect_decode),
		.clk,
		.en,
		.clr(FlushE),
		.rst
	);

	///##################///
	/// END DECODE STAGE ///
	///##################///


	///#####################///
	/// START EXECUTE STAGE ///
	///#####################///
	//CU SIGNALS
	wire [BITWIDTH-1:0] RegWriteE = decode_pipe_outputs[8];
	wire [BITWIDTH-1:0] ResultSrcE = decode_pipe_outputs[9];
	wire [BITWIDTH-1:0] MemWriteE = decode_pipe_outputs[10];
	assign JumpE = decode_pipe_outputs[11][0];
	assign BranchE = decode_pipe_outputs[12][0];
	wire [2:0] ALUControlE = decode_pipe_outputs[13][2:0];
	wire ALUSrcE = decode_pipe_outputs[14][0];
	//DP SIGNALS
	wire [BITWIDTH-1:0] ALUResultM;
	wire [BITWIDTH-1:0] RD1E = decode_pipe_outputs[0];
	wire [BITWIDTH-1:0] RD2E = decode_pipe_outputs[1];
	wire [BITWIDTH-1:0] PCE = decode_pipe_outputs[2];
	wire [BITWIDTH-1:0] Rs1E = decode_pipe_outputs[3];
	wire [BITWIDTH-1:0] Rs2E = decode_pipe_outputs[4];
	wire [BITWIDTH-1:0] RdE = decode_pipe_outputs[5];
	wire [BITWIDTH-1:0] ImmExtE = decode_pipe_outputs[6];
	wire [BITWIDTH-1:0] PCPlus4E = decode_pipe_outputs[7];

	wire [BITWIDTH-1:0] ALUmuxFWA_in [3-1:0];
	wire [BITWIDTH-1:0] SrcAE;
	assign ALUmuxFWA_in[0] = RD1E;
	assign ALUmuxFWA_in[1] = ResultW;
	assign ALUmuxFWA_in[2] = ALUResultM;
	mux #(
		.BITWIDTH(BITWIDTH),
		.NINPUTS(3)
		) ALUmuxFWA (
			.In(ALUmuxFWA_in),
			.Sel(ForwardAE),
			.Out(SrcAE)
		);
	wire [BITWIDTH-1:0] ALUmuxFWB_in [3-1:0];
	wire [BITWIDTH-1:0] WriteDataE;
	assign ALUmuxFWB_in[0] = RD2E;
	assign ALUmuxFWB_in[1] = ResultW;
	assign ALUmuxFWB_in[2] = ALUResultM;
	mux #(
		.BITWIDTH(BITWIDTH),
		.NINPUTS(3)
		) ALUmuxFWB (
			.In(ALUmuxFWB_in),
			.Sel(ForwardBE),
			.Out(WriteDataE)
		);
	wire [BITWIDTH-1:0] SrcBmux_in [2-1:0];
	wire [BITWIDTH-1:0] SrcBE;
	assign SrcBmux_in[0] = WriteDataE;
	assign SrcBmux_in[1] = ImmExtE;
	mux #(
		.BITWIDTH(BITWIDTH),
		.NINPUTS(2)
		) SrcBmux (
			.In(SrcBmux_in),
			.Sel(ALUSrcE),
			.Out(SrcBE)
		);

	RCA #(
		.BITWIDTH(BITWIDTH)
	) pcaddbranch (
			.A(PCE),
			.B(ImmExtE),
			.Sum(PCTargetE),
			.en,
			.op(1'b0),
			.Cout(Cout_do_not_connect_addbranch)
	);

	logic [BITWIDTH-1:0] ALUResultE;
	ALU #(
		.BITWIDTH(BITWIDTH)
	) ALUu_E (
			.A(SrcAE), 
			.B(SrcBE), 
			.ALUControl(ALUControlE),
			.ALUResult(ALUResultE),
			.Zero(ZeroE),
			.en(en),
			.Cout(Cout_do_not_connect_ALUu)
	);

	///#########################///
	///   EXECUTE PIPE STAGE	///
	///#########################///
	logic [BITWIDTH-1:0] execute_pipe_inputs [NINPUTS_EXECUTEPIPE-1:0];
	logic [BITWIDTH-1:0] execute_pipe_outputs [NINPUTS_EXECUTEPIPE-1:0];
	logic [BITWIDTH-1:0] Qn_do_not_connect_execute_pipe [NINPUTS_EXECUTEPIPE-1:0];
	assign execute_pipe_inputs[0] = ALUResultE;
	assign execute_pipe_inputs[1] = WriteDataE;
	assign execute_pipe_inputs[2] = RdE;
	assign execute_pipe_inputs[3] = PCPlus4E;
	assign execute_pipe_inputs[4] = RegWriteE;
	assign execute_pipe_inputs[5] = ResultSrcE;
	assign execute_pipe_inputs[6] = MemWriteE;

	wire clr_execute_pipe_reg_do_not_use;
	register_generic #(
		.BITWIDTH(BITWIDTH),
		.NINPUTS(NINPUTS_EXECUTEPIPE)
	) execute_pipe (
		.D(execute_pipe_inputs),
		.Q(execute_pipe_outputs),
		.Qn(Qn_do_not_connect_execute_pipe),
		.clk,
		.en,
		.clr(clr_execute_pipe_reg_do_not_use),
		.rst
	);

	///###################///
	/// END EXECUTE STAGE ///
	///###################///


	///#################///
	/// START MEM STAGE ///
	///#################///
	//CU SIGNALS
	wire [BITWIDTH-1:0] RegWriteM = execute_pipe_outputs[4];
	wire [BITWIDTH-1:0] ResultSrcM = execute_pipe_outputs[5];
	assign MemWriteM = execute_pipe_outputs[6];
	//DP SIGNALS
	assign ALUResultM = execute_pipe_outputs[0];
	assign WriteDataM = execute_pipe_outputs[1];
	wire [BITWIDTH-1:0] RdM = execute_pipe_outputs[2];
	wire [BITWIDTH-1:0] PCPlus4M = execute_pipe_outputs[3];

	///#####################///
	///   MEM PIPE STAGE	///
	///#####################///
	logic [BITWIDTH-1:0] mem_pipe_inputs [NINPUTS_MEMPIPE-1:0];
	logic [BITWIDTH-1:0] mem_pipe_outputs [NINPUTS_MEMPIPE-1:0];
	logic [BITWIDTH-1:0] Qn_do_not_connect_mem_pipe [NINPUTS_MEMPIPE-1:0];
	assign ALUResultMout = ALUResultM;
	assign mem_pipe_inputs[0] = ALUResultM;
	assign mem_pipe_inputs[1] = ReadDataM;
	assign mem_pipe_inputs[2] = RdM;
	assign mem_pipe_inputs[3] = PCPlus4M;
	assign mem_pipe_inputs[4] = RegWriteM;
	assign mem_pipe_inputs[5] = ResultSrcM;

	wire clr_mem_pipe_reg_do_not_use;
	register_generic #(
		.BITWIDTH(BITWIDTH),
		.NINPUTS(NINPUTS_MEMPIPE)
	) mem_pipe (
		.D(mem_pipe_inputs),
		.Q(mem_pipe_outputs),
		.Qn(Qn_do_not_connect_mem_pipe),
		.clk,
		.en,
		.clr(clr_mem_pipe_reg_do_not_use),
		.rst
	);

	///########################///
	/// START WRITE BACK STAGE ///
	///########################///
	//CU SIGNALS
	assign RegWriteW = mem_pipe_outputs[4];
	wire [1:0] ResultSrcW = mem_pipe_outputs[5][1:0];

	//DP SIGNALS
	wire [BITWIDTH-1:0] ALUResultW = mem_pipe_outputs[0] ;
	wire [BITWIDTH-1:0] ReadDataW = mem_pipe_outputs[1] ;
	assign RdW = mem_pipe_outputs[2] ;
	wire [BITWIDTH-1:0] PCPlus4W = mem_pipe_outputs[3] ;


	wire [BITWIDTH-1:0] resultmux_in [3-1:0];
	assign resultmux_in[0] = ALUResultW;
	assign resultmux_in[1] = ReadDataW;
	assign resultmux_in[2] = PCPlus4W;
	mux #(
		.BITWIDTH(BITWIDTH),
		.NINPUTS(3)
	) resultmux (
		.In(resultmux_in),
		.Sel(ResultSrcW),
		.Out(ResultW)
	);
	///######################///
	/// END WRITE BACK STAGE ///
	///######################///
	///####################///
	/// END DATAPATH STAGE ///
	///####################///

	///################################///
	/// START HAZARD SIGNAL ASSIGNMENT ///
	///################################///
	//Decode stage hazards
	assign Rs1DHz = Rs1D;
	assign Rs2DHz = Rs2D;
	//Execute stage hazards
	assign RdEHz = RdE;
	assign Rs2EHz = Rs2E;
	assign Rs1EHz = Rs1E;
	assign PCSrcEHz = PCSrcE;
	assign ResultSrcEHz = ResultSrcE[0];
	//Mem stage hazards
	assign RdMHz = RdM;
	assign RegWriteMHz = RegWriteM; 
	//WB stage hazards
	assign RdWHz = RdW;
	assign RegWriteWHz = RegWriteW; 
	///##############################///
	/// END HAZARD SIGNAL ASSIGNMENT ///
	///##############################///  


endmodule
