module hazard_u_rv (
    // Decode stage hazards
    input  logic [4:0] Rs1D, Rs2D,
    // Execute stage hazards
    input  logic [4:0] RdE, Rs2E, Rs1E,
    input  logic       PCSrcE, ResultSrcE,
    // MEM stage hazards
    input  logic [4:0] RdM,
    input  logic       RegWriteM,
    // WB stage hazards
    input  logic [4:0] RdW,
    input  logic       RegWriteW,
    // Hazard control signals output
    output logic [1:0] ForwardAE,
    output logic [1:0] ForwardBE,
    output logic       StallD,
    output logic       FlushD,
    output logic       StallF,
    output logic       FlushE
);

    logic lwStall;

    // FORWARDS LOGIC
    always_comb begin
        //SrcA ALU
        if ((Rs1E == RdM) && RegWriteM && (Rs1E != 0)) begin // Forward from Memory stage
            ForwardAE = 2'b10;
        end else if ((Rs1E == RdW) && RegWriteW && (Rs1E != 0)) begin // Forward from Writeback stage
            ForwardAE = 2'b01;
        end else begin
            ForwardAE = 2'b00; // No forwarding (use RF input)
        end

        //SrcB ALU
        if ((Rs2E == RdM) && RegWriteM && (Rs2E != 0)) begin // Forward from Memory stage
            ForwardBE = 2'b10;
        end else if ((Rs2E == RdW) && RegWriteW && (Rs2E != 0)) begin // Forward from Writeback stage
            ForwardBE = 2'b01;
        end else begin
            ForwardBE = 2'b00; // No forwarding (use RF input)
        end
    end

    // STALL LOGIC
    always_comb begin
        lwStall = ResultSrcE && ((Rs1D == RdE) || (Rs2D == RdE));
        StallF  = lwStall;
        StallD  = lwStall;
    end

    // FLUSH LOGIC
    assign FlushD = PCSrcE;
    assign FlushE = lwStall || PCSrcE;

endmodule
