module ROB #(
    parameter BITWIDTH = 32,
    parameter ENTRIES = 64
)(
    input logic [BITWIDTH-1:0] DestRegID, DestRegVal, StoreAddr, StoreData, PC,
    input logic VALID, ControlBits, EXCEPTION
);

    typedef struct packed {
	logic VALID;
	logic [BITWIDTH-1:0] DestRegID;
	logic [BITWIDTH-1:0] DestRegVal;
	logic [BITWIDTH-1:0] PC;
	logic ControlBits;
	logic [BITWIDTH-1:0] StoreAddr;
	logic [BITWIDTH-1:0] StoreData;
	logic EXCEPTION;
    }	entry_t;

    entry_t entries [ENTRIES-1:0];



endmodule
