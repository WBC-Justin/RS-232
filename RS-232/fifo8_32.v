module fifo8_32 (
    input sclk,
    input rstn,

    input [7:0] wdata_i,
    input       wr_i,

    output reg [31:0] rdata_o,
    input        rd_i,

    output       empty_o,
    output       full_o
);

    reg [127:0] mem;
    reg [4:0]   wcnt;
    reg [2:0]   rcnt;
    wire        empty = (wcnt[4:2] == rcnt[2:0]);
    wire        full = (wcnt[4] ^ rcnt[2]) & (wcnt[3:2] == rcnt[1:0]);

    always @(posedge sclk or negedge rstn) begin
        if (!rstn)
            wcnt <= 5'h0;
        else if (wr_i)
            wcnt <= #3 wcnt + 5'h1; // Adjusted the increment to 5-bits
    end

    always @(posedge sclk or negedge rstn) begin
        if (!rstn)
            rcnt <= 3'h0;
        else if (rd_i)
            rcnt <= #3 rcnt + 3'b1;
    end

    always @(posedge sclk or negedge rstn) begin
        if (!rstn) begin
            mem <= 128'h0;
        end else if (wr_i) begin
            case (wcnt[3:0])
                4'h0: mem[7:0]     <= #3 wdata_i;
                4'h1: mem[15:8]    <= #3 wdata_i;
                4'h2: mem[23:16]   <= #3 wdata_i;
                4'h3: mem[31:24]   <= #3 wdata_i;
				    4'h4: mem[39:32]   <= #3 wdata_i;
                4'h5: mem[47:40]   <= #3 wdata_i;
                4'h6: mem[55:48]   <= #3 wdata_i;
                4'h7: mem[63:56]   <= #3 wdata_i;
				    4'h8: mem[71:64]   <= #3 wdata_i;
                4'h9: mem[79:72]   <= #3 wdata_i;
                4'ha: mem[87:80]   <= #3 wdata_i;
                4'hb: mem[95:88]   <= #3 wdata_i;
				    4'hc: mem[103:96]  <= #3 wdata_i;
                4'hd: mem[111:104] <= #3 wdata_i;
                4'he: mem[119:112] <= #3 wdata_i;
                4'hf: mem[127:120] <= #3 wdata_i;
            endcase
        end
    end

    always @(*) begin
        case (rcnt[1:0])
            2'h0: rdata_o = mem[31:0];
            2'h1: rdata_o = mem[63:32];
            2'h2: rdata_o = mem[95:64];
            2'h3: rdata_o = mem[127:96]; 
        endcase
    end
	
    assign empty_o = empty;
    assign full_o  = full;

endmodule
