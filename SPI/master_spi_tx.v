module master_spi_tx
(
  input sclk,   
  input rstn,   

  input       empty_i,  
  output reg fifo_rd_o,   
  input [7:0] tx_data_i, 

  output reg [7:0] rx_data_o,
  output reg fifo_wr_o,
  
  input [7:0] mspi_div_r,  //odd number for 50% duty   
  input [1:0] tx_mode_r,
  input [1:0] rx_mode_r,
  input [1:0] msen_pol_r,

  output reg msck     ,   
  output reg  msco     ,   
  output wire  msen     ,   
  input   msci       
);


reg[2:0] bcnt;
reg[3:0] cnt;
reg[7:0] rtmp;
reg[7:0] temp;                                                      //////////
reg msen_d0, msen_d1, msen_d2, msen_df, msck1;

assign msen = msen_pol_r ? msen_d0 : ~msen_d0;

always @(*) begin 
 case(tx_mode_r)
  2'h0: msck <= msck1 & msen_d0;
  2'h1: msck <= ~msck1 & msen_d0;
  2'h2: msck <= ~msck1 & msen_df;
  2'h3: msck <= ~(~msck1 & msen_df);
 endcase
end

always @(posedge sclk or negedge rstn) begin 
    if(!rstn) cnt <= 8'h0;
    else if(cnt == mspi_div_r) cnt <= #3 8'h0;
    else cnt <= #3 cnt + 1;
end

always @(posedge sclk or negedge rstn) begin 
    if(!rstn) msck1 <= 1'b0;
    else if(cnt == mspi_div_r) msck1 <= #3 1'b0;
    else if(cnt == {1'b0, mspi_div_r[7:1]}) msck1 <= #3 1'b1;
end

always @(posedge sclk or negedge rstn) begin 
    if(!rstn) msen_df <= 1'h0;
	else if(cnt == 3'h0) msen_df <= #3 msen_d0;
end

always @(posedge msck1 or negedge rstn) begin 
    if(!rstn) bcnt <= #3 3'h0;
//	 else if(bcnt == mspi_div_r) bcnt <= #3 3'h0;                   ////////////
    else bcnt <= #3 bcnt + 1'b1;
	 
	 //$display("fff %d" , bcnt);
end

always @(posedge msck1 or negedge rstn) begin 
    if(!rstn) msen_d0 <= #3 3'h0;
    else if(bcnt == 3'h0 && empty_i == 1'b0) msen_d0 <= #3 1'b1;
	else if(bcnt == 3'h0 && empty_i == 1'b1) msen_d0 <= #3 1'b0;
end

always @(posedge msck1 or negedge rstn) begin 
    if(!rstn) begin
		fifo_rd_o <= #3 1'b0;
		msco <= #3 1'b0; 
		temp <= #3 8'h0;
	end
	else if(bcnt == 3'h0 && empty_i == 1'b0) begin
		fifo_rd_o <= #3 1'b1;
		temp[7:1] <= #3 tx_data_i[6:0];
		msco <= #3 tx_data_i[7];
	end
	else begin
	    fifo_rd_o <= #3 1'b0;
       temp[7:1] <= #3 temp[6:0];
		 msco <= #3 temp[7];		   
    end
end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//mspi_div_r = 5
//cnt 0 1 2 3 4 5 0 1 2 3 4 5 0 1 2 3 4 5 0 1 2 3 4 5 0 1 2 3 4 5 0 1 2 3 4 5
//msck1           0 0 0 1 1 1 0 0 0 1 1 1 0 0 0 1 1 1 0 0 0 1 1 1 0 0 0
//msen:                  1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0
//msen_df:                    1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//bcnt:      0 1 2 3 4 5 6 7 0 1 2 3 4 5 6 7 0 1 2 3 4 5 6 7 0 1 2 3 4 5 6 7 0 1 2 3 4 5 6 7 0 1 2 3 4 5 6 7 
//empty:     1 1 1 1 1 1 1 1 0
//fifo_rd_o: 0 0 0 0 0 0 0 0 1 0
//temp:                      D
//msck1               0 0 0 1 1 1 0 0 0 1 1 1 0 0 0 1
//msen:                      1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0
//msen_df:                         1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0
//msco:                     [7 6 5 4 3 2 1 0 7 6 5 4 3 2 1 0 -
//msci:                     [7 6 5 4 3 2 1 0 7 6 5 4 3 2 1 0 -
//rx_data_o                                  B0              B1  
//fifo_wr_o                                    1 0             1 0
//msen_d1:                     1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0
//msen_d2  :                     1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


always @(posedge msck1 or negedge rstn) begin 
    if(!rstn) rtmp <= 8'h0;
	else if(msen_d0 == 1'h1) rtmp <= #3 {rtmp[6:0], msci};
	else if(bcnt == 3'h0 && empty_i == 1'b0) rtmp <= #3 {rtmp[6:0], msci};                 //////////////
	
	$display("fff %8b" , rtmp);
end

always @(posedge msck1 or negedge rstn) begin 
    if(!rstn) rx_data_o <= 8'h0;
	 else if(bcnt == 3'h1) rx_data_o <= #3 rtmp;
	 //rx_data_o <= #3 temp;
	//rtmp = temp;
	//$display("fff %8b" , rtmp);
end

always @(posedge msck1 or negedge rstn) begin 
    if(!rstn) begin 
	 msen_d1 <= 1'h0;
	 msen_d2 <= 1'h0;
    end
	else begin
     msen_d1 <= #3 msen_d0;
	 msen_d2 <= #3 msen_d1;
	end
end

always @(posedge msck1 or negedge rstn) begin 
    if(!rstn) fifo_wr_o <= 1'h0;
    else if(bcnt == 3'h1 && msen_d2 == 1'h1) fifo_wr_o <= #3 1'h1;
	 else fifo_wr_o <= #3 1'h0;
end

endmodule
