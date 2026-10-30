`timescale 1ns/1ps

module camera_ctrl_io(
    input wire [5:0] gpio_o,input wire [5:0] gpio_t,output wire [5:0] gpio_i,
    output wire camera_configured, output wire camera_test_pattern,
    inout wire cam_scl,inout wire cam_sda,output wire cam_reset_n,output wire cam_pwdn
);
    IOBUF u_scl(.I(gpio_o[0]),.T(gpio_t[0]),.O(gpio_i[0]),.IO(cam_scl));
    IOBUF u_sda(.I(gpio_o[1]),.T(gpio_t[1]),.O(gpio_i[1]),.IO(cam_sda));
    assign cam_reset_n=gpio_o[2];assign cam_pwdn=gpio_o[3];
    assign gpio_i[5:2]=4'b0000;
    // Virtual camera control bits; no new external pin or network register.
    // Virtual bits are not physical tri-state pins. Send the registered
    // GPIO data directly into the PCLK synchronizer; combining data with
    // direction before that synchronizer creates a glitch-prone CDC source.
    // AXI GPIO DOUT reset value is zero, and PS explicitly initializes zero.
    assign camera_configured=gpio_o[4];
    assign camera_test_pattern=gpio_o[5];
endmodule
