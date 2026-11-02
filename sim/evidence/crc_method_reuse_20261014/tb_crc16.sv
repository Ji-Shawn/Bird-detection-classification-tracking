`timescale 1ns/1ps
`include "vector_config.vh"
module tb_crc16;
reg clk=0;always #5 clk=~clk;
reg resetn=0,s_valid=0,m_ready=0,s_last=0;
reg [15:0] s_data=0;reg [1:0] s_keep=0;
wire s_ready,m_valid;wire [31:0] m_crc;
crc16_stream dut(.*);
reg [18:0] words[0:`WORDS-1];reg [31:0] expected[0:`PACKETS-1];
integer sent=0,received=0,cycles=0,stalls=0;reg running=0,hold_input=0,hold_output=0;
reg [31:0] held_crc;reg [31:0] rng=32'd2276;
always @(posedge clk)if(running)begin
    cycles=cycles+1;
    if(hold_output && (!m_valid || m_crc!==held_crc))$fatal(1,"output changed under backpressure");
    hold_output=m_valid&&!m_ready;held_crc=m_crc;
    if(hold_output)stalls=stalls+1;
    if(s_valid && s_ready)sent=sent+1;
    hold_input=s_valid&&!s_ready;
    if(m_valid && m_ready)begin
        if(received>=`PACKETS || m_crc!==expected[received])$fatal(1,"CRC mismatch packet=%0d got=%h expected=%h",received,m_crc,expected[received]);
        received=received+1;
    end
end
always @(negedge clk)if(running)begin
    rng=rng^(rng<<13);rng=rng^(rng>>17);rng=rng^(rng<<5);
    m_ready=(rng[3:0]!=0);
    if(!hold_input)begin
        s_valid=sent<`WORDS && rng[7:4]!=0;
        if(sent<`WORDS)begin s_data=words[sent][15:0];s_keep=words[sent][17:16];s_last=words[sent][18];end
    end
    if(received==`PACKETS && sent==`WORDS)begin
        if(stalls==0)$fatal(1,"backpressure not exercised");
        $display("TEST_PASS packets=%0d words=%0d cycles=%0d stalls=%0d",received,sent,cycles,stalls);$finish;
    end
end
initial begin
    $readmemh("input.hex",words);$readmemh("expected.hex",expected);
    repeat(4)@(negedge clk);resetn=1;
    // Abort an unfinished packet through reset, then begin the golden stream.
    s_data=16'h1234;s_keep=3;s_valid=1;@(negedge clk);s_valid=0;resetn=0;
    repeat(3)@(negedge clk);resetn=1;running=1;
end
initial begin #100000000;$fatal(1,"watchdog");end
endmodule
