module SAM(str, mode, clk, reset, msg, frame);
	//parameter n=3;
	
	input mode,clk, reset;			 
	input str;				
	output reg [7:0]msg;
	output frame;				
		
	reg current_state;
	reg next_state;
	
	parameter[1:0]
		start = 0,											//initial 
		configure = 1,											//config
		normal = 2;											//messege decode
	
	reg all_complete = 1'b0;										//all samples done
	
	reg [3:0]read_data_0;											//n
	reg [7:0]read_data_1;											//d
	reg [7:0]read_data_2;											//N
		
	
	always@(negedge clk)begin 	
		if(reset == 1'b0) 
			current_state <= start; 								//initial
		else if(reset == 1'b1 & mode == 1'b1) 
			current_state <= configure; 								//config  
		else if(reset == 1'b1 & mode == 1'b0 & all_complete == 1'b1)
			current_state <= normal;       								//normal
		else  
			current_state <= start; 								//initial
	end


//config state...

	reg s0_sample_complete;											//n
	reg s1_sample_complete;											//d
	reg s2_sample_complete;											//N
	
	reg [2:0]count0;											//n
	reg [3:0]count1;											//d
	reg [3:0]count2;											//N
	
	
	always@(posedge clk)
		if(~reset)
			begin
				count0 <= 3'h4;									//initialize counter for n
				count1 <= 4'h8;									//initialize counter for d
				count2 <= 4'h8;									//initiallize counter for N
				
				s0_sample_complete <= 1'b0;							//flag for n (complete)
				s1_sample_complete <= 1'b0;							//flag for d (complete)
				s2_sample_complete <= 1'b0;							//flag for N (complete)
			end			
		else if(mode) begin										//norm mode
			if(s0_sample_complete == 0) begin			
				if(count0) begin
					read_data_0[3:0] <= {str};						//load the first 4bits from str
					count0 <= count0 - 1;
				end
				 
				else begin									//check if all samples are done
					if(all_complete)begin
						s0_sample_complete <= 1'b0;					//initialize 
						count0 <= 3'h4;							//initialize
					end
					else s0_sample_complete <= 1'b1;					//set s0_sample_complete to 1
				end	
			end
			else if(s1_sample_complete == 0)begin		
				if(count1) begin
					read_data_1[7:0] <= {str};						//load next 8bits from str 
					count1 <= count1 - 1;
				end
				 
				else begin
					if(all_complete)begin							//check if all samples are done
						s1_sample_complete <= 1'b0;					//initialize
						count1 <= 4'h8;							//initialize
					end
					else s1_sample_complete <= 1'b1;					//set s1_sample_complete to 1
				end
			end
			else if(s2_sample_complete)begin
				if(count2) begin
					read_data_2[7:0] <= {str};						//load next 8bits from str
					count2 <= count2 - 1;
				end
				 
				else begin		
					if(all_complete)begin							//check if all samples are done
						s2_sample_complete <= 1'b0;					//initialize
						count2 <= 4'h8;							//initialize
					end
					else s2_sample_complete <= 1'b1;					//set s2_sample_complete to 1
				end
			end
		end
		else begin											//case that reset!=0 and mode!=1
			current_state <= start;						
		end
		
		
		
	
	always@(negedge clk)											//if all samples are done -> update all_complete flag to 1
		if(!reset) 
			all_complete <= 1'b0;
		else if(s0_sample_complete == 1'b1 & s1_sample_complete == 1'b1 & s2_sample_complete <= 1'h1)
			all_complete <= 1'b1;
			

//norm state...
			
	reg count3;
	reg num_of_ones;
	reg num_of_zeros;
	reg capped = 0;

	always@(posedge clk)
		if(~reset) begin
			count3 <= 0'b0;
			num_of_ones <= 0'b0;
			num_of_zeros <= 0'b0;
		end
		else if(~mode)begin
			if(count3 < 6'b001010 || count3 > 6'b111100)begin
				count3 <= 1'b0;
			end
			else begin
				if(str == 1'b1)begin
					num_of_ones <=  num_of_ones + 1;
					count3 <= count3 + 1;
				end
				else begin
					num_of_zeros <= num_of_zeros + 1;
					count3 <= count3 + 1;
				end	
			end
		end

	reg [7:0]final;
	
	always@(posedge clk)
		while(capped < 4'b1000) begin
			if(reset & ~mode)begin
				if(num_of_ones > num_of_zeros)begin
					final[7:0] <= 1'b1;
				end
				else if(num_of_ones < num_of_zeros)begin
					final[7:0] <= 1'b0;
				end
			end
			capped <= capped + 1;
		end
		
endmodule 