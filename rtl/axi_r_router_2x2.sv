// 2-slave to 2-master AXI4 read-data response router.
// The top bit of each slave-side RID is the originating master tag;
// the remaining ID_W bits are the original master transaction ID.
// A selected slave remains locked to its destination master for the
// entire burst, including any cycles of R-channel backpressure.
module axi_r_router_2x2 #(
    parameter integer ID_W = 4,
    parameter integer DATA_W = 32
) (
    input  logic clk,
    input  logic rst_n,

    input  logic [1:0] s_rvalid,
    output logic [1:0] s_rready,
    input  logic [1:0][ID_W:0] s_rid,
    input  logic [1:0][DATA_W-1:0] s_rdata,
    input  logic [1:0][1:0] s_rresp,
    input  logic [1:0] s_rlast,

    output logic [1:0] m_rvalid,
    input  logic [1:0] m_rready,
    output logic [1:0][ID_W-1:0] m_rid,
    output logic [1:0][DATA_W-1:0] m_rdata,
    output logic [1:0][1:0] m_rresp,
    output logic [1:0] m_rlast
);
    // Requests are grouped by destination master. Each slave response's
    // tagged RID identifies exactly one destination master.
    logic [1:0] request [0:1];
    logic [1:0] arb_req [0:1];
    logic [1:0] grant [0:1];
    logic [1:0] grant_valid;
    logic [0:0] grant_idx [0:1];
    logic [1:0] lock_valid;
    logic [0:0] lock_idx [0:1];

    always @* begin
        request[0] = 2'b00;
        request[1] = 2'b00;
        for (integer s = 0; s < 2; s = s + 1) begin
            if (s_rvalid[s])
                request[s_rid[s][ID_W]][s] = 1'b1;
        end
        for (integer m = 0; m < 2; m = m + 1) begin
            arb_req[m] = request[m];
            if (lock_valid[m]) begin
                arb_req[m] = 2'b00;
                arb_req[m][lock_idx[m]] = 1'b1;
            end
        end
    end

    genvar mgen;
    generate
        for (mgen = 0; mgen < 2; mgen = mgen + 1) begin : gen_r_arb
            rr_arbiter #(.N(2), .IDX_W(1)) u_arb (
                .clk(clk),
                .rst_n(rst_n),
                .req(arb_req[mgen]),
                .grant(grant[mgen]),
                .grant_valid(grant_valid[mgen]),
                .grant_idx(grant_idx[mgen]),
                // Advance round-robin priority only after the final beat
                // of a response burst is accepted by its destination.
                .grant_ready(grant_valid[mgen] &&
                             m_rready[mgen] &&
                             s_rvalid[grant_idx[mgen]] &&
                             s_rlast[grant_idx[mgen]])
            );
        end
    endgenerate

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lock_valid <= 2'b00;
            lock_idx[0] <= 1'b0;
            lock_idx[1] <= 1'b0;
        end else begin
            for (integer m = 0; m < 2; m = m + 1) begin
                if (lock_valid[m]) begin
                    if (grant_valid[m] && m_rready[m] &&
                        s_rvalid[grant_idx[m]] && s_rlast[grant_idx[m]])
                        lock_valid[m] <= 1'b0;
                end else if (grant_valid[m] && s_rvalid[grant_idx[m]] &&
                             (!m_rready[m] || !s_rlast[grant_idx[m]])) begin
                    lock_valid[m] <= 1'b1;
                    lock_idx[m] <= grant_idx[m];
                end
            end
        end
    end

    always @* begin
        s_rready = 2'b00;
        m_rvalid = 2'b00;
        m_rid = '0;
        m_rdata = '0;
        m_rresp = '0;
        m_rlast = '0;

        for (integer m = 0; m < 2; m = m + 1) begin
            if (grant_valid[m]) begin
                m_rvalid[m] = s_rvalid[grant_idx[m]];
                m_rid[m] = s_rid[grant_idx[m]][ID_W-1:0];
                m_rdata[m] = s_rdata[grant_idx[m]];
                m_rresp[m] = s_rresp[grant_idx[m]];
                m_rlast[m] = s_rlast[grant_idx[m]];
                s_rready[grant_idx[m]] = m_rready[m];
            end
        end
    end
endmodule
