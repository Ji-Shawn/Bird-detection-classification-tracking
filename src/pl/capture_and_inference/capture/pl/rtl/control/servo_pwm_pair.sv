`timescale 1ns/1ps
// Positional PWM: hold the last position at 50 Hz, including on STOP.
// Pan [31:24] must be zero; [23:0] is pulse ticks. Reject old burst commands.
module servo_pwm_pair #(parameter integer CLOCK_HZ = 98305085) (
    input wire clk, input wire resetn,
    input wire command_valid, input wire [2:0] command,
    input wire [31:0] pan_ticks, tilt_ticks,
    output reg servo_pan, servo_tilt,
    output wire [31:0] status,
    output reg [31:0] accepted_count, left_frame_count, right_frame_count
);
    localparam integer PERIOD = (CLOCK_HZ+25)/50;
    localparam integer CENTER = (CLOCK_HZ*64'd1440+500000)/1000000;
    localparam integer PAN_MIN = (CLOCK_HZ*64'd540+500000)/1000000;
    localparam integer PAN_MAX = (CLOCK_HZ*64'd2480+500000)/1000000;
    localparam integer TILT_MIN = (CLOCK_HZ*64'd540+500000)/1000000;
    localparam integer TILT_MAX = (CLOCK_HZ*64'd2281+500000)/1000000;
    reg [21:0] counter, active_pan, active_tilt, pending_pan, target_tilt;
    reg pending, stop_pending;
    (* KEEP = "TRUE" *) wire pan_position_allowed = pan_ticks[31:24]==0 &&
        pan_ticks[23:0]>=PAN_MIN && pan_ticks[23:0]<=PAN_MAX;
    assign status = {29'd0,stop_pending,pending,1'b0};
    always @(posedge clk) begin
        if(!resetn) begin
            counter<=PERIOD-1;active_pan<=CENTER;pending_pan<=CENTER;
            active_tilt<=TILT_MIN;target_tilt<=TILT_MIN;
            pending<=0;stop_pending<=0;accepted_count<=0;
            left_frame_count<=0;right_frame_count<=0;servo_pan<=0;servo_tilt<=0;
        end else begin
            if(counter==PERIOD-1) begin
                counter<=0;servo_pan<=1;servo_tilt<=1;active_tilt<=target_tilt;
                if(stop_pending || (command_valid && command[1])) begin
                    pending<=0;stop_pending<=0;
                end else if(pending) begin
                    if(pending_pan<active_pan)left_frame_count<=left_frame_count+1'b1;
                    if(pending_pan>active_pan)right_frame_count<=right_frame_count+1'b1;
                    active_pan<=pending_pan;pending<=0;
                end
            end else begin
                counter<=counter+1'b1;
                if(counter==active_pan-1'b1)servo_pan<=0;
                if(counter==active_tilt-1'b1)servo_tilt<=0;
            end
            if(command_valid) begin
                if(command[1])begin pending<=0;stop_pending<=1;end
                if(command[2] && tilt_ticks>=TILT_MIN && tilt_ticks<=TILT_MAX)
                    target_tilt<=tilt_ticks[21:0];
                if(command[0] && !command[1] && !pending && !stop_pending && pan_position_allowed)begin
                    pending_pan<=pan_ticks[21:0];pending<=1;
                    accepted_count<=accepted_count+1'b1;
                end
            end
        end
    end
endmodule
