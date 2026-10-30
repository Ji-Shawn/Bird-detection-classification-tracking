`timescale 1ns/1ps

module audio_control_top (
    (* X_INTERFACE_PARAMETER="XIL_INTERFACENAME clk_98m304, ASSOCIATED_BUSIF S_AXI:M_AXIS_PCM:M_AXIS_MODEL_MEL, ASSOCIATED_RESET resetn" *)
    (* X_INTERFACE_INFO="xilinx.com:signal:clock:1.0 clk_98m304 CLK" *)
    input wire clk_98m304,
    (* X_INTERFACE_PARAMETER="XIL_INTERFACENAME resetn, POLARITY ACTIVE_LOW" *)
    (* X_INTERFACE_INFO="xilinx.com:signal:reset:1.0 resetn RST" *)
    input wire resetn,
    input wire [3:0] board_keys_n,
    input wire mic_sd_0,input wire mic_sd_1,input wire mic_sd_2,input wire mic_sd_3,
    output wire mic_sck,output wire mic_ws,
    output wire servo_pan,output wire servo_tilt,
    input wire [7:0] stat_mean_y,input wire [15:0] stat_dark_ratio_q15,
    input wire [31:0] stat_frame_count,input wire [31:0] stat_video_drop_count,
    input wire stat_frame_strobe,
    (* X_INTERFACE_PARAMETER="XIL_INTERFACENAME S_AXI, PROTOCOL AXI4LITE, DATA_WIDTH 32, ADDR_WIDTH 8" *)
    (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI AWADDR" *) input wire [7:0] s_axi_awaddr,
    (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI AWPROT" *) input wire [2:0] s_axi_awprot,
    (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI AWVALID" *) input wire s_axi_awvalid,
    (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI AWREADY" *) output wire s_axi_awready,
    (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI WDATA" *) input wire [31:0] s_axi_wdata,
    (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI WSTRB" *) input wire [3:0] s_axi_wstrb,
    (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI WVALID" *) input wire s_axi_wvalid,
    (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI WREADY" *) output wire s_axi_wready,
    (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI BRESP" *) output wire [1:0] s_axi_bresp,
    (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI BVALID" *) output wire s_axi_bvalid,
    (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI BREADY" *) input wire s_axi_bready,
    (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI ARADDR" *) input wire [7:0] s_axi_araddr,
    (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI ARPROT" *) input wire [2:0] s_axi_arprot,
    (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI ARVALID" *) input wire s_axi_arvalid,
    (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI ARREADY" *) output wire s_axi_arready,
    (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI RDATA" *) output wire [31:0] s_axi_rdata,
    (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI RRESP" *) output wire [1:0] s_axi_rresp,
    (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI RVALID" *) output wire s_axi_rvalid,
    (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI RREADY" *) input wire s_axi_rready,
    output wire m_axis_pcm_tvalid,input wire m_axis_pcm_tready,output wire [127:0] m_axis_pcm_tdata,
    output wire [15:0] m_axis_pcm_tkeep,output wire m_axis_pcm_tlast,
    output wire m_axis_model_mel_tvalid,input wire m_axis_model_mel_tready,
    output wire [15:0] m_axis_model_mel_tdata,output wire m_axis_model_mel_tuser,
    output wire m_axis_model_mel_tlast,output wire [31:0] m_axis_model_mel_audio_seq,
    output wire gamma_event_valid,output wire [16:0] gamma_event_data,
    output wire enhance_master_enable,output wire [31:0] audio_overflow_count,
    output wire [31:0] model_mel_drop_count
);
    wire rst=!resetn;
    wire signed [23:0] raw0,raw1,raw2,raw3,beam;
    wire raw_valid,block_start,beam_valid,beam_overflow,overflow_sticky;
    wire gamma_wr_en,gamma_commit;wire [7:0] gamma_addr,gamma_data;
    wire enhance_mode_wr; wire [1:0] enhance_mode;
    // Only the external asynchronous input -> first stage is excepted in XDC.
    // The second stage and AXI readback remain timed at clk_98m304.
    (* ASYNC_REG="TRUE" *) reg [3:0] board_keys_sync1,board_keys_sync2;
    always @(posedge clk_98m304) begin
        if(!resetn)begin board_keys_sync1<=4'hf;board_keys_sync2<=4'hf;end
        else begin board_keys_sync1<=board_keys_n;board_keys_sync2<=board_keys_sync1;end
    end
    wire mel_wr_en,mel_commit;wire [6:0] mel_index;wire [15:0] mel_data;wire [31:0] mel_seq;
    wire [5:0] sd0,sd1,sd2,sd3,ad0,ad1,ad2,ad3;
    wire [14:0] sf0,sf1,sf2,sf3,af0,af1,af2,af3;
    wire signed [15:0] sw0,sw1,sw2,sw3,aw0,aw1,aw2,aw3;
    wire config_apply;wire model_abort;wire [31:0] bad_mel_commit;
    wire [31:0] status_flags={29'd0,bad_mel_commit!=0,overflow_sticky,audio_overflow_count!=0};

    wire [31:0] servo_pan_ticks,servo_tilt_ticks,servo_status,servo_count,servo_left_frames,servo_right_frames;
    wire [2:0] servo_command;
    wire servo_command_valid;
    servo_pwm_pair u_servo(.clk(clk_98m304),.resetn(resetn),
        .command_valid(servo_command_valid),.command(servo_command),
        .pan_ticks(servo_pan_ticks),.tilt_ticks(servo_tilt_ticks),
        .servo_pan(servo_pan),.servo_tilt(servo_tilt),
        .status(servo_status),.accepted_count(servo_count),
        .left_frame_count(servo_left_frames),.right_frame_count(servo_right_frames));
    av_regs u_regs(
        .servo_pan_ticks(servo_pan_ticks),.servo_tilt_ticks(servo_tilt_ticks),
        .servo_command(servo_command),.servo_command_valid(servo_command_valid),
        .servo_status(servo_status),.servo_count(servo_count),
        .servo_left_frames(servo_left_frames),.servo_right_frames(servo_right_frames),
        .s_axi_aclk(clk_98m304),.s_axi_aresetn(resetn),
        .s_axi_awaddr(s_axi_awaddr),.s_axi_awvalid(s_axi_awvalid),.s_axi_awready(s_axi_awready),
        .s_axi_wdata(s_axi_wdata),.s_axi_wstrb(s_axi_wstrb),.s_axi_wvalid(s_axi_wvalid),.s_axi_wready(s_axi_wready),
        .s_axi_bresp(s_axi_bresp),.s_axi_bvalid(s_axi_bvalid),.s_axi_bready(s_axi_bready),
        .s_axi_araddr(s_axi_araddr),.s_axi_arvalid(s_axi_arvalid),.s_axi_arready(s_axi_arready),
        .s_axi_rdata(s_axi_rdata),.s_axi_rresp(s_axi_rresp),.s_axi_rvalid(s_axi_rvalid),.s_axi_rready(s_axi_rready),
        .block_start(block_start),.frame_start(stat_frame_strobe),.status_flags(status_flags),
        .mean_y(stat_mean_y),.dark_ratio_q15(stat_dark_ratio_q15),.frame_count(stat_frame_count),
        .video_drop_count(stat_video_drop_count),.model_mel_drop_count(model_mel_drop_count),
        .error_count(audio_overflow_count+bad_mel_commit),.board_keys_n(board_keys_sync2),.enhance_enable(enhance_master_enable),
        .enhance_mode_wr(enhance_mode_wr),.enhance_mode(enhance_mode),
        .gamma_wr_en(gamma_wr_en),.gamma_wr_addr(gamma_addr),.gamma_wr_data(gamma_data),.gamma_commit(gamma_commit),
        .mel_wr_en(mel_wr_en),.mel_wr_index(mel_index),.mel_wr_data(mel_data),
        .mel_audio_seq(mel_seq),.mel_commit(mel_commit),
        .audio_config_apply(config_apply),
        .shadow_audio_delay_0(sd0),.shadow_audio_delay_1(sd1),.shadow_audio_delay_2(sd2),.shadow_audio_delay_3(sd3),
        .shadow_audio_frac_0(sf0),.shadow_audio_frac_1(sf1),.shadow_audio_frac_2(sf2),.shadow_audio_frac_3(sf3),
        .shadow_audio_weight_0(sw0),.shadow_audio_weight_1(sw1),.shadow_audio_weight_2(sw2),.shadow_audio_weight_3(sw3),
        .audio_delay_0(ad0),.audio_delay_1(ad1),.audio_delay_2(ad2),.audio_delay_3(ad3),
        .audio_frac_0(af0),.audio_frac_1(af1),.audio_frac_2(af2),.audio_frac_3(af3),
        .audio_weight_0(aw0),.audio_weight_1(aw1),.audio_weight_2(aw2),.audio_weight_3(aw3));

    // Reuse the existing asynchronous event FIFO: no new BD pins or CDC path.
    // Ordinary commits carry no address/data semantics; canonicalize those
    // fields so a preceding gamma write cannot imitate a reserved mode packet.
    assign gamma_event_valid=gamma_wr_en||gamma_commit||enhance_mode_wr;
    assign gamma_event_data=enhance_mode_wr ? {1'b1,8'he1,6'b101001,enhance_mode} :
                            gamma_commit ? {1'b1,16'd0} : {1'b0,gamma_addr,gamma_data};

    audio_frontend_top u_audio(.clk_98m304(clk_98m304),.rst(rst),
        .mic_sd_0(mic_sd_0),.mic_sd_1(mic_sd_1),.mic_sd_2(mic_sd_2),.mic_sd_3(mic_sd_3),
        .mic_sck(mic_sck),.mic_ws(mic_ws),.config_apply(config_apply),
        .shadow_delay_0(sd0),.shadow_delay_1(sd1),.shadow_delay_2(sd2),.shadow_delay_3(sd3),
        .shadow_frac_0(sf0),.shadow_frac_1(sf1),.shadow_frac_2(sf2),.shadow_frac_3(sf3),
        .shadow_weight_0(sw0),.shadow_weight_1(sw1),.shadow_weight_2(sw2),.shadow_weight_3(sw3),
        .raw_0(raw0),.raw_1(raw1),.raw_2(raw2),.raw_3(raw3),.raw_valid(raw_valid),
        .block_start(block_start),.beam_sample(beam),.beam_valid(beam_valid),
        .beam_overflow(beam_overflow),.overflow_sticky(overflow_sticky));
    audio_dma_axis u_pcm(.clk(clk_98m304),.rst(rst),.raw_valid(raw_valid),.block_start(block_start),
        .raw_0(raw0),.raw_1(raw1),.raw_2(raw2),.raw_3(raw3),.m_tvalid(m_axis_pcm_tvalid),
        .m_tready(m_axis_pcm_tready),.m_tdata(m_axis_pcm_tdata),.m_tkeep(m_axis_pcm_tkeep),
        .m_tlast(m_axis_pcm_tlast),.overflow_count(audio_overflow_count));
    model_mel_axis u_mel(.clk(clk_98m304),.rst(rst),.s_wr_en(mel_wr_en),.s_wr_index(mel_index),
        .s_wr_data(mel_data),.s_audio_seq(mel_seq),.s_commit(mel_commit),
        .m_tvalid(m_axis_model_mel_tvalid),.m_tready(m_axis_model_mel_tready),
        .m_tdata(m_axis_model_mel_tdata),.m_tuser(m_axis_model_mel_tuser),
        .m_tlast(m_axis_model_mel_tlast),.m_audio_seq(m_axis_model_mel_audio_seq),
        .column_abort(model_abort),.model_mel_drop(model_mel_drop_count),.bad_commit_count(bad_mel_commit));
endmodule
