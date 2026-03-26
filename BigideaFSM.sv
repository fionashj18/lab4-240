`default_nettype none
module BigPictureDatapath
    (input  logic        clock, reset,
     input  logic [11:0] Guess,
     input  logic [2:0]  LoadShape,
     input  logic [1:0]  ShapeLocation,
     input  logic [1:0]  CoinValue,
     input  logic        CoinInserted,
     input  logic        StartGame,
     input  logic        GradeIt,
     input  logic        LoadShapeNow,
     output logic        gameWon,
     output logic [3:0]  Znarly,
     output logic [3:0]  Zood,
     output logic [3:0]  RoundNumber,
     output logic [3:0]  NumGames,
     output logic [11:0] masterPattern);

    logic shape_loading, drop_game, roundOver, clr_game;
    logic maxNumGames, finish_loading, can_start, max_rounds,
          znarly_win;

   

    BigPictureFSM fsm2 (.*);

    // masterPat
    masterPattern mp (
        .shapeLocation(ShapeLocation),
        .loadShape(LoadShape),
        .loadShapeNow(shape_loading),
        .CLOCK_100(clock),
        .reset,
        .masterPattern,
        .finishLoading(finish_loading)
    );

    logic circle, triangle, pentagon;
    assign circle   = CoinInserted & (CoinValue == 2'b01);
    assign triangle = CoinInserted & (CoinValue == 2'b10);
    assign pentagon = CoinInserted & (CoinValue == 2'b11);

    logic coin_drop;
    coinAcceptorFSM ca (
        .pentagon, .triangle, .circle,
        .clock, .reset,
        .drop(coin_drop),
        .credit()
    );

    // NumGames counter
    MagComp #(4) maxGamesComp (.A(NumGames), .B(4'd7), .AeqB(maxNumGames),
                               .AltB(), .AgtB());

    Counter #(4) numGamesCtr (.D(4'd0), .Q(NumGames),
                              .en((coin_drop & ~maxNumGames) | drop_game),
                              .load(1'b0), .clear(reset), .up(~drop_game),
                              .clock);

    logic canStart_AeqB, canStart_AgtB;
    MagComp #(4) canStartComp (.A(NumGames), .B(4'd1), .AeqB(canStart_AeqB),
                               .AltB(), .AgtB(canStart_AgtB));
    assign can_start = canStart_AeqB | canStart_AgtB;

    // Round counter
    Counter #(4) roundCtr (.D(4'd0), .Q(RoundNumber), .en(roundOver), .load(1'b0),
                           .clear(reset | clr_game), .up(1'b1), .clock);

    MagComp #(4) roundComp (.A(RoundNumber), .B(4'd8), .AeqB(max_rounds),
                            .AltB(), .AgtB());

    // grader
    grader g (
        .guess(Guess),
        .masterPattern,
        .GradeIt,
        .CLOCK_100(clock),
        .reset,
        .Znarly,
        .Zood,
        .Znarly_Win(znarly_win)
    );

endmodule : BigPictureDatapath

module BigPictureFSM
    (input  logic clock, reset,
    input  logic finish_loading,
    input  logic can_start,
    input  logic max_rounds,
    input  logic znarly_win,
    input  logic StartGame,
    input  logic GradeIt,
    input  logic LoadShapeNow,
    output logic roundOver,
    output logic shape_loading,
    output logic drop_game,
    output logic clr_game,
    output logic gameWon);

    enum logic [2:0] {IDLE, IN_GAME, GRADING, FINISH} currState, nextState;

    logic StartGame_bf, GradeIt_bf, LoadShapeNow_bf,
          startSeen, gradeItSeen, loadShapeNowSeen;
 
    assign startSeen = StartGame & ~StartGame_bf;
    assign gradeItSeen = GradeIt & ~GradeIt_bf;
    assign loadShapeNowSeen = LoadShapeNow & ~LoadShapeNow_bf;

    always_comb begin
        shape_loading = 1'b0;
        drop_game = 1'b0;
        clr_game = 1'b0;
        roundOver = 1'b0;
        gameWon = 1'b0;
        nextState     = currState;
        case (currState)
            IDLE: begin
                if (loadShapeNowSeen) begin
                    shape_loading = 1'b1;
                    nextState     = IDLE;
                end
                else if (startSeen & can_start & finish_loading & ~max_rounds) begin
                    drop_game = 1'b1;
                    roundOver = 1'b1;
                    nextState = IN_GAME;
                end
                else begin
                    nextState = IDLE;
                end
            end
 
            IN_GAME: begin
                if (gradeItSeen) begin
                    nextState = GRADING;
                end
                else begin
                    nextState = IN_GAME;
                end
            end
 
            GRADING: begin
                if (znarly_win | max_rounds) begin
                    gameWon   = znarly_win;
                    nextState = FINISH;
                end
                else begin
                    nextState = IN_GAME;
                end
            end
 
            FINISH: begin
                if (startSeen & gradeItSeen & loadShapeNowSeen) begin
                    clr_game = 1'b0;
                    nextState = IDLE;
                end
                else begin
                    nextState = FINISH;
                end
            end
 
            default: nextState = IDLE;
        endcase
    end
   
    always_ff @(posedge clock) begin
        if (reset) begin
            StartGame_bf    <= 1'b0;
            GradeIt_bf      <= 1'b0;
            LoadShapeNow_bf <= 1'b0;
        end
        else begin
            StartGame_bf    <= StartGame;
            GradeIt_bf      <= GradeIt;
            LoadShapeNow_bf <= LoadShapeNow;
        end
    end

    always_ff @(posedge clock)
        if (reset)
            currState <= IDLE;
        else
            currState <= nextState;

endmodule: BigPictureFSM

module BigPictureDatapath_tb;
  logic        clock, reset;
  logic [11:0] Guess;
  logic [2:0]  LoadShape;
  logic [1:0]  ShapeLocation;
  logic [1:0]  CoinValue;
  logic        CoinInserted;
  logic        StartGame;
  logic        GradeIt;
  logic        LoadShapeNow;
  logic        finish_loading, can_start, max_rounds, znarly_win, gameWon;
  logic [3:0]  Znarly, Zood, RoundNumber, NumGames;
  logic [11:0] masterPat_out;

  BigPictureDatapath dut (.*, .masterPattern(masterPat_out));

  initial begin
    clock = 0;
    forever #5 clock = ~clock;
  end

  initial begin
    $monitor($time,, "NumGames=%0d finish=%b can_start=%b Znarly=%0d Zood=%0d gameWon=%b",
             NumGames, finish_loading, can_start, Znarly, Zood, gameWon);

    // Initialize all inputs
    reset = 1; Guess = 12'b0; LoadShape = 3'b0; ShapeLocation = 2'b0;
    CoinValue = 2'b0; CoinInserted = 0; StartGame = 0;
    GradeIt = 0; LoadShapeNow = 0;
    @(posedge clock); @(posedge clock);
    reset = 0;
    @(posedge clock);

    // Test 1: Load master pattern T C O D
    LoadShape = 3'b001; ShapeLocation = 2'b00;
    LoadShapeNow = 1; @(posedge clock); LoadShapeNow = 0; @(posedge clock);

    LoadShape = 3'b010; ShapeLocation = 2'b01;
    LoadShapeNow = 1; @(posedge clock); LoadShapeNow = 0; @(posedge clock);

    LoadShape = 3'b011; ShapeLocation = 2'b10;
    LoadShapeNow = 1; @(posedge clock); LoadShapeNow = 0; @(posedge clock);

    LoadShape = 3'b100; ShapeLocation = 2'b11;
    LoadShapeNow = 1; @(posedge clock); LoadShapeNow = 0; @(posedge clock);
    #1;
    if (!finish_loading)
      $display("INCORRECT test1: expected finish_loading=1, got 0");
    else
      $display("CORRECT test1");

    // Test 2: Insert 4 circles -> NumGames should become 1
    //   CoinValue=01 (circle), pulse CoinInserted 4 times
    CoinValue <= 2'b01;
    CoinInserted <= 1;
    @(posedge clock);
    CoinInserted <= 0;
    @(posedge clock);
    CoinValue <= 2'b01;
    CoinInserted <= 1;
    @(posedge clock);
    CoinInserted <= 0;
    @(posedge clock);
    CoinValue <= 2'b01;
    CoinInserted <= 1;
    @(posedge clock);
    CoinInserted <= 0;
    @(posedge clock);
    CoinValue <= 2'b01;
    CoinInserted <= 1;
    @(posedge clock);
    CoinInserted <= 0;
    @(posedge clock);
    #1;
    if (NumGames != 4'd1)
      $display("INCORRECT test2: expected NumGames=1, got %0d", NumGames);
    else
      $display("CORRECT test2");

    // -------------------------------------------------------
    // Test 3: Start game, guess O D T C (010_001_100_011)
    //   vs master T C O D -> Znarly=0, Zood=4
    // -------------------------------------------------------
    StartGame = 1; @(posedge clock); StartGame = 0; @(posedge clock);
    Guess = 12'b010_001_100_011;
    GradeIt = 1; @(posedge clock); @(posedge clock);
    GradeIt = 0; @(posedge clock);
    #1;
    if (Znarly !== 4'd0 || Zood !== 4'd4)
      $display("INCORRECT test3: expected Znarly=0 Zood=4, got Znarly=%0d Zood=%0d",
               Znarly, Zood);
    else
      $display("CORRECT test3");

    // -------------------------------------------------------
    // Test 4: Guess T C O D (100_011_010_001) = exact match
    //   Expected: Znarly=4, Zood=0
    // -------------------------------------------------------
    Guess = 12'b100_011_010_001;
    GradeIt = 1; @(posedge clock); @(posedge clock);
    GradeIt = 0; @(posedge clock);
    #1;
    if (Znarly !== 4'd4 || Zood !== 4'd0)
      $display("INCORRECT test4: expected Znarly=4 Zood=0, got Znarly=%0d Zood=%0d",
               Znarly, Zood);
    else
      $display("CORRECT test4");

    #1 $finish;
  end
endmodule : BigPictureDatapath_tb