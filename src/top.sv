module top(
    input logic clk,        // 12 MHz input clock
    output logic RGB_R,     // Red LED (Active Low)
    output logic RGB_G,     // Green LED (Active Low)
    output logic RGB_B      // Blue LED (Active Low)
);
// this sets the output pins to be the 3 LEDs contained within the chip (together makes different colors)
// and also defines the clock pin as an input and a digital signal.
    
    // Clock and timing parameters
    localparam CLK_FREQ  = 12_000_000; 
    // 12 MHz clock which is specified in the pcf file - 12000000 times means 1 sec
    localparam COUNT_MAX = CLK_FREQ / 6; 
    // all those cycles = 1 sec divided by 6 -> 1/6 sec per state
    // localparam means its fixed at compilation and wont change

    // State definitions for the color cycle
    typedef enum logic [2:0] {
        STATE_RED,
        STATE_YELLOW,
        STATE_GREEN,
        STATE_CYAN,
        STATE_BLUE,
        STATE_MAGENTA
    } state_t;
    // creates new data type state_t which can have 6 different values (per color). it assigns each color a value (0-5)

    // Internal registers
    logic [$clog2(COUNT_MAX)-1:0] counter;
    state_t state;
    // this is the memory that the circuit needs to operate
    // it needs to count up to 2000000 - COUNTMAX, until change to different color
    // state is designed to hold one of the values of state_t, which makes sense - shifting to different colors

    // Sequential logic for the counter and state machine
    always_ff @(posedge clk) begin
        if (counter == COUNT_MAX - 1) begin
            counter <= '0;
            if (state == STATE_MAGENTA) begin
                state <= STATE_RED;
            end else begin
                state <= state_t'(state + 1);
            end
        end else begin
            counter <= counter + 1;
        end
    end
// the actual counter loop: when counter reaches 1999999, 1 before the max, it sets to 0 and state is updated to the next one.
// unless the state is the last one (magenta) - then it's returned to red. syntax is state_t'(state+1) in order to make sure addition is treated as state_t type.

    // Combinational logic for RGB output - no memory needed
    // active = LOW, meaning that 1 means the LED is off.
    always_comb begin
        // default (all LEDs off)
        {RGB_R, RGB_G, RGB_B} = 3'b111;
        case (state)
            STATE_RED:     {RGB_R, RGB_G, RGB_B} = 3'b011;
            STATE_YELLOW:  {RGB_R, RGB_G, RGB_B} = 3'b001;
            STATE_GREEN:   {RGB_R, RGB_G, RGB_B} = 3'b101;
            STATE_CYAN:    {RGB_R, RGB_G, RGB_B} = 3'b100;
            STATE_BLUE:    {RGB_R, RGB_G, RGB_B} = 3'b110;
            STATE_MAGENTA: {RGB_R, RGB_G, RGB_B} = 3'b010;
            default:       {RGB_R, RGB_G, RGB_B} = 3'b111;
        endcase
    end
endmodule