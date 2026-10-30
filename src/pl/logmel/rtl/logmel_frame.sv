`timescale 1ns/1ps
`include "config.vh"
// PCM24 frame -> periodic Hann -> scaled FFT -> Slaney Mel -> absolute dB.
// The FFT accepts one butterfly per cycle. Separate read/write stage banks
// eliminate read-after-write hazards; the pipeline drains before bank swap.
module logmel_frame (
    (* X_INTERFACE_PARAMETER="XIL_INTERFACENAME aclk, ASSOCIATED_BUSIF S_AXIS:M_AXIS, ASSOCIATED_RESET aresetn" *)
    input wire aclk,
    (* X_INTERFACE_PARAMETER="XIL_INTERFACENAME aresetn, POLARITY ACTIVE_LOW" *)
    input wire aresetn,
    (* X_INTERFACE_INFO="xilinx.com:interface:axis:1.0 S_AXIS TDATA" *) input wire [31:0] s_axis_tdata,
    (* X_INTERFACE_INFO="xilinx.com:interface:axis:1.0 S_AXIS TVALID" *) input wire s_axis_tvalid,
    (* X_INTERFACE_INFO="xilinx.com:interface:axis:1.0 S_AXIS TREADY" *) output wire s_axis_tready,
    (* X_INTERFACE_INFO="xilinx.com:interface:axis:1.0 S_AXIS TLAST" *) input wire s_axis_tlast,
    (* X_INTERFACE_INFO="xilinx.com:interface:axis:1.0 M_AXIS TDATA" *) output wire [31:0] m_axis_tdata,
    (* X_INTERFACE_INFO="xilinx.com:interface:axis:1.0 M_AXIS TVALID" *) output wire m_axis_tvalid,
    (* X_INTERFACE_INFO="xilinx.com:interface:axis:1.0 M_AXIS TREADY" *) input wire m_axis_tready,
    (* X_INTERFACE_INFO="xilinx.com:interface:axis:1.0 M_AXIS TLAST" *) output wire m_axis_tlast,
    output reg protocol_error
);
    localparam LOAD=0, LOAD_DRAIN=1, FFT=2, POWER=3, MEL=4, LOG=5, SEND=6;
    reg [2:0] state;
    (* ram_style="block" *) reg [71:0] bank0[0:1023], bank1[0:1023];
    reg signed [28:0] hann[0:1023], tw_re[0:511], tw_im[0:511];
    reg [43:0] mel_ops[0:`MEL_OPS-1];
    reg [17:0] log_rom[0:4095];
    initial begin
        $readmemh("hann.hex",hann); $readmemh("tw_re.hex",tw_re);
        $readmemh("tw_im.hex",tw_im); $readmemh("mel_ops.hex",mel_ops);
        $readmemh("log.hex",log_rom);
    end
    function automatic [9:0] reverse10(input [9:0] x);
        integer k; begin for(k=0;k<10;k=k+1) reverse10[k]=x[9-k]; end
    endfunction
    function automatic signed [35:0] half_round(input signed [36:0] x);
        half_round=(x+37'sd1)>>>1;
    endfunction
    reg [9:0] input_index;
    reg [1:0] wv;
    reg signed [23:0] w_sample;
    reg signed [28:0] w_coeff;
    reg signed [52:0] w_product;
    reg [9:0] w_addr0,w_addr1;
    reg w_last0,w_last1;
    wire [35:0] w_result=(w_product+53'sd16384)>>>15;
    assign s_axis_tready=(state==LOAD);
    wire take=s_axis_tvalid && s_axis_tready;

    reg [3:0] stage;
    reg [9:0] issued;
    wire issue=(state==FFT && issued<512);
    wire [9:0] mask=(10'd1<<stage)-1;
    wire [9:0] addr_a=((issued & ~mask)<<1) | (issued & mask);
    wire [9:0] addr_b=addr_a | (10'd1<<stage);
    wire [8:0] tw_addr=(issued & mask)<<(9-stage);
    reg [4:0] fv;
    reg [9:0] fa[0:4],fb[0:4];
    reg [4:0] flast;
    wire signed [35:0] ar0,ai0,br0,bi0;
    reg signed [35:0] ar1,ai1,ar2,ai2,ar3,ai3;
    reg signed [28:0] wr0,wi0;
    (* use_dsp="yes" *) reg signed [64:0] rr1,ii1,ri1,ir1;
    reg signed [65:0] tr2,ti2;
    reg signed [35:0] tr3,ti3;
    reg signed [35:0] ya4,yai4,yb4,ybi4;

    (* ram_style="block" *) reg [71:0] powers[0:512];
    reg [9:0] power_index;
    reg [2:0] pv;
    reg [9:0] pa0,pa1,pa2;
    wire signed [35:0] pr0,pi0;
    (* use_dsp="yes" *) reg [71:0] p_re1,p_im1;
    reg [71:0] power2;

    reg [10:0] mel_index;
    reg [3:0] mv;
    reg [43:0] op0;
    reg [71:0] mp1;
    reg [25:0] mw1;
    reg [6:0] mb1,mb2,mb3;
    reg ml1,ml2,ml3;
    (* use_dsp="yes" *) reg [97:0] product2;
    reg [97:0] product3;
    reg [103:0] mel_acc;
    reg [103:0] energy[0:127];

    reg [7:0] log_index;
    reg [4:0] lv;
    reg [6:0] lb0,lb1,lb2,lb3,lb4;
    reg [103:0] le0,le1;
    reg [6:0] exponent1,exponent2,exponent3;
    reg [11:0] fraction1;
    reg [17:0] mantissa2;
    reg signed [31:0] db3;
    reg signed [31:0] result[0:127];
    reg [6:0] send_index;
    integer k, leading;
    reg [103:0] normalized;
    assign m_axis_tvalid=(state==SEND);
    assign m_axis_tdata=result[send_index];
    assign m_axis_tlast=(send_index==127);

    // Canonical true-dual-port RAM: one clocked process per physical port.
    // Window load and power read share bank0 port A with the FFT, by phase.
    reg [71:0] q0a,q0b,q1a,q1b;
    wire we0a=aresetn && (wv[1] || (fv[4] && stage[0]));
    wire we0b=aresetn && fv[4] && stage[0];
    wire we1=aresetn && fv[4] && !stage[0];
    wire [9:0] a0=wv[1] ? w_addr1 : ((fv[4] && stage[0]) ? fa[4] : ((state==POWER) ? power_index : addr_a));
    wire [9:0] b0=(fv[4] && stage[0]) ? fb[4] : addr_b;
    wire [9:0] a1=(fv[4] && !stage[0]) ? fa[4] : addr_a;
    wire [9:0] b1=(fv[4] && !stage[0]) ? fb[4] : addr_b;
    wire [71:0] d0a=wv[1] ? {36'd0,w_result} : {yai4,ya4};
    assign {ai0,ar0}=stage[0] ? q1a:q0a;
    assign {bi0,br0}=stage[0] ? q1b:q0b;
    assign {pi0,pr0}=q0a;
    always @(posedge aclk) begin
        if(we0a) bank0[a0]<=d0a;
        q0a<=bank0[a0];
    end
    always @(posedge aclk) begin
        if(we0b) bank0[b0]<={ybi4,yb4};
        q0b<=bank0[b0];
    end
    always @(posedge aclk) begin
        if(we1) bank1[a1]<={yai4,ya4};
        q1a<=bank1[a1];
    end
    always @(posedge aclk) begin
        if(we1) bank1[b1]<={ybi4,yb4};
        q1b<=bank1[b1];
    end
    always @(posedge aclk) begin
        if(!aresetn) begin
            state<=LOAD;input_index<=0;wv<=0;fv<=0;pv<=0;mv<=0;lv<=0;
            stage<=0;issued<=0;power_index<=0;mel_index<=0;log_index<=0;
            mel_acc<=0;send_index<=0;protocol_error<=0;flast<=0;
        end else begin
            wv<={wv[0],take};
            if(take) begin
                w_sample<=s_axis_tdata[23:0];w_coeff<=hann[input_index];
                w_addr0<=reverse10(input_index);w_last0<=(input_index==1023);
                if(s_axis_tlast != (input_index==1023)) protocol_error<=1;
                input_index<=input_index+1'b1;
                if(input_index==1023) state<=LOAD_DRAIN;
            end
            if(wv[0]) begin w_product<=w_sample*w_coeff;w_addr1<=w_addr0;w_last1<=w_last0;end
            if(wv[1] && w_last1) begin state<=FFT;stage<=0;issued<=0;end

            fv<={fv[3:0],issue};flast<={flast[3:0],(issue && issued==511)};
            for(k=1;k<5;k=k+1) begin fa[k]<=fa[k-1];fb[k]<=fb[k-1];end
            if(issue) begin
                wr0<=tw_re[tw_addr];wi0<=tw_im[tw_addr];fa[0]<=addr_a;fb[0]<=addr_b;
                issued<=issued+1'b1;
            end
            if(fv[0]) begin
                rr1<=br0*wr0;ii1<=bi0*wi0;ri1<=br0*wi0;ir1<=bi0*wr0;ar1<=ar0;ai1<=ai0;
            end
            if(fv[1]) begin
                tr2<=$signed({rr1[64],rr1})-$signed({ii1[64],ii1});
                ti2<=$signed({ri1[64],ri1})+$signed({ir1[64],ir1});ar2<=ar1;ai2<=ai1;
            end
            if(fv[2]) begin tr3<=(tr2+66'sd67108864)>>>27;ti3<=(ti2+66'sd67108864)>>>27;ar3<=ar2;ai3<=ai2;end
            if(fv[3]) begin
                ya4<=half_round($signed({ar3[35],ar3})+$signed({tr3[35],tr3}));
                yb4<=half_round($signed({ar3[35],ar3})-$signed({tr3[35],tr3}));
                yai4<=half_round($signed({ai3[35],ai3})+$signed({ti3[35],ti3}));
                ybi4<=half_round($signed({ai3[35],ai3})-$signed({ti3[35],ti3}));
            end
            if(fv[4] && flast[4]) begin
                issued<=0;
                if(stage==9) begin state<=POWER;power_index<=0;end else stage<=stage+1'b1;
            end

            pv<={pv[1:0],(state==POWER && power_index<513)};
            if(state==POWER && power_index<513) begin
                pa0<=power_index;power_index<=power_index+1'b1;
            end
            if(pv[0]) begin p_re1<=pr0*pr0;p_im1<=pi0*pi0;pa1<=pa0;end
            if(pv[1]) begin power2<=p_re1+p_im1;pa2<=pa1;end
            if(pv[2]) begin
                powers[pa2]<=power2;
                if(pa2==512) begin state<=MEL;mel_index<=0;mel_acc<=0;end
            end

            mv<={mv[2:0],(state==MEL && mel_index<`MEL_OPS)};
            if(state==MEL && mel_index<`MEL_OPS) begin op0<=mel_ops[mel_index];mel_index<=mel_index+1'b1;end
            if(mv[0]) begin mp1<=powers[op0[35:26]];mw1<=op0[25:0];mb1<=op0[42:36];ml1<=op0[43];end
            if(mv[1]) begin product2<=mp1*mw1;mb2<=mb1;ml2<=ml1;end
            if(mv[2]) begin product3<=product2;mb3<=mb2;ml3<=ml2;end
            if(mv[3]) begin
                if(ml3) begin
                    energy[mb3]<=mel_acc+product3;mel_acc<=0;
                    if(mb3==127) begin state<=LOG;log_index<=0;end
                end else mel_acc<=mel_acc+product3;
            end

            lv<={lv[3:0],(state==LOG && log_index<128)};
            if(state==LOG && log_index<128) begin le0<=energy[log_index];lb0<=log_index;log_index<=log_index+1'b1;end
            if(lv[0]) begin
                leading=0;
                for(k=0;k<104;k=k+1) if(le0[k]) leading=k;
                exponent1<=leading;le1<=le0;lb1<=lb0;
            end
            if(lv[1]) begin
                normalized=le1<<(103-exponent1);
                fraction1<=normalized[102:91];exponent2<=exponent1;lb2<=lb1;
            end
            if(lv[2]) begin mantissa2<=log_rom[fraction1];exponent3<=exponent2;lb3<=lb2;end
            // 10*log10(raw / 2^80), in Q16.16. LUT truncation < 0.0011 dB.
            if(lv[3]) begin db3<=($signed({1'b0,exponent3})-32'sd80)*32'sd197283+$signed({1'b0,mantissa2});lb4<=lb3;end
            if(lv[4]) begin
                result[lb4]<=(db3 < -32'sd6553600) ? -32'sd6553600 : db3;
                if(lb4==127) begin state<=SEND;send_index<=0;end
            end
            if(m_axis_tvalid && m_axis_tready) begin
                if(send_index==127) begin state<=LOAD;input_index<=0;end
                else send_index<=send_index+1'b1;
            end
        end
    end
endmodule
