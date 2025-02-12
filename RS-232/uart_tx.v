module uart_tx
(
  input sclk,   
  input baud_clk,   
  input rstn,   

  input       empty_i,  
  input [7:0] tx_data_i,     // TX data 

  output reg  rd_o     ,   // add rd enable @ baud_clk 
  output wire fifo_rd_o,   // finish 1 TX cycle 
  output reg  tx_out       // UART TX
);

reg[3:0] state;
reg[2:0] cnt;
reg[7:0] temp;
reg rd_1d, rd_2d, rd_3d;
reg[3:0] baud_cnt;


always @(posedge sclk or negedge rstn) begin 
    if(!rstn) begin
	rd_1d <= 1'b0;
	rd_2d <= 1'b0;
	rd_3d <= 1'b0;
    end
    else begin
	rd_1d <= rd_o ;
	rd_2d <= rd_1d;
	rd_3d <= rd_2d;
    end
end
assign fifo_rd_o =  ~rd_3d  & rd_2d ;   //  == 01


always @(posedge baud_clk or negedge rstn) begin 
    if(!rstn) 
        baud_cnt <= 4'h0;
    else 
	baud_cnt <= baud_cnt + 1;
end

wire baud_cnt_co = (baud_cnt==4'b1111);

//always @(posedge sclk or negedge rstn) begin 
always @(posedge baud_clk or negedge rstn) begin 
    if(!rstn) begin
        state <= 4'h0;
		//fifo_rd_o <= #3 1'b0;
		rd_o <= #3 1'b0;
		cnt <= #3 3'h0;
		tx_out <= #3 1'b1; //idle bit
		temp <= #3 8'h0;
	end
//	else begin
	else if (baud_cnt_co)  begin
		  case(state)
		    4'h0: begin
			       if(!empty_i) begin
				    //fifo_rd_o <= #3 1'b1;
				    rd_o <= #3 1'b1;
					temp <= #3 tx_data_i;
					tx_out <= #3 1'b0; //start bit
				    	state <= #3 4'h1;
				   end
			      end
		    4'h1: begin
				   //fifo_rd_o <= #3 1'b0;
				   rd_o <= #3 1'b0;
			       if(&cnt) begin
				   	tx_out <= #3 temp[7]; //last bit
				    //state <= #3 4'h2;
				    state <= #3 4'h3;
				   end
				   else begin
				   	tx_out <= #3 temp[7]; //1st bit
                    temp[7:1] <= #3 temp[6:0];
                    cnt <= #3 cnt + 1;
				   end
			      end
			4'h2: begin
				   if(!empty_i) begin
				    //fifo_rd_o <= #3 1'b1;
				    rd_o <= #3 1'b1;
					//temp[7:1] <= #3 tx_data_i[6:0];
					//tx_out <= #3 tx_data_i[7]; //1st bit
					//cnt <= #3 3'h1;
					temp <= #3 tx_data_i;
					tx_out <= #3 1'b0 ; //START bit
					cnt <= #3 3'h0;
				    state <= #3 4'h1;
                   end
				   else begin
				    tx_out <= #3 1'b1; //stop bit
		            state <= #3 4'h0;
                   end
			      end
			default: begin
			          state <= 2'h0;
		              //fifo_rd_o <= #3 1'b0;
		              rd_o <= #3 1'b0;
		              cnt <= #3 3'h0;
		              tx_out <= #3 1'b1; //idle bit
		              temp <= #3 8'h0;
			end
		  endcase
    end
end 


endmodule
