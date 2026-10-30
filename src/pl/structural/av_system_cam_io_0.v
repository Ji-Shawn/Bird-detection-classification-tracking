// (c) Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// (c) Copyright 2022-2026 Advanced Micro Devices, Inc. All rights reserved.
// 
// This file contains confidential and proprietary information
// of AMD and is protected under U.S. and international copyright
// and other intellectual property laws.
// 
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// AMD, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) AMD shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or AMD had been advised of the
// possibility of the same.
// 
// CRITICAL APPLICATIONS
// AMD products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of AMD products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
// 
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
// 
// DO NOT MODIFY THIS FILE.


// IP VLNV: xilinx.com:module_ref:camera_ctrl_io:1.0
// IP Revision: 1

(* X_CORE_INFO = "camera_ctrl_io,Vivado 2023.2" *)
(* CHECK_LICENSE_TYPE = "av_system_cam_io_0,camera_ctrl_io,{}" *)
(* CORE_GENERATION_INFO = "av_system_cam_io_0,camera_ctrl_io,{x_ipProduct=Vivado 2023.2,x_ipVendor=xilinx.com,x_ipLibrary=module_ref,x_ipName=camera_ctrl_io,x_ipVersion=1.0,x_ipCoreRevision=1,x_ipLanguage=VERILOG,x_ipSimLanguage=MIXED}" *)
(* IP_DEFINITION_SOURCE = "module_ref" *)
(* DowngradeIPIdentifiedWarnings = "yes" *)
module av_system_cam_io_0 (
  gpio_o,
  gpio_t,
  gpio_i,
  camera_configured,
  camera_test_pattern,
  cam_scl,
  cam_sda,
  cam_reset_n,
  cam_pwdn
);

input wire [5 : 0] gpio_o;
input wire [5 : 0] gpio_t;
output wire [5 : 0] gpio_i;
output wire camera_configured;
output wire camera_test_pattern;
inout wire cam_scl;
inout wire cam_sda;
output wire cam_reset_n;
output wire cam_pwdn;

  camera_ctrl_io inst (
    .gpio_o(gpio_o),
    .gpio_t(gpio_t),
    .gpio_i(gpio_i),
    .camera_configured(camera_configured),
    .camera_test_pattern(camera_test_pattern),
    .cam_scl(cam_scl),
    .cam_sda(cam_sda),
    .cam_reset_n(cam_reset_n),
    .cam_pwdn(cam_pwdn)
  );
endmodule
