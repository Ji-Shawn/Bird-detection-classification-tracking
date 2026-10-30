`timescale 1ns/1ps

// Stable board-internal seam for the future inference core. Replace this module
// with the model adapter; the producer-side AXI4-Stream contracts do not change.
(* DONT_TOUCH = "TRUE" *)
module model_ingress_stub (
    (* X_INTERFACE_PARAMETER="XIL_INTERFACENAME video_clk, ASSOCIATED_BUSIF S_AXIS_VIDEO, ASSOCIATED_RESET video_resetn" *)
    (* X_INTERFACE_INFO="xilinx.com:signal:clock:1.0 video_clk CLK" *)
    input wire video_clk,
    (* X_INTERFACE_PARAMETER="XIL_INTERFACENAME video_resetn, POLARITY ACTIVE_LOW" *)
    (* X_INTERFACE_INFO="xilinx.com:signal:reset:1.0 video_resetn RST" *)
    input wire video_resetn,
    input wire s_axis_video_tvalid,
    output wire s_axis_video_tready,
    input wire [23:0] s_axis_video_tdata,
    input wire s_axis_video_tuser,
    input wire s_axis_video_tlast,

    (* X_INTERFACE_PARAMETER="XIL_INTERFACENAME mel_clk, ASSOCIATED_BUSIF S_AXIS_MEL, ASSOCIATED_RESET mel_resetn" *)
    (* X_INTERFACE_INFO="xilinx.com:signal:clock:1.0 mel_clk CLK" *)
    input wire mel_clk,
    (* X_INTERFACE_PARAMETER="XIL_INTERFACENAME mel_resetn, POLARITY ACTIVE_LOW" *)
    (* X_INTERFACE_INFO="xilinx.com:signal:reset:1.0 mel_resetn RST" *)
    input wire mel_resetn,
    input wire s_axis_mel_tvalid,
    output wire s_axis_mel_tready,
    input wire [15:0] s_axis_mel_tdata,
    input wire s_axis_mel_tuser,
    input wire s_axis_mel_tlast
);
    (* KEEP = "TRUE" *) reg [31:0] video_words;
    (* KEEP = "TRUE" *) reg [31:0] mel_words;
    assign s_axis_video_tready = video_resetn;
    assign s_axis_mel_tready = mel_resetn;
    always @(posedge video_clk) begin
        if (!video_resetn) video_words <= 0;
        else if (s_axis_video_tvalid && s_axis_video_tready)
            video_words <= video_words + 1'b1 + {31'd0, s_axis_video_tuser & s_axis_video_tlast & s_axis_video_tdata[0]};
    end
    always @(posedge mel_clk) begin
        if (!mel_resetn) mel_words <= 0;
        else if (s_axis_mel_tvalid && s_axis_mel_tready)
            mel_words <= mel_words + 1'b1 + {31'd0, s_axis_mel_tuser & s_axis_mel_tlast & s_axis_mel_tdata[0]};
    end
endmodule
