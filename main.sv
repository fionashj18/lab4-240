`default_nettype none

module ChipInterface (
  output logic [7:0] D2_SEG, D1_SEG,
  output logic [3:0] D2_AN, D1_AN,
  output logic [15:0] LD,
  input  logic [15:0] SW,
  input  logic [3:0]  BTN,
  input  logic        CLOCK_100
);

  // BTN[0] is async reset
  logic reset;
  assign reset = BTN[0];

  // Synchronize all other asynchronous button inputs
  logic CoinInserted_sync, StartGame_sync, GradeIt_sync;
  logic [1:0] CoinValue_sync;

  Synchronizer #(1) syncCoin  (.async(BTN[1]),  .clock(CLOCK_100), .sync(CoinInserted_sync));
  Synchronizer #(1) syncStart (.async(BTN[2]),  .clock(CLOCK_100), .sync(StartGame_sync));
  Synchronizer #(1) syncGrade (.async(BTN[3]),  .clock(CLOCK_100), .sync(GradeIt_sync));
  Synchronizer #(1) syncCV0   (.async(SW[14]),  .clock(CLOCK_100), .sync(CoinValue_sync[0]));
  Synchronizer #(1) syncCV1   (.async(SW[15]),  .clock(CLOCK_100), .sync(CoinValue_sync[1]));

  //--------------------------------------------------------------------
  // Coin accepter FSM (myAbstractFSM from coinAccepter.sv)
  // Decode CoinValue + CoinInserted into per-denomination signals
  //--------------------------------------------------------------------
  logic circle, triangle, pentagon;
  assign circle   = CoinInserted_sync & (CoinValue_sync == 2'b01);
  assign triangle = CoinInserted_sync & (CoinValue_sync == 2'b10);
  assign pentagon = CoinInserted_sync & (CoinValue_sync == 2'b11);

  logic drop;
  logic q2, q1, q0;

  coinAcceptorFSM coinFSM (
    .circle,
    .triangle,
    .pentagon,
    .coin(CoinValue_sync),
    .clock(CLOCK_100),
    .reset,
    .drop,
    .q2, .q1, .q0
  );

  //--------------------------------------------------------------------
  // NumGames counter: increment on rising edge of drop (game paid),
  //                   decrement when BigPictureFSM starts a game
  //--------------------------------------------------------------------
  logic drop_prev, dropRising;
  always_ff @(posedge CLOCK_100, posedge reset)
    if (reset) drop_prev <= 1'b0;
    else       drop_prev <= drop;
  assign dropRising = drop & ~drop_prev;

  logic [3:0] NumGames;
  logic can_start;
  assign can_start = (NumGames != 4'd0);

  logic drop_game; // driven by BigPictureFSM below

  logic numGames_inc, numGames_dec;
  assign numGames_inc = dropRising      & (NumGames < 4'd7);
  assign numGames_dec = drop_game       & (NumGames > 4'd0);

  Counter #(4) numGamesCnt (
    .D(4'd0),
    .en(numGames_inc | numGames_dec),
    .clear(reset),
    .load(1'b0),
    .clock(CLOCK_100),
    .up(numGames_inc),
    .Q(NumGames)
  );

  // Master pattern loader
  logic [11:0] masterPat;
  logic finishLoading;

  masterPattern mpInst (
    .shapeLocation(SW[4:3]),
    .loadShape(SW[2:0]),
    .loadShapeNow(GradeIt_sync),
    .CLOCK_100,
    .reset,
    .masterPattern(masterPat),
    .finishLoading
  );

  // Grader
  logic [3:0] Znarly, Zood;
  logic Znarly_Win;

  grader grInst (
    .guess(SW[11:0]),
    .masterPattern(masterPat),
    .GradeIt(GradeIt_sync),
    .CLOCK_100,
    .reset,
    .Znarly,
    .Zood,
    .Znarly_Win
  );

  //--------------------------------------------------------------------
  // Round counter: cleared when a new game starts (roundOver),
  //               incremented on each rising edge of GradeIt
  //--------------------------------------------------------------------
  logic [3:0] RoundNumber;
  logic max_rounds;
  assign max_rounds = (RoundNumber >= 4'd8);

  logic GradeIt_prev_r, gradeItRising;
  always_ff @(posedge CLOCK_100, posedge reset)
    if (reset) GradeIt_prev_r <= 1'b0;
    else       GradeIt_prev_r <= GradeIt_sync;
  assign gradeItRising = GradeIt_sync & ~GradeIt_prev_r;

  logic roundOver; // driven by BigPictureFSM below

  Counter #(4) roundCnt (
    .D(4'd0),
    .en(gradeItRising),
    .clear(roundOver | reset),
    .load(1'b0),
    .clock(CLOCK_100),
    .up(1'b1),
    .Q(RoundNumber)
  );

  //--------------------------------------------------------------------
  // Big-picture FSM
  //--------------------------------------------------------------------
  logic shape_loading, clr_game, gameWon;

  BigPictureFSM bigFSM (
    .clock(CLOCK_100),
    .reset,
    .finish_loading(finishLoading),
    .can_start,
    .max_rounds,
    .znarly_win(Znarly_Win),
    .StartGame(StartGame_sync),
    .GradeIt(GradeIt_sync),
    .LoadShapeNow(GradeIt_sync),   // BTN[3] doubles as LoadShapeNow
    .shape_loading,
    .drop_game,
    .roundOver,
    .clr_game,
    .gameWon
  );

  // 7-segment displays
  EightSevenSegmentDisplays display (
    .HEX7(4'd0), .HEX6(4'd0), .HEX5(4'd0), .HEX4(4'd0),
    .HEX3(Znarly),
    .HEX2(Zood),
    .HEX1(RoundNumber),
    .HEX0(NumGames),
    .CLOCK_100,
    .reset,
    .dec_points(8'b0),
    .blank(8'b1111_0000),
    .D2_AN, .D1_AN,
    .D2_SEG, .D1_SEG
  );

  // LD[0] = GameWon
  assign LD = {15'b0, gameWon};

endmodule : ChipInterface
