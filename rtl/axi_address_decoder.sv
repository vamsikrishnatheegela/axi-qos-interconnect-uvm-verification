// Two-window address decoder for the initial 2x2 interconnect milestone.
// A decode miss is reported explicitly; no slave is selected on a miss.
module axi_address_decoder #(
    parameter logic [31:0] S0_BASE  = 32'h0000_0000,
    parameter logic [31:0] S0_LIMIT = 32'h0000_FFFF,
    parameter logic [31:0] S1_BASE  = 32'h0001_0000,
    parameter logic [31:0] S1_LIMIT = 32'h0001_FFFF
) (
    input  logic [31:0] addr,
    output logic [1:0]  slave_sel,
    output logic        decode_valid,
    output logic        decode_error
);
    always_comb begin
        slave_sel    = 2'b00;
        decode_valid = 1'b1;
        decode_error = 1'b0;

        if ((addr >= S0_BASE) && (addr <= S0_LIMIT))
            slave_sel = 2'b01;
        else if ((addr >= S1_BASE) && (addr <= S1_LIMIT))
            slave_sel = 2'b10;
        else begin
            decode_valid = 1'b0;
            decode_error = 1'b1;
        end
    end

    initial begin
        if (S0_BASE > S0_LIMIT) $error("S0_BASE must be <= S0_LIMIT");
        if (S1_BASE > S1_LIMIT) $error("S1_BASE must be <= S1_LIMIT");
        if (!((S0_LIMIT < S1_BASE) || (S1_LIMIT < S0_BASE)))
            $error("Address decoder windows must not overlap");
    end
endmodule
