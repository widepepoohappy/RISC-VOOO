`include  "OoO_packages.pkg"

module RS #(
    parameter BITWIDTH = 32,
    parameter DEPTH = 8,	    //Possible operation waiting for the PE
    parameter ID = 1,		    //This will be needed to identify and making this RS unique
    parameter RF_DEPTH = 32	    //RF #n lines
)(
    input rs_entry_t In,
    output rs_entry_t Out,
    output logic Entry_ready,
    output [$clog2(DEPTH)-1:0] Entry_Idx_slot,
    input clk, rst, en
);

// MEMORY ELEMENT
    rs_entry_t RS_entry [DEPTH-1:0];
    always_comb begin
	for (int i = 0; i < DEPTH; i++) begin
	    RS_entry[i].RS_ENTRY_ID = (ID << BITWIDTH/2) + i;	// Questa sintassi è sintetizzabile solo se usata come ROM
	end
    end
// ASSIGN PROCEDURE
    alwasy_ff @(posedge clk | posedge rst) begin
	if ( rst ) begin
	    for( int i = 0; i < DEPTH; i++) begin
		RS_entry[i] <= '0;
	    end
	end else if ( en && Entry_Idx_valid) begin
	    RS_entry[Idx_RS_slot] <= In;
	    RS_entry[Idx_RS_slot].Entry_free <= 0;		// MARK THAT THE ENTRY SLOT IS NOT FREE ANYMORE
	end
    end
    
// ########################################### START INPUT PORTION ########################################### //
//PE FOR ENTRY ASSIGNMENT
    wire [DEPTH-1:0] PE_entry_assignment_in;
    wire [$clog2(DEPTH)-1:0] Idx_RS_slot;
    wire Entry_Idx_valid;					// THIS SIGNALS INDICATE IF THERE IS AT LEAST ONE ENTRY SLOT FREE
    assign Entry_ready = Entry_Idx_valid;

    always_comb begin
	for(int i = 0; i < DEPTH; i ++) begin
	    PE_entry_assignment_in[i] = RS_entry[i].Entry_free;
	end
    end
    priority_encoder #(						// NEEDED TO RESOLVE CONFLICT ON WHERE TO PLACE THE DATA
	.N(DEPTH),
    ) PE_entry_assignment (
	.in(PE_entry_assignment_in),
	.out(Idx_RS_slot),
	.valid(Entry_Idx_valid)    
    );
// ############################################# END OUTPUT PORTION ########################################## //


// ########################################## START OUTPUT PORTION ########################################### //
//PE FOR ALU DATA DELIVERY
    wire [DEPTH-1:0] PE_ALU_dispatch_in;
    wire [$clog2(DEPTH)-1:0] Idx_RS_dispatch;
    wire Dispatch_Idx_valid;					// SIGNAL USED TO NOTE IF THERE IS A VALID ENTRY SLOT
    logic entry_ready;						
    always_comb begin
	for(int i = 0; i < DEPTH; i ++) begin
	    entry_ready = RS_dispatch[i].VALID_A & RS_dispatch[i].VALID_B;  //IF BOTH OF THE INPUTS ARE VALID, THE OPERATION IS READY TO BE PERFORMED
	    PE_ALU_dispatch_in[i] = entry_ready;			    // MARK WHICH ENTRY SLOT IS READY
	end
    end
    priority_encoder #(						// NEEDED TO RESOLVE MULTIPLE READY CONFLICT
	.N(DEPTH),
    ) PE_ALU_dispatch (
	.in(PE_ALU_dispatch_in),
	.out(Idx_RS_dispatch),
	.valid(Dispatch_Idx_valid)
    );

//ALU DISPATCH ASSIGNMENT
    always_ff @(posedge clk) begin
	if( Dispatch_Idx_valid && en ) begin
	    Out <= RS_entry[Idx_RS_dispatch];
	    RS_entry[Idx_RS_dispatch] <= 1;			// ONCE USED THE ENTRY SLOT CAN BE REASSIGNED
	end 
    end
// ########################################### END OUTPUT PORTION ########################################### //

endmodule
