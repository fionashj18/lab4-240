`default_nettype none
module ChipInterface
 (output logic [7:0] D2_SEG, D1_SEG,
  output logic [3:0] D2_AN, D1_AN,
  output logic [15:0] LD, 
  input  logic [15:0] SW,
  input  logic [3:0] BTN,
  input  logic CLOCK_100);

  logic [3:0] HEX3, HEX2, HEX1, HEX0;
  logic [7:0] dec_points;
  logic [7:0] blank;


endmodule : ChipInterface