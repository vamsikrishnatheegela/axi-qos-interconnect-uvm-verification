`timescale 1ns/1ps
module axi_ar_router_smoke_tb;
    logic clk = 0;
    logic rst_n = 0;
    always #5 clk = ~clk;

    logic [1:0] m_arvalid, m_arready;
    logic [1:0][3:0] m_arid;
    logic [1:0][31:0] m_araddr;
    logic [1:0][7:0] m_arlen;
    logic [1:0][2:0] m_arsize;
    logic [1:0][1:0] m_arburst;
    logic [1:0][3:0] m_arcache, m_arqos;
    logic [1:0][2:0] m_arprot;

    logic [1:0] s_arvalid, s_arready;
    logic [1:0][4:0] s_arid;
    logic [1:0][31:0] s_araddr;
    logic [1:0][7:0] s_arlen;
    logic [1:0][2:0] s_arsize;
    logic [1:0][1:0] s_arburst;
    logic [1:0][3:0] s_arcache, s_arqos;
    logic [1:0][2:0] s_arprot;
    logic [1:0] decode_error;

    axi_ar_router_2x2 dut (.*);

    task automatic tick;
        begin @(posedge clk); #1; end
    endtask

    initial begin
        m_arvalid = 0;
        m_arid = '0;
        m_araddr = '0;
        m_arlen = '0;
        m_arsize = '0;
        m_arburst = '0;
        m_arcache = '0;
        m_arprot = '0;
        m_arqos = '0;
        s_arready = 0;

        repeat (2) tick();
        rst_n = 1;
        @(negedge clk);

        // Both masters target S0. Stall it, then add a second request.
        m_arvalid[0] = 1;
        m_arid[0] = 4'hA;
        m_araddr[0] = 32'h0000_0010;
        #1;
        if (s_arvalid[0] !== 1 || s_arid[0] !== {1'b0, 4'hA})
            $fatal(1, "S0 failed to route master 0 request");

        m_arvalid[1] = 1;
        m_arid[1] = 4'hB;
        m_araddr[1] = 32'h0000_0020;
        #1;
        if (s_arvalid[0] !== 1 || s_arid[0] !== 4'hA)
            $fatal(1, "AR grant changed during downstream backpressure");

        // Accept M0, then round-robin should allow M1 on the next transfer.
        s_arready[0] = 1;
        tick();
        m_arvalid[0] = 0;
        #1;
        if (s_arvalid[0] !== 1 || s_arid[0] !== {1'b1, 4'hB})
            $fatal(1, "S0 did not grant waiting master after accepted transfer");

        tick();
        m_arvalid[1] = 0;
        s_arready = 0;

        // Independent simultaneous routing to S0 and S1.
        @(negedge clk);
        m_arvalid = 2'b11;
        m_araddr[0] = 32'h0000_0040;
        m_araddr[1] = 32'h0001_0040;
        m_arid[0] = 4'h1;
        m_arid[1] = 4'h2;
        #1;
        if (s_arvalid !== 2'b11 || s_arid[0] !== {1'b0, 4'h1} || s_arid[1] !== {1'b1, 4'h2})
            $fatal(1, "Independent S0/S1 routing failed");

        // Out-of-map address must be flagged and must not be routed.
        m_arvalid[0] = 1;
        m_araddr[0] = 32'h0002_0000;
        m_arvalid[1] = 0;
        #1;
        if (decode_error[0] !== 1'b1 || s_arvalid[0] !== 1'b0)
            $fatal(1, "Decode miss was not flagged or was incorrectly routed");

        $display("PASS: AR routing, stall stability, arbitration, concurrency, and decode miss");
        $finish;
    end
endmodule
