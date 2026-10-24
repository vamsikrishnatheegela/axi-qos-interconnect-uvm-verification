`timescale 1ns/1ps
module axi_aw_router_smoke_tb;
    logic clk = 0;
    logic rst_n = 0;
    always #5 clk = ~clk;

    logic [1:0] m_awvalid, m_awready;
    logic [1:0][3:0] m_awid;
    logic [1:0][31:0] m_awaddr;
    logic [1:0][7:0] m_awlen;
    logic [1:0][2:0] m_awsize;
    logic [1:0][1:0] m_awburst;
    logic [1:0][3:0] m_awcache, m_awqos;
    logic [1:0][2:0] m_awprot;

    logic [1:0] s_awvalid, s_awready;
    logic [1:0][4:0] s_awid;
    logic [1:0][31:0] s_awaddr;
    logic [1:0][7:0] s_awlen;
    logic [1:0][2:0] s_awsize;
    logic [1:0][1:0] s_awburst;
    logic [1:0][3:0] s_awcache, s_awqos;
    logic [1:0][2:0] s_awprot;
    logic [1:0] decode_error;

    axi_aw_router_2x2 dut (.*);

    task automatic tick;
        begin @(posedge clk); #1; end
    endtask

    initial begin
        m_awvalid = 0;
        m_awid = '0;
        m_awaddr = '0;
        m_awlen = '0;
        m_awsize = '0;
        m_awburst = '0;
        m_awcache = '0;
        m_awprot = '0;
        m_awqos = '0;
        s_awready = 0;

        repeat (2) tick();
        rst_n = 1;
        @(negedge clk);

        // Both masters target S0. Stall it, then add a second request.
        m_awvalid[0] = 1;
        m_awid[0] = 4'hA;
        m_awaddr[0] = 32'h0000_0010;
        #1;
        if (s_awvalid[0] !== 1 || s_awid[0] !== {1'b0, 4'hA})
            $fatal(1, "S0 failed to route master 0 request");

        m_awvalid[1] = 1;
        m_awid[1] = 4'hB;
        m_awaddr[1] = 32'h0000_0020;
        #1;
        if (s_awvalid[0] !== 1 || s_awid[0] !== 4'hA)
            $fatal(1, "AW grant changed during downstream backpressure");

        // Accept M0, then round-robin should allow M1 on the next transfer.
        s_awready[0] = 1;
        tick();
        m_awvalid[0] = 0;
        #1;
        if (s_awvalid[0] !== 1 || s_awid[0] !== {1'b1, 4'hB})
            $fatal(1, "S0 did not grant waiting master after accepted transfer");

        tick();
        m_awvalid[1] = 0;
        s_awready = 0;

        // Independent simultaneous routing to S0 and S1.
        @(negedge clk);
        m_awvalid = 2'b11;
        m_awaddr[0] = 32'h0000_0040;
        m_awaddr[1] = 32'h0001_0040;
        m_awid[0] = 4'h1;
        m_awid[1] = 4'h2;
        #1;
        if (s_awvalid !== 2'b11 || s_awid[0] !== {1'b0, 4'h1} || s_awid[1] !== {1'b1, 4'h2})
            $fatal(1, "Independent S0/S1 routing failed");

        // Out-of-map address must be flagged and must not be routed.
        m_awvalid[0] = 1;
        m_awaddr[0] = 32'h0002_0000;
        m_awvalid[1] = 0;
        #1;
        if (decode_error[0] !== 1'b1 || s_awvalid[0] !== 1'b0)
            $fatal(1, "Decode miss was not flagged or was incorrectly routed");

        $display("PASS: AW routing, stall stability, arbitration, concurrency, and decode miss");
        $finish;
    end
endmodule
