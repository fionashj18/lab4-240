`default_nettype none
module BigPictureDatapath
    (input  logic clock, reset,
    input  logic [11:0] Guess,
    input  logic [2:0]  LoadShape,
    input  logic [1:0]  ShapeLocation,
    input  logic [1:0]  CoinValue,
    input  logic CoinInserted,
    input  logic shape_loading,
    input  logic drop_game,
    input  logic roundOver,
    input logic StartGame,
    input  logic clr_game,
    output logic finish_loading,
    output logic can_start,
    output logic max_rounds,
    output logic znarly_win,
    output logic [3:0] Znarly,
    output logic [3:0] Zood,
    output logic [3:0] RoundNumber,
    output logic [3:0] NumGames,
    output logic [11:0] masterPattern);

    BigPictureFSM fsm2(.*)

    logic canStart_AeqB, canStart_AgtB; 

    Counter #(4) numGamesCtr (.D(4'd0), .Q(NumGames), 
                              .en(~maxNumGames & (startgame | drop)),
                              .load(1'b0), .clear(reset), .up(drop_game), .clock);
    Synchronizer syn (.sync(StartGame), .async(StartGame), .clock);

    MagComp #(4) canStartComp (.A(NumGames), .B(4'd1), .AeqB(canStart_AeqB), .AltB(),
                               .AgtB(canStart_AgtB));
    assign can_start = canStart_AeqB | canStart_AgtB;

    MagComp #(4) maxGamesComp (.A(NumGames), .B(4'd9), .AeqB(maxNumGames), .AltB(), .AgtB());

    Counter #(4) roundCtr (.D(4'd0), .Q(RoundNumber), .en(roundOver), .load(1'b0),
                           .clear(reset | clr_game), .up(1'b1), .clock);
 
    MagComp #(4) roundComp (.A(RoundNumber), .B(4'd8), .AeqB(max_rounds), .AltB(), .AgtB());
    

endModule: BigPictureDatapath
module BigPictureFSM
    (input  logic clock, reset,
    input  logic finish_loading,
    input  logic can_start,
    input  logic max_rounds,
    input  logic znarly_win,
    input  logic StartGame,
    input  logic GradeIt,
    input  logic LoadShapeNow,
    output logic shape_loading,
    output logic drop_game,
    output logic roundOver,
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
