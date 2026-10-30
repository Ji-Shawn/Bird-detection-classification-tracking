`timescale 1ns/1ps
module hist_lut_builder(input wire clk,rst,start,input wire[7:0]mean_y,
 output wire bin_read,output wire[7:0]bin_addr,
 input wire bin_valid,input wire[31:0]bin_count,
 output reg gain_write,output reg[7:0]gain_addr,output reg[20:0]gain_data,
 output reg done,error,output reg[31:0]build_cycles);
 localparam[20:0]Q=21'd262144;
 localparam INIT=0,IDLE=1,READ=2,RWAIT=3,CAP=4,CLIP=5,PREP=6,
 EQSTART=7,EQWAIT=8,TARGET=9,GSTART=10,GWAIT=11,
 FIXSTART=12,FIXWAIT=13,FIXSAVE=14,INTERP=15,IWAIT=16,EMIT=17,FINISH=18;
 reg[5:0]state;reg[7:0]idx;reg[1:0]bank;
 (* ram_style="block" *) reg[31:0]counts[0:255];
 (* ram_style="block" *) reg[7:0]previous[0:255];
 (* ram_style="block" *) reg[20:0]gains[0:255];
 localparam CFETCH=19,CWAIT=20,EFETCH=21,EWAIT=22,
 FL=23,FLW=24,FR=25,FRW=26,IL=27,ILW=28,IR=29,IRW=30,II=31,IIW=32,
 OFETCH=33,OWAIT=34;
 reg[31:0]count_q;reg[7:0]previous_q;reg[20:0]gain_q,gl,gr,gi;
 reg[7:0]gain_read_addr;

 reg[31:0]total,cap,sum,first,cdf,denom;reg first_seen;
 reg[7:0]eq,target;reg[6:0]k;reg component;
 reg[20:0]limit;
 reg div_start;reg[47:0]num;reg[31:0]den;
 wire div_busy,div_done,div_zero;wire[47:0]quotient;
 unsigned_divider u_div(.clk(clk),.rst(rst),.start(div_start),.numerator(num),.denominator(den),
 .busy(div_busy),.done(div_done),.zero_error(div_zero),.quotient(quotient));
 wire[7:0]gamma_value;
 gamma_rom u_gamma(.bank(bank),.level(idx),.value(gamma_value));
 function automatic[7:0]level(input[6:0]j);
 reg[4:0]r;reg[5:0]g;reg[7:0]rr,gg;
 begin r=j>>1;g=j;rr={r,r[4:2]};gg={g,g[5:4]};level=rr>gg?rr:gg;end endfunction
 wire[7:0]left_level=level(k),right_level=level(k+1'b1);
 wire[6:0]code_now=component ? k : (k>>1);
 wire[6:0]code_next=component ? k+1'b1 : ((k+1'b1)>>1);
 always @* begin
 gain_read_addr=idx;
 if(state==FL || state==FLW || state==IL || state==ILW)gain_read_addr=left_level;
 if(state==FR || state==FRW || state==IR || state==IRW)gain_read_addr=right_level;
 end
 always @(posedge clk)begin
 count_q<=counts[idx];previous_q<=previous[idx];gain_q<=gains[gain_read_addr];
 end
 reg gain_we;reg[7:0]gain_wa;reg[20:0]gain_wd;
 always @*begin
 gain_we=0;gain_wa=idx;gain_wd=Q;
 if(!rst)case(state)
 INIT:gain_we=1;
 GSTART:if(idx==0)gain_we=1;
 GWAIT:if(div_done)begin gain_we=1;gain_wd=quotient[20:0];end
 FIXSAVE:begin gain_we=1;gain_wa=left_level;gain_wd=limit<Q?Q:limit;end
 IWAIT:if(div_done && gi>quotient)begin gain_we=1;gain_wd=quotient[20:0];end
 default:;
 endcase
 end
 always @(posedge clk)if(gain_we)gains[gain_wa]<=gain_wd;
 wire[31:0]clipped=count_q>cap ? cap : count_q;
 wire[31:0]cdf_next=cdf+count_q;
 reg[31:0]cdf_delta_q;reg[39:0]cdf_product_q;
 localparam EQDELTA=37,EQMUL=38,EQDIV=39;
 wire[7:0]h=eq>idx?eq:idx;
 wire[10:0]blend=(11'd3*gamma_value+h+2)>>2;
 reg[10:0]bounded;reg[7:0]bounded_q;
 wire[9:0]smooth_sum=bounded_q+10'd3*previous_q+2;
 wire[31:0]interp_sum=gl*(right_level-idx)+gr*(idx-left_level);
 localparam TBOUND=35,TSAVE=36;
 reg[10:0]blend_q;reg[9:0]bound_q;
 wire[9:0]bound_limit=idx<=16 ? {idx,2'b0} : idx<=32 ? ({2'b0,idx}<<1)+10'd32 : idx<=191 ? {2'b0,idx}+10'd64 : 10'd255;
 wire[10:0]bounded_min=blend_q>bound_q?{1'b0,bound_q}:blend_q;
 assign bin_read=state==READ;
 assign bin_addr=idx;
 always @(posedge clk)begin
 if(rst)begin state<=INIT;idx<=0;done<=0;error<=0;gain_write<=0;div_start<=0;build_cycles<=0;
 total<=0;cap<=0;sum<=0;first<=0;cdf<=0;denom<=0;first_seen<=0;bank<=0;eq<=0;target<=0;k<=0;component<=0;limit<=Q;num<=0;den<=1;gain_addr<=0;gain_data<=Q;end
 else begin
 done<=0;gain_write<=0;div_start<=0;
 if(state!=INIT && state!=IDLE)begin
  build_cycles<=build_cycles+1'b1;
  if(build_cycles>=65535)begin error<=1;state<=IDLE;end
 end
 case(state)
 INIT:begin previous[idx]<=idx;if(idx==255)state<=IDLE;else idx<=idx+1'b1;end
 IDLE:if(start && !error)begin idx<=0;total<=0;build_cycles<=0;bank<=mean_y<65?0:mean_y<85?1:2;state<=READ;end
 READ:state<=RWAIT;
 RWAIT:if(bin_valid)begin counts[idx]<=bin_count;total<=total+bin_count;if(idx==255)state<=CAP;else begin idx<=idx+1'b1;state<=READ;end end
 CAP:begin
  if(total==0)begin error<=1;state<=IDLE;end
  else begin cap<=((total+63)>>6);sum<=0;first<=0;first_seen<=0;idx<=0;state<=CFETCH;end
 end
 CLIP:begin
  counts[idx]<=clipped;sum<=sum+clipped;
  if(!first_seen && clipped!=0)begin first<=clipped;first_seen<=1;end
  if(idx==255)state<=PREP;else begin idx<=idx+1'b1;state<=CFETCH;end
 end
 PREP:begin denom<=sum-first;cdf<=0;idx<=0;state<=EFETCH;end
 EQSTART:begin
  cdf<=cdf_next;
  if(denom==0)begin eq<=idx;state<=TARGET;end
  else state<=EQDELTA;
 end
 EQDELTA:begin cdf_delta_q<=cdf>first?cdf-first:0;state<=EQMUL;end
 EQMUL:begin cdf_product_q<=40'd255*cdf_delta_q;state<=EQDIV;end
 EQDIV:begin num<={8'b0,cdf_product_q}+(denom>>1);den<=denom;div_start<=1;state<=EQWAIT;
 end
 EQWAIT:if(div_done)begin eq<=quotient[7:0];state<=TARGET;end
 TARGET:begin blend_q<=blend;bound_q<=bound_limit;state<=TBOUND;end
 TBOUND:begin bounded_q<=bounded_min<idx?idx:bounded_min[7:0];state<=TSAVE;end
 TSAVE:begin target<=smooth_sum[9:2];previous[idx]<=smooth_sum[9:2];state<=GSTART;end
 GSTART:if(idx==0)begin idx<=1;state<=EFETCH;end
 else begin num<=({40'b0,target}<<18)+(idx>>1);den<=idx;div_start<=1;state<=GWAIT;end
 GWAIT:if(div_done)begin
  
  if(idx==255)begin k<=62;component<=0;state<=FL;end
  else begin idx<=idx+1'b1;state<=EFETCH;end
 end
 FIXSTART:begin
  if(!component)limit<=gl;
  if(code_now==0 || code_now==code_next)begin
   if(code_now!=0)begin
    if(!component)limit<=gl<gr?gl:gr;
    else if(limit>gr)limit<=gr;
   end
   if(!component)component<=1;else state<=FIXSAVE;
  end else begin num<=code_next*gr;den<=code_now;div_start<=1;state<=FIXWAIT;end
 end
 FIXWAIT:if(div_done)begin
  if(quotient>0 && limit>quotient-1)limit<=quotient-1;
  if(!component)begin component<=1;state<=FL;end else state<=FIXSAVE;
 end
 FIXSAVE:begin
  
  if(k==0)begin k<=0;idx<=1;state<=IL;end
  else begin k<=k-1'b1;component<=0;state<=FL;end
 end
 INTERP:begin
  if(idx>=right_level)begin
   // Gray codes 62 and 63 both have max RGB=255; no final interval.
   if(k==61)begin idx<=0;state<=OFETCH;end
   else begin k<=k+1'b1;idx<=right_level+1'b1;state<=IL;end
  end else begin num<=interp_sum;den<=right_level-left_level;div_start<=1;state<=IWAIT;end
 end
 IWAIT:if(div_done)begin idx<=idx+1'b1;state<=IL;end
 EMIT:begin gain_write<=1;gain_addr<=idx;gain_data<=gain_q;
  if(idx==255)state<=FINISH;else begin idx<=idx+1'b1;state<=OFETCH;end
 end
 CFETCH:state<=CWAIT;
 CWAIT:state<=CLIP;
 EFETCH:state<=EWAIT;
 EWAIT:state<=EQSTART;
 FL:state<=FLW;
 FLW:begin gl<=gain_q;state<=FR;end
 FR:state<=FRW;
 FRW:begin gr<=gain_q;state<=FIXSTART;end
 IL:state<=ILW;
 ILW:begin gl<=gain_q;state<=IR;end
 IR:state<=IRW;
 IRW:begin gr<=gain_q;state<=II;end
 II:state<=IIW;
 IIW:begin gi<=gain_q;state<=INTERP;end
 OFETCH:state<=OWAIT;
 OWAIT:state<=EMIT;
 FINISH:begin done<=1;state<=IDLE;end
 default:begin error<=1;state<=IDLE;end
 endcase
 if(div_zero || (state!=INIT && state!=IDLE && build_cycles>=65535))begin error<=1;state<=IDLE;end
 end end
endmodule
