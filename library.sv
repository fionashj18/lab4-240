`default_nettype none

module Comparator
   #(parameter WIDTH = 4)
   (input  logic [WIDTH-1:0] A, B,
    output logic       AeqB);

   assign AeqB = (A == B);

endmodule : Comparator

module MagComp
   #(parameter WIDTH = 4)
   (input  logic [WIDTH-1:0] A, B,
    output logic       AeqB, AltB, AgtB);

   assign AeqB = (A == B);
   assign AltB = (A < B);
   assign AgtB = (A > B);

endmodule : MagComp

module Adder
   #(parameter WIDTH = 8)
   (input  logic [WIDTH-1:0] A, B,
    input  logic             cin,
    output logic [WIDTH-1:0] sum,
    output logic             cout);
    
   logic [WIDTH:0] temp;

   always_comb begin
      temp = A + B + cin;
      sum  = temp[WIDTH-1:0];
      cout = temp[WIDTH];
   end

endmodule : Adder

module Subtracter
   #(parameter WIDTH = 8)
   (input  logic [WIDTH-1:0] A, B,
    input  logic             bin,
    output logic [WIDTH-1:0] diff,
    output logic             bout);

   logic [WIDTH:0] temp;

   always_comb begin
      temp = A - B - bin;
      diff = temp[WIDTH-1:0];
      bout = temp[WIDTH];
   end

endmodule : Subtracter

module Multiplexer
   #(parameter WIDTH = 8)
   (input  logic [$clog2(WIDTH)-1:0] S,
    input  logic [WIDTH-1:0] I,
    output logic       Y);

   assign Y = I[S];

endmodule : Multiplexer

module Mux2to1
   #(parameter WIDTH = 8)
   (input  logic [WIDTH-1:0] I0, I1,
    input  logic             S,
    output logic [WIDTH-1:0] Y);

    assign Y = S ? I1 : I0;

endmodule : Mux2to1

module Decoder
    #(parameter WIDTH = 8)
    (input  logic [$clog2(WIDTH)-1:0] I,
     input  logic       en,
     output logic [WIDTH-1:0] D);

    always_comb begin
      D = '0;
      if (en == 1'b1)
        D[I] = 1'b1;
    end
endmodule : Decoder

module DFlipFlop
  (input  logic D,
   input  logic  reset_L, clock, preset_L,
   output logic Q);

  always_ff @(posedge clock, negedge preset_L, negedge reset_L)
    if (~reset_L & ~preset_L)
      Q <= 1'bX;
    else if (preset_L & ~reset_L)
      Q <= 1'b0;
    else if (~preset_L & reset_L)
      Q <= 1'b1;
    else
      Q <= D;

endmodule : DFlipFlop

module Register
  #(parameter WIDTH = 8)
  (input  logic [WIDTH-1:0] D,
   input  logic             en, clear, clock,
   output logic [WIDTH-1:0] Q);

  always_ff @(posedge clock)
    if (en)
      Q <= D;
    else if (clear)
      Q <= '0;

endmodule : Register

module Counter
  #(parameter WIDTH=8)
  (input  logic [WIDTH-1:0] D,
   input  logic             en, clear, load, clock, up,
   output logic [WIDTH-1:0] Q);

  always_ff @(posedge clock)
    if (clear)
      Q <= '0;
    else if (load)
      Q <= D;
    else if (en)
      if (up)
        Q <= Q + 1'b1;
      else
        Q <= Q - 1'b1;

endmodule : Counter

module ShiftRegisterSIPO
  #(parameter WIDTH=8)
  (input  logic             en, left, serial, clock,
   output logic [WIDTH-1:0] Q);

  always_ff @(posedge clock)
    if (en & left)
      Q <= {Q[WIDTH-2:0], serial};
    else if (en & ~left)
      Q <= {serial, Q[WIDTH-1:1]};
endmodule : ShiftRegisterSIPO

module ShiftRegisterPIPO
  #(parameter WIDTH=8)
  (input  logic [WIDTH-1:0] D,
   input  logic             en, left, load, clock,
   output logic [WIDTH-1:0] Q);

  always_ff @(posedge clock)
    if (load)
      Q <= D;
    else if (en)
      if (left)
        Q <= {Q[WIDTH-2:0], 1'b0};
      else
        Q <= {1'b0, Q[WIDTH-1:1]};
     
endmodule : ShiftRegisterPIPO

module BarrelShiftRegister
  #(parameter WIDTH=8)
  (input  logic [WIDTH-1:0] D,
   input  logic [1:0]       by,
   input  logic             en, load, clock,
   output logic [WIDTH-1:0] Q);

  logic [WIDTH-1:0] shifted;

  always_comb
    case (by)
      2'b01: shifted = {Q[WIDTH-2:0], 1'b0};
      2'b10: shifted = {Q[WIDTH-3:0], 2'b0};
      2'b11: shifted = {Q[WIDTH-4:0], 3'b0};
      default: shifted = Q;
    endcase

  always_ff @(posedge clock)
    if (load)
      Q <= D;
    else if (en)
       Q <= shifted;

endmodule : BarrelShiftRegister

module Synchronizer
  #(parameter WIDTH=8)
  (input  logic async, clock,
   output logic sync);

  logic metastable;

  DFlipFlop one(.D(async),
                .Q(metastable),
                .clock,
                .preset_L(1'b1),
                .reset_L(1'b1));

  DFlipFlop two(.D(metastable),
                .Q(sync),
                .clock,
                .preset_L(1'b1),
                .reset_L(1'b1));

endmodule : Synchronizer

module BusDriver
  #(parameter WIDTH = 8)
  (input  logic             en,
   input  logic [WIDTH-1:0] data,
   output logic [WIDTH-1:0] buff,
   inout  tri   [WIDTH-1:0] bus);

  assign buff =  bus;
  assign bus = (en) ? data : 'z;
endmodule : BusDriver

module Memory
  #(parameter DW = 16,
              W  = 256,
              AW = $clog2(W))
  (input logic re, we, clock,
   input logic [AW-1:0] addr,
   inout tri   [DW-1:0] data);

  logic [DW-1:0] M[W];
  logic [DW-1:0] rData;

  assign data = (re) ? rData: 'bz;

  always_ff @(posedge clock)
    if (we)
      M[addr] <= data;

  always_comb
    rData = M[addr];
endmodule : Memory
