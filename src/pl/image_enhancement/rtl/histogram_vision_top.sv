`timescale 1ns/1ps
module histogram_vision_top #(parameter integer WIDTH=1920,HEIGHT=1080)(
 input wire clk,rst,config_done,master_enable,upstream_error,fifo_overflow,
 input wire pixel_valid,frame_start,line_end,frame_end,input wire[15:0]pixel_rgb565,
 input wire[10:0]x,y,output wire out_valid,out_sof,out_eol,out_eof,
 output wire[15:0]out_pixel,output wire[10:0]out_x,out_y,
 output wire[7:0]mean_y,output wire[8:0]dark_ratio_q8,output wire enhance_active,enhance_led_n,
 output wire[8:0]debug_alpha,output wire debug_error,debug_stats_valid,input_ready);
 localparam CW=$clog2(WIDTH*HEIGHT+1);
 wire hist_ready,hist_done,hist_error,bin_read,bin_valid,build_done,build_error,gain_write;
 wire[7:0]bin_addr,gain_addr;wire[CW-1:0]bin_count;wire[20:0]gain_data;
 wire[31:0]build_cycles;wire mode;
 reg active_bank,initialized;reg[7:0]init_addr;reg frame_mode;
 reg[31:0]frame_id;
 (* ram_style="distributed" *) reg[20:0]lut0[0:255],lut1[0:255];
 wire fault=upstream_error||fifo_overflow||hist_error||build_error||!config_done;
 wire processing_mode=frame_start ? (mode && master_enable) : frame_mode;
 wire[7:0]r={pixel_rgb565[15:11],pixel_rgb565[15:13]};
 wire[7:0]g={pixel_rgb565[10:5],pixel_rgb565[10:9]};
 wire[7:0]b={pixel_rgb565[4:0],pixel_rgb565[4:2]};
 wire[7:0]level=(r>g)?((r>b)?r:b):((g>b)?g:b);
 wire[20:0]gain=active_bank?lut1[level]:lut0[level];
 wire[74:0]token={processing_mode,(frame_start?frame_id+1'b1:frame_id),y,x,line_end,frame_end,frame_start,pixel_valid,pixel_rgb565};
 wire[74:0]out_token;
 frame_histogram #(.WIDTH(WIDTH),.HEIGHT(HEIGHT)) stats(
 .clk(clk),.rst(rst),.pixel_valid(pixel_valid),.sof(frame_start),.eof(frame_end),.rgb565(pixel_rgb565),
 .release_frame(build_done),.bin_read(bin_read),.bin_addr(bin_addr),.ready(hist_ready),.done(hist_done),.error(hist_error),
 .bin_valid(bin_valid),.bin_count(bin_count),.mean_y(mean_y),.dark_ratio(dark_ratio_q8));
 hist_lut_builder builder(.clk(clk),.rst(rst),.start(hist_done),.mean_y(mean_y),.bin_read(bin_read),.bin_addr(bin_addr),
 .bin_valid(bin_valid),.bin_count({{(32-CW){1'b0}},bin_count}),.gain_write(gain_write),.gain_addr(gain_addr),.gain_data(gain_data),
 .done(build_done),.error(build_error),.build_cycles(build_cycles));
 hist_mode_ctrl ctrl(.clk(clk),.rst(rst),.stats_valid(hist_done),.fault(fault),.mean_y(mean_y),.active(mode));
 hist_gain_pipeline pixels(.clk(clk),.rst(rst),.s_token(token),.gain(gain),.alpha(9'd256),
 .bypass(!processing_mode || fault),.m_token(out_token));
 always @(posedge clk)begin
 if(rst)begin initialized<=0;init_addr<=0;active_bank<=0;frame_id<=32'hffffffff;frame_mode<=0;end
 else begin
 if(!initialized)begin
 lut0[init_addr]<=21'd262144;lut1[init_addr]<=21'd262144;
 if(init_addr==255)initialized<=1;else init_addr<=init_addr+1'b1;
 end else if(gain_write)begin
 if(active_bank)lut0[gain_addr]<=gain_data;else lut1[gain_addr]<=gain_data;
 end
 // Builder takes thousands of cycles, so the four-stage pixel path has
 // drained before bank swap. Output FIFO stores already transformed words.
 if(build_done && !fault)active_bank<=!active_bank;
 if(pixel_valid && frame_start)begin frame_id<=frame_id+1'b1;frame_mode<=mode && master_enable;end
 end end
 assign input_ready=initialized && hist_ready && !fault && !rst;
 assign debug_error=fault;assign debug_stats_valid=hist_done;
 assign out_pixel=out_token[15:0];assign out_valid=out_token[16];assign out_sof=out_token[17];
 assign out_eof=out_token[18];assign out_eol=out_token[19];assign out_x=out_token[30:20];assign out_y=out_token[41:31];
 assign enhance_active=frame_mode && !fault;
 assign debug_alpha=enhance_active ? 9'd256 : 9'd0;
 assign enhance_led_n=!enhance_active;
endmodule
