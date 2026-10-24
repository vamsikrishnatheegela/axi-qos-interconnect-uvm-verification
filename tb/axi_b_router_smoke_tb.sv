`timescale 1ns/1ps
module axi_b_router_smoke_tb;
    logic clk = 0;
    logic rst_n = 0;
    always #5 clk = ~clk;

    logic [1:0] s_bvalid, s_bready;
    logic [1:0][4:0] s_bid;
    logic [1:0][1:0] s_bresp;
    logic [1:0] m_bvalid, m_bready;
    logic [1:0][3:0] m_bid;
    logic [1:0][1:0] m_bresp;

    axi_b_router_2x2 dut (.*);

    task automatic tick;
        begin @(posedge clk); #1; end
    endtask

    initial begin
        s_bvalid = 0;
        s_bid = '0;
        s_bresp = '0;
        m_bready = 0;
        repeat (2) tick();
        rst_n = 1;
        @(negedge clk);

        // Both slaves respond concurrently to different masters.
        s_bvalid = 2'b11;
        s_bid[0] = {1'b0, 4'h3};
        s_bid[1] = {1'b1, 4'h5};
        s_bresp[0] = 2'b00;
        s_bresp[1] = 2'b10;
        m_bready = 2'b11;
        #1;
        if (m_bvalid !== 2'b11 || m_bid[0] !== 4'h3 ||
            m_bid[1] !== 4'h5 || m_bresp[1] !== 2'b10 ||
            s_bready !== 2'b11)
            $fatal(1, "Concurrent B responses or ID restoration failed");
        tick();

        // Both slaves now target master 0; a stall must preserve the grant.
        @(negedge clk);
        s_bvalid = 2'b11;
        s_bid[0] = {1'b0, 4'h6};
        s_bid[1] = {1'b0, 4'h7};
        m_bready = 2'b00;
        #1;
        if (m_bvalid[0] !== 1'b1 || m_bid[0] !== 4'h6 ||
            s_bready !== 2'b00)
            $fatal(1, "B arbitration/backpressure failed");
        m_bready[0] = 1;
        tick();
        s_bvalid[0] = 0;
        #1;
        if (m_bvalid[0] !== 1'b1 || m_bid[0] !== 4'h7 ||
            s_bready !== 2'b10)
            $fatal(1, "B arbiter did not serve waiting slave");
        $display("PASS: B response routing, ID restoration, concurrency, and backpressure");
        $finish;
    end
endmodule
