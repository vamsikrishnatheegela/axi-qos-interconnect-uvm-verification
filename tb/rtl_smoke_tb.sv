module rtl_smoke_tb;
    logic clk = 1'b0;
    logic rst_n = 1'b0;
    always #5 clk = ~clk;

    logic [1:0] req;
    logic [1:0] grant;
    logic grant_valid;
    logic grant_ready;
    logic [0:0] grant_idx;

    logic [31:0] addr;
    logic [1:0] slave_sel;
    logic decode_valid;
    logic decode_error;

    rr_arbiter #(.N(2)) u_arb (
        .clk(clk), .rst_n(rst_n), .req(req), .grant(grant),
        .grant_valid(grant_valid), .grant_idx(grant_idx),
        .grant_ready(grant_ready)
    );

    axi_address_decoder u_dec (
        .addr(addr), .slave_sel(slave_sel),
        .decode_valid(decode_valid), .decode_error(decode_error)
    );

    task automatic check_decode(
        input logic [31:0] test_addr,
        input logic [1:0] expected_sel,
        input logic expected_valid
    );
        begin
            addr = test_addr;
            #1;
            if (slave_sel !== expected_sel ||
                decode_valid !== expected_valid ||
                decode_error !== !expected_valid) begin
                $display("FAIL decode addr=%h sel=%b valid=%b error=%b",
                         addr, slave_sel, decode_valid, decode_error);
                $fatal(1);
            end
        end
    endtask

    initial begin
        req = 2'b00;
        grant_ready = 1'b1;
        addr = '0;
        repeat (2) @(posedge clk);
        rst_n = 1'b1;
        @(negedge clk);

        check_decode(32'h0000_0000, 2'b01, 1'b1);
        check_decode(32'h0000_FFFF, 2'b01, 1'b1);
        check_decode(32'h0001_0000, 2'b10, 1'b1);
        check_decode(32'h0001_FFFF, 2'b10, 1'b1);
        check_decode(32'h0002_0000, 2'b00, 1'b0);

        req = 2'b11;
        #1;
        if (!grant_valid || grant !== 2'b01 || grant_idx !== 1'b0)
            $fatal(1, "Expected initial grant to requester 0; grant=%b", grant);

        @(posedge clk); #1;
        if (!grant_valid || grant !== 2'b10 || grant_idx !== 1'b1)
            $fatal(1, "Expected second grant to requester 1; grant=%b", grant);

        @(posedge clk); #1;
        if (!grant_valid || grant !== 2'b01 || grant_idx !== 1'b0)
            $fatal(1, "Expected third grant to requester 0; grant=%b", grant);

        @(negedge clk);
        req = 2'b00;
        #1;
        if (grant_valid || grant !== 2'b00)
            $fatal(1, "Grant asserted when no request was active");

        $display("PASS: address decoder boundaries, decode miss, and round-robin smoke test");
        $finish;
    end
endmodule
