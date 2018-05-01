module serial_receive(clk, RxD, is_last, data, nonce, target1);//target0, 
   input      clk;
   input      RxD;

   output [607:0] data;     
   output [31:0]  nonce;    
//   output [31:0]  target0;    
   output [31:0]  target1;  
 //  output [7:0]	  freq;   
   output is_last;  

   
   wire       RxD_data_ready;
   wire [7:0] RxD_data;   

   reg [671:0] input_buffer;

   reg is_last_reg = 1'b0;
   
   reg [6:0]   demux_state = 7'b0000000;

/*   
   assign data   	= input_buffer[703:96];           
   assign nonce   	= input_buffer[95:64];  
   assign target0  	= input_buffer[63:32];   
   assign target1  	= input_buffer[31:0];
//   assign freq   	= input_buffer[7:0];
*/
   assign data   	= input_buffer[671:64];           
   assign nonce   	= input_buffer[63:32];  
   assign target1  	= input_buffer[31:0];




   
   assign is_last = is_last_reg;   
   
    
   
`ifndef SIM
    uart_receiver urx (.clk(clk), .uart_rx(RxD), .tx_new_byte(RxD_data_ready), .tx_byte(RxD_data)); 	
`else
	async_receiver deserializer(.clk(clk), .RxD(RxD), .RxD_data_ready(RxD_data_ready), .RxD_data(RxD_data)); 
`endif   
   

   
   // we probably don't need a busy signal here, just read the latest
   // complete input that is available.
   
   always @(posedge clk)
     case (demux_state)
//	  7'b1011001://712
//	  7'b1011000://704
	  7'b1010100://672	   
	 begin
	//    input_copy <= input_buffer;
	    demux_state <= 0;
		is_last_reg <= 1;		
	 end
       
       default:
	 if(RxD_data_ready)
	   begin
		  is_last_reg <= 0;
	      input_buffer <= input_buffer << 8;
	      input_buffer[7:0] <= RxD_data;
	      demux_state <= demux_state + 7'b0000001;
	   end else
			is_last_reg <= 0;
     endcase // case (demux_state)
   
endmodule // serial_receive

module serial_transmit (clk, TxD, busy, send, word);
   input      clk;
   output     TxD;
   
   input [31:0] word;
   input 	send;
   output 	busy; 
 
`ifndef SIM 
	wire [15:0] measured_temperature;
	comm_temperature_measurement temperature_blk (
		.clk (clk),
		.tx_temp (measured_temperature)
	);   
`else
	wire [15:0] measured_temperature= 16'h0123;	
`endif 

   wire TxD_start;
   wire TxD_ready;
   
   reg [7:0]  out_byte;
   reg        serial_start;
   reg [4:0]  mux_state = 5'b00000;

   assign TxD_start = serial_start;



   reg [63:0] 	word_copy;
   
   assign busy = (|mux_state);

   always @(posedge clk)
     begin

	if (!busy && send)
	  begin
	     mux_state <= 5'b10000;
	     word_copy <= {word, measured_temperature, 16'h4567};
	  end  

	else if (mux_state[4] && ~mux_state[0] && TxD_ready)
	  begin
	     serial_start <= 1;
	     mux_state <= mux_state + 5'b00001;

	     out_byte <= word_copy[63:56];
	     word_copy <= (word_copy << 8);
	  end
	
	// wait stages
	else if (mux_state[4] && mux_state[0])
	  begin
	     serial_start <= 0;
	     if (TxD_ready) mux_state <= mux_state + 5'b00001;
	  end
     end

`ifndef SIM
    uart_transmitter utx (.clk(clk), .uart_tx(TxD), .rx_new_byte(TxD_start), .rx_byte(out_byte), .tx_ready(TxD_ready));
`else
	async_transmitter serializer(.clk(clk), .TxD_start(TxD_start), .TxD_data(out_byte), .TxD(TxD), .TxD_ready(TxD_ready));
`endif 
endmodule // serial_send


`ifndef SIM
module comm_temperature_measurement (
	input clk,
	output reg [15:0] tx_temp
);

	wire drdy;
	wire [15:0] d;

	xadc_temp_sensor xadc_blk (
		.daddr_in (7'd0),
		.dclk_in (clk),
		.den_in (1'b1),
		.di_in (16'd0),
		.dwe_in (1'b0),
		.vp_in (1'b0),
		.vn_in (1'b0),
		.busy_out (),
		.channel_out (),
		.do_out (d),
		.drdy_out (drdy),
		.eoc_out (),
		.eos_out (),
		.ot_out (),
		.vccaux_alarm_out (),
		.vccint_alarm_out (),
		.user_temp_alarm_out (),
		.alarm_out ()
	);

	always @ (posedge clk)
	begin
		if (drdy)
			tx_temp <= d;
	end

endmodule
`endif 


