module uart_baud
(
  input sclk,   
  input rstn,   

  input [15:0] cnt_z_r,  
  input [15:0] remain_r,     
  input [15:0] baud_r,     

  output reg  baud_clk_o      
);

reg[15:0] cnt, accumlate;

wire over_accu = (accumlate > baud_r);
wire[15:0] cnt_zero =  cnt_z_r + over_accu;
wire[15:0] accu1 = accumlate + remain_r;
wire[15:0] accu2 = accu1 - baud_r;

always @(posedge sclk or negedge rstn) begin 
    if(!rstn) accumlate <= 16'h0;
	else if(cnt == cnt_zero && over_accu) accumlate <= #3 accu2;
    else if(cnt == cnt_zero) accumlate <= #3 accu1;
end 

always @(posedge sclk or negedge rstn) begin 
    if(!rstn) cnt <= 16'h0;
	else if(cnt == cnt_zero) cnt <= #3 16'h0;
    else cnt <= #3 cnt + 1;
end 

always @(posedge sclk or negedge rstn) begin 
    if(!rstn) baud_clk_o <= 1'h0;
    else if(cnt == cnt_zero) baud_clk_o <= #3 ~baud_clk_o;
end

endmodule