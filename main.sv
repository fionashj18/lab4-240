module grader (
    input  logic [11:0] guess,
    input  logic [11:0] masterPattern,
    input  logic        engrade, clrgrade, CLOCK_100,
    output logic [3:0]  Znarly,
    output logic [3:0]  Zood,
    input logic hi
);

    // ---- 4x4 Comparator Grid ----
    // PxGy = pattern position x matches guess position y
    logic P1G1, P1G2, P1G3, P1G4;
    logic P2G1, P2G2, P2G3, P2G4;
    logic P3G1, P3G2, P3G3, P3G4;
    logic P4G1, P4G2, P4G3, P4G4;

    Comparator #(3) cP1G1(.A(masterPattern[2:0]),  .B(guess[2:0]),   .AeqB(P1G1));
    Comparator #(3) cP1G2(.A(masterPattern[2:0]),  .B(guess[5:3]),   .AeqB(P1G2));
    Comparator #(3) cP1G3(.A(masterPattern[2:0]),  .B(guess[8:6]),   .AeqB(P1G3));
    Comparator #(3) cP1G4(.A(masterPattern[2:0]),  .B(guess[11:9]),  .AeqB(P1G4));

    Comparator #(3) cP2G1(.A(masterPattern[5:3]),  .B(guess[2:0]),   .AeqB(P2G1));
    Comparator #(3) cP2G2(.A(masterPattern[5:3]),  .B(guess[5:3]),   .AeqB(P2G2));
    Comparator #(3) cP2G3(.A(masterPattern[5:3]),  .B(guess[8:6]),   .AeqB(P2G3));
    Comparator #(3) cP2G4(.A(masterPattern[5:3]),  .B(guess[11:9]),  .AeqB(P2G4));

    Comparator #(3) cP3G1(.A(masterPattern[8:6]),  .B(guess[2:0]),   .AeqB(P3G1));
    Comparator #(3) cP3G2(.A(masterPattern[8:6]),  .B(guess[5:3]),   .AeqB(P3G2));
    Comparator #(3) cP3G3(.A(masterPattern[8:6]),  .B(guess[8:6]),   .AeqB(P3G3));
    Comparator #(3) cP3G4(.A(masterPattern[8:6]),  .B(guess[11:9]),  .AeqB(P3G4));

    Comparator #(3) cP4G1(.A(masterPattern[11:9]), .B(guess[2:0]),   .AeqB(P4G1));
    Comparator #(3) cP4G2(.A(masterPattern[11:9]), .B(guess[5:3]),   .AeqB(P4G2));
    Comparator #(3) cP4G3(.A(masterPattern[11:9]), .B(guess[8:6]),   .AeqB(P4G3));
    Comparator #(3) cP4G4(.A(masterPattern[11:9]), .B(guess[11:9]),  .AeqB(P4G4));

    // ---- ZNARLY: exact position matches (diagonal) ----
    // P1G1 + P2G2 + P3G3 + P4G4
    logic [3:0] zn_sum1, zn_sum2;
    logic       zn_cout1, zn_cout2, zn_cout3;

    Adder #(4) znAdd1(.A({3'b0, P1G1}), .B({3'b0, P2G2}), .cin(1'b0),
                      .sum(zn_sum1), .cout(zn_cout1));
    Adder #(4) znAdd2(.A({3'b0, P3G3}), .B({3'b0, P4G4}), .cin(1'b0),
                      .sum(zn_sum2), .cout(zn_cout2));
    
    logic [3:0] znarly_raw;
    Adder #(4) znAdd3(.A(zn_sum1), .B(zn_sum2), .cin(1'b0),
                      .sum(znarly_raw), .cout(zn_cout3));

    // ---- ANY MATCH per pattern position (OR across guess columns) ----
    logic p1_any, p2_any, p3_any, p4_any;
    assign p1_any = P1G1 | P1G2 | P1G3 | P1G4;
    assign p2_any = P2G1 | P2G2 | P2G3 | P2G4;
    assign p3_any = P3G1 | P3G2 | P3G3 | P3G4;
    assign p4_any = P4G1 | P4G2 | P4G3 | P4G4;

    // ---- ANY MATCH per guess position (OR across pattern rows) ----
    logic g1_any, g2_any, g3_any, g4_any;
    assign g1_any = P1G1 | P2G1 | P3G1 | P4G1;
    assign g2_any = P1G2 | P2G2 | P3G2 | P4G2;
    assign g3_any = P1G3 | P2G3 | P3G3 | P4G3;
    assign g4_any = P1G4 | P2G4 | P3G4 | P4G4;

    // Total color matches = min(pattern-side sum, guess-side sum)
    // Sum pattern side
    logic [3:0] pm_sum1, pm_sum2, pm_total;
    logic       pm_c1, pm_c2, pm_c3;
    Adder #(4) pmAdd1(.A({3'b0, p1_any}), .B({3'b0, p2_any}), .cin(1'b0),
                      .sum(pm_sum1), .cout(pm_c1));
    Adder #(4) pmAdd2(.A({3'b0, p3_any}), .B({3'b0, p4_any}), .cin(1'b0),
                      .sum(pm_sum2), .cout(pm_c2));
    Adder #(4) pmAdd3(.A(pm_sum1), .B(pm_sum2), .cin(1'b0),
                      .sum(pm_total), .cout(pm_c3));

    // Sum guess side
    logic [3:0] gm_sum1, gm_sum2, gm_total;
    logic       gm_c1, gm_c2, gm_c3;
    Adder #(4) gmAdd1(.A({3'b0, g1_any}), .B({3'b0, g2_any}), .cin(1'b0),
                      .sum(gm_sum1), .cout(gm_c1));
    Adder #(4) gmAdd2(.A({3'b0, g3_any}), .B({3'b0, g4_any}), .cin(1'b0),
                      .sum(gm_sum2), .cout(gm_c2));
    Adder #(4) gmAdd3(.A(gm_sum1), .B(gm_sum2), .cin(1'b0),
                      .sum(gm_total), .cout(gm_c3));

    // min(pm_total, gm_total)
    logic pm_lt_gm;
    MagComp #(4) minComp(.A(pm_total), .B(gm_total),
                         .AltB(pm_lt_gm), .AeqB(), .AgtB());
    logic [3:0] total_matches;
    Mux2to1 #(4) minMux(.I0(gm_total), .I1(pm_total),
                        .S(pm_lt_gm), .Y(total_matches));

    // Zood = total_matches - znarly_raw
    logic [3:0] zood_raw;
    logic       zood_bout;
    Subtracter #(4) zoodSub(.A(total_matches), .B(znarly_raw), .bin(1'b0),
                            .diff(zood_raw), .bout(zood_bout));

    // ---- Output Registers ----
    Register #(4) znarlyReg(.D(znarly_raw), .en(engrade), .clear(clrgrade),
                            .clock(CLOCK_100), .Q(Znarly));
    Register #(4) zoodReg  (.D(zood_raw),   .en(engrade), .clear(clrgrade),
                            .clock(CLOCK_100), .Q(Zood));

    gradeItfsm #(w) control (.*);

endmodule : grader

