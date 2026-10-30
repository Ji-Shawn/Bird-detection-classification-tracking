`timescale 1ns/1ps
// Restoring unsigned divider: 48 iterations; no variable combinational divide.
module unsigned_divider(input wire clk,rst,start,input wire[47:0]numerator,
 input wire[31:0]denominator,output reg busy,done,zero_error,
 output reg[47:0]quotient);
 reg[47:0]shift;reg[31:0]divisor;reg[31:0]remainder;
 reg[5:0]count;
 wire[32:0]trial={remainder,shift[47]};
 wire ge=trial>={1'b0,divisor};
 always @(posedge clk)begin
 if(rst)begin busy<=0;done<=0;zero_error<=0;quotient<=0;shift<=0;divisor<=0;remainder<=0;count<=0;end
 else begin
 done<=0;
 if(start && !busy)begin
  if(denominator==0)begin zero_error<=1;done<=1;quotient<=0;end
  else begin busy<=1;zero_error<=0;shift<=numerator;divisor<=denominator;remainder<=0;count<=0;end
 end else if(busy)begin
  remainder<=ge ? trial-divisor : trial;
  shift<={shift[46:0],ge};
  if(count==47)begin quotient<={shift[46:0],ge};busy<=0;done<=1;end
  else count<=count+1'b1;
 end
 end end
endmodule

