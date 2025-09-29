`timescale 1ns/1ns
`include "../src/top.sv"

module top_tb;

    logic clk = 0;
    logic RGB_R, RGB_G, RGB_B;
    
    // Analog values for plotting on gtkwave
    real red_analog = 0;
    real green_analog = 0;
    real blue_analog = 0;
    
    // PWM duty cycle tracking - tracking how long each stayed on
    logic [7:0] red_duty = 0;
    logic [7:0] green_duty = 0;
    logic [7:0] blue_duty = 0;
    logic [7:0] pwm_count = 0;
    
    // monitor variables
    top dut (
        .clk(clk),
        .RGB_R(RGB_R),
        .RGB_G(RGB_G),
        .RGB_B(RGB_B)
    );
    
    // Clock generation (41.67 ns period for 12 MHz)
    always #41.67 clk = ~clk;
    
    // own new PWM counter to track when each cycle starts/ends
    always @(posedge clk) begin
        pwm_count <= pwm_count + 1;
    end
    
    // Measure PWM duty cycles over each PWM period
    always @(posedge clk) begin
        if (pwm_count == 255) begin
            red_analog <= red_duty;
            green_analog <= green_duty;
            blue_analog <= blue_duty;
            red_duty <= 0;
            green_duty <= 0;
            blue_duty <= 0;
        end else begin
            // Accumulate duty cycle - figure out how many of the period each one was on and calcualte RGB value to plot from there.
            if (!RGB_R) red_duty <= red_duty + 1;
            if (!RGB_G) green_duty <= green_duty + 1;
            if (!RGB_B) blue_duty <= blue_duty + 1;
        end
    end
    
    // Main simulation
    initial begin
        $dumpfile("top.vcd"); //create recording file
        $dumpvars(0, top_tb); //record all
        
        // Add analog signals to waveform
        $dumpvars(0, red_analog);
        $dumpvars(0, green_analog);
        $dumpvars(0, blue_analog);
                
        // Simulate for 1.2 seconds, full second plus more
        #1200000000;
        
        $finish;
    end

endmodule