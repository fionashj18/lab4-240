/** FILE
 *  chip_interface.sv
 *
 *  BRIEF
 *  This is a chip interface couples mastermindVGA.sv with the 40MHz clk
 *  to drive the VGA and a 200 MHz clk to drive the VGA to hdmi input.
 *  Includes HDMI_TX & clk_wizard for a proper HDMI output
 *  for the AMD FPGA.
 *
 *  This includes a couple 'TO DO:'s that students should fill out
 *  to properly connect with their mastermind
 *
 *  AUTHOR
 *  Angie Shere (ashere)
 *
 */

module ChipInterface (
    input  logic        CLOCK_100,
    input  logic [ 3:0] BTN,
    input  logic [15:0] SW,
    output logic [ 3:0] D2_AN, D1_AN,
    output logic [ 7:0] D2_SEG, D1_SEG,
    output logic        hdmi_clk_n, hdmi_clk_p,
    output logic [ 2:0] hdmi_tx_p, hdmi_tx_n,
    output logic [15:0] LD
    );

    //TO DO:
    // - Include your game here!
    // - Declare connecting wires/signals to/from your game
    // - Use those wires/signals to connect to the MastermindVGA and
    //   EightSevenSegmentDisplays modules below

                               
  // Big-picture datapath + FSM
  logic [3:0] Znarly, Zood, RoundNumber, NumGames;
  logic [11:0] masterPattern;
  logic gameWon;

  // Track which of the 4 shape positions have been loaded.
  // BTN[3] acts as LoadShapeNow until all positions are loaded,
  // then it acts as GradeIt.
  logic [3:0] positionsLoaded;
  logic       allLoaded;

  assign allLoaded = &positionsLoaded;

  always_ff @(posedge CLOCK_100) begin
    if (BTN[0] || BTN[2])           // reset or StartGame clears tracking
      positionsLoaded <= 4'b0;
    else if (BTN[3] && !allLoaded)  // LoadShapeNow: mark this position loaded
      positionsLoaded[SW[4:3]] <= 1'b1;
  end

  // Prevent the same BTN[3] press that loaded the 4th shape from
  // immediately triggering GradeIt. Require BTN[3] to be released
  // at least once after allLoaded before grading is allowed.
  logic btn3Released;
  always_ff @(posedge CLOCK_100) begin
    if (BTN[0] || BTN[2])
      btn3Released <= 1'b0;
    else if (!allLoaded)
      btn3Released <= 1'b0;
    else if (!BTN[3])               // BTN[3] released while allLoaded
      btn3Released <= 1'b1;
  end

  logic gradeIt, loadShapeNow;
  assign gradeIt      = BTN[3] & allLoaded & btn3Released;
  assign loadShapeNow = BTN[3] & ~allLoaded;

  BigPictureDatapath bigDP (
    .clock(CLOCK_100),
    .reset(BTN[0]),
    .Guess(SW[11:0]),
    .LoadShape(SW[2:0]),
    .ShapeLocation(SW[4:3]),
    .CoinValue(SW[15:14]),
    .CoinInserted(BTN[1]),
    .StartGame(BTN[2]),
    .GradeIt(gradeIt),
    .LoadShapeNow(loadShapeNow),
    .Znarly,
    .Zood,
    .RoundNumber,
    .NumGames,
    .gameWon(LD[0]),
    .masterPattern(masterPattern)
  );

/*
 *  BEWARE CHANGING CODE BELOW THIS LINE !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
 *
 *  You will need to connect your signals to these modules by changing what
 *  is written in the ( ... ) parenthesis places.  You shouldn't have to make
 *  any other changes than those connections.
 */

    // Don't change these signals
    logic [7:0] VGA_R, VGA_G, VGA_B;
    logic       VGA_BLANK_N, VGA_CLK, VGA_SYNC_N;
    logic       VGA_VS, VGA_HS;
    logic       reset_sync;

    MastermindVGA mmVGA(.clk_40MHz,
                        .VGA_R,
                        .VGA_G,
                        .VGA_B,
                        .VGA_BLANK_N,
                        .VGA_CLK,
                        .VGA_SYNC_N,
                        .VGA_VS,
                        .VGA_HS,
                        .reset(reset_sync),
                        .numGames(NumGames),
                        .loadNumGames(1'b1),
                        .roundNumber(RoundNumber),
                        .guess(SW[11:0]),
                        .loadGuess(gradeIt),
                        .znarly(Znarly),
                        .zood(Zood),
                        .clearGame(BTN[0]),
                        .masterPattern(masterPattern),
                        .displayMasterPattern(SW[13]),
                        .loadZnarlyZood(gradeIt)
                       );


    EightSevenSegmentDisplays display (
    .HEX7(4'd0), .HEX6(4'd0), .HEX5(4'd0), .HEX4(4'd0),
    .HEX3(Znarly),
    .HEX2(Zood),
    .HEX1(RoundNumber),
    .HEX0(NumGames),
    .CLOCK_100,
    .reset(reset_sync),
    .dec_points(8'b0),
    .blank(8'b0),
    .D2_AN, .D1_AN,
    .D2_SEG, .D1_SEG
  );

     Synchronizer sync_reset(.async(BTN[0]), 
                             .clock(clk_40MHz), 
                             .sync(reset_sync)
                            );
     assign LD[15:1] = 15'b0;                   
                        

/*
 *  DO NOT EDIT CODE BELOW THIS LINE !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
 *  If you do, the Zorgmeister will Zzzzzt you!
 */

    logic clk_40MHz, clk_200MHz;
    logic locked;
    
    // 2 clk freq outputs
    clk_wiz_0 clk_wiz (
        .clk_out1(clk_40MHz),
        .clk_out2(clk_200MHz),
        .reset(1'b0), 
        .locked(locked),
        .clk_in1(CLOCK_100)
    );

    //convert sigs from VGA to HDMI converter
    hdmi_tx_0 vga_to_hdmi (
        //clk and reset
        .pix_clk(clk_40MHz),
        .pix_clkx5(clk_200MHz),
        .pix_clk_locked(locked),
    
        .rst(reset_sync),

        //color and sync Signals
        .red(VGA_R),
        .green(VGA_G),
        .blue(VGA_B),

        .hsync(VGA_HS),
        .vsync(VGA_VS),
        .vde(VGA_BLANK_N),

        //differential outputs
        .TMDS_CLK_P(hdmi_clk_p),          
        .TMDS_CLK_N(hdmi_clk_n),          
        .TMDS_DATA_P(hdmi_tx_p),        
        .TMDS_DATA_N(hdmi_tx_n)          
    );

endmodule : ChipInterface