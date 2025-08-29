/***************************************************/
/* ECE 327: Digital Hardware Systems - Spring 2025 */
/* Lab 4                                           */
/* Matrix Vector Multiplication (MVM) Module       */
/***************************************************/

module mvm # (
    parameter IWIDTH = 8,
    parameter OWIDTH = 32,
    parameter MEM_DATAW = IWIDTH * 8,
    parameter VEC_MEM_DEPTH = 256,
    parameter VEC_ADDRW = $clog2(VEC_MEM_DEPTH),
    parameter MAT_MEM_DEPTH = 512,
    parameter MAT_ADDRW = $clog2(MAT_MEM_DEPTH),
    parameter NUM_OLANES = 8
)(
    input clk,
    input rst,
    input [MEM_DATAW-1:0] i_vec_wdata,
    input [VEC_ADDRW-1:0] i_vec_waddr,
    input i_vec_wen,
    input [MEM_DATAW-1:0] i_mat_wdata,
    input [MAT_ADDRW-1:0] i_mat_waddr,
    input [NUM_OLANES-1:0] i_mat_wen,
    input i_start,
    input [VEC_ADDRW-1:0] i_vec_start_addr,
    input [VEC_ADDRW:0] i_vec_num_words,
    input [MAT_ADDRW-1:0] i_mat_start_addr,
    input [MAT_ADDRW:0] i_mat_num_rows_per_olane,
    output o_busy,
    output [OWIDTH-1:0] o_result [0:NUM_OLANES-1],
    output o_valid
);

/******* Your code starts here *******/

// localparams for VEC_SIZEW and MAT_SIZEW used later
localparam VEC_SIZEW = VEC_ADDRW + 1;
localparam MAT_SIZEW = MAT_ADDRW + 1;


logic [VEC_ADDRW-1:0] vec_raddr;
logic [MAT_ADDRW-1:0] mat_raddr;
logic accum_first;
logic accum_last;
logic ctrl_ovalid;
logic ctrl_busy;


logic [MEM_DATAW-1:0] vec_rdata;
logic [MEM_DATAW-1:0] mat_rdata [0:NUM_OLANES-1];
logic [OWIDTH-1:0] dot_result [0:NUM_OLANES-1];
logic dot_ovalid [0:NUM_OLANES-1];
logic [OWIDTH-1:0] accum_result [0:NUM_OLANES-1];
logic accum_ovalid [0:NUM_OLANES-1];

// pipelining registers for timing alignment
logic ctrl_ovalid_1;
logic accum_first_1, accum_first_2, accum_first_3, accum_first_4, accum_first_5, accum_first_6;
logic accum_last_1, accum_last_2, accum_last_3, accum_last_4, accum_last_5, accum_last_6;


always_ff @(posedge clk) begin
    if (rst) begin
        ctrl_ovalid_1 <= 0;
        accum_first_1 <= 0;
        accum_first_2 <= 0;
        accum_first_3 <= 0;
        accum_first_4 <= 0;
        accum_first_5 <= 0;
        accum_first_6 <= 0;
        accum_last_1 <= 0;
        accum_last_2 <= 0;
        accum_last_3 <= 0;
        accum_last_4 <= 0;
        accum_last_5 <= 0;
        accum_last_6 <= 0;
    end else begin
        // stage 1: account for memory read latency
        ctrl_ovalid_1 <= ctrl_ovalid;
        accum_first_1 <= accum_first;
        accum_last_1 <= accum_last;
        
        // stages 2-6: account for dot8 pipeline depth
        accum_first_2 <= accum_first_1;
        accum_last_2 <= accum_last_1;
        
        accum_first_3 <= accum_first_2;
        accum_last_3 <= accum_last_2;
        
        accum_first_4 <= accum_first_3;
        accum_last_4 <= accum_last_3;
        
        accum_first_5 <= accum_first_4;
        accum_last_5 <= accum_last_4;
        
        accum_first_6 <= accum_first_5;
        accum_last_6 <= accum_last_5;
        
    end
end

// vec_mem instantiation
mem #(
    .DATAW(MEM_DATAW),
    .DEPTH(VEC_MEM_DEPTH)
) vec_memory (
    .clk(clk),
    .wdata(i_vec_wdata),
    .waddr(i_vec_waddr),
    .wen(i_vec_wen),
    .raddr(vec_raddr),
    .rdata(vec_rdata)
);

// generate NUM_OLANES output lanes
genvar i;
generate
    for (i = 0; i < NUM_OLANES; i++) begin : output_lane
        
        // matrix memory for this olane
        mem #(
            .DATAW(MEM_DATAW),
            .DEPTH(MAT_MEM_DEPTH)
        ) mat_memory (
            .clk(clk),
            .wdata(i_mat_wdata),
            .waddr(i_mat_waddr),
            .wen(i_mat_wen[i]),
            .raddr(mat_raddr),
            .rdata(mat_rdata[i])
        );
        
        // dot8 unit for this olane
        dot8 #(
            .IWIDTH(IWIDTH),
            .OWIDTH(OWIDTH)
        ) dot_unit (
            .clk(clk),
            .rst(rst),
            .vec0(vec_rdata),
            .vec1(mat_rdata[i]),
            .ivalid(ctrl_ovalid_1),
            .result(dot_result[i]),
            .ovalid(dot_ovalid[i])
        );
        
        // accum for this olane
        accum #(
            .DATAW(OWIDTH),
            .ACCUMW(OWIDTH)
        ) accumulator (
            .clk(clk),
            .rst(rst),
            .data(dot_result[i]),
            .ivalid(dot_ovalid[i]),
            .first(accum_first_6),
            .last(accum_last_6),
            .result(accum_result[i]),
            .ovalid(accum_ovalid[i])
        );
        
    end
endgenerate

// ctrl instantiation
ctrl #(
    .VEC_ADDRW(VEC_ADDRW),
    .MAT_ADDRW(MAT_ADDRW),
    .VEC_SIZEW(VEC_SIZEW),
    .MAT_SIZEW(MAT_SIZEW)
) controller (
    .clk(clk),
    .rst(rst),
    .start(i_start),
    .vec_start_addr(i_vec_start_addr),
    .vec_num_words(i_vec_num_words),
    .mat_start_addr(i_mat_start_addr),
    .mat_num_rows_per_olane(i_mat_num_rows_per_olane),
    .vec_raddr(vec_raddr),
    .mat_raddr(mat_raddr),
    .accum_first(accum_first),
    .accum_last(accum_last),
    .ovalid(ctrl_ovalid),
    .busy(ctrl_busy)
);


assign o_busy = ctrl_busy;
assign o_valid = accum_ovalid[0];
assign o_result = accum_result;

/******* Your code ends here ********/

endmodule