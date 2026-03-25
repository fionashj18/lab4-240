`default_nettype none

module ChipInterface (
  output logic [7:0] D2_SEG, D1_SEG,
  output logic [3:0] D2_AN, D1_AN,
  output logic [15:0] LD,
  input  logic [15:0] SW,
  input  logic [3:0]  BTN,
  input  logic        CLOCK_100
);

  // BTN[0]: async reset
  logic reset;
  assign reset = BTN[0];

  // Synchronize all other asynchronous button inputs
  logic CoinInserted_sync, StartGame_sync, GradeIt_sync;
  logic [1:0] CoinValue_sync;

  Synchronizer #(1) syncCoin  (.async(BTN[1]),  .clock(CLOCK_100), 
                               .sync(CoinInserted_sync));
  Synchronizer #(1) syncStart (.async(BTN[2]),  .clock(CLOCK_100), 
                               .sync(StartGame_sync));
  Synchronizer #(1) syncGrade (.async(BTN[3]),  .clock(CLOCK_100), 
                               .sync(GradeIt_sync));
  Synchronizer #(1) syncCV0   (.async(SW[14]),  .clock(CLOCK_100), 
                               .sync(CoinValue_sync[0]));
  Synchronizer #(1) syncCV1   (.async(SW[15]),  .clock(CLOCK_100), 
                               .sync(CoinValue_sync[1]));

  // Big-picture datapath + FSM
  logic [3:0] Znarly, Zood, RoundNumber, NumGames;
  logic [11:0] masterPat;
  logic GameWon;

  BigPictureDatapath bigDP (
    .clock(CLOCK_100),
    .reset,
    .Guess(SW[11:0]),
    .LoadShape(SW[2:0]),
    .ShapeLocation(SW[4:3]),
    .CoinValue(CoinValue_sync),
    .CoinInserted(CoinInserted_sync),
    .StartGame(StartGame_sync),
    .GradeIt(GradeIt_sync),
    .LoadShapeNow(GradeIt_sync),
    .Znarly,
    .Zood,
    .RoundNumber,
    .NumGames,
    .GameWon,
    .masterPattern(masterPat)
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

  assign LD = {15'b0, GameWon};

endmodule : ChipInterface
