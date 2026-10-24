// Parameterized, work-conserving round-robin arbiter.
// Priority advances only after a granted transfer is accepted.
module rr_arbiter #(
    parameter integer N = 2,
    parameter integer IDX_W = (N < 2) ? 1 : $clog2(N)
) (
    input  logic             clk,
    input  logic             rst_n,
    input  logic [N-1:0]     req,
    output logic [N-1:0]     grant,
    output logic             grant_valid,
    output logic [IDX_W-1:0] grant_idx,
    input  logic             grant_ready
);
    integer rr_ptr;
    integer scan_idx;
    integer k;
    logic found;

    always_comb begin
        grant       = '0;
        grant_valid = 1'b0;
        grant_idx   = '0;
        found       = 1'b0;
        scan_idx    = 0;

        for (k = 0; k < N; k = k + 1) begin
            scan_idx = rr_ptr + k;
            if (scan_idx >= N)
                scan_idx = scan_idx - N;
            if (!found && req[scan_idx]) begin
                grant[scan_idx] = 1'b1;
                grant_valid     = 1'b1;
                grant_idx       = scan_idx[IDX_W-1:0];
                found           = 1'b1;
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rr_ptr <= 0;
        else if (grant_valid && grant_ready) begin
            if (grant_idx == N-1)
                rr_ptr <= 0;
            else
                rr_ptr <= grant_idx + 1'b1;
        end
    end

    initial begin
        if (N < 1) $error("rr_arbiter: N must be >= 1");
    end
endmodule
