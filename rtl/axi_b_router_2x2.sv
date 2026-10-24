// 2-slave to 2-master AXI4 write-response router.
// The top bit of each slave-side BID is the originating master tag.
// Write responses are single-beat; round-robin arbitration is maintained
// independently for each master when both slaves target that master.
module axi_b_router_2x2 #(
    parameter integer ID_W = 4
) (
    input  logic clk,
    input  logic rst_n,

    input  logic [1:0] s_bvalid,
    output logic [1:0] s_bready,
    input  logic [1:0][ID_W:0] s_bid,
    input  logic [1:0][1:0] s_bresp,

    output logic [1:0] m_bvalid,
    input  logic [1:0] m_bready,
    output logic [1:0][ID_W-1:0] m_bid,
    output logic [1:0][1:0] m_bresp
);
    logic [1:0] request [0:1];
    logic [1:0] grant [0:1];
    logic [1:0] grant_valid;
    logic [0:0] grant_idx [0:1];

    always @* begin
        request[0] = 2'b00;
        request[1] = 2'b00;
        if (s_bvalid[0]) begin
            if (s_bid[0][ID_W]) request[1][0] = 1'b1;
            else                request[0][0] = 1'b1;
        end
        if (s_bvalid[1]) begin
            if (s_bid[1][ID_W]) request[1][1] = 1'b1;
            else                request[0][1] = 1'b1;
        end
    end

    genvar mgen;
    generate
        for (mgen = 0; mgen < 2; mgen = mgen + 1) begin : gen_b_arb
            rr_arbiter #(.N(2), .IDX_W(1)) u_arb (
                .clk(clk),
                .rst_n(rst_n),
                .req(request[mgen]),
                .grant(grant[mgen]),
                .grant_valid(grant_valid[mgen]),
                .grant_idx(grant_idx[mgen]),
                .grant_ready(grant_valid[mgen] &&
                             m_bready[mgen] &&
                             s_bvalid[grant_idx[mgen]])
            );
        end
    endgenerate

    always @* begin
        s_bready = 2'b00;
        m_bvalid = 2'b00;
        m_bid = '0;
        m_bresp = '0;
        for (integer m = 0; m < 2; m = m + 1) begin
            if (grant_valid[m]) begin
                if (grant_idx[m] == 1'b0) begin
                    m_bvalid[m] = s_bvalid[0];
                    m_bid[m] = s_bid[0][ID_W-1:0];
                    m_bresp[m] = s_bresp[0];
                    s_bready[0] = m_bready[m];
                end else begin
                    m_bvalid[m] = s_bvalid[1];
                    m_bid[m] = s_bid[1][ID_W-1:0];
                    m_bresp[m] = s_bresp[1];
                    s_bready[1] = m_bready[m];
                end
            end
        end
    end
endmodule
