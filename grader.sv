//`default_nettype none
module grader (
  input  logic [11:0] guess,
  input  logic [11:0] masterPattern,
  input  logic        GradeIt, CLOCK_100, reset,
  output logic [3:0]  Znarly,
  output logic [3:0]  Zood,
  output logic        Znarly_Win
);

  logic enGrade, clrGrade, roundOver;

  // ZNARLY: exact position matches
  logic P1G1, P2G2, P3G3, P4G4;
  Comparator #(3) cP1G1(.A(masterPattern[2:0]),  .B(guess[2:0]),   .AeqB(P1G1));
  Comparator #(3) cP2G2(.A(masterPattern[5:3]),  .B(guess[5:3]),   .AeqB(P2G2));
  Comparator #(3) cP3G3(.A(masterPattern[8:6]),  .B(guess[8:6]),   .AeqB(P3G3));
  Comparator #(3) cP4G4(.A(masterPattern[11:9]), .B(guess[11:9]),  .AeqB(P4G4));

  logic [3:0] zn_sum1, zn_sum2, znarly_total;
  Adder #(4) znAdd1(.A({3'b0, P1G1}), .B({3'b0, P2G2}), .cin(1'b0), .sum(zn_sum1), .cout());
  Adder #(4) znAdd2(.A({3'b0, P3G3}), .B({3'b0, P4G4}), .cin(1'b0), .sum(zn_sum2), .cout());
  Adder #(4) znAdd3(.A(zn_sum1),       .B(zn_sum2),       .cin(1'b0), .sum(znarly_total), .cout());

  // ZOOD: correct algorithm — for each shape, count occurrences in masterPattern (cntP)
  // and in guess (cntG), then take min(cntP, cntG). Sum all six mins = total_matches.
  // Zood = total_matches - Znarly.

  // --- Shape T (001) ---
  logic mpT0, mpT1, mpT2, mpT3, gsT0, gsT1, gsT2, gsT3;
  Comparator #(3) cmpMpT0(.A(masterPattern[2:0]),  .B(3'b001), .AeqB(mpT0));
  Comparator #(3) cmpMpT1(.A(masterPattern[5:3]),  .B(3'b001), .AeqB(mpT1));
  Comparator #(3) cmpMpT2(.A(masterPattern[8:6]),  .B(3'b001), .AeqB(mpT2));
  Comparator #(3) cmpMpT3(.A(masterPattern[11:9]), .B(3'b001), .AeqB(mpT3));
  Comparator #(3) cmpGsT0(.A(guess[2:0]),  .B(3'b001), .AeqB(gsT0));
  Comparator #(3) cmpGsT1(.A(guess[5:3]),  .B(3'b001), .AeqB(gsT1));
  Comparator #(3) cmpGsT2(.A(guess[8:6]),  .B(3'b001), .AeqB(gsT2));
  Comparator #(3) cmpGsT3(.A(guess[11:9]), .B(3'b001), .AeqB(gsT3));
  logic [2:0] cntPT_lo, cntPT_hi, cntPT, cntGT_lo, cntGT_hi, cntGT, minT;
  logic pltgT;
  Adder #(3) addPT_lo(.A({2'b0, mpT0}), .B({2'b0, mpT1}), .cin(1'b0), .sum(cntPT_lo), .cout());
  Adder #(3) addPT_hi(.A({2'b0, mpT2}), .B({2'b0, mpT3}), .cin(1'b0), .sum(cntPT_hi), .cout());
  Adder #(3) addPT   (.A(cntPT_lo),     .B(cntPT_hi),     .cin(1'b0), .sum(cntPT),    .cout());
  Adder #(3) addGT_lo(.A({2'b0, gsT0}), .B({2'b0, gsT1}), .cin(1'b0), .sum(cntGT_lo), .cout());
  Adder #(3) addGT_hi(.A({2'b0, gsT2}), .B({2'b0, gsT3}), .cin(1'b0), .sum(cntGT_hi), .cout());
  Adder #(3) addGT   (.A(cntGT_lo),     .B(cntGT_hi),     .cin(1'b0), .sum(cntGT),    .cout());
  MagComp #(3) cmpT(.A(cntPT), .B(cntGT), .AeqB(), .AltB(pltgT), .AgtB());
  Mux2to1 #(3) muxT(.I0(cntGT), .I1(cntPT), .S(pltgT), .Y(minT));

  // --- Shape C (010) ---
  logic mpC0, mpC1, mpC2, mpC3, gsC0, gsC1, gsC2, gsC3;
  Comparator #(3) cmpMpC0(.A(masterPattern[2:0]),  .B(3'b010), .AeqB(mpC0));
  Comparator #(3) cmpMpC1(.A(masterPattern[5:3]),  .B(3'b010), .AeqB(mpC1));
  Comparator #(3) cmpMpC2(.A(masterPattern[8:6]),  .B(3'b010), .AeqB(mpC2));
  Comparator #(3) cmpMpC3(.A(masterPattern[11:9]), .B(3'b010), .AeqB(mpC3));
  Comparator #(3) cmpGsC0(.A(guess[2:0]),  .B(3'b010), .AeqB(gsC0));
  Comparator #(3) cmpGsC1(.A(guess[5:3]),  .B(3'b010), .AeqB(gsC1));
  Comparator #(3) cmpGsC2(.A(guess[8:6]),  .B(3'b010), .AeqB(gsC2));
  Comparator #(3) cmpGsC3(.A(guess[11:9]), .B(3'b010), .AeqB(gsC3));
  logic [2:0] cntPC_lo, cntPC_hi, cntPC, cntGC_lo, cntGC_hi, cntGC, minC;
  logic pltgC;
  Adder #(3) addPC_lo(.A({2'b0, mpC0}), .B({2'b0, mpC1}), .cin(1'b0), .sum(cntPC_lo), .cout());
  Adder #(3) addPC_hi(.A({2'b0, mpC2}), .B({2'b0, mpC3}), .cin(1'b0), .sum(cntPC_hi), .cout());
  Adder #(3) addPC   (.A(cntPC_lo),     .B(cntPC_hi),     .cin(1'b0), .sum(cntPC),    .cout());
  Adder #(3) addGC_lo(.A({2'b0, gsC0}), .B({2'b0, gsC1}), .cin(1'b0), .sum(cntGC_lo), .cout());
  Adder #(3) addGC_hi(.A({2'b0, gsC2}), .B({2'b0, gsC3}), .cin(1'b0), .sum(cntGC_hi), .cout());
  Adder #(3) addGC   (.A(cntGC_lo),     .B(cntGC_hi),     .cin(1'b0), .sum(cntGC),    .cout());
  MagComp #(3) cmpC(.A(cntPC), .B(cntGC), .AeqB(), .AltB(pltgC), .AgtB());
  Mux2to1 #(3) muxC(.I0(cntGC), .I1(cntPC), .S(pltgC), .Y(minC));

  // --- Shape O (011) ---
  logic mpO0, mpO1, mpO2, mpO3, gsO0, gsO1, gsO2, gsO3;
  Comparator #(3) cmpMpO0(.A(masterPattern[2:0]),  .B(3'b011), .AeqB(mpO0));
  Comparator #(3) cmpMpO1(.A(masterPattern[5:3]),  .B(3'b011), .AeqB(mpO1));
  Comparator #(3) cmpMpO2(.A(masterPattern[8:6]),  .B(3'b011), .AeqB(mpO2));
  Comparator #(3) cmpMpO3(.A(masterPattern[11:9]), .B(3'b011), .AeqB(mpO3));
  Comparator #(3) cmpGsO0(.A(guess[2:0]),  .B(3'b011), .AeqB(gsO0));
  Comparator #(3) cmpGsO1(.A(guess[5:3]),  .B(3'b011), .AeqB(gsO1));
  Comparator #(3) cmpGsO2(.A(guess[8:6]),  .B(3'b011), .AeqB(gsO2));
  Comparator #(3) cmpGsO3(.A(guess[11:9]), .B(3'b011), .AeqB(gsO3));
  logic [2:0] cntPO_lo, cntPO_hi, cntPO, cntGO_lo, cntGO_hi, cntGO, minO;
  logic pltgO;
  Adder #(3) addPO_lo(.A({2'b0, mpO0}), .B({2'b0, mpO1}), .cin(1'b0), .sum(cntPO_lo), .cout());
  Adder #(3) addPO_hi(.A({2'b0, mpO2}), .B({2'b0, mpO3}), .cin(1'b0), .sum(cntPO_hi), .cout());
  Adder #(3) addPO   (.A(cntPO_lo),     .B(cntPO_hi),     .cin(1'b0), .sum(cntPO),    .cout());
  Adder #(3) addGO_lo(.A({2'b0, gsO0}), .B({2'b0, gsO1}), .cin(1'b0), .sum(cntGO_lo), .cout());
  Adder #(3) addGO_hi(.A({2'b0, gsO2}), .B({2'b0, gsO3}), .cin(1'b0), .sum(cntGO_hi), .cout());
  Adder #(3) addGO   (.A(cntGO_lo),     .B(cntGO_hi),     .cin(1'b0), .sum(cntGO),    .cout());
  MagComp #(3) cmpO(.A(cntPO), .B(cntGO), .AeqB(), .AltB(pltgO), .AgtB());
  Mux2to1 #(3) muxO(.I0(cntGO), .I1(cntPO), .S(pltgO), .Y(minO));

  // --- Shape D (100) ---
  logic mpD0, mpD1, mpD2, mpD3, gsD0, gsD1, gsD2, gsD3;
  Comparator #(3) cmpMpD0(.A(masterPattern[2:0]),  .B(3'b100), .AeqB(mpD0));
  Comparator #(3) cmpMpD1(.A(masterPattern[5:3]),  .B(3'b100), .AeqB(mpD1));
  Comparator #(3) cmpMpD2(.A(masterPattern[8:6]),  .B(3'b100), .AeqB(mpD2));
  Comparator #(3) cmpMpD3(.A(masterPattern[11:9]), .B(3'b100), .AeqB(mpD3));
  Comparator #(3) cmpGsD0(.A(guess[2:0]),  .B(3'b100), .AeqB(gsD0));
  Comparator #(3) cmpGsD1(.A(guess[5:3]),  .B(3'b100), .AeqB(gsD1));
  Comparator #(3) cmpGsD2(.A(guess[8:6]),  .B(3'b100), .AeqB(gsD2));
  Comparator #(3) cmpGsD3(.A(guess[11:9]), .B(3'b100), .AeqB(gsD3));
  logic [2:0] cntPD_lo, cntPD_hi, cntPD, cntGD_lo, cntGD_hi, cntGD, minD;
  logic pltgD;
  Adder #(3) addPD_lo(.A({2'b0, mpD0}), .B({2'b0, mpD1}), .cin(1'b0), .sum(cntPD_lo), .cout());
  Adder #(3) addPD_hi(.A({2'b0, mpD2}), .B({2'b0, mpD3}), .cin(1'b0), .sum(cntPD_hi), .cout());
  Adder #(3) addPD   (.A(cntPD_lo),     .B(cntPD_hi),     .cin(1'b0), .sum(cntPD),    .cout());
  Adder #(3) addGD_lo(.A({2'b0, gsD0}), .B({2'b0, gsD1}), .cin(1'b0), .sum(cntGD_lo), .cout());
  Adder #(3) addGD_hi(.A({2'b0, gsD2}), .B({2'b0, gsD3}), .cin(1'b0), .sum(cntGD_hi), .cout());
  Adder #(3) addGD   (.A(cntGD_lo),     .B(cntGD_hi),     .cin(1'b0), .sum(cntGD),    .cout());
  MagComp #(3) cmpD(.A(cntPD), .B(cntGD), .AeqB(), .AltB(pltgD), .AgtB());
  Mux2to1 #(3) muxD(.I0(cntGD), .I1(cntPD), .S(pltgD), .Y(minD));

  // --- Shape I (101) ---
  logic mpI0, mpI1, mpI2, mpI3, gsI0, gsI1, gsI2, gsI3;
  Comparator #(3) cmpMpI0(.A(masterPattern[2:0]),  .B(3'b101), .AeqB(mpI0));
  Comparator #(3) cmpMpI1(.A(masterPattern[5:3]),  .B(3'b101), .AeqB(mpI1));
  Comparator #(3) cmpMpI2(.A(masterPattern[8:6]),  .B(3'b101), .AeqB(mpI2));
  Comparator #(3) cmpMpI3(.A(masterPattern[11:9]), .B(3'b101), .AeqB(mpI3));
  Comparator #(3) cmpGsI0(.A(guess[2:0]),  .B(3'b101), .AeqB(gsI0));
  Comparator #(3) cmpGsI1(.A(guess[5:3]),  .B(3'b101), .AeqB(gsI1));
  Comparator #(3) cmpGsI2(.A(guess[8:6]),  .B(3'b101), .AeqB(gsI2));
  Comparator #(3) cmpGsI3(.A(guess[11:9]), .B(3'b101), .AeqB(gsI3));
  logic [2:0] cntPI_lo, cntPI_hi, cntPI, cntGI_lo, cntGI_hi, cntGI, minI;
  logic pltgI;
  Adder #(3) addPI_lo(.A({2'b0, mpI0}), .B({2'b0, mpI1}), .cin(1'b0), .sum(cntPI_lo), .cout());
  Adder #(3) addPI_hi(.A({2'b0, mpI2}), .B({2'b0, mpI3}), .cin(1'b0), .sum(cntPI_hi), .cout());
  Adder #(3) addPI   (.A(cntPI_lo),     .B(cntPI_hi),     .cin(1'b0), .sum(cntPI),    .cout());
  Adder #(3) addGI_lo(.A({2'b0, gsI0}), .B({2'b0, gsI1}), .cin(1'b0), .sum(cntGI_lo), .cout());
  Adder #(3) addGI_hi(.A({2'b0, gsI2}), .B({2'b0, gsI3}), .cin(1'b0), .sum(cntGI_hi), .cout());
  Adder #(3) addGI   (.A(cntGI_lo),     .B(cntGI_hi),     .cin(1'b0), .sum(cntGI),    .cout());
  MagComp #(3) cmpI(.A(cntPI), .B(cntGI), .AeqB(), .AltB(pltgI), .AgtB());
  Mux2to1 #(3) muxI(.I0(cntGI), .I1(cntPI), .S(pltgI), .Y(minI));

  // --- Shape Z (110) ---
  logic mpZ0, mpZ1, mpZ2, mpZ3, gsZ0, gsZ1, gsZ2, gsZ3;
  Comparator #(3) cmpMpZ0(.A(masterPattern[2:0]),  .B(3'b110), .AeqB(mpZ0));
  Comparator #(3) cmpMpZ1(.A(masterPattern[5:3]),  .B(3'b110), .AeqB(mpZ1));
  Comparator #(3) cmpMpZ2(.A(masterPattern[8:6]),  .B(3'b110), .AeqB(mpZ2));
  Comparator #(3) cmpMpZ3(.A(masterPattern[11:9]), .B(3'b110), .AeqB(mpZ3));
  Comparator #(3) cmpGsZ0(.A(guess[2:0]),  .B(3'b110), .AeqB(gsZ0));
  Comparator #(3) cmpGsZ1(.A(guess[5:3]),  .B(3'b110), .AeqB(gsZ1));
  Comparator #(3) cmpGsZ2(.A(guess[8:6]),  .B(3'b110), .AeqB(gsZ2));
  Comparator #(3) cmpGsZ3(.A(guess[11:9]), .B(3'b110), .AeqB(gsZ3));
  logic [2:0] cntPZ_lo, cntPZ_hi, cntPZ, cntGZ_lo, cntGZ_hi, cntGZ, minZ;
  logic pltgZ;
  Adder #(3) addPZ_lo(.A({2'b0, mpZ0}), .B({2'b0, mpZ1}), .cin(1'b0), .sum(cntPZ_lo), .cout());
  Adder #(3) addPZ_hi(.A({2'b0, mpZ2}), .B({2'b0, mpZ3}), .cin(1'b0), .sum(cntPZ_hi), .cout());
  Adder #(3) addPZ   (.A(cntPZ_lo),     .B(cntPZ_hi),     .cin(1'b0), .sum(cntPZ),    .cout());
  Adder #(3) addGZ_lo(.A({2'b0, gsZ0}), .B({2'b0, gsZ1}), .cin(1'b0), .sum(cntGZ_lo), .cout());
  Adder #(3) addGZ_hi(.A({2'b0, gsZ2}), .B({2'b0, gsZ3}), .cin(1'b0), .sum(cntGZ_hi), .cout());
  Adder #(3) addGZ   (.A(cntGZ_lo),     .B(cntGZ_hi),     .cin(1'b0), .sum(cntGZ),    .cout());
  MagComp #(3) cmpZ(.A(cntPZ), .B(cntGZ), .AeqB(), .AltB(pltgZ), .AgtB());
  Mux2to1 #(3) muxZ(.I0(cntGZ), .I1(cntPZ), .S(pltgZ), .Y(minZ));

  // Sum all six per-shape minimums → total_matches
  logic [3:0] sum_TC, sum_OD, sum_IZ, sum_TCOD, total_matches;
  Adder #(4) addTC  (.A({1'b0, minT}), .B({1'b0, minC}), .cin(1'b0), .sum(sum_TC),       .cout());
  Adder #(4) addOD  (.A({1'b0, minO}), .B({1'b0, minD}), .cin(1'b0), .sum(sum_OD),       .cout());
  Adder #(4) addIZ  (.A({1'b0, minI}), .B({1'b0, minZ}), .cin(1'b0), .sum(sum_IZ),       .cout());
  Adder #(4) addTCOD(.A(sum_TC),        .B(sum_OD),        .cin(1'b0), .sum(sum_TCOD),     .cout());
  Adder #(4) addAll (.A(sum_TCOD),      .B(sum_IZ),        .cin(1'b0), .sum(total_matches),.cout());

  // Zood = total_matches - Znarly
  logic [3:0] z_actual;
  Subtracter #(4) zoodSub(.A(total_matches), .B(znarly_total), .bin(1'b0),
                           .diff(z_actual), .bout());

  // Output Registers
  Register #(4) znarlyReg(.D(znarly_total), .en(enGrade), .clear(clrGrade),
                          .clock(CLOCK_100), .Q(Znarly));
  Register #(4) zoodReg  (.D(z_actual),   .en(enGrade), .clear(clrGrade),
                          .clock(CLOCK_100), .Q(Zood));
  
  // Znarly Win
  Comparator #(4) znWin(.A(4'd4), .B(Znarly), .AeqB(Znarly_Win));
  
  gradeItFSM control (.GradeIt, .clock(CLOCK_100), .reset,
                      .enGrade, .clrGrade, .roundOver);

endmodule : grader

module gradeItFSM
  (input  logic GradeIt, clock, reset,
   output logic enGrade, clrGrade, roundOver);

  enum logic {IDLE = 1'b0, GRADE = 1'b1} cs, ns;
  logic GradeIt_prev, gradeItSeen, roundOver_next;
  assign gradeItSeen = GradeIt & ~GradeIt_prev;

  always_comb begin
    ns           = cs;
    enGrade      = 0;
    clrGrade     = 0;
    roundOver_next = 0;
    case (cs)
      IDLE: begin
        ns       = gradeItSeen ? GRADE : IDLE;
        clrGrade = 1;
      end
      GRADE: begin
        ns             = GradeIt ? GRADE : IDLE;
        enGrade        = 1;
        roundOver_next = ~GradeIt;
      end
      default: begin
        ns       = IDLE;
        clrGrade = 1;
      end
    endcase
  end

  always_ff @(posedge clock, posedge reset)
    if (reset) begin
      cs           <= IDLE;
      GradeIt_prev <= 1'b0;
      roundOver    <= 1'b0;
    end else begin
      cs           <= ns;
      GradeIt_prev <= GradeIt;
      roundOver    <= roundOver_next;
    end
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
    @(posedge CLOCK_100);  // FSM: GRADE -> IDLE (outputs clear)

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

    // A = 3'b001, B = 3'b010, C = 3'b011, D = 3'b100

// Master: A A B C
masterPattern = {3'b011, 3'b010, 3'b001, 3'b001};

// Guess : A D D D
guess = {3'b100, 3'b100, 3'b100, 3'b001};

// Reset
reset = 1;
GradeIt = 0;
@(posedge CLOCK_100);
reset = 0;

// Trigger grading (one pulse)
@(posedge CLOCK_100);
GradeIt = 1;
@(posedge CLOCK_100);
GradeIt = 0;

// Wait a cycle for register to latch
@(posedge CLOCK_100);

// Check results
$display("Znarly = %0d (expected 1)", Znarly);
$display("Zood = %0d (expected 0)", Zood);

    #1 $finish;
  end
endmodule : grader_tb


// module task1_comb_tb;

//     logic [11:0] Guess;
//     logic [11:0] Master;
//     logic [3:0] Znarly;
//     logic [3:0] Zood;
//     logic clock;

//     grader dut (
//         .guess(Guess),
//         .masterPattern(Master),
//         .GradeIt(1'b1),
//         .CLOCK_100(clock),
//         .reset(1'b0),
//         .Znarly(Znarly),
//         .Zood(Zood)
//     );

//     initial begin
//         clock = 0;
//         forever #5 clock = ~clock;
//     end

//     initial begin
//         $monitor($time,, "Guess=%b, Master=%b, Znarly=%d, Zood=%d",
//                  Guess, Master, Znarly, Zood);

//          #5 Guess  = 12'b001_010_011_100;
//             Master = 12'b001_010_011_100;
//             Znarly = 0;
//             Zood = 0; 
//         // test 1: all exact matches (znarly=4, zood=0)
//         // tet=001, cube=010, oct=011, dod=100, ico=101, sph=110
//         #5 $display("Test 1: All exact matches");
//         $display("  TET,CUBE,OCT,DOD vs TET,CUBE,OCT,DOD");
//         $display("  Expected: Znarly=4, Zood=0");
//         #5 Guess  = 12'b001_010_011_100;
//            Master = 12'b001_010_011_100;

//         // test 2: no matches at all (znarly=0, zood=0)
//         #5 $display("Test 2: No matches");
//         $display("  TET,TET,TET,TET vs CUBE,CUBE,CUBE,CUBE");
//         $display("  Expected: Znarly=0, Zood=0");
//         #10 Guess  = 12'b001_001_001_001;
//             Master = 12'b010_010_010_010;

//         // test 3: all wrong position (znarly=0, zood=4)
//         #5 $display("Test 3: All wrong positions");
//         $display("  TET,CUBE,OCT,DOD vs DOD,OCT,CUBE,TET");
//         $display("  Expected: Znarly=0, Zood=4");
//         #10 Guess  = 12'b001_010_011_100;
//             Master = 12'b100_011_010_001;

//         // test 4: two exact, two wrong position (znarly=2, zood=2)
//         #5 $display("Test 4: Two exact, two wrong");
//         $display("  TET,CUBE,OCT,DOD vs TET,CUBE,DOD,OCT");
//         $display("  Expected: Znarly=2, Zood=2");
//         #10 Guess  = 12'b001_010_011_100;
//             Master = 12'b001_010_100_011;

//         // test 5: one exact match only (znarly=1, zood=0)
//         #5 $display("Test 5: One exact match");
//         $display("  TET,ICO,ICO,ICO vs TET,CUBE,CUBE,CUBE");
//         $display("  Expected: Znarly=1, Zood=0");
//         #10 Guess  = 12'b001_101_101_101;
//             Master = 12'b001_010_010_010;

//         // test 6: duplicate shapes, guess has 2 tet, master has 1 (znarly=1, zood=0)
//         #5 $display("Test 6: Duplicates");
//         $display("  TET,TET,CUBE,OCT vs TET,DOD,DOD,DOD");
//         $display("  Expected: Znarly=1, Zood=0");
//         #10 Guess  = 12'b001_001_010_011;
//             Master = 12'b001_100_100_100;

//         // test 7: duplicate shapes wrong position (znarly=0, zood=3)
//         #5 $display("Test 7: Duplicates wrong position");
//         $display("  CUBE,TET,TET,OCT vs TET,CUBE,OCT,DOD");
//         $display("  Expected: Znarly=0, Zood=3");
//         #10 Guess  = 12'b010_001_001_011;
//             Master = 12'b001_010_011_100;

//         // test 8: three exact matches (znarly=3, zood=0)
//         #5 $display("Test 8: Three exact matches");
//         $display("  TET,CUBE,OCT,DOD vs TET,CUBE,OCT,ICO");
//         $display("  Expected: Znarly=3, Zood=0");
//         #10 Guess  = 12'b001_010_011_100;
//             Master = 12'b001_010_011_101;

//         // test 9: one exact, one wrong position (znarly=1, zood=1)
//         #5 $display("Test 9: One exact, one wrong");
//         $display("  TET,CUBE,ICO,ICO vs TET,ICO,DOD,DOD");
//         $display("  Expected: Znarly=1, Zood=1");
//         #10 Guess  = 12'b001_010_101_101;
//             Master = 12'b001_101_100_100;

//         // test 10: all same shape (znarly=4, zood=0)
//         #5 $display("Test 10: All same shape");
//         $display("  SPH,SPH,SPH,SPH vs SPH,SPH,SPH,SPH");
//         $display("  Expected: Znarly=4, Zood=0");
//         #10 Guess  = 12'b110_110_110_110;
//             Master = 12'b110_110_110_110;

//         // test 11: mixed duplicates all swapped (znarly=0, zood=4)
//         #5 $display("Test 11");
//         $display("  TET,TET,CUBE,CUBE vs CUBE,CUBE,TET,TET");
//         $display("  Expected: Znarly=0, Zood=4");
//         #10 Guess  = 12'b001_001_010_010;
//             Master = 12'b010_010_001_001;

//         // test 12: partial duplicate overlap (znarly=2, zood=1)
//         #5 $display("Test 12: Partial overlap");
//         $display("  TET,TET,TET,CUBE vs TET,TET,CUBE,CUBE");
//         $display("  Expected: Znarly=3, Zood=0");
//         #10 Guess  = 12'b001_001_001_010;
//             Master = 12'b001_001_010_010;

//          // test 13: partial duplicate overlap (znarly=0, zood=3)
//         #5 $display("Test 13: 3 zood test");
//         $display("  TET,TET,TET,CUBE vs SPH,SPH,CUBE,TET");
//         $display("  Expected: Znarly=0, Zood=2");
//         #10 Guess  = 12'b001_001_001_010;
//             Master = 12'b110_110_010_001;

//         #10 $finish;
//     end

// endmodule

