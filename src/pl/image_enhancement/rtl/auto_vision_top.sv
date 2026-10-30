`timescale 1ns/1ps
// Continuous camera input: histogram availability never gates pixel delivery.
module auto_vision_top #(
 parameter integer WIDTH=1920,HEIGHT=1080,
 parameter integer STARTUP_FRAMES=30,CONFIRM_FRAMES=5,HOLD_FRAMES=30,
 parameter [1:0] MODE_REQUEST=0,
 parameter integer RUNTIME_MODE_ENABLE=0,
 parameter integer BYPASS=0,DENOISE_ENABLE=0
)(input wire clk,rst,config_done,master_enable,upstream_error,fifo_overflow,
 input wire force_enhance,force_disable,
 input wire pixel_valid,frame_start,line_end,frame_end,input wire[15:0]pixel_rgb565,
 input wire[10:0]x,y,
 output wire out_valid,out_sof,out_eol,out_eof,output wire[15:0]out_pixel,
 output wire[10:0]out_x,out_y,
 output wire[7:0]mean_y,output wire[8:0]dark_ratio_q8,
 output wire enhance_active,enhance_led_n,
 output wire[15:0]debug_status,output wire fault_active);
 localparam CW=$clog2(WIDTH*HEIGHT+1);
 wire reset_stats=rst || !config_done;
 wire sof=pixel_valid && frame_start;
 wire eof=pixel_valid && frame_end;
 wire [1:0]ready,hdone,herror,hvalid;
 wire[CW-1:0]hc0,hc1;wire[7:0]hm0,hm1;wire[8:0]dr0,dr1;
 reg collecting,collect_bank,build_bank,building;
 reg[1:0]held,release_hist;
 reg build_start;wire build_done,build_error,gain_write,bin_read;
 wire[7:0]bin_addr,gain_addr;wire[20:0]gain_data;wire[31:0]build_cycles;
 (* keep="true" *) reg[31:0]skipped_histograms;
 wire choose_bank=!ready[0];
 wire take=sof ? (|ready) : collecting;
 wire cb=sof ? choose_bank : collect_bank;
 wire hp0=pixel_valid && take && !cb;
 wire hp1=pixel_valid && take && cb;
 frame_histogram #(.WIDTH(WIDTH),.HEIGHT(HEIGHT)) h0(
 .clk(clk),.rst(reset_stats),.pixel_valid(hp0),.sof(frame_start),.eof(frame_end),.rgb565(pixel_rgb565),
 .release_frame(release_hist[0]),.bin_read(bin_read && !build_bank),.bin_addr(bin_addr),
 .ready(ready[0]),.done(hdone[0]),.error(herror[0]),.bin_valid(hvalid[0]),.bin_count(hc0),.mean_y(hm0),.dark_ratio(dr0));
 frame_histogram #(.WIDTH(WIDTH),.HEIGHT(HEIGHT)) h1(
 .clk(clk),.rst(reset_stats),.pixel_valid(hp1),.sof(frame_start),.eof(frame_end),.rgb565(pixel_rgb565),
 .release_frame(release_hist[1]),.bin_read(bin_read && build_bank),.bin_addr(bin_addr),
 .ready(ready[1]),.done(hdone[1]),.error(herror[1]),.bin_valid(hvalid[1]),.bin_count(hc1),.mean_y(hm1),.dark_ratio(dr1));
 hist_lut_builder builder(.clk(clk),.rst(reset_stats),.start(build_start),.mean_y(build_bank?hm1:hm0),
 .bin_read(bin_read),.bin_addr(bin_addr),.bin_valid(build_bank?hvalid[1]:hvalid[0]),
 .bin_count(build_bank?{{(32-CW){1'b0}},hc1}:{{(32-CW){1'b0}},hc0}),
 .gain_write(gain_write),.gain_addr(gain_addr),.gain_data(gain_data),
 .done(build_done),.error(build_error),.build_cycles(build_cycles));
 wire stats_valid,stats_error,mode;
 // Mode statistics are independent of skipped histogram frames.
 live_frame_stats #(.WIDTH(WIDTH),.HEIGHT(HEIGHT)) metrics(
 .clk(clk),.rst(reset_stats),.valid(pixel_valid),.sof(frame_start),.eof(frame_end),
 .eol(line_end),.x(x),.y(y),.rgb(pixel_rgb565),.mean(mean_y),.dark(dark_ratio_q8),.done(stats_valid),.error(stats_error));
 reg fault_latched;
 always @(posedge clk)begin
  if(reset_stats)fault_latched<=0;
  else if(upstream_error || fifo_overflow || (|herror) || build_error || stats_error)fault_latched<=1;
 end
 // DVP error indications can clear at a later VSYNC. Do not resurrect a
 // partially computed candidate after such a pulse: require explicit reset.
 wire fault=!config_done || fault_latched || upstream_error || fifo_overflow || (|herror) || build_error || stats_error;
 hist_mode_ctrl ctrl(.clk(clk),.rst(reset_stats),.stats_valid(stats_valid),.fault(fault),.mean_y(mean_y),.active(mode));
 (* ram_style="block" *) reg[20:0]lut[0:511];
 reg initialized,active_bank,pending,lut_valid,write_bank,frame_mode;
 reg[8:0]init_addr;reg[2:0]commit_guard;
 reg[31:0]frame_id;
 wire commit=sof && pending && !fault;
 wire selected_bank=commit ? !active_bank : active_bank;
 wire runtime_force=(RUNTIME_MODE_ENABLE!=0) ? force_enhance : 1'b0;
 wire runtime_disable=(RUNTIME_MODE_ENABLE!=0) ? force_disable : 1'b0;
 wire selected_mode=sof ? ((runtime_disable ? 1'b0 : runtime_force ? 1'b1 : MODE_REQUEST==2'b10 ? 1'b1 : MODE_REQUEST==2'b01 ? 1'b0 : mode)
     && master_enable && (lut_valid || commit) && BYPASS==0 && DENOISE_ENABLE==0) : frame_mode;
 wire[7:0]r={pixel_rgb565[15:11],pixel_rgb565[15:13]};
 wire[7:0]g={pixel_rgb565[10:5],pixel_rgb565[10:9]};
 wire[7:0]b={pixel_rgb565[4:0],pixel_rgb565[4:2]};
 wire[7:0]level=r>g?(r>b?r:b):(g>b?g:b);
 reg[20:0]gain_q;reg[74:0]token_q;reg bypass_q;
 wire[74:0]out_token;
 wire[8:0]lut_wa=!initialized?init_addr:{write_bank,gain_addr};
 wire[20:0]lut_wd=!initialized?21'd262144:gain_data;
 always @(posedge clk)begin
  if(!initialized || (gain_write && building))lut[lut_wa]<=lut_wd;
  gain_q<=lut[{selected_bank,level}];
 end
 always @(posedge clk)begin
  if(rst)begin token_q<=0;bypass_q<=1;end
  else begin
   token_q<={selected_mode,(sof?frame_id+1'b1:frame_id),y,x,line_end,frame_end,frame_start,pixel_valid,pixel_rgb565};
   bypass_q<=!selected_mode || fault || !initialized;
  end
 end
 hist_gain_pipeline pixels(.clk(clk),.rst(rst),.s_token(token_q),.gain(gain_q),.alpha(9'd256),.bypass(bypass_q),.m_token(out_token));
 always @(posedge clk)begin
  if(reset_stats)begin
   initialized<=0;init_addr<=0;active_bank<=0;pending<=0;lut_valid<=0;write_bank<=1;
   held<=0;release_hist<=0;building<=0;build_start<=0;build_bank<=0;
   collecting<=0;collect_bank<=0;frame_mode<=0;frame_id<=32'hffffffff;commit_guard<=0;skipped_histograms<=0;
  end else begin
   release_hist<=0;build_start<=0;
   if(!initialized)begin if(init_addr==511)initialized<=1;else init_addr<=init_addr+1'b1;end
   if(commit_guard!=0)commit_guard<=commit_guard-1'b1;
   if(sof)begin
    frame_id<=frame_id+1'b1;frame_mode<=selected_mode;collecting<=|ready;collect_bank<=choose_bank;
    if(!(|ready))skipped_histograms<=skipped_histograms+1'b1;
   end
   if(eof)collecting<=0;
   if(hdone[0])held[0]<=1;
   if(hdone[1])held[1]<=1;
   if(initialized && !building && !pending && commit_guard==0 && !fault && (|held))begin
    build_bank<=!held[0];held[held[0]?0:1]<=0;write_bank<=!active_bank;build_start<=1;building<=1;
   end
   if(build_done)begin
    building<=0;release_hist[build_bank]<=1;
    if(!fault)pending<=1;
   end
   if(commit)begin active_bank<=!active_bank;pending<=0;lut_valid<=1;commit_guard<=4;end
   if(fault)begin pending<=0;frame_mode<=0;end
  end
 end
 assign out_pixel=out_token[15:0];assign out_valid=out_token[16];assign out_sof=out_token[17];
 assign out_eof=out_token[18];assign out_eol=out_token[19];assign out_x=out_token[30:20];assign out_y=out_token[41:31];
 assign enhance_active=frame_mode && !fault;assign enhance_led_n=!enhance_active;
 assign fault_active=fault;
 // Frame snapshots expose the actual enable chain and sticky fault causes.
 reg[6:0]fault_causes;
 always @(posedge clk)begin
  if(reset_stats)fault_causes<=0;
  else fault_causes<=fault_causes | {stats_error,build_error,herror,fifo_overflow,upstream_error,fault};
 end
 assign debug_status={building,pending,lut_valid,initialized,master_enable,mode,frame_mode,enhance_active,fault_latched,fault_causes};
endmodule
