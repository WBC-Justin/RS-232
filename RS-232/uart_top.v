module uart_top
(
  input sclk,   
  input rstn,   

// Parallel Data I/O
// CPU to UART register access port : 
  input [7:0] 	reg_addr_i	,               //
  input [31:0] 	reg_wdata_i	,            //一個空間放32bit資料
  input       	reg_wr_i	,                  //甚麼時候寫
  input       	reg_rd_i	,					    //甚麼時候讀
  output [31:0] reg_rdata_o	,            //uart讀32bit資料

/*
// Status Signals
  input [31:0] 	uart_wdata_i	,
  input 	uart_wr_i	,
  output 	empty_tx_o	,
  output 	full_tx_o	,
  output [31:0] uart_rdata_o	,
  input 	uart_rd_i	,
  output 	empty_rx_o	,
//  output 	full_rx_o, parity_err_o, fifo_full_err_o,
  output 	full_rx_o	, 
  output 	parity_err_o	, 
  output 	fifo_full_err_o	,
*/
  
// UART : Serial Data IO 
  input  	rx_i		, // from UART RX input 
  output 	tx_o		  // to   UART TX output
);

  wire[15:0] cnt_z_r;
  wire[15:0] remain_r;
  wire[15:0] baud_r;
  wire[7:0]  tx_data_i;
  wire[1:0]  parity_r;
  wire[15:0] data_size_r;
  wire[7:0]  rx_data_o;
  wire	     baud_clk_o;
// Status Signals
  wire[31:0] uart_wdata	;
  wire	     uart_wr	;
  wire 	     empty_tx_o	;
  wire 	     full_tx_o	;
  wire[31:0] uart_rdata	;
  wire	     uart_rd	;
  wire 	     empty_rx_o	;
  wire 	     full_rx_o	; 
  wire 	     parity_err_o	; 
  wire 	     fifo_full_err_o	;
  wire        test_tx_out_to_rx_i;///////////////
 uart_baud uart_baud_u
(
  .sclk (sclk),   
  .rstn (rstn),   

  .cnt_z_r	(cnt_z_r	),  
  .remain_r 	(remain_r	),     
  .baud_r 	(baud_r		),     

  .baud_clk_o 	(baud_clk_o	)     
);

 uart_tx uart_tx_u
(
  .sclk (sclk),   
  .baud_clk (baud_clk_o	),   // add
  .rstn (rstn),   

  .empty_i 	(empty_tx_o	), 
  .tx_data_i 	(tx_data_i	), // TX data

  .rd_o		(		), // @ baud_clk
  .fifo_rd_o 	(fifo_rd_o	), // finish 1 TX cycle 
  //.tx_out 	(test_tx_out_to_rx_i	)  // UART TX/////////////////////.tx_out 	(tx_o)
  .tx_out 	(tx_o)
);

 fifo32_8 fifo32_8_u(
  .sclk (sclk),   
  .rstn (rstn),  

  .wdata_i 	(uart_wdata	),
  .wr_i 	(uart_wr	),

  .rdata_o 	(tx_data_i	),
  .rd_i 	(fifo_rd_o	),

  .empty_o 	(empty_tx_o	),
  .full_o 	(full_tx_o	)
);

 uart_rx uart_rx_u
(
  .sclk (sclk),   
  .rstn (rstn),  
  
  .baud_clk_i 	(baud_clk_o	),
  //.rx_i 	(test_tx_out_to_rx_i		),////////////////////////////////////////////////////////////////////////////////////////元.rx_i 	(rx_i		)
  .rx_i 	(rx_i		),
  .full_i 	(full_rx_o	),  
  .parity_r 	(parity_r	), //parity_r[1]: ON/OFF, parity[0]: ODD/EVEN
  .data_size_r 	(data_size_r	),

  //.rx_data_o 	(wdata_i	), ///////////////////// .rx_data_o 	(rx_data_o	), 
  .rx_data_o 	(rx_data_o	), 
  .fifo_wr 	(wr_rx		),
  .parity_err_o (parity_err_o	),
  .fifo_full_err_o (fifo_full_err_o)
);

 fifo8_32 fifo8_32_u(
  .sclk (sclk),   
  .rstn (rstn),  

  //.wdata_i 	(wdata_i	),////////////////////////////// .wdata_i 	(rx_data_o	),\
  .wdata_i 	(rx_data_o	),
  .wr_i 	(wr_rx		),

  .rdata_o 	(uart_rdata	),
  .rd_i 	(uart_rd	),

  .empty_o 	(empty_rx_o	),
  .full_o 	(full_rx_o	)
);

uart_regfile uart_regfile_u(
  .sclk (sclk),   
  .rstn (rstn),  

  .reg_addr_i 	(reg_addr_i	),
  .reg_wdata_i 	(reg_wdata_i	),
  .reg_wr_i 	(reg_wr_i	),
  .reg_rd_i 	(reg_rd_i	),

  .reg_rdata_o	(reg_rdata_o	),

// to TX fifo32_8
  .wdata_o 	(uart_wdata	),
  .wr_o 	(uart_wr	),
  .full_tx_i 	(full_tx_o	),
// from RX fifo8_32
  .rdata_i 	(uart_rdata	),
  .rd_o 	(uart_rd	),
  .empty_rx_i 	(empty_rx_o	),
  .full_rx_i 	(full_rx_o	),

  .cnt_z_r 	(cnt_z_r	),  
  .remain_r 	(remain_r	),     
  .baud_r 	(baud_r		), 
  .parity_r 	(parity_r	), //parity_r[1]: ON/OFF, parity[0]: ODD/EVEN
  .data_size_r 	(data_size_r	)
);
  


endmodule
