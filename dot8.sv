/***************************************************/
/* ECE 327: Digital Hardware Systems - Spring 2025 */
/* Lab 4                                           */
/* 8-Lane Dot Product Module                       */
/***************************************************/

module dot8 # (
    parameter IWIDTH = 8,
    parameter OWIDTH = 32
)(
    input clk,
    input rst,
    input signed [8*IWIDTH-1:0] vec0,
    input signed [8*IWIDTH-1:0] vec1,
    input ivalid,
    output signed [OWIDTH-1:0] result,
    output ovalid
);

/******* Your code starts here *******/

logic signed [IWIDTH-1:0] a0, a1, a2, a3, a4, a5, a6, a7;
logic signed [IWIDTH-1:0] b0, b1, b2, b3, b4, b5, b6, b7;
logic signed [2*IWIDTH+1:0] mul_1, mul_2, mul_3, mul_4, mul_5, mul_6, mul_7, mul_8;
logic signed [2*IWIDTH+2:0] f_add_1, f_add_2, f_add_3, f_add_4;
logic signed [2*IWIDTH+3:0] s_add_1, s_add_2;
logic signed [OWIDTH-1:0] final_result;
logic ro_valid1, ro_valid2, ro_valid3, ro_valid4, ro_valid5;


always_ff @ (posedge clk) begin
    if (rst) begin
        // reset all pipeline registers
        ro_valid1 <= 0;
        ro_valid2 <= 0;
        ro_valid3 <= 0;
        ro_valid4 <= 0;
        ro_valid5 <= 0;

        mul_1 <= 0;
        mul_2 <= 0;
        mul_3 <= 0;
        mul_4 <= 0;
        mul_5 <= 0;
        mul_6 <= 0;
        mul_7 <= 0;
        mul_8 <= 0;

        f_add_1 <= 0;
        f_add_2 <= 0;
        f_add_3 <= 0;
        f_add_4 <= 0;

        s_add_1 <= 0;
        s_add_2 <= 0;

        final_result <= 0;

    end else begin

        // stage 1: initial stage
        ro_valid1 <= ivalid;

        a0 <= vec0[8*IWIDTH-1:7*IWIDTH];
        a1 <= vec0[7*IWIDTH-1:6*IWIDTH];
        a2 <= vec0[6*IWIDTH-1:5*IWIDTH];
        a3 <= vec0[5*IWIDTH-1:4*IWIDTH];
        a4 <= vec0[4*IWIDTH-1:3*IWIDTH];
        a5 <= vec0[3*IWIDTH-1:2*IWIDTH];
        a6 <= vec0[2*IWIDTH-1:1*IWIDTH];
        a7 <= vec0[1*IWIDTH-1:0*IWIDTH];

        b0 <= vec1[8*IWIDTH-1:7*IWIDTH];
        b1 <= vec1[7*IWIDTH-1:6*IWIDTH];
        b2 <= vec1[6*IWIDTH-1:5*IWIDTH];
        b3 <= vec1[5*IWIDTH-1:4*IWIDTH];
        b4 <= vec1[4*IWIDTH-1:3*IWIDTH];
        b5 <= vec1[3*IWIDTH-1:2*IWIDTH];
        b6 <= vec1[2*IWIDTH-1:1*IWIDTH];
        b7 <= vec1[1*IWIDTH-1:0*IWIDTH];

        // stage 2: multiplication
        ro_valid2 <= ro_valid1;

        mul_1 <= a0 * b0;
        mul_2 <= a1 * b1;
        mul_3 <= a2 * b2;
        mul_4 <= a3 * b3;
        mul_5 <= a4 * b4;
        mul_6 <= a5 * b5;
        mul_7 <= a6 * b6;
        mul_8 <= a7 * b7;

        // stage 3: first addition stage
        ro_valid3 <= ro_valid2;

        f_add_1 <= mul_1 + mul_2;
        f_add_2 <= mul_3 + mul_4;
        f_add_3 <= mul_5 + mul_6;
        f_add_4 <= mul_7 + mul_8;

        // stage 4: second addition stage
        ro_valid4 <= ro_valid3;

        s_add_1 <= f_add_1 + f_add_2;
        s_add_2 <= f_add_3 + f_add_4;

        // stage 5: final addition (result)
        ro_valid5 <= ro_valid4;

        final_result <= s_add_1 + s_add_2;

    end
end


assign result = final_result;
assign ovalid = ro_valid5;

/******* Your code ends here ********/

endmodule