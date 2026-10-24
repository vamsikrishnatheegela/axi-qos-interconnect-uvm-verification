`timescale 1ns/1ps
module axi_r_router_smoke_tb;
    logic clk = 0;
    logic rst_n = 0;
    always #5 clk = ~clk;

    logic [1:0] s_rvalid, s_rready;
    logic [1:0][4:0] s_rid;
    logic [1:0][31:0] s_rdata;
    logic [1:0][1:0] s_rresp;
    logic [1:0] s_rlast;

    logic [1:0] m_rvalid, m_rready;
    logic [1:0][3:0] m_rid;
    logic [1:0][31:0] m_rdata;
    logic [1:0][1:0] m_rresp;
    logic [1:0] m_rlast;

    axi_r_router_2x2 dut (.*);

    task automatic tick;
        begin @(posedge clk); #1; end
    endtask

    initial begin
        s_rvalid = 0;
        s_rid = '0;
        s_rdata = '0;
        s_rresp = '0;
        s_rlast = '0;
        m_rready = 0;

        repeat (2) tick();
        rst_n = 1;
        @(negedge clk);

        // Independent slave responses to different masters at the same time.
        s_rvalid = 2'b11;
        s_rid[0] = {1'b0, 4'h3};
        s_rid[1] = {1'b1, 4'h5};
        s_rdata[0] = 32'hA0A0_0001;
        s_rdata[1] = 32'hB0B0_0002;
        s_rresp = 0;
        s_rlast = 2'b11;
        m_rready = 2'b11;
        #1;
        if (m_rvalid !== 2'b11 ||
            m_rid[0] !== 4'h3 || m_rid[1] !== 4'h5 ||
            m_rdata[0] !== 32'hA0A0_0001 ||
            m_rdata[1] !== 32'hB0B0_0002 ||
            s_rready !== 2'b11)
            $fatal(1, "Concurrent R responses or master-tag stripping failed");
        tick();

        // Reset arbiter history, then make both slaves target master 0.
        @(negedge clk);
        rst_n = 0;
        s_rvalid = 0;
        m_rready = 0;
        tick();
        @(negedge clk);
        rst_n = 1;
        s_rvalid = 2'b11;
        s_rid[0] = {1'b0, 4'h6};
        s_rid[1] = {1'b0, 4'h7};
        s_rdata[0] = 32'h1111_0000;
        s_rdata[1] = 32'h2222_0000;
        s_rlast = 2'b00;
        #1;
        if (m_rvalid[0] !== 1'b1 || m_rdata[0] !== 32'h1111_0000 ||
            m_rid[0] !== 4'h6 || s_rready !== 2'b00)
            $fatal(1, "Initial R arbitration or backpressure handling failed");

        // Accept a non-final beat; ownership must remain with slave 0.
        m_rready[0] = 1;
        tick();
        s_rdata[0] = 32'h1111_0001;
        s_rdata[1] = 32'h2222_0001;
        #1;
        if (m_rvalid[0] !== 1'b1 || m_rdata[0] !== 32'h1111_0001 ||
            s_rready !== 2'b01)
            $fatal(1, "R burst ownership changed before RLAST");

        // Final beat accepted from slave 0; then slave 1 may be selected.
        s_rlast[0] = 1;
        tick();
        s_rvalid[0] = 0;
        s_rlast[1] = 1;
        #1;
        if (m_rvalid[0] !== 1'b1 || m_rdata[0] !== 32'h2222_0001 ||
            m_rid[0] !== 4'h7)
            $fatal(1, "Round-robin did not select waiting second slave after RLAST");

        $display("PASS: R response routing, ID restoration, concurrent responses, backpressure, and burst locking");
        $finish;
    end
endmodule
