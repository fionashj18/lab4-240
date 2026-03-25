`default_nettype none
module grader (
  input  logic [11:0] guess,
  input  logic [11:0] masterPattern,
  input  logic        GradeIt, CLOCK_100, reset,
  output logic [3:0]  Znarly,
  output logic [3:0]  Zood,
  output logic        Znarly_Win
);

  logic clock;
  assign clock = CLOCK_100;
  logic enGrade, clrGrade, roundOver;

  // ZOOD
  logic P1G1, P1G2, P1G3, P1G4;
  logic P2G1, P2G2, P2G3, P2G4;
  logic P3G1, P3G2, P3G3, P3G4;
  logic P4G1, P4G2, P4G3, P4G4;

  Comparator #(3) cP1G2(.A(masterPattern[2:0]), .B(guess[5:3]), .AeqB(P1G2));
  Comparator #(3) cP1G3(.A(masterPattern[2:0]), .B(guess[8:6]), .AeqB(P1G3));
  Comparator #(3) cP1G4(.A(masterPattern[2:0]), .B(guess[11:9]), .AeqB(P1G4));

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
  assign p1 = P1G1 | P1G2 | P1G3 | P1G4;
  assign p2 = P2G1 | P2G2 | P2G3 | P2G4;
  assign p3 = P3G1 | P3G2 | P3G3 | P3G4;
  assign p4 = P4G1 | P4G2 | P4G3 | P4G4;
  
  // Using Adder to add the results from the OR outputs
  // p1 + p2 + p3 + p4 = z_matches
  logic [3:0] z_sum1, z_sum2, z_total;
  Adder #(4) zoodAdd1(.A({3'b0, p1}), .B({3'b0, p2}), .cin(1'b0),
                    .sum(z_sum1), .cout());
  Adder #(4) zoodAdd2(.A({3'b0, p3}), .B({3'b0, p4}), .cin(1'b0),
                    .sum(z_sum2), .cout());
  Adder #(4) zoodAdd3(.A(z_sum1), .B(z_sum2), .cin(1'b0),
                    .sum(z_total), .cout());

  // ZNARLY
  Comparator #(3) cP1G1(.A(masterPattern[2:0]), .B(guess[2:0]),  .AeqB(P1G1));
  Comparator #(3) cP2G2(.A(masterPattern[5:3]), .B(guess[5:3]),  .AeqB(P2G2));
  Comparator #(3) cP3G3(.A(masterPattern[8:6]), .B(guess[8:6]),  .AeqB(P3G3));
  Comparator #(3) cP4G4(.A(masterPattern[11:9]),.B(guess[11:9]), .AeqB(P4G4));

  // P1G1 + P2G2 + P3G3 + P4G4 = znarly_final
  logic [3:0] zn_sum1, zn_sum2;
  logic [3:0] znarly_total;
  Adder #(4) znAdd1(.A({3'b0, P1G1}), .B({3'b0, P2G2}), .cin(1'b0),
                    .sum(zn_sum1), .cout());
  Adder #(4) znAdd2(.A({3'b0, P3G3}), .B({3'b0, P4G4}), .cin(1'b0),
                    .sum(zn_sum2), .cout());
  Adder #(4) znAdd3(.A(zn_sum1), .B(zn_sum2), .cin(1'b0),
                    .sum(znarly_total), .cout());

  // Zood = zood_total - znarly_final
  logic [3:0] z_actual;
  Subtracter #(4) zoodSub(.A(z_total), .B(znarly_total), .bin(1'b0),
                          .diff(z_actual), .bout());

  // Output Registers
  Register #(4) znarlyReg(.D(znarly_total), .en(enGrade), .clear(clrGrade),
                          .clock(CLOCK_100), .Q(Znarly));
  Register #(4) zoodReg  (.D(z_actual),   .en(enGrade), .clear(clrGrade),
                          .clock(CLOCK_100), .Q(Zood));
  
  // Znarly Win
  Comparator #(4) znWin(.A(4'd4), .B(Znarly), .AeqB(Znarly_Win));
  
  gradeItFSM control (.*);

endmodule : grader

module gradeItFSM
  (input  logic GradeIt, clock, reset,
   output logic enGrade, clrGrade, roundOver);

  enum logic {IDLE = 1'b0, GRADE = 1'b1} cs, ns;
  
  always_comb begin
   case (cs)
    IDLE: begin
      ns = (GradeIt) ? GRADE : IDLE;
      enGrade = 0;
      clrGrade = 1;
      roundOver = 1;
    end
    GRADE: begin
      ns = (GradeIt) ? GRADE : IDLE;
      enGrade = 1;
      clrGrade = 0;
      roundOver = 0;
    end
   endcase
  end

  always_ff @(posedge clock, posedge reset)
    if (reset)
      cs <= IDLE;
    else
      cs <= ns;

endmodule : gradeItFSM

module grader_tb;
  logic [11:0] guess, masterPattern;
  logic        GradeIt, CLOCK_100, reset;
  logic [3:0]  Znarly, Zood;
  logic        Znarly_Win;

  grader dut (.*);

  initial begin
    CLOCK_100 = 0;
    forever #5 CLOCK_100 = ~CLOCK_100;
  end

  initial begin
    $monitor($time,, "guess=%b  master=%b  GradeIt=%b  Znarly=%0d  Zood=%0d",
             guess, masterPattern, GradeIt, Znarly, Zood);

    // Reset
    reset <= 1;
    GradeIt <= 0;
    guess <= 12'b0;
    masterPattern <= 12'b0;
    @(posedge CLOCK_100);
    @(posedge CLOCK_100);
    reset <= 0;
    @(posedge CLOCK_100);

    // Test 1: Znarly=4, Zood=0
    // master = T C O D = 001_010_011_100, guess = same
    masterPattern <= 12'b001_010_011_100;
    guess         <= 12'b001_010_011_100;
    GradeIt       <= 1;
    @(posedge CLOCK_100);  // FSM: IDLE -> GRADE
    @(posedge CLOCK_100);  // registers latch
    #1;
    if (Znarly != 4) $display("INCORRECT test1: Znarly expected 4, got %0d", Znarly);
    if (Zood   != 0) $display("INCORRECT test1: Zood expected 0, got %0d", Zood);
    GradeIt <= 0;
    @(posedge CLOCK_100);  // FSM: GRADE -> IDLE(outputs clear)

    // Test 2: Znarly=0, Zood=0
    // master = T T T T (001_001_001_001), guess = C C C C (010_010_010_010)
    masterPattern <= 12'b001_001_001_001;
    guess         <= 12'b010_010_010_010;
    GradeIt       <= 1;
    @(posedge CLOCK_100);
    @(posedge CLOCK_100);
    #1;
    if (Znarly != 0) 
      $display("INCORRECT test2: Znarly expected 0, got %0d", Znarly);
    if (Zood   != 0) 
      $display("INCORRECT test2: Zood expected 0, got %0d", Zood);
    GradeIt <= 0;
    @(posedge CLOCK_100);

    // Test 3: Znarly=0, Zood=4
    // master = T C O D (001_010_011_100), guess = O D T C (011_100_001_010)
    masterPattern <= 12'b001_010_011_100;
    guess         <= 12'b011_100_001_010;
    GradeIt       <= 1;
    @(posedge CLOCK_100);
    @(posedge CLOCK_100);
    #1;
    if (Znarly != 0) 
      $display("INCORRECT test3: Znarly expected 0, got %0d", Znarly);
    if (Zood   != 4) 
      $display("INCORRECT test3: Zood expected 4, got %0d", Zood);
    GradeIt <= 0;
    @(posedge CLOCK_100);

    // Test 4: Znarly=0, Zood=1
    // master = I Z D T = 101_110_100_001
    // guess  = T T C C = 001_001_010_010
    masterPattern <= 12'b101_110_100_001;
    guess         <= 12'b001_001_010_010;
    GradeIt       <= 1;
    @(posedge CLOCK_100);
    @(posedge CLOCK_100);
    #1;
    if (Znarly != 0) 
      $display("INCORRECT test4: Znarly expected 0, got %0d", Znarly);
    if (Zood   != 1) 
      $display("INCORRECT test4: Zood expected 1, got %0d", Zood);
    GradeIt <= 0;
    @(posedge CLOCK_100);

    // Test 5: Znarly=1, Zood=2
    // master = I Z D T = 101_110_100_001
    // guess  = I O T Z = 101_011_001_110
    masterPattern <= 12'b101_110_100_001;
    guess         <= 12'b101_011_001_110;
    GradeIt       <= 1;
    @(posedge CLOCK_100);
    @(posedge CLOCK_100);
    #1;
    if (Znarly != 1) $display("INCORRECT test5: Znarly expected 1, got %0d", Znarly);
    if (Zood   != 2) $display("INCORRECT test5: Zood expected 2, got %0d", Zood);
    GradeIt <= 0;
    @(posedge CLOCK_100);

    // Test 6: Znarly=4, Zood=0 -> game won
    // master = I Z D T = 101_110_100_001, guess = same
    masterPattern <= 12'b101_110_100_001;
    guess         <= 12'b101_110_100_001;
    GradeIt       <= 1;
    @(posedge CLOCK_100);
    @(posedge CLOCK_100);
    #1;
    if (Znarly != 4) $display("INCORRECT test6: Znarly expected 4, got %0d", Znarly);
    if (Zood   != 0) $display("INCORRECT test6: Zood expected 0, got %0d", Zood);
    GradeIt <= 0;
    @(posedge CLOCK_100);

    #1 $finish;
  end
endmodule : grader_tb