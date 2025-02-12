module uart_rx
(
  input sclk,   
  input rstn,   
  input baud_clk_i,
  input rx_i,
  input full_i,  
  input[1:0] parity_r, //parity_r[1]: ON/OFF, parity[0]: ODD/EVEN
  input[15:0] data_size_r,

  output reg[7:0] rx_data_o, 
  output reg  fifo_wr,
  output reg parity_err_o,
  output fifo_full_err_o
);

reg [2:0] state ;  // State variable
reg rx_1d,rx_2d, rx_3d;
wire level_change = rx_2d ^ rx_3d;
reg[4:0] cnt_16;
reg[2:0] cnt_byte;
reg byte_valid;
reg[7:0] rx_data_shift;
reg[15:0] data_cnt;
reg parity_chk;
wire parity_even_odd = parity_r[0]? rx_2d : ~rx_2d;
reg byte_valid_1d, byte_valid_2d, byte_valid_3d;
wire fifo_wr_p = ~byte_valid_3d & byte_valid_2d;

assign fifo_full_err_o = fifo_wr_p & full_i;

always @(posedge baud_clk_i or negedge rstn) begin 
	
    if(!rstn) begin
    rx_1d <= 1'b1;
	 rx_2d <= 1'b1;
	 rx_3d <= 1'b1;
    end
	else begin
	 rx_1d <= #3 rx_i;
	 rx_2d <= #3 rx_1d;
	 rx_3d <= #3 rx_2d;
	end
end

always @(posedge baud_clk_i or negedge rstn) begin 
    if(!rstn) cnt_16 <= 5'h0;
    else if(level_change) cnt_16 <= #3 5'h0;
    else if(&cnt_16[3:0]) cnt_16 <= #3 5'h0;
	else cnt_16 <= #3 cnt_16 + 1'b1;
end

always @(posedge baud_clk_i or negedge rstn) begin 
    if(!rstn) begin
	 state <= 3'h0;
	 cnt_byte <= 3'h0;
	 byte_valid <= 1'b0;
	 rx_data_shift <= 8'h0;
	 data_cnt <= 16'h0;
	 parity_chk <= 1'b0;
	 parity_err_o <= 1'b0;
    end
	else begin
	 case(state)
	   0: begin
	       if(~rx_2d) begin
		    state <= #3 3'h1;
	        parity_chk <= #3 1'b0;
		   end
	      end
	   1: begin
	       if(cnt_16== 5'h2) state <= #3 3'h2; //START BIT
	      end
	   2: begin
	       if(cnt_16== 5'h2) begin //data bit
		    cnt_byte <= #3 cnt_byte + 1'b1;
			rx_data_shift <= #3 {rx_data_shift[6:0], rx_2d};
			if(rx_2d == 1'b1) parity_chk <= #3 ~parity_chk;
			
		    if(cnt_byte == 3'h7) byte_valid <= #3 1'b1;
            else if(cnt_byte == 3'h0) byte_valid <= #3 1'b0;
			
		    if(cnt_byte == 3'h7) begin
			 data_cnt <= #3 data_cnt + 1;
//			 state <= #3 3'h3;
			 state <= #3 3'h4;
			end
		   end	
	      end
	   3: begin
	       cnt_byte <= #3 3'h0;
		   if(data_cnt == data_size_r) state <= #3 3'h4;
		   else state <= #3 3'h2;
	      end
	   4: begin  //
	   	   if(cnt_16== 5'h2) begin //Parity or STOP
		    if(parity_r[1] == 1'b1) begin
		         if(parity_r[1] == 1'b1 && parity_even_odd ^ parity_chk) parity_err_o <= #3 1;
		         state <= #3 3'h5;
           	     end
 		     else state <= #3 3'h0;  // IDLE
		   end
	      end
	   5: begin  //
	   	   if(cnt_16== 5'h2) begin //STOP or IDLE
		    //if(parity_r[1] == 1'b1) state <= #3 3'h6;
		     state <= #3 3'h0;
			rx_data_shift <= #3 0; 
		   end
	      end
	   6: begin  //
	   	   if(cnt_16== 5'h2) begin //IDLE
		    state <= #3 3'h0;
		   end
	      end
	   default: begin  
	             state <= 3'h0;
	             cnt_byte <= 3'h0;
	             byte_valid <= 1'b0;
			     rx_data_shift <= 8'h0;
	             data_cnt <= 16'h0;
	             parity_chk <= 1'b0;
	             parity_err_o <= 1'b0;
                end
	 endcase
	end
end

always @(posedge sclk or negedge rstn) begin 
    if(!rstn) begin
     byte_valid_1d <= 1'b0;
	 byte_valid_2d <= 1'b0;
	 byte_valid_3d <= 1'b0;
	 fifo_wr <= 1'b0;
    end
	else begin
	 byte_valid_1d <= #3 byte_valid;
	 byte_valid_2d <= #3 byte_valid_1d;
	 byte_valid_3d <= #3 byte_valid_2d;
	 fifo_wr <= #3 fifo_wr_p;
	end
end

always @(posedge sclk or negedge rstn) begin 
    if(!rstn) rx_data_o <= 8'h0;
    else if(fifo_wr_p) rx_data_o <= #3 rx_data_shift;
end




endmodule
