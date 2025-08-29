/***************************************************/
/* ECE 327: Digital Hardware Systems - Spring 2025 */
/* Lab 4                                           */
/* MVM Control FSM                                 */
/***************************************************/

module ctrl # (
    parameter VEC_ADDRW = 8,
    parameter MAT_ADDRW = 9, 
    parameter VEC_SIZEW = VEC_ADDRW + 1,
    parameter MAT_SIZEW = MAT_ADDRW + 1
    
)(
    input  clk,
    input  rst,
    input  start,
    input  [VEC_ADDRW-1:0] vec_start_addr,
    input  [VEC_SIZEW-1:0] vec_num_words,
    input  [MAT_ADDRW-1:0] mat_start_addr,
    input  [MAT_SIZEW-1:0] mat_num_rows_per_olane,
    output [VEC_ADDRW-1:0] vec_raddr,
    output [MAT_ADDRW-1:0] mat_raddr,
    output accum_first,
    output accum_last,
    output ovalid,
    output busy
);

/******* Your code starts here *******/

// state defns
typedef enum logic {
    IDLE = 1'b0,
    COMPUTE = 1'b1
} state_t;

// state registers
state_t current_state, next_state;

logic [VEC_ADDRW-1:0] reg_vec_start_addr;
logic [VEC_SIZEW-1:0] reg_vec_num_words;
logic [MAT_ADDRW-1:0] reg_mat_start_addr;
logic [MAT_SIZEW-1:0] reg_mat_num_rows_per_olane;

// counters
logic [VEC_SIZEW-1:0] vec_word_counter;
logic [MAT_SIZEW-1:0] mat_row_counter;

// output registers
logic [VEC_ADDRW-1:0] reg_vec_raddr;
logic [MAT_ADDRW-1:0] reg_mat_raddr;
logic reg_accum_first;
logic reg_accum_last;
logic reg_ovalid;
logic reg_busy;

// fsm next state logic
always_comb begin
    case (current_state)
        IDLE: begin
            if (start)
                next_state = COMPUTE;
            else
                next_state = IDLE;
        end
        
        COMPUTE: begin
            // check if we finished all rows and all vector words
            if ((mat_row_counter == reg_mat_num_rows_per_olane - 1) && 
                (vec_word_counter == reg_vec_num_words - 1))
                next_state = IDLE;
            else
                next_state = COMPUTE;
        end
        
        default: next_state = IDLE;
    endcase
end

// fsm state register update
always_ff @(posedge clk) begin
    if (rst) begin
        current_state <= IDLE;
    end else begin
        current_state <= next_state;
    end
end

// main ctrl logic
always_ff @(posedge clk) begin
    if (rst) begin
        // reset all registers
        reg_vec_start_addr <= 0;
        reg_vec_num_words <= 0;
        reg_mat_start_addr <= 0;
        reg_mat_num_rows_per_olane <= 0;
        
        vec_word_counter <= 0;
        mat_row_counter <= 0;
        
        reg_vec_raddr <= 0;
        reg_mat_raddr <= 0;
        reg_accum_first <= 1'b0;
        reg_accum_last <= 1'b0;
        reg_ovalid <= 1'b0;
        reg_busy <= 1'b0;
        
    end else begin
        case (current_state)
            IDLE: begin
                if (start) begin
                    // capture input parameters
                    reg_vec_start_addr <= vec_start_addr;
                    reg_vec_num_words <= vec_num_words;
                    reg_mat_start_addr <= mat_start_addr;
                    reg_mat_num_rows_per_olane <= mat_num_rows_per_olane;
                    
                    // reset counters
                    vec_word_counter <= 0;
                    mat_row_counter <= 0;
                    
                    // start first computation
                    reg_vec_raddr <= vec_start_addr;
                    reg_mat_raddr <= mat_start_addr;
                    reg_accum_first <= 1'b1;
                    reg_accum_last <= (vec_num_words == 1);
                    reg_ovalid <= 1'b1;
                    reg_busy <= 1'b1;
                    
                end else begin
                    // stay in idle state
                    reg_accum_first <= 1'b0;
                    reg_accum_last <= 1'b0;
                    reg_ovalid <= 1'b0;
                    reg_busy <= 1'b0;
                end
            end
            
            COMPUTE: begin
                // always busy in compute state
                reg_busy <= 1'b1;
                reg_ovalid <= 1'b1;
                
                // update counters and addresses
                if (vec_word_counter == reg_vec_num_words - 1) begin
                    vec_word_counter <= 0;
                    mat_row_counter <= mat_row_counter + 1;
                    reg_vec_raddr <= reg_vec_start_addr;
                    reg_mat_raddr <= reg_mat_start_addr + (mat_row_counter + 1) * reg_vec_num_words;
                    

                    reg_accum_first <= 1'b1;
                    
                    // check if this is the last word of the last row
                    reg_accum_last <= (mat_row_counter == reg_mat_num_rows_per_olane - 1) && 
                                      (reg_vec_num_words == 1);
                    
                end else begin
                    // continue with current row
                    vec_word_counter <= vec_word_counter + 1;
                    
                    // increment addresses
                    reg_vec_raddr <= reg_vec_raddr + 1;
                    reg_mat_raddr <= reg_mat_raddr + 1;
                    reg_accum_first <= 1'b0;
                    reg_accum_last <= (vec_word_counter == reg_vec_num_words - 2);
                end
                
                if ((mat_row_counter == reg_mat_num_rows_per_olane - 1) && 
                    (vec_word_counter == reg_vec_num_words - 1)) begin
                    reg_busy <= 1'b0;
                end
            end
            
            default: begin
                reg_accum_first <= 1'b0;
                reg_accum_last <= 1'b0;
                reg_ovalid <= 1'b0;
                reg_busy <= 1'b0;
            end
        endcase
    end
end

assign vec_raddr = reg_vec_raddr;
assign mat_raddr = reg_mat_raddr;
assign accum_first = reg_accum_first;
assign accum_last = reg_accum_last;
assign ovalid = reg_ovalid;
assign busy = reg_busy;

/******* Your code ends here ********/

endmodule