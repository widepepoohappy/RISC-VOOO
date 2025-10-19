module testbench;
    logic	 clk;
    logic	 en;
    logic	 reset;
    logic [31:0] WriteData, DataAdr;
    logic	 MemWrite;
// instantiate device to be tested
    RV_wrapper dut(clk, reset, en,  WriteData, DataAdr, MemWrite);
// initialize test
initial begin
    en = 1;
    reset = 1; 
    #22; 
    reset = 0; 
    #1000;
    $finish;
end
// generate clock to sequence tests
initial clk = 0; 
always #5 clk = ~clk;

endmodule

