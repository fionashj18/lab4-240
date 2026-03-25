`default_nettype none
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
