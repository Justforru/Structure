module regfile(
    input  wire        clk,
    input  wire       reset,
    // READ PORT 1
    input  wire [ 4:0] raddr1,
    output wire [31:0] rdata1,
    // READ PORT 2
    input  wire [ 4:0] raddr2,
    output wire [31:0] rdata2,
    // WRITE PORT
    input  wire        we,       //write enable, HIGH valid
    input  wire [ 4:0] waddr,
    input  wire [31:0] wdata
);
reg [31:0] rf[31:0];

//WRITE
integer i;
    always @(posedge clk)
     if(reset)     
    begin
        for(i=0;i<32;i=i+1)
            rf[i] <= 32'b00;
    end else if(we == 1'b1 && waddr != 5'b0)
        begin
            rf[waddr] <= wdata;
        end

//READ OUT 1
assign rdata1 = (raddr1==5'b0) ? 32'b0 : rf[raddr1];

//READ OUT 2
assign rdata2 = (raddr2==5'b0) ? 32'b0 : rf[raddr2];

endmodule
