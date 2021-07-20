// Created by H. T. Vergos
// Revision 1.4

module SAMtest ();

  reg  str;
  reg  mode;
  reg  clk;
  reg  reset;
  wire msg;
  wire frame;
  integer seed;   		   // a seed for random variables
  integer idle_cycles;     // Configuration starts after some random idle_cycles
  integer key_length;      // This needs to be an integer in order for the Simulator to use it in
                           // computations. This is a limit of the specific simulator and NOT of Verilog.

  reg  [2:0] counter; 	   // counts the 4 clock cycles that n is loaded in SAM.
  reg  [9:0] counter2;	   // to count the bits of d 
  reg  [9:0] counter3;     // to count the bits of capsN 
                           // note that capsN is used instead of N

  reg  [3:0] n;
  reg  [7:0] d;            // Indicative for this example values used. They are not necessary though when 3 is assigned in n
  reg  [7:0] capsN;       // Provided here for future revisions

//SAM CUT (str, mode, clk, reset, msg, frame); 	// Once you have described SAM you need to uncomment this
                                                // You may need to change that if you have arranged I/Os in a different way
                                             	// or if you have named your module diferrently 


initial                    			// At initialisation all signals are inactive.
  begin                    			// SAM should therefore get in some weird DECODE stage
    clk        = 1'b0;
    str        = 1'b1;
    reset      = 1'b1;
    n          = 4'h3;    			// These are sample values. However if your circuit is configured  
    counter    = 3'h4; 				// correctly for these values you get a mark > 5.
    counter2   = 10'h008;
    counter3   = 10'h008;
    key_length = 8;
 #5 mode       = 1'b0;
    reset      = 1'b0;
#2  reset      = 1'b1;
  end


always #20 clk = !clk; // Our clock ticks here


// Configuration Starts Here


// Wait for a random (0 - 15) number of clock cycles
// Also assign random values to d and capsN
// Note that random returns an integer of 15 bits. Although d and capsN may need more or less
// these are more than enough for our example. Of course we will only program SAM with a subset
// of them.

initial
  begin
    seed        = $random(32434);
    idle_cycles = $random(seed - 21) % 16;
    d           = $random(seed +3);
    capsN       = $random(seed -5);
  end


// At next positive edge set MODE to 1. Turn it back to 0 once n, d and capsN have been sent.
initial
  begin
    # (40*idle_cycles +21)        mode = 1'b1;
    # (40*(n+(2*key_length)+1)+5) mode = 1'b0; // Extra cycle required for handling the two unmodelled edges 
                                               // that is, the one before transmission of n and 
						                       // the one after the last bit of capsN
  end 


// At every next negative edge the value of n is presented on the str line. 
// After n is done d and capsN follow. I have assumed MSB appears first.

always @(negedge clk)
    if (mode)  						// n appears just after mode goes high
      begin
        if (counter)
          begin
            str     <= n[counter-1];
            counter <= counter - 1;
          end 
         else if (counter2) 				// time for d
                begin
                  str      <= d[counter2-1];
                  counter2 <= counter2 - 1; 
                end
               else if (counter3) 			// time for capsN
                 begin
                   str      <= capsN[counter3-1]; 
                   counter3 <= counter3 - 1; 
                 end
      end


// That completes our configuration phase. By now your SAM should have its registers keeeping n, d, N 
// configured. You may want to add after this code straight comparisons between the random values 
// and those configured. This means that you may want to alter your FSM, in a way that once the config phase is
// over the configured values appear at new outputs that you would like this testbench to have access to.

endmodule

