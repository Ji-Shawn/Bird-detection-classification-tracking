`timescale 1ns/1ps
// IEEE CRC32, reflected, low byte first. Pure stream sidecar: no pixel changes.
// s_last terminates one UDP payload, not a video scanline or whole frame.
module crc16_stream(
    input wire clk, input wire resetn,
    input wire s_valid, output wire s_ready,
    input wire [15:0] s_data, input wire [1:0] s_keep, input wire s_last,
    output reg m_valid, input wire m_ready, output reg [31:0] m_crc
);
    reg [31:0] state;
    reg [31:0] next_crc;
    integer byte_index,bit_index;
    assign s_ready = !m_valid || m_ready;
    always @* begin
        next_crc=state;
        for(byte_index=0;byte_index<2;byte_index=byte_index+1) begin
            if(s_keep[byte_index]) begin
                next_crc=next_crc ^ ((s_data >> (byte_index*8)) & 32'hff);
                for(bit_index=0;bit_index<8;bit_index=bit_index+1)
                    next_crc=(next_crc>>1) ^ (next_crc[0]?32'hedb88320:32'b0);
            end
        end
    end
    always @(posedge clk) begin
        if(!resetn)begin state<=32'hffffffff;m_valid<=0;m_crc<=0;end
        else begin
            if(m_valid && m_ready)m_valid<=0;
            if(s_valid && s_ready)begin
                if(s_last)begin
                    m_crc<=~next_crc;m_valid<=1;state<=32'hffffffff;
                end else state<=next_crc;
            end
        end
    end
endmodule
