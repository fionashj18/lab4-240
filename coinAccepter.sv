`default_nettype none
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




/*

module coinAcceptorFSM
    (output logic drop,
     output logic q2, q1, q0,
     input logic pentagon, triangle, circle,
     input logic [1:0] coin,
     input logic clock,
     input logic reset);

    enum logic [2:0] {S0, S1, S2, S3, S4, S5, S6, S7} currState, nextState;

    // Store previous state
    logic prevCircle, prevTriangle, prevPentagon;
    logic check_circle, check_triangle, check_pentagon;

    // Check for rising edge
    assign check_circle   = (~prevCircle   & circle);
    assign check_triangle = (~prevTriangle & triangle);
    assign check_pentagon = (~prevPentagon & pentagon);

    // Assign q2, q1, q0
    assign {q2, q1, q0} = currState;

    // If we see a rising edge, update value. Otherwise, it stays the same.
    always_comb begin
        nextState = currState;

        if (check_circle | check_triangle | check_pentagon) begin
            case (currState)
                S0, S4: begin
                    if      (check_circle)   nextState = S1;
                    else if (check_triangle)  nextState = S3;
                    else if (check_pentagon)  nextState = S5; 
                end
                S1, S5: begin
                    if      (check_circle)   nextState = S2; 
                    else if (check_triangle)  nextState = S4;
                    else if (check_pentagon)  nextState = S6;
                end
                S2, S6: begin
                    if      (check_circle)   nextState = S3; 
                    else if (check_triangle)  nextState = S5; 
                    else if (check_pentagon)  nextState = S7; 
                end
                S3, S7: begin
                    if      (check_circle)   nextState = S4; 
                    else if (check_triangle)  nextState = S6; 
                    else if (check_pentagon)  nextState = S4; 
                end
                default: nextState = S0;
            endcase
        end
    end


    always_comb begin
        unique case (currState)
            S0: begin credit = 4'd0; drop = 1'b0; end
            S1: begin credit = 4'd1; drop = 1'b0; end
            S2: begin credit = 4'd2; drop = 1'b0; end
            S3: begin credit = 4'd3; drop = 1'b0; end
            S4: begin credit = 4'd0; drop = 1'b1; end
            S5: begin credit = 4'd1; drop = 1'b1; end
            S6: begin credit = 4'd2; drop = 1'b1; end
            S7: begin credit = 4'd3; drop = 1'b1; end
        endcase
    end

    // State reset logic, and update nextstate using clockedge dectection
    always_ff @(posedge clock) begin
        if (reset) begin
            currState    <= S0;
            prevCircle   <= 1'b0;
            prevTriangle <= 1'b0;
            prevPentagon <= 1'b0;
        end else begin
            currState    <= nextState;
            prevCircle   <= circle;
            prevTriangle <= triangle;
            prevPentagon <= pentagon;
        end
    end

endmodule : coinAccepterFSM
*/