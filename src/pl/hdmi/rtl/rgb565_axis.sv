`timescale 1ns/1ps
// Exact bit replication preserves every RGB565 level. Digilent rgb2dvi uses RBG.
module rgb565_axis(
 (* X_INTERFACE_INFO="xilinx.com:signal:clock:1.0 aclk CLK", X_INTERFACE_PARAMETER="ASSOCIATED_BUSIF s_axis:m_axis, ASSOCIATED_RESET aresetn" *) input wire aclk,
 (* X_INTERFACE_INFO="xilinx.com:signal:reset:1.0 aresetn RST", X_INTERFACE_PARAMETER="POLARITY ACTIVE_LOW" *) input wire aresetn,
 (* X_INTERFACE_INFO="xilinx.com:interface:axis:1.0 s_axis TDATA" *) input wire[15:0]s_axis_tdata,
 (* X_INTERFACE_INFO="xilinx.com:interface:axis:1.0 s_axis TVALID" *) input wire s_axis_tvalid,
 (* X_INTERFACE_INFO="xilinx.com:interface:axis:1.0 s_axis TREADY" *) output wire s_axis_tready,
 (* X_INTERFACE_INFO="xilinx.com:interface:axis:1.0 s_axis TUSER" *) input wire s_axis_tuser,
 (* X_INTERFACE_INFO="xilinx.com:interface:axis:1.0 s_axis TLAST" *) input wire s_axis_tlast,
 (* X_INTERFACE_INFO="xilinx.com:interface:axis:1.0 s_axis TKEEP" *) input wire[1:0]s_axis_tkeep,
 (* X_INTERFACE_INFO="xilinx.com:interface:axis:1.0 m_axis TDATA" *) output wire[23:0]m_axis_tdata,
 (* X_INTERFACE_INFO="xilinx.com:interface:axis:1.0 m_axis TVALID" *) output wire m_axis_tvalid,
 (* X_INTERFACE_INFO="xilinx.com:interface:axis:1.0 m_axis TREADY" *) input wire m_axis_tready,
 (* X_INTERFACE_INFO="xilinx.com:interface:axis:1.0 m_axis TUSER" *) output wire m_axis_tuser,
 (* X_INTERFACE_INFO="xilinx.com:interface:axis:1.0 m_axis TLAST" *) output wire m_axis_tlast
);
 wire[7:0]r={s_axis_tdata[15:11],s_axis_tdata[15:13]};
 wire[7:0]g={s_axis_tdata[10:5],s_axis_tdata[10:9]};
 wire[7:0]b={s_axis_tdata[4:0],s_axis_tdata[4:2]};
 assign m_axis_tdata={r,b,g};
 assign m_axis_tvalid=aresetn && s_axis_tvalid && (&s_axis_tkeep);
 assign s_axis_tready=aresetn && m_axis_tready;
 assign m_axis_tuser=s_axis_tuser;assign m_axis_tlast=s_axis_tlast;
endmodule
