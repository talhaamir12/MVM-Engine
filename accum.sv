/***************************************************/
/* ECE 327: Digital Hardware Systems - Spring 2025 */
/* Lab 4                                           */
/* Accumulator Module                              */
/***************************************************/

module accum # (
    parameter DATAW = 32,
    parameter ACCUMW = 32
)(
    input  clk,
    input  rst,
    input  signed [DATAW-1:0] data,
    input  ivalid,
    input  first,
    input  last,
    output signed [ACCUMW-1:0] result,
    output ovalid
);

/******* Your code starts here *******/

// internal accumulation register
logic signed [ACCUMW-1:0] accum_reg;
logic ovalid_reg;

always_ff @(posedge clk) begin
    if (rst) begin
        accum_reg <= 0;
        ovalid_reg <= 1'b0;
    end else begin
        // clear ovalid unless its the last input
        ovalid_reg <= 1'b0;
        
        if (ivalid) begin
            if (first) begin
                // start new accumulation
                accum_reg <= data;
            end else begin
                // continue accumulation
                accum_reg <= accum_reg + data;
            end
            
            // assert ovalid if this is the last input in the accumulation
            if (last) begin
                ovalid_reg <= 1'b1;
            end
        end
    end
end

assign result = accum_reg;
assign ovalid = ovalid_reg;

/******* Your code ends here ********/

endmodule