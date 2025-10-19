module fulladder #(
    parameter BITWIDTH = 16
)(
    input wire en,A,B,Cin,
    output Sout,Cout);

assign Sout = A ^ B ^ Cin;
assign Cout = (A & B) | (A ^ B) & Cin;

endmodule
