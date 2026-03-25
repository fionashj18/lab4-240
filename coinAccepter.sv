`default_nettype none
module coinAcceptorFSM
    (output logic [3:0] credit,
     output logic drop,
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

endmodule : coinAcceptorFSM
