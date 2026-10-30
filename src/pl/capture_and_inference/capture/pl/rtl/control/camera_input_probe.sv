`timescale 1ns/1ps

module camera_input_probe (
    input  wire        clk,
    input  wire        resetn,
    input  wire        cam_pclk,
    input  wire        cam_vsync,
    input  wire        cam_href,
    input  wire [7:0]  cam_d,
    input  wire        pixel_reset,
    input  wire        debug_strobe,
    input  wire [15:0] enhancement_debug,
    output wire [31:0] probe_data
);
    (* ASYNC_REG = "TRUE" *) reg [2:0] pclk_sync;
    (* ASYNC_REG = "TRUE" *) reg [2:0] vsync_sync;
    (* ASYNC_REG = "TRUE" *) reg [2:0] href_sync;
    (* ASYNC_REG = "TRUE" *) reg [7:0] data_meta;
    (* ASYNC_REG = "TRUE" *) reg [7:0] data_sync;
    reg pclk_seen, vsync_seen, href_seen;
    wire [15:0] debug_snapshot;
    wire debug_valid;
    cdc_snapshot #(.WIDTH(16)) u_snapshot (
        .src_clk(cam_pclk),.src_rst(pixel_reset),.src_strobe(debug_strobe),
        .src_data(enhancement_debug),.dst_clk(clk),.dst_rst(!resetn),
        .dst_strobe(debug_valid),.dst_data(debug_snapshot)
    );

    always @(posedge clk) begin
        if (!resetn) begin
            pclk_sync <= 3'b000;
            vsync_sync <= 3'b000;
            href_sync <= 3'b000;
            data_meta <= 8'h00;
            data_sync <= 8'h00;
            pclk_seen <= 1'b0;
            vsync_seen <= 1'b0;
            href_seen <= 1'b0;
        end else begin
            pclk_sync <= {pclk_sync[1:0], cam_pclk};
            vsync_sync <= {vsync_sync[1:0], cam_vsync};
            href_sync <= {href_sync[1:0], cam_href};
            data_meta <= cam_d;
            data_sync <= data_meta;
            if (pclk_sync[2] ^ pclk_sync[1]) pclk_seen <= 1'b1;
            if (vsync_sync[2] ^ vsync_sync[1]) vsync_seen <= 1'b1;
            if (href_sync[2] ^ href_sync[1]) href_seen <= 1'b1;
        end
    end

    assign probe_data = {debug_snapshot, data_sync, 2'b00,
                         href_sync[2], vsync_sync[2], pclk_sync[2],
                         href_seen, vsync_seen, pclk_seen};
endmodule
