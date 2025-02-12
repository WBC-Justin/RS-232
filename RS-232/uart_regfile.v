module uart_regfile (
    input sclk,
    input rstn,

    input [7:0] reg_addr_i,
    input [31:0] reg_wdata_i,
    input       reg_wr_i,
    input       reg_rd_i,

    output [31:0] reg_rdata_o,

// to TX fifo32_8
    output [31:0] wdata_o,   
    output        wr_o,     
    input	  full_tx_i,
// from RX fifo8_32
    input [31:0] rdata_i, 
    output       rd_o,   
    input 	 empty_rx_i,
    input	 full_rx_i,

// register output to TX/RX
    output reg [15:0] cnt_z_r,  
    output reg [15:0] remain_r,     
    output reg [15:0] baud_r, 
    output reg [1:0]  parity_r, //parity_r[1]: ON/OFF, parity[0]: ODD/EVEN
    output reg [15:0] data_size_r
);

// Control Register
    wire reg00_cs = (reg_addr_i == 8'h0);
    wire reg01_cs = (reg_addr_i == 8'h1);
    wire reg02_cs = (reg_addr_i == 8'h2);
    wire reg03_cs = (reg_addr_i == 8'h3);
    wire reg04_cs = (reg_addr_i == 8'h4);

// Data Register
    wire reg10_cs = (reg_addr_i == 8'h10);
    assign wr_o    = reg10_cs & reg_wr_i;
    assign wdata_o = reg_wdata_i; 
    assign rd_o    = reg10_cs & reg_rd_i; 

    wire reg20_cs = (reg_addr_i == 8'h20);

    always @(posedge sclk or negedge rstn) begin
        if (!rstn) cnt_z_r <= 16'h0;
        else if (reg_wr_i && (reg_addr_i == 8'h0)) 
		cnt_z_r <= #3 reg_wdata_i[15:0]; 
    end

    always @(posedge sclk or negedge rstn) begin
        if (!rstn) remain_r <= 16'h0;
        else if (reg_wr_i && (reg_addr_i == 8'h1)) 
		remain_r <= #3 reg_wdata_i[15:0]; 
    end

    always @(posedge sclk or negedge rstn) begin
        if (!rstn) baud_r <= 16'h0;
        else if (reg_wr_i && (reg_addr_i == 8'h2)) 
		baud_r <= #3 reg_wdata_i[15:0]; 
    end

    always @(posedge sclk or negedge rstn) begin
        if (!rstn) parity_r <= 2'h0;
        else if (reg_wr_i && (reg_addr_i == 8'h3)) 
		parity_r <= #3 reg_wdata_i[1:0]; 
    end
	
    always @(posedge sclk or negedge rstn) begin
        if (!rstn) data_size_r <= 16'h0;   
        else if (reg_wr_i && (reg_addr_i == 8'h4))  
		data_size_r <= #3 reg_wdata_i[15:0]; 
    end


	
    wire [31:0] reg_0 = (reg_addr_i == 8'h0) ? {16'h0,cnt_z_r}	: 32'h0;
    wire [31:0] reg_1 = (reg_addr_i == 8'h1) ? {16'h0,remain_r} : 32'h0;
    wire [31:0] reg_2 = (reg_addr_i == 8'h2) ? {16'h0,baud_r} 	: 32'h0;
    wire [31:0] reg_3 = (reg_addr_i == 8'h3) ? {30'h0,parity_r} : 32'h0;
    wire [31:0] reg_4 = (reg_addr_i == 8'h4) ? {16'h0,data_size_r} : 32'h0;
	 //wire [31:0] reg_10 =(reg_addr_i == 8'h10) ? {16'h0,reg_wdata_i[31:0]} : 32'h0;
    wire [31:0] reg_10 = reg10_cs ? rdata_i : 32'h0;
    wire [31:0] reg_20 = reg20_cs ? { 24'h0, {2'b00, full_rx_i, empty_rx_i}, {3'b000, full_tx_i}} : 32'h0; 


    assign reg_rdata_o = reg_0 | reg_1  | reg_2 | reg_3 | reg_4 | reg_10;
	
endmodule
