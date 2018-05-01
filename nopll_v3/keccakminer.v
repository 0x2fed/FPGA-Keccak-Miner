module keccakminer(

    input wire  osc_clk,
  	input 		RxD,
	output 	   	TxD,	  
	output      [3:0] LED	  
     );
	  
	//// Clocking	  
	wire hash_clk;
	wire uart_clk;	

	assign hash_clk = osc_clk;	
	assign uart_clk = osc_clk;		
		
	assign LED[3:0] = nonce[23:20];
			
	//// Virtual Wire Control
	wire	[607:0] 	data_vw;
	wire	[31:0] 		nonce_vw;
//	wire	[31:0] 		target_vw0;	
	wire	[31:0] 		target_vw1;	
//	wire 	[7:0]		freq_vw;

	
	wire	last_recv_vw;
	wire	gn_match;
	
	//// Virtual Wire Output
	reg 		serial_send;
	
	wire 	  	serial_busy;	

	
	reg [607:0] 	data = 0;	
	reg [31:0] 		nonce;
	reg [31:0] 		golden_nonce;
	reg [31:0] 		target0;		
	reg [31:0] 		target1;		

	
	serial_receive serrx (.clk(uart_clk), .RxD(RxD), .is_last(last_recv_vw), .data(data_vw), .nonce(nonce_vw), .target1(target_vw1));//.target0(target_vw0), 	
	serial_transmit sertx (.clk(uart_clk), .TxD(TxD), .send(serial_send), .busy(serial_busy), .word(golden_nonce));	
	
    keccak uut (
        .clk(hash_clk),
        .in(data),
		.nonce(nonce),
//		.target0(target0),
		.target1(target1),				
        .gn_match(gn_match)
    );	
	


	//// Control Unit
	reg [5:0]   state = 0;		

	always @(posedge hash_clk)
	begin

		if (last_recv_vw) begin			//golden_nonce <= data2_vw[255:224];//golden_nonce_next;	
			data <= data_vw;			
			nonce <= nonce_vw;	
//			target0 <= target_vw0;	
			target1 <= target_vw1;		
			state <= 1;			
		end
			
			
	case (state)
      0:    // Start FULL ALL
	 begin
				serial_send <= 0;
	 end	
	 50://50//26
	 begin
		nonce <= nonce + 1;
	 
		if ((gn_match) | (nonce==32'hffffffff))//& (!serial_busy)
			begin
			//$display("hash    %h",uut.round23_out);
			//$display("hash    %h",uut.f_out);			
			//$display("hash    %h",uut.out1);			


				serial_send <= 1;	
				golden_nonce <= nonce;   //  - 32'd49  //  50

				state <= 0;	//state <= 3'b011;							
			end		 
	 		
	 end     
	 
	 default:
		begin
		nonce <= nonce + 1;
		state <= state + 6'b000001;	
		end	
	 
     endcase // case 
			

			
     end

	 

		


endmodule



