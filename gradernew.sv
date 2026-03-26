// `default_nettype none
module gradernew(
  input  logic [11:0] Guess,
  input  logic [11:0] masterPattern,
  output logic [3:0]  Zood,
  output logic [3:0]  Znarly,
  output logic        GameWon
);

    logic [3:0] gt, gc, go, gd, gi, gz;
    logic [3:0] mt, mc, mo, md, mi, mz;

    countShapes cs1 (.Guess, .masterPattern, .shape(3'b001), .guessCount(gt),
                 .masterCount(mt));
    countShapes cs2 (.Guess, .masterPattern, .shape(3'b010), .guessCount(gc),
                 .masterCount(mc));
    countShapes cs3 (.Guess, .masterPattern, .shape(3'b011), .guessCount(go),
                 .masterCount(mo));
    countShapes cs4 (.Guess, .masterPattern, .shape(3'b100), .guessCount(gd),
                 .masterCount(md));
    countShapes cs5 (.Guess, .masterPattern, .shape(3'b101), .guessCount(gi),
                 .masterCount(mi));
    countShapes cs6 (.Guess, .masterPattern, .shape(3'b110), .guessCount(gz),
                 .masterCount(mz));

    logic [3:0] tmin, cmin, omin, dmin, imin, zmin;
    minCount mc1 (.guessCount(gt), .masterCount(mt), .minCount(tmin));
    minCount mc2 (.guessCount(gc), .masterCount(mc), .minCount(cmin));
    minCount mc3 (.guessCount(go), .masterCount(mo), .minCount(omin));
    minCount mc4 (.guessCount(gd), .masterCount(md), .minCount(dmin));
    minCount mc5 (.guessCount(gi), .masterCount(mi), .minCount(imin));
    minCount mc6 (.guessCount(gz), .masterCount(mz), .minCount(zmin));

    ZoodComp zd1 (.Znarly, .tcount(tmin), .ccount(cmin), .ocount(omin), 
             .dcount(dmin), .icount(imin), .zcount(zmin), .Zood);

    ZnarlyCalc zncalc(.Guess, .masterPattern, .Znarly, .GameWon);

endmodule : gradernew


module countShapes(
  input  logic [11:0] Guess,
  input  logic [11:0] masterPattern,
  input  logic [2:0]  shape,
  output logic [3:0]  guessCount,
  output logic [3:0]  masterCount
);
  
    logic g1, g2, g3, g4;
    logic m1, m2, m3, m4;

    Comparator #(3) c1 (.A(Guess[2:0]), .B(shape),  .AeqB(g1));
    Comparator #(3) c2 (.A(Guess[5:3]), .B(shape),  .AeqB(g2));
    Comparator #(3) c3 (.A(Guess[8:6]), .B(shape),  .AeqB(g3));
    Comparator #(3) c4 (.A(Guess[11:9]), .B(shape),  .AeqB(g4));

    logic gSum1, gCout1, gSum2, gCout2;

    Adder #(1) a1 (.A(g1), .B(g2), .sum(gSum1), .cin(1'b0), .cout(gCout1));
    Adder #(1) a2 (.A(g3), .B(g4), .sum(gSum2), .cin(1'b0), .cout(gCout2));

    Adder #(2) a3 (.A({gCout1, gSum1}), .B({gCout2, gSum2}), 
                .sum(guessCount[1:0]), .cin(1'b0), .cout(guessCount[2]));
    Comparator #(3) c5 (.A(masterPattern[2:0]), .B(shape),  .AeqB(m1));
    Comparator #(3) c6 (.A(masterPattern[5:3]), .B(shape),  .AeqB(m2));
    Comparator #(3) c7 (.A(masterPattern[8:6]), .B(shape),  .AeqB(m3));
    Comparator #(3) c8 (.A(masterPattern[11:9]), .B(shape),  .AeqB(m4));
    
    
    logic mSum1, mCout1, mSum2, mCout2;

    Adder #(1) a4 (.A(m1), .B(m2), .sum(mSum1), .cin(1'b0), .cout(mCout1));
    Adder #(1) a5 (.A(m3), .B(m4), .sum(mSum2), .cin(1'b0), .cout(mCout2));

    Adder #(2) a6 (.A({mCout1, mSum1}), .B({mCout2, mSum2}), 
                .sum(masterCount[1:0]), .cin(1'b0), .cout(masterCount[2]));
    
    assign guessCount[3] = 1'b0;
    assign masterCount[3] = 1'b0;

endmodule : countShapes

module minCount(
    input  logic [3:0] guessCount,
    input  logic [3:0] masterCount,
    output logic [3:0] minCount
);
    logic less, equal;
    MagComp #(4) mg1 (.A(guessCount), .B(masterCount), .AltB(less), .AeqB(equal), 
                      .AgtB());

    Mux2to1 #(4) mg2 (.S(less|equal), .I0(masterCount), .I1(guessCount), 
                      .Y(minCount));

endmodule : minCount

module ZoodComp(
    input logic [3:0] Znarly,
    input logic [3:0] tcount,
    input logic [3:0] ccount,
    input logic [3:0] ocount,
    input logic [3:0] dcount,
    input logic [3:0] icount,
    input logic [3:0] zcount,
    output logic [3:0] Zood
);
    logic [3:0] a1, a2, a3, a4, total;
    Adder #(4) tcAdd (.A(tcount), .B(ccount), .sum(a1), .cin(1'b0), .cout());
    Adder #(4) odAdd (.A(ocount), .B(dcount), .sum(a2), .cin(1'b0), .cout());
    Adder #(4) izAdd (.A(icount), .B(zcount), .sum(a3), .cin(1'b0), .cout());
    Adder #(4) a1a2Add (.A(a1), .B(a2), .sum(a4), .cin(1'b0), .cout());
    Adder #(4) a3a4Add (.A(a3), .B(a4), .sum(total), .cin(1'b0), .cout());

    Subtracter #(4) s1(.A(total), .B(Znarly), .bin(1'b0), .diff(Zood), .bout());

endmodule : ZoodComp

module ZnarlyCalc(
  input  logic [11:0] Guess,
  input  logic [11:0] masterPattern,
  output logic [3:0]  Znarly,
  output logic        GameWon
);
    logic z1, z2, z3, z4;
    Comparator #(3) zn1(.A(masterPattern[2:0]), .B(Guess[2:0]),  .AeqB(z1));
    Comparator #(3) zn2(.A(masterPattern[5:3]), .B(Guess[5:3]),  .AeqB(z2));
    Comparator #(3) zn3(.A(masterPattern[8:6]), .B(Guess[8:6]),  .AeqB(z3));
    Comparator #(3) zn4(.A(masterPattern[11:9]),.B(Guess[11:9]), .AeqB(z4));

    logic [3:0] zn_sum1, zn_sum2;
    Adder #(4) znAdd1(.A({3'b0, z1}), .B({3'b0, z2}), .cin(1'b0),
                    .sum(zn_sum1), .cout());
    Adder #(4) znAdd2(.A({3'b0, z3}), .B({3'b0, z4}), .cin(1'b0),
                    .sum(zn_sum2), .cout());
    Adder #(4) znAdd3(.A(zn_sum1), .B(zn_sum2), .cin(1'b0),
                    .sum(Znarly), .cout());

    Comparator #(4) won (.A(Znarly),.B(4'd4), .AeqB(GameWon));

endmodule : ZnarlyCalc


module grader_tb;
  logic [11:0] Guess, masterPattern;
  logic [3:0]  Znarly, Zood;
  logic        GameWon;

  gradernew dut (.*);

  initial begin
    $monitor($time,, "guess=%b  master=%b  gameWon=%b  Znarly=%0d  Zood=%0d",
             Guess, masterPattern, GameWon, Znarly, Zood);

    // Test 1: Znarly=4, Zood=0
    // master = T C O D = 001_010_011_100, guess = same
    masterPattern <= 12'b001_010_011_100;
    Guess         <= 12'b001_010_011_100;
    #1;
    if (Znarly !== 4) $display("INCORRECT test1: Znarly expected 4, got %0d", Znarly);
    if (Zood !== 0) $display("INCORRECT test1: Zood expected 0, got %0d", Zood);

    // Test 2: Znarly=0, Zood=0
    // master = T T T T (001_001_001_001), guess = C C C C (010_010_010_010)
    masterPattern <= 12'b001_001_001_001;
    Guess         <= 12'b010_010_010_010;
    #1;
    if (Znarly !== 0) 
      $display("INCORRECT test2: Znarly expected 0, got %0d", Znarly);
    if (Zood !== 0) 
      $display("INCORRECT test2: Zood expected 0, got %0d", Zood);

    // Test 3: Znarly=0, Zood=4
    // master = T C O D (001_010_011_100), guess = O D T C (011_100_001_010)
    masterPattern <= 12'b001_010_011_100;
    Guess         <= 12'b011_100_001_010;
    #1;
    if (Znarly !== 0) 
      $display("INCORRECT test3: Znarly expected 0, got %0d", Znarly);
    if (Zood !== 4) 
      $display("INCORRECT test3: Zood expected 4, got %0d", Zood);

    // Test 4: Znarly=0, Zood=1
    // master = I Z D T = 101_110_100_001
    // guess  = T T C C = 001_001_010_010
    masterPattern <= 12'b101_110_100_001;
    Guess         <= 12'b001_001_010_010;
    #1;
    if (Znarly !== 0) 
      $display("INCORRECT test4: Znarly expected 0, got %0d", Znarly);
    if (Zood   !== 1) 
      $display("INCORRECT test4: Zood expected 1, got %0d", Zood);

    // Test 5: Znarly=1, Zood=2
    // master = I Z D T = 101_110_100_001
    // guess  = I O T Z = 101_011_001_110
    masterPattern <= 12'b101_110_100_001;
    Guess         <= 12'b101_011_001_110;
    #1;
    if (Znarly !== 1) $display("INCORRECT test5: Znarly expected 1, got %0d", Znarly);
    if (Zood   !== 2) $display("INCORRECT test5: Zood expected 2, got %0d", Zood);

    // Test 6: Znarly=4, Zood=0 -> game won
    // master = I Z D T = 101_110_100_001, guess = same
    masterPattern <= 12'b101_110_100_001;
    Guess         <= 12'b101_110_100_001;
    #1;
    if (Znarly !== 4) $display("INCORRECT test6: Znarly expected 4, got %0d", Znarly);
    if (Zood   !== 0) $display("INCORRECT test6: Zood expected 0, got %0d", Zood);

    #1 $finish;
  end
endmodule : grader_tb


module gradeItFSM
  (input  logic GradeIt, CanGrade,
   input logic clock, reset,
   output logic RoundOver);

  enum logic {IDLE = 1'b0, GRADE = 1'b1} cs, ns;
 
  always_comb begin
    case (cs)
      IDLE: begin
        ns = (GradeIt & CanGrade) ? GRADE : IDLE;
        RoundOver = 1'b0;
      end
      GRADE: begin
        ns = IDLE;
        RoundOver = 1'b1;
      end
      default: begin
        ns = IDLE;
        RoundOver = 1'b0;
      end
    endcase
  end

  always_ff @(posedge clock)
    if (reset) begin
      cs <= IDLE;
    end else begin
      cs <= ns;
    end
endmodule : gradeItFSM
