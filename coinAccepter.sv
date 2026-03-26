//`default_nettype none
module coinAcceptorFSM
    (output logic [3:0] credit,
     output logic drop,
     input  logic circle, triangle, pentagon,
     input  logic clock , reset);

     enum logic [2:0] {C0, C1, C2, C3, D0, D1, D2, D3} currState, nextState;
     logic circle_bf, triangle_bf, pentagon_bf;
     logic circleSeen, triangleSeen, pentagonSeen;

     assign circleSeen = circle & ~circle_bf;
     assign triangleSeen = triangle & ~triangle_bf;
     assign pentagonSeen = pentagon & ~pentagon_bf;
    // Increase bitwidth if you need more than eight states
    // Don 't specify state encoding values
    // Use sensible state names
    // Next state logic is defined here . You are basically
    // transcribing the " next - state " column of the state transition
    // table into a SystemVerilog case statement .
     always_comb begin
        case (currState)
            C0 : begin
                if (circleSeen) nextState = C1;
                else if (triangleSeen) nextState = C3;
                else if (pentagonSeen) nextState = D1;
                else nextState = C0;
                end

            C1 : begin
                if (circleSeen) nextState = C2;
                else if (triangleSeen) nextState = D0;
                else if (pentagonSeen) nextState = D2;
                else nextState = C1;
                end

            C2 : begin
                if (circleSeen) nextState = C3;
                else if (triangleSeen) nextState = D1;
                else if (pentagonSeen) nextState = D3;
                else nextState = C2;
                end

            C3 : begin
                if (circleSeen) nextState = D0;
                else if (triangleSeen) nextState = D2;
                else if (pentagonSeen) nextState = D0;
                else nextState = C3;
                end

            D0 : begin
                if (circleSeen) nextState = C1;
                else if (triangleSeen) nextState = C3;
                else if (pentagonSeen) nextState = D1;
                else nextState = C0;
                end

            D1 : begin
                if (circleSeen) nextState = C2;
                else if (triangleSeen) nextState = D0;
                else if (pentagonSeen) nextState = D2;
                else nextState = C1;
                end

            D2 : begin
                if (circleSeen) nextState = C3;
                else if (triangleSeen) nextState = D1;
                else if (pentagonSeen) nextState = D3;
                else nextState = C2;
                end

            D3 : begin
                if (circleSeen) nextState = D0;
                else if (triangleSeen) nextState = D2;
                else if (pentagonSeen) nextState = D0;
                else nextState = C3;
                end

            default : begin nextState = C0 ; end
        endcase
     end

    // Output logic defined here . You are basically transcribing
    // the output column of the state transition table into a
    // SystemVerilog case statement .
    // Remember , if this is a Moore machine , this logic should only
    // depend on the current state . Mealy also involves inputs .
    always_comb begin
        credit = 4'b0000 ; drop = 1'b0 ;
        unique case (currState)
            C0 : begin
                drop = 1'b0 ;
                credit = 4'b0000 ; end
            C1 : begin
                drop = 1'b0 ;
                credit = 4'b0001 ; end

            C2 : begin
                drop = 1'b0 ;
                credit = 4'b0010 ; end

            C3 : begin
                drop = 1'b0 ;
                credit = 4'b0011 ; end

            D0 : begin
                drop = 1'b1 ;
                credit = 4'b0000 ; end

            D1 : begin
                drop = 1'b1 ;
                credit = 4'b0001 ; end

            D2 : begin
                drop = 1'b1 ;
                credit = 4'b0010 ; end

            D3 : begin
                drop = 1'b1 ;
                credit = 4'b0011 ; end
    // ...
    // no default statement needed , due to unique case
        endcase
    end
    // Synchronous state update described here as an always_ff block .
    // In essence , these are your flip flops that will hold the state
    // This doesn 't do anything interesting except to capture the new
    // state value on each clock edge . Also , synchronous reset .

    //This clock cycle properly updates the logic so that there is one
    // clock cycle in which the seen coin can be asserted and not repeat
    // when the signal lasts multiple clock cycles
    always_ff @(posedge clock) begin
        if (reset) begin
            circle_bf   <= 1'b0;
            triangle_bf <= 1'b0;
            pentagon_bf <= 1'b0;
        end
        else begin
            circle_bf   <= circle;
            triangle_bf <= triangle;
            pentagon_bf <= pentagon;
        end
    end

    always_ff @(posedge clock)
        if (reset)
            currState <= C0; // or whatever the reset state is
        else
            currState <= nextState;

endmodule : coinAcceptorFSM
