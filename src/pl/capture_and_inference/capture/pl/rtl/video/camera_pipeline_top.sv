`timescale 1ns/1ps

module camera_pipeline_top #(
    parameter integer FRAME_WIDTH = 1920,
    parameter integer FRAME_HEIGHT = 1080
) (
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME cam_pclk, ASSOCIATED_BUSIF m_axis_video:m_axis_model_video, ASSOCIATED_RESET resetn, FREQ_HZ 84000000" *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 cam_pclk CLK" *)
    input wire cam_pclk, input wire resetn,
    input wire cam_vsync, input wire cam_href, input wire [7:0] cam_d,
    input wire camera_configured, input wire camera_test_pattern,
    input wire enhance_master_enable,
    input wire gamma_wr_en, input wire [7:0] gamma_wr_addr, input wire [7:0] gamma_wr_data,
    input wire gamma_commit,
    output wire m_axis_video_tvalid, input wire m_axis_video_tready,
    output wire [15:0] m_axis_video_tdata, output wire [1:0] m_axis_video_tkeep,
    output wire m_axis_video_tuser, output wire m_axis_video_tlast,
    output wire m_axis_model_video_tvalid, input wire m_axis_model_video_tready,
    output wire [23:0] m_axis_model_video_tdata,
    output wire m_axis_model_video_tuser, output wire m_axis_model_video_tlast,
    output wire [7:0] mean_y, output wire [15:0] dark_ratio_q15,
    output wire [31:0] frame_count, output wire [31:0] video_drop_count,
    output wire [31:0] model_video_drop_count, output wire enhance_active,
    output wire frame_start, output wire enhance_led_n,
    output wire [15:0] enhancement_debug
);
    wire rst = !resetn;
    // The retained board profile (4740=21) presents a LOW VSYNC pulse
    // during vertical blanking; all observed HREF data is at VSYNC HIGH.
    // The capture core uses an active-HIGH blanking/sync convention.
    // Normalize at the sensor boundary, not in the frozen AXIS interface.
    // Capture the source-synchronous bus once at a common register boundary. Direct
    // HREF/VSYNC fanout into the receiver's many fabric registers can sample
    // different cycles when the external edge is near the capture edge.
    // Data and both markers receive exactly the same one-clock latency.
    // Fabric placement leaves routing delay available for the established
    // external hold constraint. Forced IOB placement fails that constraint.
    // Keep one physical sampling register per input; do not replicate it.
    (* IOB="FALSE", KEEP="TRUE", DONT_TOUCH="TRUE" *) reg [7:0] cam_input_data;
    (* IOB="FALSE", KEEP="TRUE", DONT_TOUCH="TRUE" *) reg cam_input_href,cam_input_vsync;
    always @(posedge cam_pclk)begin
        cam_input_data<=cam_d;cam_input_href<=cam_href;cam_input_vsync<=cam_vsync;
    end
    wire capture_vsync = !cam_input_vsync;
    wire px_valid, px_sof, px_eol, frame_good;
    (* mark_debug="true" *) wire config_done;
    wire test_pattern;
    (* mark_debug="true" *) wire frame_end,frame_size_error,line_size_error,format_error;
    (* mark_debug="true" *) wire byte_phase,camera_active;
    (* mark_debug="true" *) wire [31:0] pixel_count;
    (* mark_debug="true" *) wire [15:0] line_count,current_width,current_height;
    (* mark_debug="true" *) wire fifo_full,fifo_empty,fifo_overflow,fifo_underflow;
    wire [15:0] px_data;
    wire [10:0] px_x;
    wire [10:0] px_y;
    wire framed_valid, framed_sof, framed_eol;
    wire [15:0] framed_data;
    wire model_abort;

    // The capture and downstream adapter are frozen. Only this PCLK-domain
    // insertion performs frame-atomic RAW/enhanced selection.
    // Preserve the established first-stage name matched by the existing XDC.
    // Only the asynchronous source -> stage1 is excepted; stage1 -> stage2
    // remains timed at PCLK. No clock/pin/blanket timing exceptions are added.
    (* ASYNC_REG="TRUE" *) reg enhance_enable_s1,enhance_enable_s2;
    always @(posedge cam_pclk) begin
        if(rst)begin enhance_enable_s1<=0;enhance_enable_s2<=0;end
        else begin enhance_enable_s1<=enhance_master_enable;enhance_enable_s2<=enhance_enable_s1;end
    end
    // gamma_* are already transferred atomically by gamma_event_cdc. Decode
    // the complete reserved event; ordinary gamma writes/commits cannot select
    // a mode. A sensor recovery retains this user choice; PL reset restores AUTO.
    reg [1:0] enhance_mode_request;
    always @(posedge cam_pclk) begin
        if(rst)enhance_mode_request<=0;
        else if(gamma_commit && !gamma_wr_en && gamma_wr_addr==8'he1 &&
                gamma_wr_data[7:2]==6'b101001 &&
                gamma_wr_data[1:0]!=2'd3)
            enhance_mode_request<=gamma_wr_data[1:0];
    end
    wire vision_valid,vision_sof,vision_eol,vision_eof;
    wire [15:0] vision_data;
    wire [10:0] vision_x;
    wire [10:0] vision_y;
    wire [8:0] dark_ratio_q8;
    wire [15:0] vision_debug;
    wire vision_fault;
    reg recover_reset,recovery_seen,overflow_in_frame;
    reg [2:0] recovery_good_frames;
    reg [2:0] capture_errors_seen;
    // A transient malformed sensor frame must not disable enhancement forever.
    // Quarantine four complete, receiver-validated frames, then reset ONLY the
    // enhancement analysis in vertical blanking. Capture and both output FIFOs
    // keep running; no partial histogram/table can be committed during recovery.
    always @(posedge cam_pclk) begin
        if(rst || !config_done)begin
            recover_reset<=0;recovery_seen<=0;overflow_in_frame<=0;recovery_good_frames<=0;
            capture_errors_seen<=0;
        end else begin
            capture_errors_seen<=capture_errors_seen | {frame_size_error,line_size_error,format_error};
            recover_reset<=0;
            if(px_valid && px_sof)overflow_in_frame<=0;
            if(fifo_overflow)overflow_in_frame<=1;
            if(frame_end)begin
                if(!vision_fault)recovery_good_frames<=0;
                else if(frame_good && !frame_size_error && !line_size_error && !format_error &&
                        !overflow_in_frame && !fifo_overflow)begin
                    if(recovery_good_frames==3)begin
                        recover_reset<=1;recovery_seen<=1;recovery_good_frames<=0;
                    end else recovery_good_frames<=recovery_good_frames+1'b1;
                end else recovery_good_frames<=0;
            end
        end
    end
    assign enhancement_debug={recovery_seen,vision_debug[14:13],capture_errors_seen[2],
                              vision_debug[11:2],capture_errors_seen[1:0]};
    // u_rx.frame_end reports physical VSYNC in blanking (pixel_valid=0).
    // M15 consumes an EOF token with the final active pixel instead. Adapt
    // only this boundary: retain the receiver's delayed size/format checks
    // on upstream_error, so a short/extra/malformed frame still fails closed.
    wire vision_input_eof = px_valid && px_eol &&
                            (px_x == FRAME_WIDTH-1) && (px_y == FRAME_HEIGHT-1);
    assign dark_ratio_q15 = {dark_ratio_q8,7'b0};
    assign frame_start = px_valid && px_sof;

    ov5640_sccb_config u_config (
        .pclk(cam_pclk),.resetn(resetn),.configured_async(camera_configured),
        .test_pattern_async(camera_test_pattern),.config_done(config_done),.test_pattern(test_pattern)
    );
    ov5640_dvp_capture #(.FRAME_WIDTH(FRAME_WIDTH), .FRAME_HEIGHT(FRAME_HEIGHT)) u_rx (
        .pclk(cam_pclk), .rst(rst),.config_done(config_done), .vsync(capture_vsync), .href(cam_input_href), .d(cam_input_data),
        .pixel_valid(px_valid), .pixel_rgb565(px_data), .frame_start(px_sof), .line_end(px_eol),
        .frame_end(frame_end),.frame_good(frame_good),.frame_count(frame_count),
        .frame_size_error(frame_size_error),.line_size_error(line_size_error),.format_error(format_error),
        .byte_phase(byte_phase),.camera_active(camera_active),.pixel_count(pixel_count),
        .line_count(line_count),.current_width(current_width),.current_height(current_height),.x(px_x),.y(px_y)
    );
    auto_vision_top #(.WIDTH(FRAME_WIDTH),.HEIGHT(FRAME_HEIGHT),.RUNTIME_MODE_ENABLE(1)) u_auto_vision (
        .clk(cam_pclk),.rst(rst),.config_done(config_done && !recover_reset),.master_enable(enhance_enable_s2),
        .force_enhance(enhance_mode_request==2'd2),.force_disable(enhance_mode_request==2'd1),
        .upstream_error(frame_size_error | line_size_error | format_error),.fifo_overflow(fifo_overflow),
        .pixel_valid(px_valid),.pixel_rgb565(px_data),.frame_start(px_sof),.line_end(px_eol),.frame_end(vision_input_eof),
        .x(px_x),.y(px_y),.out_valid(vision_valid),.out_pixel(vision_data),.out_sof(vision_sof),
        .out_eol(vision_eol),.out_eof(vision_eof),.out_x(vision_x),.out_y(vision_y),
        .mean_y(mean_y),.dark_ratio_q8(dark_ratio_q8),.enhance_active(enhance_active),
        .enhance_led_n(enhance_led_n),.debug_status(vision_debug),.fault_active(vision_fault)
    );
    assign framed_sof=vision_sof;
    assign framed_eol=vision_eol;
    camera_eth_adapter #(.FRAME_WIDTH(FRAME_WIDTH)) u_adapter (
        .clk(cam_pclk), .rst(rst), .s_valid(vision_valid), .s_data(vision_data),
        .s_sof(vision_sof), .s_eol(vision_eol),.s_x(vision_x),.test_pattern(test_pattern),
        .selected_valid(framed_valid),.selected_data(framed_data),.m_tvalid(m_axis_video_tvalid),
        .m_tready(m_axis_video_tready), .m_tdata(m_axis_video_tdata),
        .m_tkeep(m_axis_video_tkeep), .m_tuser(m_axis_video_tuser),
        .m_tlast(m_axis_video_tlast), .drop_count(video_drop_count),
        .full(fifo_full),.empty(fifo_empty),.overflow(fifo_overflow),.underflow(fifo_underflow)
    );

    model_video_axis u_model_fifo (
        .clk(cam_pclk), .rst(rst), .s_valid(framed_valid),
        .s_data({framed_data[15:11], framed_data[15:13],
                 framed_data[10:5], framed_data[10:9],
                 framed_data[4:0], framed_data[4:2]}),
        .s_sof(framed_sof), .s_eol(framed_eol),
        .m_tvalid(m_axis_model_video_tvalid), .m_tready(m_axis_model_video_tready),
        .m_tdata(m_axis_model_video_tdata), .m_tuser(m_axis_model_video_tuser),
        .m_tlast(m_axis_model_video_tlast), .frame_abort(model_abort),
        .drop_count(model_video_drop_count)
    );

    wire unused_control = gamma_wr_en | gamma_commit |
                          (|gamma_wr_addr) | (|gamma_wr_data) | frame_good |
                          (|px_x) | (|px_y) | model_abort;
endmodule
