module slave_spi_tx
(
  input sclk,   
  input rstn,   

  input msck,   
  input msci, 
  input msen,   

  input       empty_i,  
  output reg fifo_rd_o,   
  input [7:0] tx_data_i, 

  output reg [7:0] rx_data_o,
  output reg fifo_wr_o,
  
  input [1:0] tx_mode_r,
  input [1:0] rx_mode_r,
  input [1:0] msen_pol_r,

  output reg  msco 
);

reg[2:0] bcnt;
reg[7:0] rtmp;
reg msen_d1, msen_d2, msen_d3;

always @(posedge msck or negedge rstn) begin 
    if(!rstn) bcnt <= 3'h0;
    else if(msen == 1'b1 || msen_d2 == 1'b1) bcnt <= #3 bcnt + 1'b1;
    else bcnt <= #3 3'h0;
end

always @(posedge msck or negedge rstn) begin 
    if(!rstn) rtmp <= 3'h0;
    else if(msen) rtmp <= #3 {rtmp[6:0], msci};
end

always @(posedge msck or negedge rstn) begin 
    if(!rstn) begin
	 msen_d1 <= 1'h0;
	 msen_d2 <= 1'h0;
	 msen_d3 <= 1'h0;
    end
    else begin
	 msen_d1 <= #3 msen;
	 msen_d2 <= #3 msen_d1;
 	 msen_d3 <= #3 msen_d2;
   end
end

//msck 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 
//msen 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0 
//msen_d1  0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0 
//msen_d2  0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0 
//msen_d3  0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0 

//bcnt 0 0 0 0 0 1   2   3   4   5   6   7   0   1   2   3   4   5   6   7   0   0
//rtmp 0 0 0 0 0[0] [1] [2] [3] [4] [5] [6] [7] [0] [1] [2] [3] [4] [5] [6] [7]  0


always @(posedge msck or negedge rstn) begin 
    if(!rstn) rx_data_o <= 3'h0;
    else if(msen_d3 == 1'b1 && bcnt == 3'h0 ) rx_data_o <= #3 rtmp;
end

always @(posedge msck or negedge rstn) begin 
    if(!rstn) fifo_wr_o <= 3'h0;
    else if(msen_d3 == 1'b1 && bcnt == 3'h0 ) fifo_wr_o <= #3 1'b1;
	else fifo_wr_o <= #3 1'b0;
end





endmodule
