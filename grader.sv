module grader (
  input  logic [11:0] guess,
  input  logic [11:0] masterPattern,
  input  logic        engrade, clrgrade, CLOCK_100,
  output logic [3:0]  Znarly,
  output logic [3:0]  Zood
);
  // ZOOD
  logic P1G1, P1G2, P1G3, P1G4;
  logic P2G1, P2G2, P2G3, P2G4;
  logic P3G1, P3G2, P3G3, P3G4;
  logic P4G1, P4G2, P4G3, P4G4;

  Comparator #(3) cP1G1(.A(masterPattern[2:0]), .B(guess[2:0]), .AeqB(P1G1));
  Comparator #(3) cP1G2(.A(masterPattern[2:0]), .B(guess[5:3]), .AeqB(P1G2));
  Comparator #(3) cP1G3(.A(masterPattern[2:0]), .B(guess[8:6]), .AeqB(P1G3));

  Comparator #(3) cP2G1(.A(masterPattern[5:3]), .B(guess[2:0]),  .AeqB(P2G1));
  Comparator #(3) cP2G3(.A(masterPattern[5:3]), .B(guess[8:6]),  .AeqB(P2G3));
  Comparator #(3) cP2G4(.A(masterPattern[5:3]), .B(guess[11:9]), .AeqB(P2G4));

  Comparator #(3) cP3G1(.A(masterPattern[8:6]), .B(guess[2:0]),  .AeqB(P3G1));
  Comparator #(3) cP3G2(.A(masterPattern[8:6]), .B(guess[5:3]),  .AeqB(P3G2));
  Comparator #(3) cP3G4(.A(masterPattern[8:6]), .B(guess[11:9]), .AeqB(P3G4));

  Comparator #(3) cP4G1(.A(masterPattern[11:9]),.B(guess[2:0]),  .AeqB(P4G1));
  Comparator #(3) cP4G2(.A(masterPattern[11:9]),.B(guess[5:3]),  .AeqB(P4G2));
  Comparator #(3) cP4G3(.A(masterPattern[11:9]),.B(guess[8:6]),  .AeqB(P4G3));

  // OR outputs from Comparators
  logic p1, p2, p3, p4;
  assign p1 = P1G2 | P1G3 | P1G4;
  assign p2 = P2G1 | P2G3 | P2G4;
  assign p3 = P3G1 | P3G2 | P3G4;
  assign p4 = P4G1 | P4G2 | P4G3;
  
  // Using Adder to add the results from the OR outputs
  // p1 + p2 + p3 + p4 = z_matches
  logic [3:0] z_sum1, z_sum2, z_total;
  Adder #(4) zoodAdd1(.A({3'b0, p1}), .B({3'b0, p2}), .cin({3'b0, p3}),
                    .sum(z_sum1), .cout());
  Adder #(4) zoodAdd2(.A(z_sum1), .B({3'b0, p4}), .cin(1'b0),
                    .sum(z_total), .cout());

  // ZNARLY
  Comparator #(3) cP1G1(.A(masterPattern[2:0]), .B(guess[2:0]),  .AeqB(P1G1));
  Comparator #(3) cP2G2(.A(masterPattern[5:3]), .B(guess[5:3]),  .AeqB(P2G2));
  Comparator #(3) cP3G3(.A(masterPattern[8:6]), .B(guess[8:6]),  .AeqB(P3G3));
  Comparator #(3) cP4G4(.A(masterPattern[11:9]),.B(guess[11:9]), .AeqB(P4G4));

  // P1G1 + P2G2 + P3G3 + P4G4 = znarly_final
  logic [3:0] zn_sum1, zn_sum2;
  logic [3:0] znarly_total;
  Adder #(4) znAdd1(.A({3'b0, P1G1}), .B({3'b0, P2G2}), .cin(),
                    .sum(zn_sum1), .cout());
  Adder #(4) znAdd2(.A({3'b0, P3G3}), .B({3'b0, P4G4}), .cin(),
                    .sum(zn_sum2), .cout());
  Adder #(4) znAdd3(.A(zn_sum1), .B(zn_sum2), .cin(),
                    .sum(znarly_total), .cout());

  // Zood = zood_total - znarly_final
  logic [3:0] z_actual;
  Subtracter #(4) zoodSub(.A(z_total), .B(znarly_total), .bin(),
                          .diff(z_actual), .bout());

  // Output Registers
  Register #(4) znarlyReg(.D(znarly_total), .en(engrade), .clear(clrgrade),
                          .clock(CLOCK_100), .Q(Znarly));
  Register #(4) zoodReg  (.D(z_actual),   .en(engrade), .clear(clrgrade),
                          .clock(CLOCK_100), .Q(Zood));

endmodule : grader