//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.12.2025 23:59:52
// Design Name: 
// Module Name: prefixadder
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


`timescale 1ns / 1ps

module prefix_adder (
    input  [4:0] A,
    input  [4:0] B,
    input        Cin,
    output [4:0] Sum,
    output Cout
);

    wire [4:0] P, G;
    wire [5:0] c;

    assign c[0] = Cin;

    // Propagate signals
    assign P = A ^ B;

    // Generate signals
    assign G = A & B;

    // Carry prefix network
    assign c[1] = G[0] | (P[0] & c[0]);

    assign c[2] = G[1] | (P[1] & c[1]);

    assign c[3] = G[2] | (P[2] & c[2]);

    assign c[4] = (G[3] | (P[3] & G[2])) | ((P[3]&P[2]) & c[2]);

    assign c[5] = G[4] | (P[4] & c[4]);

    // Sum bits
    assign Sum = P ^ c[4:0];

    assign Cout = c[5];

endmodule
