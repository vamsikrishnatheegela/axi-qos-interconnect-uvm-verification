// 2-master x 2-slave AXI4 write-data router.
//
// Contract: supports at most one accepted AW transaction per master at a time.
// The top-level must suppress a master's AWVALID while m_aw_block is high.
// m_aw_fire is the corresponding accepted AW handshake from the AW router.
// W data is not forwarded until its AW has been accepted. Ownership is held
// from the first W beat through an accepted WLAST; arbitration never switches
// masters in the middle of a burst. This module does not buffer W beats.
module axi_w_router_2x2 #(
    parameter integer ADDR_W = 32,
    parameter integer DATA_W = 32,
    parameter integer STRB_W = DATA_W / 8,
    parameter integer BASE0 = 0,
    parameter integer LIMIT0 = 65535,
    parameter integer BASE1 = 65536,
    parameter integer LIMIT1 = 131071
) (
    input  logic clk,
    input  logic rst_n,

    // Pulses on the actual AWVALID && AWREADY handshake for each master.
    input  logic [1:0] m_aw_fire,
    input  logic [1:0][ADDR_W-1:0] m_awaddr,
    output logic [1:0] m_aw_block,

    input  logic [1:0] m_wvalid,
    output logic [1:0] m_wready,
    input  logic [1:0][DATA_W-1:0] m_wdata,
    input  logic [1:0][STRB_W-1:0] m_wstrb,
    input  logic [1:0] m_wlast,

    output logic [1:0] s_wvalid,
    input  logic [1:0] s_wready,
    output logic [1:0][DATA_W-1:0] s_wdata,
    output logic [1:0][STRB_W-1:0] s_wstrb,
    output logic [1:0] s_wlast
);
    logic [1:0] pending;
    logic [1:0] dest_is_s1;
    logic [1:0] request [0:1];
    logic [1:0] arb_req [0:1];
    logic [1:0] grant [0:1];
    logic [1:0] grant_valid;
    logic [0:0] grant_idx [0:1];
    logic [1:0] grant_ready;
    logic [1:0] lock_valid;
    logic [0:0] lock_idx [0:1];

    always @* begin
        m_aw_block = pending;
        request[0] = 2'b00;
        request[1] = 2'b00;
        for (integer i = 0; i < 2; i = i + 1) begin
            if (pending[i] && m_wvalid[i]) begin
                if (dest_is_s1[i])
                    request[1][i] = 1'b1;
                else
                    request[0][i] = 1'b1;
            end
        end
        for (integer j = 0; j < 2; j = j + 1) begin
            arb_req[j] = request[j];
            if (lock_valid[j]) begin
                arb_req[j] = 2'b00;
                arb_req[j][lock_idx[j]] = 1'b1;
            end
        end
    end

    genvar g;
    generate
        for (g = 0; g < 2; g = g + 1) begin : gen_w_arb
            rr_arbiter #(.N(2), .IDX_W(1)) u_arb (
                .clk(clk),
                .rst_n(rst_n),
                .req(arb_req[g]),
                .grant(grant[g]),
                .grant_valid(grant_valid[g]),
                .grant_idx(grant_idx[g]),
                .grant_ready(grant_ready[g])
            );
        end
    endgenerate

    always @* begin
        s_wvalid = 2'b00;
        s_wdata = '0;
        s_wstrb = '0;
        s_wlast = 2'b00;
        m_wready = 2'b00;
        grant_ready = 2'b00;

        for (integer j = 0; j < 2; j = j + 1) begin
            if (grant_valid[j]) begin
                if (grant_idx[j] == 1'b0) begin
                    s_wvalid[j] = m_wvalid[0] && pending[0];
                    s_wdata[j] = m_wdata[0];
                    s_wstrb[j] = m_wstrb[0];
                    s_wlast[j] = m_wlast[0];
                    if (s_wready[j] && m_wvalid[0] && pending[0]) begin
                        m_wready[0] = 1'b1;
                        if (m_wlast[0]) grant_ready[j] = 1'b1;
                    end
                end else begin
                    s_wvalid[j] = m_wvalid[1] && pending[1];
                    s_wdata[j] = m_wdata[1];
                    s_wstrb[j] = m_wstrb[1];
                    s_wlast[j] = m_wlast[1];
                    if (s_wready[j] && m_wvalid[1] && pending[1]) begin
                        m_wready[1] = 1'b1;
                        if (m_wlast[1]) grant_ready[j] = 1'b1;
                    end
                end
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pending <= 2'b00;
            dest_is_s1 <= 2'b00;
            lock_valid <= 2'b00;
            lock_idx[0] <= 1'b0;
            lock_idx[1] <= 1'b0;
        end else begin
            for (integer j = 0; j < 2; j = j + 1) begin
                if (lock_valid[j]) begin
                    if (grant_ready[j])
                        lock_valid[j] <= 1'b0;
                end else if (grant_valid[j]) begin
                    if (grant_idx[j] == 1'b0) begin
                        if (m_wvalid[0] && (!s_wready[j] || !m_wlast[0])) begin
                            lock_valid[j] <= 1'b1;
                            lock_idx[j] <= 1'b0;
                        end
                    end else begin
                        if (m_wvalid[1] && (!s_wready[j] || !m_wlast[1])) begin
                            lock_valid[j] <= 1'b1;
                            lock_idx[j] <= 1'b1;
                        end
                    end
                end
            end

            for (integer i = 0; i < 2; i = i + 1) begin
                if (m_aw_fire[i] && !pending[i]) begin
                    if ((m_awaddr[i] >= BASE0) && (m_awaddr[i] <= LIMIT0)) begin
                        pending[i] <= 1'b1;
                        dest_is_s1[i] <= 1'b0;
                    end else if ((m_awaddr[i] >= BASE1) && (m_awaddr[i] <= LIMIT1)) begin
                        pending[i] <= 1'b1;
                        dest_is_s1[i] <= 1'b1;
                    end
                end

                // Release the write slot only when the final W beat handshakes.
                if (m_wvalid[i] && m_wready[i] && m_wlast[i])
                    pending[i] <= 1'b0;
            end
        end
    end

    initial begin
        if (BASE0 > LIMIT0 || BASE1 > LIMIT1)
            $error("axi_w_router_2x2: each address window base must be <= limit");
        if (!((LIMIT0 < BASE1) || (LIMIT1 < BASE0)))
            $error("axi_w_router_2x2: address windows must not overlap");
    end
endmodule
