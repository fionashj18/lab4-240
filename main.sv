// `default_nettype none

module BigPictureDatapath
    (input  logic        clock, reset, debug,
     input  logic [11:0] Guess,
     input  logic [2:0]  LoadShape,
     input  logic [1:0]  ShapeLocation,
     input  logic [1:0]  CoinValue,
     input  logic        CoinInserted,
     input  logic        StartGame,
     input  logic        GradeIt,
     input  logic        LoadShapeNow,
     output logic        GameWon,
     output logic [3:0]  Znarly,
     output logic [3:0]  Zood,
     output logic [3:0]  RoundNumber,
     output logic [3:0]  NumGames,
     output logic        CanGrade,
     output logic        clr,
     output logic [11:0] masterPattern);

    // dectecting rising edge to prevent the gradeItFSM 
    // from triggering multiple times
    logic gradeIt_prev, gradeIt_new;
    always_ff @(posedge clock)
        if (reset)
            gradeIt_prev <= 1'b0;
        else
            gradeIt_prev <= GradeIt;
    assign gradeIt_new = GradeIt & ~gradeIt_prev;

    logic RoundOver;
    gradernew grading(.Guess, .masterPattern, .Zood, .Znarly, .GameWon);
    gradeItFSM gradefsm(.GradeIt(gradeIt_new), .CanGrade, .clock, 
                        .reset, .RoundOver);

    logic MaxRounds;
    Round numrounds(.RoundOver, .reset, .clr, .clock, .RoundNumber, .MaxRounds);
    
    logic FinishLoading;
    masterPatternLoad MPL (.ShapeLocation, .LoadShape, .LoadShapeNow, .clock, 
                           .clr(reset | clr), .masterPattern, .FinishLoading);

    logic CanStart;
    NumGameCounter numgam (.clock, .clr, .CoinInserted, .StartGame, .CoinValue,
                           .NumGames, .CanStart, .reset);

    bpdFSM bpd(.CoinInserted, .CanStart, .StartGame, .FinishLoading, .MaxRounds, 
               .GameWon, .reset, .clock, .CanGrade, .clr);
    

endmodule : BigPictureDatapath

module Round(
    input  logic RoundOver, reset, clr, clock,
    output logic [3:0] RoundNumber,
    output logic       MaxRounds
);
    Counter #(4) roundCtr (.D(4'd0), .Q(RoundNumber), .en(RoundOver), 
                      .load(1'b0), .clear(reset | clr), .up(1'b1), .clock);

    MagComp #(4) roundComp (.A(RoundNumber), .B(4'd8), .AeqB(MaxRounds),
                            .AltB(), .AgtB());
endmodule : Round

module NumGameCounter(
    input  logic       clock, clr, reset,
    input  logic       CoinInserted, StartGame,
    input  logic [1:0] CoinValue,
    output logic [3:0] NumGames,
    output logic       CanStart
);
    
    logic circle, triangle, pentagon;
    assign circle   = CoinInserted & (CoinValue == 2'b01);
    assign triangle = CoinInserted & (CoinValue == 2'b10);
    assign pentagon = CoinInserted & (CoinValue == 2'b11);

    logic CoinDrop, MaxNumGames;
    coinAcceptorFSM ca (.pentagon, .triangle, .circle, .clock, .reset,
                        .drop(CoinDrop), .credit());

    Counter #(4) numGamesCtr (.D(4'd0), .Q(NumGames),
                              .en((~MaxNumGames & (CoinDrop | StartGame))),
                              .load(1'b0), .clear(clr), .up(~StartGame),
                              .clock);
    
    MagComp #(4) maxGamesComp (.A(NumGames), .B(4'd7), .AeqB(MaxNumGames),
                               .AltB(), .AgtB());
    
    logic eqGames, gtGames;
    MagComp #(4) max (.A(NumGames), .B(4'd1), .AeqB(eqGames),
                               .AltB(), .AgtB(gtGames));
    assign CanStart = eqGames | gtGames;

endmodule : NumGameCounter


module bpdFSM(
    input  logic CoinInserted, CanStart, StartGame, FinishLoading, 
    input  logic MaxRounds, GameWon, reset, clock,
    output logic CanGrade, clr
);

    enum logic [1:0] {IDLE = 2'b00, GUESSING = 2'b01, GAMEOVER = 2'b10} cs, ns;

    always_comb begin
        case (cs)
          IDLE: begin
            if (CanStart & StartGame & FinishLoading) begin
                    ns = GUESSING;
                    CanGrade = 1'b1;
                    clr = 1'b0;
                end else begin
                    ns = IDLE;
                    CanGrade = 1'b0;
                    clr = 1'b0;
                end
          end
          GUESSING: begin
            if (~MaxRounds & ~GameWon) begin
                ns = GUESSING;
                CanGrade = 1'b1;
                clr = 1'b0;
            end else begin
                // MaxRounds | GameWon
                ns = GAMEOVER;
                CanGrade = 1'b0;
                clr = 1'b0;
            end
          end
          GAMEOVER: begin
            if (reset) 
              ns = IDLE;
              clr = 1'b0;
          end
          default: begin
            ns = IDLE;
            CanGrade = 1'b0;
            clr = 1'b0;
          end
        endcase
    end

    always_ff @(posedge clock)
        if (reset)
            cs = IDLE;
        else
            cs = ns;
endmodule : bpdFSM