`timescale 1ns/1ps

// Store complete 10 ms PCM packets before presenting them to AXI DMA.  The
// microphone clock cannot be backpressured; if both banks are occupied, drop
// the incoming block as a unit instead of losing its TLAST inside a packet.
module audio_dma_axis (
    input wire clk, input wire rst, input wire raw_valid, input wire block_start,
    input wire signed [23:0] raw_0, raw_1, raw_2, raw_3,
    output wire m_tvalid, input wire m_tready, output wire [127:0] m_tdata,
    output wire [15:0] m_tkeep, output wire m_tlast,
    output reg [31:0] overflow_count
);
    (* ram_style = "block" *) reg [127:0] sample_ram [0:959];
    reg bank0_busy, bank1_busy, bank0_ready, bank1_ready;
    reg write_active, write_bank, next_write_bank;
    reg [8:0] write_index;
    reg read_active, read_bank, next_read_bank;
    reg [8:0] read_index;
    reg [127:0] out_data;
    reg out_valid, out_last;
    wire choose_bank0 = !bank0_busy && (!next_write_bank || bank1_busy);
    wire choose_bank1 = !choose_bank0 && !bank1_busy;
    wire ram_write_en = raw_valid &&
                        ((block_start && (choose_bank0 || choose_bank1)) ||
                         (!block_start && write_active));
    wire ram_write_bank = block_start ? choose_bank1 : write_bank;
    wire [8:0] ram_write_index = block_start ? 9'd0 : write_index;
    wire [9:0] ram_write_addr = (ram_write_bank ? 10'd480 : 10'd0) +
                                 {1'b0, ram_write_index};
    wire ram_read_en = read_active && !out_valid;
    wire [9:0] ram_read_addr = (read_bank ? 10'd480 : 10'd0) +
                                {1'b0, read_index};
    wire [127:0] packed_samples = {
        {8{raw_3[23]}}, raw_3, {8{raw_2[23]}}, raw_2,
        {8{raw_1[23]}}, raw_1, {8{raw_0[23]}}, raw_0
    };

    assign m_tvalid = out_valid;
    assign m_tdata = out_data;
    assign m_tkeep = 16'hffff;
    assign m_tlast = out_last;

    // One write port and one registered read port infer true dual-port BRAM.
    always @(posedge clk) begin
        if (ram_write_en) sample_ram[ram_write_addr] <= packed_samples;
        if (ram_read_en) out_data <= sample_ram[ram_read_addr];
    end

    always @(posedge clk) begin
        if (rst) begin
            bank0_busy <= 1'b0;
            bank1_busy <= 1'b0;
            bank0_ready <= 1'b0;
            bank1_ready <= 1'b0;
            write_active <= 1'b0;
            write_bank <= 1'b0;
            next_write_bank <= 1'b0;
            write_index <= 9'd0;
            read_active <= 1'b0;
            read_bank <= 1'b0;
            next_read_bank <= 1'b0;
            read_index <= 9'd0;
            out_valid <= 1'b0;
            out_last <= 1'b0;
            overflow_count <= 32'd0;
        end else begin
            if (raw_valid) begin
                if (block_start) begin
                    if (choose_bank0) begin
                        bank0_busy <= 1'b1;
                        write_bank <= 1'b0;
                        next_write_bank <= 1'b1;
                        write_index <= 9'd1;
                        write_active <= 1'b1;
                    end else if (choose_bank1) begin
                        bank1_busy <= 1'b1;
                        write_bank <= 1'b1;
                        next_write_bank <= 1'b0;
                        write_index <= 9'd1;
                        write_active <= 1'b1;
                    end else begin
                        write_active <= 1'b0;
                        overflow_count <= overflow_count + 1'b1;
                    end
                end else if (write_active) begin
                    if (write_index == 9'd479) begin
                        if (write_bank) bank1_ready <= 1'b1;
                        else bank0_ready <= 1'b1;
                        write_active <= 1'b0;
                    end else write_index <= write_index + 1'b1;
                end else overflow_count <= overflow_count + 1'b1;
            end

            if (!read_active && !out_valid) begin
                if (bank0_ready && (!bank1_ready || !next_read_bank)) begin
                    bank0_ready <= 1'b0;
                    read_bank <= 1'b0;
                    read_index <= 9'd0;
                    read_active <= 1'b1;
                end else if (bank1_ready) begin
                    bank1_ready <= 1'b0;
                    read_bank <= 1'b1;
                    read_index <= 9'd0;
                    read_active <= 1'b1;
                end
            end else if (read_active && !out_valid) begin
                out_last <= (read_index == 9'd479);
                out_valid <= 1'b1;
            end else if (out_valid && m_tready) begin
                out_valid <= 1'b0;
                if (out_last) begin
                    read_active <= 1'b0;
                    if (read_bank) bank1_busy <= 1'b0;
                    else bank0_busy <= 1'b0;
                    next_read_bank <= !read_bank;
                end else read_index <= read_index + 1'b1;
            end
        end
    end
endmodule
