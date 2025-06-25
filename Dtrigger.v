`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/06/20 15:32:49
// Design Name: 
// Module Name: Dtrigger
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Dtrigger #(parameter WIDTH = 8)
(
    input wire clk,reset,clear,
    input wire [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
);
    always @(posedge clk)
    begin
        if(reset)
            q <= 0;
        else if(clear)
            q <= 0;
        else
            q <= d;
     end
endmodule
