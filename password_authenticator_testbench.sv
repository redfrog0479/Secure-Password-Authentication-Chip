// Secure Password Authenticator Testbench

`timescale 1ns / 1ps

module Discovery_Project_Testbench;
    // I/O signals
    logic        clk;
    logic        rst_n;
    logic        enter_btn;
    logic [15:0] password_in;
    logic        led_success;
    logic        led_fail;
    logic        led_locked;

    // Instantiate Device Under Test (DUT)
    Discovery_Project dut (
        .clk(clk),
        .rst_n(rst_n),
        .enter_btn(enter_btn),
        .password_in(password_in),
        .led_success(led_success),
        .led_fail(led_fail),
        .led_locked(led_locked)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
	 
	 // Helper signals to catch LED pulses
	 logic        saw_success;
	 logic        saw_fail;
	 
	 // Logic to catch LED pulses
	 always @(posedge clk) begin
		  if (!rst_n) begin
				saw_success <= 0;
				saw_fail    <= 0;
		  end else begin
				if (led_success)
					 saw_success <= 1;
				if (led_fail)
					 saw_fail    <= 1;
		  end
	 end
	 
    // Button press task
    task press_enter;
        begin
            @(posedge clk);
            enter_btn = 1;
            #20;
            @(posedge clk);
            enter_btn = 0;
            #20;
        end
    endtask

    // Simulation
    initial begin
        rst_n = 0;
        enter_btn = 0;
        password_in = 16'h0000;
        
		  #50;
		  
        rst_n = 1;
		  saw_success = 0;
		  saw_fail = 0;
        
        // 1. Test success (Password 0x1234)
        $display("Test 1: Entering correct password (0x1234)...");
        password_in = 16'h1234;
        press_enter();
        
        if (saw_success)
				$display(">> TEST PASSED: Unlocked!");
        else
				$display(">> TEST FAILED: Did not unlock.");
				
        #50;

        // 2. Test failure and lockout (Password 0xFFFF)
        $display("Test 2: Entering incorrect password (0xFFFF) 3 times...");
        password_in = 16'hFFFF;

        repeat(3) begin
            press_enter();
            if (saw_fail)
					 $display(">> Incorrect password detected.");
        end

        #20;
		  
        if (led_locked)
				$display(">> TEST PASSED: System locked.");
        else
				$display(">> TEST FAILED: System did not lock.");

        $stop;
    end

endmodule
