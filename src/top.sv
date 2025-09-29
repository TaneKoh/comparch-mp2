module top(
    input logic clk,        // 12 MHz clock
    output logic RGB_R,     // Red LED - Active Low
    output logic RGB_G,     // Green LED - Active Low
    output logic RGB_B      // Blue LED - Active Low
);

    // Clock+timing parameters
    localparam CLK_FREQ = 12_000_000; // clock
    localparam PWM_RESOLUTION = 8;  // 8-bit PWM means there are 256 levels
    localparam PWM_MAX = (1 << PWM_RESOLUTION) - 1;  // caps out at 255
    localparam PWM_CYCLES = 256;  // PWM period = 256 cycles - so pwm cant go over that
    localparam DEGREES_MAX = 360;
    localparam CYCLES_PER_DEGREE = CLK_FREQ / DEGREES_MAX;  // cycles per degree for 1 second full cycle - 360 degrees, 12 million cycles

    // FSM States used to track
    // pwm count and degree count for the brightness level and the degree we're at
    typedef enum logic [1:0] {
        STATE_PWM_COUNT,
        STATE_DEGREE_COUNT,
        STATE_HSV_CALC,
        STATE_PWM_OUTPUT
    } state_t;

    logic [PWM_RESOLUTION-1:0] pwm_counter = 0;
    logic [PWM_RESOLUTION-1:0] red_pwm_value, green_pwm_value, blue_pwm_value;
    logic [31:0] degree_counter = 0;
    logic [8:0] current_degree = 0;
    state_t current_state = STATE_PWM_COUNT;
    state_t next_state;

    // establishing fsm state transition
    always_ff @(posedge clk) begin
        current_state <= next_state;
    end
    
    always_comb begin //more fsm logic
        case (current_state)
            STATE_PWM_COUNT: begin
                // with PWM counting, check if we need to add one degree too
                if (degree_counter == CYCLES_PER_DEGREE - 1) begin
                    next_state = STATE_DEGREE_COUNT;
                end else begin
                    next_state = STATE_PWM_COUNT;
                end
            end
            
            STATE_DEGREE_COUNT: begin
                // After degree changes, make sure to check color numbers
                next_state = STATE_HSV_CALC;
            end
            
            STATE_HSV_CALC: begin
                // After HSV color calc, update PWM outputs
                next_state = STATE_PWM_OUTPUT;
            end
            
            STATE_PWM_OUTPUT: begin
                // Return to PWM counter
                next_state = STATE_PWM_COUNT;
            end
            
            default: begin
                next_state = STATE_PWM_COUNT;
            end
        endcase
    end
    
    // FSM Logic
    always_ff @(posedge clk) begin
        case (current_state)
            STATE_PWM_COUNT: begin
                // PWM counter continuously increasing with clock
                pwm_counter <= pwm_counter + 1;                
                // Increment degree counter - counts to 12million/360 over and over again to count degrees
                if (degree_counter == CYCLES_PER_DEGREE - 1) begin
                    degree_counter <= 0;
                end else begin
                    degree_counter <= degree_counter + 1;
                end
            end
            
            STATE_DEGREE_COUNT: begin
                // Update current degree - updates which degree its at every degree-second (1/360).
                // maybe could have been condensed into one state variable but dgaf lowkey.
                if (current_degree == DEGREES_MAX - 1) begin
                    current_degree <= 0;
                end else begin
                    current_degree <= current_degree + 1;
                end
            end
            
            STATE_HSV_CALC: begin
                // HSV to RGB conversion based on current degree
                // Red channel - for each part of the plot, given a different value, calculated using degree and PWM max.
                if (current_degree < 60) begin
                    red_pwm_value <= PWM_MAX;
                end else if (current_degree < 120) begin
                    red_pwm_value <= PWM_MAX - ((current_degree - 60) * PWM_MAX / 60);
                end else if (current_degree < 240) begin
                    red_pwm_value <= 0;
                end else if (current_degree < 300) begin
                    red_pwm_value <= (current_degree - 240) * PWM_MAX / 60;
                end else begin
                    red_pwm_value <= PWM_MAX;
                end
                
                // Green channel - same math
                if (current_degree < 60) begin
                    green_pwm_value <= current_degree * PWM_MAX / 60;
                end else if (current_degree < 180) begin
                    green_pwm_value <= PWM_MAX;
                end else if (current_degree < 240) begin
                    green_pwm_value <= PWM_MAX - ((current_degree - 180) * PWM_MAX / 60);
                end else begin
                    green_pwm_value <= 0;
                end
                
                // Blue channel - same ish
                if (current_degree < 120) begin
                    blue_pwm_value <= 0;
                end else if (current_degree < 180) begin
                    blue_pwm_value <= (current_degree - 120) * PWM_MAX / 60;
                end else if (current_degree < 300) begin
                    blue_pwm_value <= PWM_MAX;
                end else begin
                    blue_pwm_value <= PWM_MAX - ((current_degree - 300) * PWM_MAX / 60);
                end
            end
            
            STATE_PWM_OUTPUT: begin
                // ensuring timing between the previous changes and output.
            end
        endcase
    end
    
    // PWM output generation (active low) - Combinational output
    // the ***_pwm_value changes with degree, pwm_counter changes with clock, so lots of
    // individual blinks slowly change in ratio over time.
    assign RGB_R = (pwm_counter > red_pwm_value) ? 1'b1 : 1'b0;
    assign RGB_G = (pwm_counter > green_pwm_value) ? 1'b1 : 1'b0;
    assign RGB_B = (pwm_counter > blue_pwm_value) ? 1'b1 : 1'b0;

endmodule