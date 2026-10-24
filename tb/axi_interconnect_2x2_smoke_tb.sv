`timescale 1ns/1ps
module axi_interconnect_2x2_smoke_tb;
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

    logic [1:0] m_wvalid, m_wready;
    logic [1:0][31:0] m_wdata;
    logic [1:0][3:0] m_wstrb;
    logic [1:0] m_wlast;

    logic [1:0] m_bvalid, m_bready;
    logic [1:0][3:0] m_bid;
    logic [1:0][1:0] m_bresp;

    logic [1:0] m_arvalid, m_arready;
    logic [1:0][3:0] m_arid;
    logic [1:0][31:0] m_araddr;
    logic [1:0][7:0] m_arlen;
    logic [1:0][2:0] m_arsize;
    logic [1:0][1:0] m_arburst;
    logic [1:0][3:0] m_arcache, m_arqos;
    logic [1:0][2:0] m_arprot;

    logic [1:0] m_rvalid, m_rready;
    logic [1:0][3:0] m_rid;
    logic [1:0][31:0] m_rdata;
    logic [1:0][1:0] m_rresp;
    logic [1:0] m_rlast;

    logic [1:0] s_awvalid, s_awready;
    logic [1:0][4:0] s_awid;
    logic [1:0][31:0] s_awaddr;
    logic [1:0][7:0] s_awlen;
    logic [1:0][2:0] s_awsize;
    logic [1:0][1:0] s_awburst;
    logic [1:0][3:0] s_awcache, s_awqos;
    logic [1:0][2:0] s_awprot;

    logic [1:0] s_wvalid, s_wready;
    logic [1:0][31:0] s_wdata;
    logic [1:0][3:0] s_wstrb;
    logic [1:0] s_wlast;

    logic [1:0] s_bvalid, s_bready;
    logic [1:0][4:0] s_bid;
    logic [1:0][1:0] s_bresp;

    logic [1:0] s_arvalid, s_arready;
    logic [1:0][4:0] s_arid;
    logic [1:0][31:0] s_araddr;
    logic [1:0][7:0] s_arlen;
    logic [1:0][2:0] s_arsize;
    logic [1:0][1:0] s_arburst;
    logic [1:0][3:0] s_arcache, s_arqos;
    logic [1:0][2:0] s_arprot;

    logic [1:0] s_rvalid, s_rready;
    logic [1:0][4:0] s_rid;
    logic [1:0][31:0] s_rdata;
    logic [1:0][1:0] s_rresp;
    logic [1:0] s_rlast;

    logic [1:0] m_aw_block, m_aw_decode_error, m_ar_decode_error;

    axi_interconnect_2x2 dut (.*);

    task automatic tick;
        begin @(posedge clk); #1; end
    endtask

    initial begin
        m_awvalid = 0; m_awid = '0; m_awaddr = '0; m_awlen = '0;
        m_awsize = 3'd2; m_awburst = 2'b01; m_awcache = '0;
        m_awprot = '0; m_awqos = '0;
        m_wvalid = 0; m_wdata = '0; m_wstrb = '0; m_wlast = 0;
        m_bready = 2'b11;
        m_arvalid = 0; m_arid = '0; m_araddr = '0; m_arlen = '0;
        m_arsize = 3'd2; m_arburst = 2'b01; m_arcache = '0;
        m_arprot = '0; m_arqos = '0;
        m_rready = 2'b11;

        s_awready = 2'b11;
        s_wready = 2'b11;
        s_bvalid = 0; s_bid = '0; s_bresp = '0;
        s_arready = 2'b11;
        s_rvalid = 0; s_rid = '0; s_rdata = '0;
        s_rresp = '0; s_rlast = 0;

        repeat (2) tick();
        rst_n = 1;
        @(negedge clk);

        // M0 writes a two-beat burst to S1. Verify route and master-tagged AWID.
        m_awvalid[0] = 1;
        m_awid[0] = 4'h3;
        m_awaddr[0] = 32'h0001_0020;
        m_awlen[0] = 8'd1;
        #1;
        if (!m_awready[0] || s_awvalid !== 2'b10 ||
            s_awaddr[1] !== 32'h0001_0020 || s_awid[1] !== 5'b00011)
            $fatal(1, "Integrated AW route or ID tag failed");
        tick();
        m_awvalid[0] = 0;

        // First W beat: non-final beat must stay on S1.
        m_wvalid[0] = 1;
        m_wdata[0] = 32'hCAFE_BABE;
        m_wstrb[0] = 4'hF;
        m_wlast[0] = 0;
        #1;
        if (s_wvalid !== 2'b10 || s_wdata[1] !== 32'hCAFE_BABE ||
            !m_wready[0] || s_wlast[1])
            $fatal(1, "Integrated first W beat route/payload failed");
        tick();

        // Second W beat completes the burst and releases the write slot.
        m_wdata[0] = 32'hDEAD_BEEF;
        m_wlast[0] = 1;
        #1;
        if (s_wvalid !== 2'b10 || s_wdata[1] !== 32'hDEAD_BEEF ||
            !m_wready[0] || !s_wlast[1])
            $fatal(1, "Integrated final W beat route/payload failed");
        tick();
        m_wvalid[0] = 0;
        m_wlast[0] = 0;
        if (m_aw_block[0] !== 0)
            $fatal(1, "Write slot did not release after WLAST");

        // Return B from S1 using tagged ID; verify original ID at M0.
        @(negedge clk);
        s_bvalid[1] = 1;
        s_bid[1] = 5'b00011;
        s_bresp[1] = 2'b00;
        #1;
        if (!m_bvalid[0] || m_bid[0] !== 4'h3 || m_bresp[0] !== 2'b00)
            $fatal(1, "Integrated B response or ID restoration failed");
        tick();
        s_bvalid[1] = 0;

        // M1 reads a two-beat burst from S0. Verify route and tagged ARID.
        @(negedge clk);
        m_arvalid[1] = 1;
        m_arid[1] = 4'h9;
        m_araddr[1] = 32'h0000_0040;
        m_arlen[1] = 8'd1;
        #1;
        if (!m_arready[1] || s_arvalid !== 2'b01 ||
            s_araddr[0] !== 32'h0000_0040 || s_arid[0] !== 5'b11001)
            $fatal(1, "Integrated AR route or ID tag failed");
        tick();
        m_arvalid[1] = 0;

        // First R beat is stalled at the master. VALID/payload must hold stable.
        @(negedge clk);
        s_rvalid[0] = 1;
        s_rid[0] = 5'b11001;
        s_rdata[0] = 32'h1234_5678;
        s_rresp[0] = 2'b00;
        s_rlast[0] = 0;
        m_rready[1] = 0;
        #1;
        if (!m_rvalid[1] || m_rid[1] !== 4'h9 ||
            m_rdata[1] !== 32'h1234_5678 || m_rlast[1] ||
            s_rready[0])
            $fatal(1, "Integrated first R beat or backpressure failed");
        tick();
        if (!m_rvalid[1] || m_rid[1] !== 4'h9 ||
            m_rdata[1] !== 32'h1234_5678 || m_rlast[1])
            $fatal(1, "R payload changed while stalled");
        m_rready[1] = 1;
        tick();

        // Second R beat must remain routed to M1 and complete the burst.
        @(negedge clk);
        s_rdata[0] = 32'h8765_4321;
        s_rlast[0] = 1;
        #1;
        if (!m_rvalid[1] || m_rid[1] !== 4'h9 ||
            m_rdata[1] !== 32'h8765_4321 || !m_rlast[1])
            $fatal(1, "Integrated final R beat or burst ownership failed");
        tick();
        s_rvalid[0] = 0;
        s_rlast[0] = 0;

        if (m_aw_decode_error !== 2'b00 || m_ar_decode_error !== 2'b00)
            $fatal(1, "Unexpected decode error for mapped transactions");

        $display("PASS: integrated two-beat AW/W/B and AR/R bursts, R backpressure stability, routing, and ID tag/restore");
        $finish;
    end
endmodule
