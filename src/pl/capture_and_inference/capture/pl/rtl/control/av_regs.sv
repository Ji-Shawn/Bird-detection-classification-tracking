`timescale 1ns/1ps

module av_regs #(
    parameter [31:0] BUILD_ID = 32'h00000000
) (
    input wire s_axi_aclk, input wire s_axi_aresetn,
    input wire [7:0] s_axi_awaddr, input wire s_axi_awvalid, output wire s_axi_awready,
    input wire [31:0] s_axi_wdata, input wire [3:0] s_axi_wstrb,
    input wire s_axi_wvalid, output wire s_axi_wready,
    output reg [1:0] s_axi_bresp, output reg s_axi_bvalid, input wire s_axi_bready,
    input wire [7:0] s_axi_araddr, input wire s_axi_arvalid, output wire s_axi_arready,
    output reg [31:0] s_axi_rdata, output reg [1:0] s_axi_rresp,
    output reg s_axi_rvalid, input wire s_axi_rready,
    input wire block_start, input wire frame_start,
    input wire [31:0] status_flags, input wire [7:0] mean_y,
    input wire [15:0] dark_ratio_q15, input wire [31:0] frame_count,
    input wire [31:0] video_drop_count, input wire [31:0] model_mel_drop_count,
    input wire [31:0] error_count,
    input wire [3:0] board_keys_n,
    output wire enhance_enable,
    output reg enhance_mode_wr, output reg [1:0] enhance_mode,
    output reg gamma_wr_en, output reg [7:0] gamma_wr_addr,
    output reg [7:0] gamma_wr_data, output reg gamma_commit,
    output reg mel_wr_en, output reg [6:0] mel_wr_index,
    output reg [15:0] mel_wr_data, output reg [31:0] mel_audio_seq,
    output reg mel_commit,
    output wire [7:0] mean_enter_threshold,
    output wire [7:0] mean_exit_threshold,
    output wire [7:0] dark_y_threshold,
    output wire [15:0] dark_ratio_enter_q15,
    output wire audio_config_apply,
    output wire [5:0] shadow_audio_delay_0, shadow_audio_delay_1,
    output wire [5:0] shadow_audio_delay_2, shadow_audio_delay_3,
    output wire [14:0] shadow_audio_frac_0, shadow_audio_frac_1,
    output wire [14:0] shadow_audio_frac_2, shadow_audio_frac_3,
    output wire signed [15:0] shadow_audio_weight_0, shadow_audio_weight_1,
    output wire signed [15:0] shadow_audio_weight_2, shadow_audio_weight_3,
    output reg [5:0] audio_delay_0, audio_delay_1, audio_delay_2, audio_delay_3,
    output reg [14:0] audio_frac_0, audio_frac_1, audio_frac_2, audio_frac_3,
    output reg signed [15:0] audio_weight_0, audio_weight_1,
    output reg signed [15:0] audio_weight_2, audio_weight_3,
    output reg [31:0] servo_pan_ticks, servo_tilt_ticks,
    output reg servo_command_valid, output reg [2:0] servo_command,
    input wire [31:0] servo_status, servo_count, servo_left_frames, servo_right_frames
);
    localparam [1:0] OKAY = 2'b00, SLVERR = 2'b10;
    reg aw_hold, w_hold;
    reg [7:0] awaddr_hold;
    reg [31:0] wdata_hold;
    reg [3:0] wstrb_hold;
    reg [31:0] control_reg, thresholds_reg, dark_ratio_reg;
    reg [31:0] shadow_delay [0:3];
    reg signed [15:0] shadow_weight [0:3];
    reg audio_pending, gamma_pending;
    integer i;

    assign s_axi_awready = !aw_hold && !s_axi_bvalid;
    assign s_axi_wready = !w_hold && !s_axi_bvalid;
    assign s_axi_arready = !s_axi_rvalid;
    assign enhance_enable = control_reg[0];
    assign mean_enter_threshold = thresholds_reg[7:0];
    assign mean_exit_threshold = thresholds_reg[15:8];
    assign dark_y_threshold = thresholds_reg[23:16];
    assign dark_ratio_enter_q15 = dark_ratio_reg[15:0];
    assign audio_config_apply = block_start && audio_pending;
    assign shadow_audio_delay_0=shadow_delay[0][5:0];
    assign shadow_audio_delay_1=shadow_delay[1][5:0];
    assign shadow_audio_delay_2=shadow_delay[2][5:0];
    assign shadow_audio_delay_3=shadow_delay[3][5:0];
    assign shadow_audio_frac_0=shadow_delay[0][20:6];
    assign shadow_audio_frac_1=shadow_delay[1][20:6];
    assign shadow_audio_frac_2=shadow_delay[2][20:6];
    assign shadow_audio_frac_3=shadow_delay[3][20:6];
    assign shadow_audio_weight_0=shadow_weight[0];
    assign shadow_audio_weight_1=shadow_weight[1];
    assign shadow_audio_weight_2=shadow_weight[2];
    assign shadow_audio_weight_3=shadow_weight[3];

    function [31:0] merge_wstrb;
        input [31:0] old_value, new_value;
        input [3:0] strobes;
        integer byte_index;
        begin
            merge_wstrb = old_value;
            for (byte_index=0; byte_index<4; byte_index=byte_index+1)
                if (strobes[byte_index])
                    merge_wstrb[byte_index*8 +: 8] = new_value[byte_index*8 +: 8];
        end
    endfunction

    function is_writable;
        input [7:0] address;
        begin
            case (address)
                8'h0c,8'h2c,8'h30,8'h34,8'h38,8'h3c,
                8'h40,8'h44,8'h48,8'h4c,
                8'h50,8'h54,8'h58,8'h5c,8'h60,
                8'h68,8'h6c,8'h70,8'h74,8'h78,8'h7c,8'h80,8'h9c: is_writable=1'b1;
                default: is_writable=1'b0;
            endcase
        end
    endfunction

    function is_readable;
        input [7:0] address;
            begin is_readable = (address[1:0] == 0) && (address <= 8'ha0); end
    endfunction

    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            aw_hold<=0; w_hold<=0; s_axi_bvalid<=0; s_axi_bresp<=OKAY;
            s_axi_rvalid<=0; s_axi_rresp<=OKAY; s_axi_rdata<=0;
            control_reg<=32'h0;
            enhance_mode<=2'd0; enhance_mode_wr<=0;
            thresholds_reg<={8'd0,8'd64,8'd85,8'd70};
            dark_ratio_reg<=32'd19661;
            gamma_wr_en<=0; gamma_wr_addr<=0; gamma_wr_data<=0; gamma_commit<=0;
            mel_wr_en<=0; mel_wr_index<=0; mel_wr_data<=0; mel_audio_seq<=0; mel_commit<=0;
            audio_pending<=0; gamma_pending<=0;
            servo_pan_ticks<=0; servo_tilt_ticks<=0; servo_command<=0; servo_command_valid<=0;
            for (i=0;i<4;i=i+1) begin shadow_delay[i]<=0; shadow_weight[i]<=16'sd8192; end
            audio_delay_0<=0; audio_delay_1<=0; audio_delay_2<=0; audio_delay_3<=0;
            audio_frac_0<=0; audio_frac_1<=0; audio_frac_2<=0; audio_frac_3<=0;
            audio_weight_0<=16'sd8192; audio_weight_1<=16'sd8192;
            audio_weight_2<=16'sd8192; audio_weight_3<=16'sd8192;
        end else begin
            gamma_wr_en<=0; gamma_commit<=0; mel_wr_en<=0; mel_commit<=0;
            enhance_mode_wr<=0;
            servo_command_valid<=0;
            if (s_axi_awready && s_axi_awvalid) begin aw_hold<=1; awaddr_hold<=s_axi_awaddr; end
            if (s_axi_wready && s_axi_wvalid) begin
                w_hold<=1; wdata_hold<=s_axi_wdata; wstrb_hold<=s_axi_wstrb;
            end
            if (!s_axi_bvalid && aw_hold && w_hold) begin
                aw_hold<=0; w_hold<=0; s_axi_bvalid<=1;
                if ((awaddr_hold[1:0] != 0) || !is_writable(awaddr_hold)) begin
                    s_axi_bresp<=SLVERR;
                end else begin
                    s_axi_bresp<=OKAY;
                    case (awaddr_hold)
                        8'h0c: control_reg<=merge_wstrb(control_reg,wdata_hold,wstrb_hold);
                        8'h2c: thresholds_reg<=merge_wstrb(thresholds_reg,wdata_hold,wstrb_hold);
                        8'h30: dark_ratio_reg<=merge_wstrb(dark_ratio_reg,wdata_hold,wstrb_hold);
                        8'h34: gamma_wr_addr<=merge_wstrb({24'd0,gamma_wr_addr},wdata_hold,wstrb_hold);
                        8'h38: begin
                            gamma_wr_data<=merge_wstrb({24'd0,gamma_wr_data},wdata_hold,wstrb_hold);
                            gamma_wr_en<=1;
                        end
                        8'h3c: if (wdata_hold[0]) begin gamma_commit<=1; gamma_pending<=1; end
                        8'h40: shadow_delay[0]<=merge_wstrb(shadow_delay[0],wdata_hold,wstrb_hold);
                        8'h44: shadow_delay[1]<=merge_wstrb(shadow_delay[1],wdata_hold,wstrb_hold);
                        8'h48: shadow_delay[2]<=merge_wstrb(shadow_delay[2],wdata_hold,wstrb_hold);
                        8'h4c: shadow_delay[3]<=merge_wstrb(shadow_delay[3],wdata_hold,wstrb_hold);
                        8'h50: shadow_weight[0]<=merge_wstrb({16'd0,shadow_weight[0]},wdata_hold,wstrb_hold);
                        8'h54: shadow_weight[1]<=merge_wstrb({16'd0,shadow_weight[1]},wdata_hold,wstrb_hold);
                        8'h58: shadow_weight[2]<=merge_wstrb({16'd0,shadow_weight[2]},wdata_hold,wstrb_hold);
                        8'h5c: shadow_weight[3]<=merge_wstrb({16'd0,shadow_weight[3]},wdata_hold,wstrb_hold);
                        8'h60: if (wdata_hold[0]) audio_pending<=1;
                        8'h68: mel_wr_index<=merge_wstrb({25'd0,mel_wr_index},wdata_hold,wstrb_hold);
                        8'h6c: begin
                            mel_wr_data<=merge_wstrb({16'd0,mel_wr_data},wdata_hold,wstrb_hold);
                            mel_wr_en<=1;
                        end
                        8'h70: mel_audio_seq<=merge_wstrb(mel_audio_seq,wdata_hold,wstrb_hold);
                        8'h74: if (wdata_hold[0]) mel_commit<=1;
                        8'h78: servo_pan_ticks<=merge_wstrb(servo_pan_ticks,wdata_hold,wstrb_hold);
                        8'h7c: servo_tilt_ticks<=merge_wstrb(servo_tilt_ticks,wdata_hold,wstrb_hold);
                        8'h80: if(wstrb_hold[0]) begin
                            servo_command<=wdata_hold[2:0]; servo_command_valid<=1;
                        end
                        // Only an explicit byte-0 write of AUTO or FORCE is a
                        // mode request. Other byte strobes cannot emit events.
                        8'h9c: if(wstrb_hold[0]) begin
                            if(merge_wstrb(32'd0,wdata_hold,wstrb_hold)<=32'd2) begin
                                enhance_mode<=wdata_hold[1:0]; enhance_mode_wr<=1;
                            end else s_axi_bresp<=SLVERR;
                        end
                    endcase
                end
            end
            if (s_axi_bvalid && s_axi_bready) s_axi_bvalid<=0;
            if (frame_start) gamma_pending<=0;
            if (block_start && audio_pending) begin
                audio_delay_0<=shadow_delay[0][5:0]; audio_frac_0<=shadow_delay[0][20:6];
                audio_delay_1<=shadow_delay[1][5:0]; audio_frac_1<=shadow_delay[1][20:6];
                audio_delay_2<=shadow_delay[2][5:0]; audio_frac_2<=shadow_delay[2][20:6];
                audio_delay_3<=shadow_delay[3][5:0]; audio_frac_3<=shadow_delay[3][20:6];
                audio_weight_0<=shadow_weight[0]; audio_weight_1<=shadow_weight[1];
                audio_weight_2<=shadow_weight[2]; audio_weight_3<=shadow_weight[3];
                audio_pending<=0;
            end

            if (s_axi_arready && s_axi_arvalid) begin
                s_axi_rvalid<=1;
                if ((s_axi_araddr[1:0] != 0) || !is_readable(s_axi_araddr)) begin
                    s_axi_rresp<=SLVERR; s_axi_rdata<=0;
                end else begin
                    s_axi_rresp<=OKAY;
                    case (s_axi_araddr)
                        8'h00:s_axi_rdata<=32'h41563031; 8'h04:s_axi_rdata<=32'h0001000A;
                        8'h08:s_axi_rdata<=BUILD_ID; 8'h0c:s_axi_rdata<=control_reg;
                        8'h10:s_axi_rdata<=status_flags; 8'h14:s_axi_rdata<={24'd0,mean_y};
                        8'h18:s_axi_rdata<={16'd0,dark_ratio_q15}; 8'h1c:s_axi_rdata<=frame_count;
                        8'h20:s_axi_rdata<=video_drop_count; 8'h24:s_axi_rdata<=model_mel_drop_count;
                        8'h28:s_axi_rdata<=error_count; 8'h2c:s_axi_rdata<=thresholds_reg;
                        8'h30:s_axi_rdata<=dark_ratio_reg; 8'h34:s_axi_rdata<={24'd0,gamma_wr_addr};
                        8'h38:s_axi_rdata<={24'd0,gamma_wr_data}; 8'h3c:s_axi_rdata<={31'd0,gamma_pending};
                        8'h40:s_axi_rdata<=shadow_delay[0]; 8'h44:s_axi_rdata<=shadow_delay[1];
                        8'h48:s_axi_rdata<=shadow_delay[2]; 8'h4c:s_axi_rdata<=shadow_delay[3];
                        8'h50:s_axi_rdata<={{16{shadow_weight[0][15]}},shadow_weight[0]};
                        8'h54:s_axi_rdata<={{16{shadow_weight[1][15]}},shadow_weight[1]};
                        8'h58:s_axi_rdata<={{16{shadow_weight[2][15]}},shadow_weight[2]};
                        8'h5c:s_axi_rdata<={{16{shadow_weight[3][15]}},shadow_weight[3]};
                        8'h60:s_axi_rdata<={31'd0,audio_pending};
                        8'h64:s_axi_rdata<={30'd0,gamma_pending,audio_pending};
                        8'h68:s_axi_rdata<={25'd0,mel_wr_index};
                        8'h6c:s_axi_rdata<={16'd0,mel_wr_data};
                        8'h70:s_axi_rdata<=mel_audio_seq;
                        8'h74:s_axi_rdata<=32'd0;
                        8'h78:s_axi_rdata<=servo_pan_ticks;
                        8'h7c:s_axi_rdata<=servo_tilt_ticks;
                        8'h80:s_axi_rdata<=0;
                        8'h84:s_axi_rdata<=servo_status;
                        8'h88:s_axi_rdata<=32'h53525631;
                        8'h8c:s_axi_rdata<=servo_count;
                        8'h90:s_axi_rdata<=32'd98305085;
                        8'h94:s_axi_rdata<=servo_left_frames;
                        8'h98:s_axi_rdata<=servo_right_frames;
                        8'h9c:s_axi_rdata<={30'd0,enhance_mode};
                        // K4 identifies the four-PL-key ABI. Values are raw,
                        // active low and already synchronized in audio_control_top.
                        8'ha0:s_axi_rdata<={16'h4b34,12'd0,board_keys_n};
                        default:s_axi_rdata<=0;
                    endcase
                end
            end
            if (s_axi_rvalid && s_axi_rready) s_axi_rvalid<=0;
        end
    end
endmodule
