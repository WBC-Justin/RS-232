module fifo32_8 (
    input sclk,
    input rstn,

    input [31:0] wdata_i,
    input       wr_i,

    output reg [7:0] rdata_o,
    input        rd_i,

    output       empty_o,
    output       full_o
);

    reg [127:0] mem;
    reg [4:0]   wcnt;
    reg [4:0]   rcnt;
    wire        empty = (wcnt == rcnt);
    wire        full = (wcnt[4] ^ rcnt[4]) & (wcnt[3:0] == rcnt[3:0]);

    always @(posedge sclk or negedge rstn) begin
        if (!rstn)
            wcnt <= 5'h0;
        else if (wr_i)
            wcnt <= #3 wcnt + 5'h4; // Adjusted the increment to 5-bits
    end

    always @(posedge sclk or negedge rstn) begin
        if (!rstn)
            rcnt <= 5'h0;
        else if (rd_i)
            rcnt <= #3 rcnt + 1'b1;
    end

    always @(posedge sclk or negedge rstn) begin
        if (!rstn) begin
            mem <= 128'h0;
        end else if (wr_i) begin
            case (wcnt[3:2])
                2'h0: mem[31:0]   <= #3 wdata_i;
                2'h1: mem[63:32]  <= #3 wdata_i;
                2'h2: mem[95:64]  <= #3 wdata_i;
                2'h3: mem[127:96] <= #3 wdata_i;
            endcase
        end
    end

    always @(*) begin
        case (rcnt[3:0])
            4'h0: rdata_o = mem[7:0];
            4'h1: rdata_o = mem[15:8];
            4'h2: rdata_o = mem[23:16];
            4'h3: rdata_o = mem[31:24];
            4'h4: rdata_o = mem[39:32];
            4'h5: rdata_o = mem[47:40];
            4'h6: rdata_o = mem[55:48];
            4'h7: rdata_o = mem[63:56];
            4'h8: rdata_o = mem[71:64];
            4'h9: rdata_o = mem[79:72];
            4'ha: rdata_o = mem[87:80];
            4'hb: rdata_o = mem[95:88];
            4'hc: rdata_o = mem[103:96];
            4'hd: rdata_o = mem[111:104];
            4'he: rdata_o = mem[119:112];
            4'hf: rdata_o = mem[127:120];
        endcase
    end
   
    assign empty_o = empty;
    assign full_o  = full;
  
endmodule