`timescale 1ns/1ps

module video_axis_fifo565 #(
    parameter integer DEPTH=2048,
    parameter integer PTR_WIDTH=$clog2(DEPTH)
) (
    input wire clk, input wire rst,
    input wire s_valid, input wire [15:0] s_data, input wire s_sof, input wire s_eol,
    output wire m_tvalid, input wire m_tready, output wire [15:0] m_tdata,
    output wire [1:0] m_tkeep, output wire m_tuser, output wire m_tlast,
    output reg [31:0] drop_count,
    output wire full, output wire empty,
    output reg overflow, output wire underflow
);
    reg [15:0] data_mem[0:DEPTH-1]; reg user_mem[0:DEPTH-1], last_mem[0:DEPTH-1];
    reg [PTR_WIDTH-1:0] wr_ptr, rd_ptr; reg [PTR_WIDTH:0] count; reg dropping;
    wire pop=(count!=0)&&m_tready;
    wire restart=dropping&&s_valid&&s_sof;
    wire request=s_valid&&(!dropping||restart);
    wire overflow_event=request&&(count==DEPTH)&&!pop;
    wire push=request&&!overflow_event;
    assign full=(count==DEPTH);
    assign empty=(count==0);
    // AXIS ready on an empty queue is legal, not an underflow request.
    assign underflow=1'b0;
    assign m_tvalid=(count!=0); assign m_tdata=data_mem[rd_ptr]; assign m_tkeep=2'b11;
    assign m_tuser=user_mem[rd_ptr]; assign m_tlast=last_mem[rd_ptr];
    always @(posedge clk) begin
        if(rst) begin wr_ptr<=0;rd_ptr<=0;count<=0;dropping<=1;drop_count<=0;overflow<=0; end
        else begin
            overflow<=overflow_event;
            // Never retract an AXIS beat already offered to the consumer.
            // Drain the accepted prefix, reject the rest of the input frame,
            // then resume only with a new SOF that can actually be queued.
            if(overflow_event) begin dropping<=1;drop_count<=drop_count+1'b1;end
            else if(restart && push) dropping<=0;
            if(push) begin data_mem[wr_ptr]<=s_data;user_mem[wr_ptr]<=s_sof;last_mem[wr_ptr]<=s_eol;wr_ptr<=wr_ptr+1'b1;end
            if(pop) rd_ptr<=rd_ptr+1'b1;
            case({push,pop}) 2'b10:count<=count+1'b1;2'b01:count<=count-1'b1;default:count<=count;endcase
        end
    end
endmodule
