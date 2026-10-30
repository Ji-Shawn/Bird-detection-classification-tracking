`timescale 1ns/1ps
// SCCB bus transactions/reset/table/readback remain in PS ov5640.c.
// GPIO bit4 is asserted ONLY after successful key-register verification.
// This module synchronizes the completion level, not the multi-bit pixel bus.
module ov5640_sccb_config (
    input wire pclk, resetn, configured_async, test_pattern_async,
    output wire config_done, output wire test_pattern
);
    (* ASYNC_REG="TRUE" *) reg [1:0] done_sync;
    (* ASYNC_REG="TRUE" *) reg [1:0] test_sync;
    always @(posedge pclk or negedge resetn) begin
        if(!resetn) begin done_sync<=0;test_sync<=0;end
        else begin done_sync<={done_sync[0],configured_async};test_sync<={test_sync[0],test_pattern_async};end
    end
    assign config_done=done_sync[1];
    assign test_pattern=test_sync[1];
endmodule
