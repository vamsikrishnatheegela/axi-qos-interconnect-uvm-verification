// 2-master x 2-slave AXI4 write-address router.
// Routes only the AW channel. Read-data return routing is a later block.
// Address misses are intentionally not accepted here; a dedicated error
// responder will be added when the complete R path is integrated.
module axi_aw_router_2x2 #(
    parameter integer ADDR_W = 32,
    parameter integer ID_W   = 4,
    parameter integer LEN_W  = 8,
    parameter integer SIZE_W = 3,
    parameter integer BURST_W = 2,
    parameter integer BASE0 = 0,
    parameter integer LIMIT0 = 65535,
    parameter integer BASE1 = 65536,
    parameter integer LIMIT1 = 131071
) (
    input  logic clk,
    input  logic rst_n,

    input  logic [1:0] m_awvalid,
    output logic [1:0] m_awready,
    input  logic [1:0][ID_W-1:0] m_awid,
    input  logic [1:0][ADDR_W-1:0] m_awaddr,
    input  logic [1:0][LEN_W-1:0] m_awlen,
    input  logic [1:0][SIZE_W-1:0] m_awsize,
    input  logic [1:0][BURST_W-1:0] m_awburst,
    input  logic [1:0][3:0] m_awcache,
    input  logic [1:0][2:0] m_awprot,
    input  logic [1:0][3:0] m_awqos,

    output logic [1:0] s_awvalid,
    input  logic [1:0] s_awready,
    output logic [1:0][ID_W:0] s_awid,
    output logic [1:0][ADDR_W-1:0] s_awaddr,
    output logic [1:0][LEN_W-1:0] s_awlen,
    output logic [1:0][SIZE_W-1:0] s_awsize,
    output logic [1:0][BURST_W-1:0] s_awburst,
    output logic [1:0][3:0] s_awcache,
    output logic [1:0][2:0] s_awprot,
    output logic [1:0][3:0] s_awqos,

    output logic [1:0] decode_error
);
    logic [1:0] decoded_slave [0:1];
    logic [1:0] request [0:1];
    logic [1:0] grant [0:1];
    logic [1:0] grant_valid;
    logic [0:0] grant_idx [0:1];
    logic [1:0] arb_req [0:1];
    logic [1:0] lock_valid;
    logic [0:0] lock_idx [0:1];
    integer m;
    integer s;

    // Decode each master's address to one of the two configured windows.
    always @* begin
        for (integer i = 0; i < 2; i = i + 1) begin
            decoded_slave[i] = 2'b00;
            decode_error[i] = 1'b0;
            if ((m_awaddr[i] >= BASE0) && (m_awaddr[i] <= LIMIT0))
                decoded_slave[i] = 2'b01;
            else if ((m_awaddr[i] >= BASE1) && (m_awaddr[i] <= LIMIT1))
                decoded_slave[i] = 2'b10;
            else
                decode_error[i] = m_awvalid[i];
        end
    end

    always @* begin
        request[0] = 2'b00;
        request[1] = 2'b00;
        for (integer i = 0; i < 2; i = i + 1) begin
            if (m_awvalid[i] && decoded_slave[i][0]) request[0][i] = 1'b1;
            if (m_awvalid[i] && decoded_slave[i][1]) request[1][i] = 1'b1;
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
        for (g = 0; g < 2; g = g + 1) begin : gen_ar_arb
            rr_arbiter #(.N(2), .IDX_W(1)) u_arb (
                .clk(clk),
                .rst_n(rst_n),
                .req(arb_req[g]),
                .grant(grant[g]),
                .grant_valid(grant_valid[g]),
                .grant_idx(grant_idx[g]),
                .grant_ready(grant_valid[g] && s_awready[g])
            );
        end
    endgenerate

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lock_valid[0] <= 1'b0;
            lock_valid[1] <= 1'b0;
            lock_idx[0] <= 1'b0;
            lock_idx[1] <= 1'b0;
        end else begin
            for (integer j = 0; j < 2; j = j + 1) begin
                if (lock_valid[j]) begin
                    if (grant_valid[j] && s_awready[j])
                        lock_valid[j] <= 1'b0;
                end else if (grant_valid[j] && !s_awready[j]) begin
                    lock_valid[j] <= 1'b1;
                    lock_idx[j] <= grant_idx[j];
                end
            end
        end
    end

    always @* begin
        m_awready = 2'b00;
        s_awvalid = grant_valid;
        s_awid = '0;
        s_awaddr = '0;
        s_awlen = '0;
        s_awsize = '0;
        s_awburst = '0;
        s_awcache = '0;
        s_awprot = '0;
        s_awqos = '0;

        for (integer j = 0; j < 2; j = j + 1) begin
            if (grant_valid[j]) begin
                s_awid[j] = {grant_idx[j], m_awid[grant_idx[j]]};
                s_awaddr[j] = m_awaddr[grant_idx[j]];
                s_awlen[j] = m_awlen[grant_idx[j]];
                s_awsize[j] = m_awsize[grant_idx[j]];
                s_awburst[j] = m_awburst[grant_idx[j]];
                s_awcache[j] = m_awcache[grant_idx[j]];
                s_awprot[j] = m_awprot[grant_idx[j]];
                s_awqos[j] = m_awqos[grant_idx[j]];
                if (s_awready[j])
                    m_awready[grant_idx[j]] = 1'b1;
            end
        end
    end

    initial begin
        if (BASE0 > LIMIT0 || BASE1 > LIMIT1)
            $error("axi_aw_router_2x2: each address window base must be <= limit");
        if (!((LIMIT0 < BASE1) || (LIMIT1 < BASE0)))
            $error("axi_aw_router_2x2: address windows must not overlap");
    end
endmodule
