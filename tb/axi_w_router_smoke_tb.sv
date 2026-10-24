`timescale 1ns/1ps
module axi_w_router_smoke_tb;
    logic clk = 0;
    logic rst_n = 0;
    always #5 clk = ~clk;

    logic [1:0] m_aw_fire;
    logic [1:0][31:0] m_awaddr;
    logic [1:0] m_aw_block;
    logic [1:0] m_wvalid, m_wready;
    logic [1:0][31:0] m_wdata;
    logic [1:0][3:0] m_wstrb;
    logic [1:0] m_wlast;
    logic [1:0] s_wvalid, s_wready;
    logic [1:0][31:0] s_wdata;
    logic [1:0][3:0] s_wstrb;
    logic [1:0] s_wlast;

    axi_w_router_2x2 dut (.*);

    task automatic tick;
        begin @(posedge clk); #1; end
    endtask

    initial begin
        m_aw_fire = 0;
        m_awaddr = '0;
        m_wvalid = 0;
        m_wdata = '0;
        m_wstrb = '0;
        m_wlast = 0;
        s_wready = 0;

        repeat (2) tick();
        rst_n = 1;
        @(negedge clk);

        // W must wait until its corresponding AW handshake has been observed.
        m_wvalid[0] = 1;
        m_wdata[0] = 32'hA0A0_0001;
        m_wstrb[0] = 4'hF;
        m_wlast[0] = 1;
        #1;
        if (s_wvalid !== 2'b00 || m_wready !== 2'b00)
            $fatal(1, "W data forwarded before AW acceptance");

        // Accept AW for both masters, both targeting S0.
        m_awaddr[0] = 32'h0000_0010;
        m_awaddr[1] = 32'h0000_0020;
        m_aw_fire = 2'b11;
        tick();
        m_aw_fire = 0;
        if (m_aw_block !== 2'b11)
            $fatal(1, "AW block did not assert for active write bursts");

        // M0 is first in round-robin order; accept a non-final beat.
        m_wlast[0] = 0;
        m_wdata[0] = 32'hA0A0_0002;
        m_wvalid[1] = 1;
        m_wdata[1] = 32'hB0B0_0001;
        m_wstrb[1] = 4'h5;
        m_wlast[1] = 1;
        s_wready[0] = 1;
        #1;
        if (s_wvalid[0] !== 1 || s_wdata[0] !== 32'hA0A0_0002 ||
            m_wready[0] !== 1 || m_wready[1] !== 0)
            $fatal(1, "Initial W arbitration or payload routing failed");
        tick();

        // The burst owner must remain M0 while downstream backpressures it.
        m_wlast[0] = 1;
        m_wdata[0] = 32'hA0A0_0003;
        s_wready[0] = 0;
        #1;
        if (s_wvalid[0] !== 1 || s_wdata[0] !== 32'hA0A0_0003 ||
            m_wready[0] !== 0 || m_wready[1] !== 0)
            $fatal(1, "W burst ownership/backpressure behavior failed");
        tick();

        // Release stall; M0's WLAST completes its burst.
        s_wready[0] = 1;
        #1;
        if (s_wvalid[0] !== 1 || s_wlast[0] !== 1 || m_wready[0] !== 1)
            $fatal(1, "M0 final W beat was not presented correctly");
        tick();
        if (m_aw_block[0] !== 0 || m_aw_block[1] !== 1)
            $fatal(1, "Write slot was not released exactly at accepted WLAST");

        // RR should now service M1 and complete its one-beat burst.
        #1;
        if (s_wvalid[0] !== 1 || s_wdata[0] !== 32'hB0B0_0001 ||
            m_wready[1] !== 1 || m_wready[0] !== 0)
            $fatal(1, "Round-robin did not select M1 after M0 burst");
        tick();
        m_wvalid = 0;
        s_wready = 0;

        // Independent simultaneous W routing to S0 and S1.
        @(negedge clk);
        m_awaddr[0] = 32'h0000_0040;
        m_awaddr[1] = 32'h0001_0040;
        m_aw_fire = 2'b11;
        tick();
        m_aw_fire = 0;
        m_wvalid = 2'b11;
        m_wdata[0] = 32'h1111_2222;
        m_wdata[1] = 32'h3333_4444;
        m_wstrb[0] = 4'h3;
        m_wstrb[1] = 4'hC;
        m_wlast = 2'b11;
        s_wready = 2'b11;
        #1;
        if (s_wvalid !== 2'b11 ||
            s_wdata[0] !== 32'h1111_2222 || s_wdata[1] !== 32'h3333_4444 ||
            s_wstrb[0] !== 4'h3 || s_wstrb[1] !== 4'hC ||
            m_wready !== 2'b11)
            $fatal(1, "Independent S0/S1 W routing failed");
        tick();

        $display("PASS: W routing, AW/W independence, burst locking, backpressure, slot release, and concurrent destinations");
        $finish;
    end
endmodule
