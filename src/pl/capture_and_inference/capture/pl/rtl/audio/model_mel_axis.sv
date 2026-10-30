`timescale 1ns/1ps

module model_mel_axis (
    input wire clk, input wire rst,
    input wire s_wr_en, input wire [6:0] s_wr_index, input wire [15:0] s_wr_data,
    input wire [31:0] s_audio_seq, input wire s_commit,
    output wire m_tvalid, input wire m_tready,
    output wire [15:0] m_tdata, output wire m_tuser, output wire m_tlast,
    output wire [31:0] m_audio_seq,
    output reg column_abort, output reg [31:0] model_mel_drop,
    output reg [31:0] bad_commit_count
);
    reg [15:0] bank0 [0:127];
    reg [15:0] bank1 [0:127];
    reg [31:0] seq0, seq1;
    reg write_bank, active_bank, busy;
    reg [7:0] write_count;
    reg [127:0] written;
    reg [6:0] read_index;

    assign m_tvalid = busy;
    assign m_tdata = active_bank ? bank1[read_index] : bank0[read_index];
    assign m_tuser = busy && (read_index == 0);
    assign m_tlast = busy && (read_index == 127);
    assign m_audio_seq = active_bank ? seq1 : seq0;

    always @(posedge clk) begin
        if (rst) begin
            seq0<=0; seq1<=0; write_bank<=0; active_bank<=0; busy<=0;
            write_count<=0; written<=0; read_index<=0;
            column_abort<=0; model_mel_drop<=0; bad_commit_count<=0;
        end else begin
            column_abort <= 0;
            if (s_wr_en) begin
                if (write_bank) bank1[s_wr_index] <= s_wr_data;
                else bank0[s_wr_index] <= s_wr_data;
                if (!written[s_wr_index]) begin
                    written[s_wr_index] <= 1'b1;
                    write_count <= write_count + 1'b1;
                end
            end

            if (s_commit) begin
                if (write_count != 128) begin
                    bad_commit_count <= bad_commit_count + 1'b1;
                end else begin
                    if (write_bank) seq1 <= s_audio_seq; else seq0 <= s_audio_seq;
                    if (busy) begin
                        model_mel_drop <= model_mel_drop + 1'b1;
                        column_abort <= 1'b1;
                    end
                    active_bank <= write_bank;
                    write_bank <= !write_bank;
                    read_index <= 0;
                    busy <= 1'b1;
                    written <= 0;
                    write_count <= 0;
                end
            end else if (busy && m_tready) begin
                if (read_index == 127) begin
                    busy <= 1'b0;
                    read_index <= 0;
                end else begin
                    read_index <= read_index + 1'b1;
                end
            end
        end
    end
endmodule
