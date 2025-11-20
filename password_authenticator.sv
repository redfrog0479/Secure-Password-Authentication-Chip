// Secure Password Authenticator

`timescale 1ns / 1ps

module Discovery_Project (
    input  logic        clk,         // Clock input
    input  logic        rst_n,       // Active low reset input
    input  logic        enter_btn,   // Button to submit password input
    input  logic [15:0] password_in, // Password input
    
    output logic        led_success, // Success output
    output logic        led_fail,    // Fail output
    output logic        led_locked   // System locked output
);

    // Constants
    // Target Hash = Rotate_Left_4[(0x1234 ^ 0xABBA) + 0x6767] = 0F52
    localparam [15:0] TARGET_HASH = 16'h0F52;
    localparam int    MAX_TRIALS  = 3;

    // States
    typedef enum logic [2:0] {
        S_IDLE    = 3'b000,
        S_CHECK   = 3'b001,
        S_GRANTED = 3'b010,
        S_DENIED  = 3'b011,
        S_LOCKED  = 3'b100
    } state_t;
	 
    state_t current_state;
	 state_t next_state;

    logic [15:0] computed_hash;
    logic [1:0]  fail_counter;
    logic        inc_fail_cnt;
    logic        clr_fail_cnt;

    // Hashing logic
    // Hash = Rotate_Left_4[(Input ^ 0xABBA) + 0x6767]
    always_comb begin
        logic [15:0] intermediate;
        intermediate = (password_in ^ 16'hABBA) + 16'h6767;
        computed_hash = {intermediate[11:0], intermediate[15:12]};
    end

    // State register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            current_state <= S_IDLE;
        else 
            current_state <= next_state;
    end

    // Fail counter
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fail_counter <= 0;
        end else begin
            if (clr_fail_cnt)
                fail_counter <= 0;
            else if (inc_fail_cnt && (fail_counter < MAX_TRIALS))
                fail_counter <= fail_counter + 1;
        end
    end

    // Next state logic
    always_comb begin
        next_state   = current_state;
        inc_fail_cnt = 0;
        clr_fail_cnt = 0;
        led_success  = 0;
        led_fail     = 0;
        led_locked   = 0;

        case (current_state)
            S_IDLE: begin
                if (fail_counter >= MAX_TRIALS)
                    next_state = S_LOCKED;
                else if (enter_btn) 
                    next_state = S_CHECK;
            end

            S_CHECK: begin
                if (computed_hash == TARGET_HASH)
                    next_state = S_GRANTED;
                else
                    next_state = S_DENIED;
            end

            S_GRANTED: begin
                led_success  = 1;
                clr_fail_cnt = 1; 
                if (!enter_btn)
						  next_state = S_IDLE;
            end

            S_DENIED: begin
                led_fail = 1;
                if (!enter_btn) begin
                    inc_fail_cnt = 1;
                    next_state = S_IDLE;
                end
            end

            S_LOCKED: begin
                led_locked = 1;
            end

            default:
					 next_state = S_IDLE;
        endcase
    end

endmodule
