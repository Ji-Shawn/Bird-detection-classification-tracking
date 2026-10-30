`timescale 1ns/1ps

module model_video_axis #(
    parameter integer FIFO_DEPTH = 16,
    parameter integer PTR_WIDTH = $clog2(FIFO_DEPTH)
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        s_valid,
    input  wire [23:0] s_data,
    input  wire        s_sof,
    input  wire        s_eol,
    output wire        m_tvalid,
    input  wire        m_tready,
    output wire [23:0] m_tdata,
    output wire        m_tuser,
    output wire        m_tlast,
    output reg         frame_abort,
    output reg [31:0]  drop_count
);
    reg [23:0] data_fifo [0:FIFO_DEPTH-1];
    reg user_fifo [0:FIFO_DEPTH-1];
    reg last_fifo [0:FIFO_DEPTH-1];
    reg [PTR_WIDTH-1:0] write_ptr;
    reg [PTR_WIDTH-1:0] read_ptr;
    reg [PTR_WIDTH:0] count;
    reg dropping;

    wire pop = (count != 0) && m_tready;
    wire restart = dropping && s_valid && s_sof;
    wire push_request = s_valid && (!dropping || restart);
    wire overflow = push_request && (count == FIFO_DEPTH) && !pop;
    wire push = push_request && !overflow;

    assign m_tvalid = (count != 0);
    assign m_tdata = data_fifo[read_ptr];
    assign m_tuser = user_fifo[read_ptr];
    assign m_tlast = last_fifo[read_ptr];

    always @(posedge clk) begin
        if (rst) begin
            write_ptr <= {PTR_WIDTH{1'b0}};
            read_ptr <= {PTR_WIDTH{1'b0}};
            count <= {(PTR_WIDTH + 1){1'b0}};
            dropping <= 1'b0;
            frame_abort <= 1'b0;
            drop_count <= 32'd0;
        end else begin
            frame_abort <= 1'b0;
            if (overflow) begin
                count <= {(PTR_WIDTH + 1){1'b0}};
                read_ptr <= write_ptr;
                dropping <= 1'b1;
                frame_abort <= 1'b1;
                drop_count <= drop_count + 1'b1;
            end else begin
                if (restart)
                    dropping <= 1'b0;
                if (push) begin
                    data_fifo[write_ptr] <= s_data;
                    user_fifo[write_ptr] <= s_sof;
                    last_fifo[write_ptr] <= s_eol;
                    write_ptr <= write_ptr + 1'b1;
                end
                if (pop)
                    read_ptr <= read_ptr + 1'b1;
                case ({push, pop})
                    2'b10: count <= count + 1'b1;
                    2'b01: count <= count - 1'b1;
                    default: count <= count;
                endcase
            end
        end
    end
endmodule
