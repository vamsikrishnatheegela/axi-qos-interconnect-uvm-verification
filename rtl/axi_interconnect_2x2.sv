// Integrated 2-master x 2-slave AXI4 routing fabric.
// This first integration supports mapped addresses only. Decode misses are
// exposed and left unaccepted; a dedicated AXI SLVERR/DECERR responder is
// still required for a complete system. Downstream IDs carry one master tag
// bit above the original ID. The W path limits each master to one outstanding
// write burst until an accepted WLAST.
module axi_interconnect_2x2 #(
    parameter integer ADDR_W = 32,
    parameter integer DATA_W = 32,
    parameter integer ID_W = 4,
    parameter integer LEN_W = 8,
    parameter integer SIZE_W = 3,
    parameter integer BURST_W = 2,
    parameter integer STRB_W = DATA_W / 8,
    parameter integer BASE0 = 0,
    parameter integer LIMIT0 = 65535,
    parameter integer BASE1 = 65536,
    parameter integer LIMIT1 = 131071
) (
    input logic clk,
    input logic rst_n,

    // Master-side AW
    input logic [1:0] m_awvalid,
    output logic [1:0] m_awready,
    input logic [1:0][ID_W-1:0] m_awid,
    input logic [1:0][ADDR_W-1:0] m_awaddr,
    input logic [1:0][LEN_W-1:0] m_awlen,
    input logic [1:0][SIZE_W-1:0] m_awsize,
    input logic [1:0][BURST_W-1:0] m_awburst,
    input logic [1:0][3:0] m_awcache,
    input logic [1:0][2:0] m_awprot,
    input logic [1:0][3:0] m_awqos,

    // Master-side W
    input logic [1:0] m_wvalid,
    output logic [1:0] m_wready,
    input logic [1:0][DATA_W-1:0] m_wdata,
    input logic [1:0][STRB_W-1:0] m_wstrb,
    input logic [1:0] m_wlast,

    // Master-side B
    output logic [1:0] m_bvalid,
    input logic [1:0] m_bready,
    output logic [1:0][ID_W-1:0] m_bid,
    output logic [1:0][1:0] m_bresp,

    // Master-side AR
    input logic [1:0] m_arvalid,
    output logic [1:0] m_arready,
    input logic [1:0][ID_W-1:0] m_arid,
    input logic [1:0][ADDR_W-1:0] m_araddr,
    input logic [1:0][LEN_W-1:0] m_arlen,
    input logic [1:0][SIZE_W-1:0] m_arsize,
    input logic [1:0][BURST_W-1:0] m_arburst,
    input logic [1:0][3:0] m_arcache,
    input logic [1:0][2:0] m_arprot,
    input logic [1:0][3:0] m_arqos,

    // Master-side R
    output logic [1:0] m_rvalid,
    input logic [1:0] m_rready,
    output logic [1:0][ID_W-1:0] m_rid,
    output logic [1:0][DATA_W-1:0] m_rdata,
    output logic [1:0][1:0] m_rresp,
    output logic [1:0] m_rlast,

    // Slave-side AW
    output logic [1:0] s_awvalid,
    input logic [1:0] s_awready,
    output logic [1:0][ID_W:0] s_awid,
    output logic [1:0][ADDR_W-1:0] s_awaddr,
    output logic [1:0][LEN_W-1:0] s_awlen,
    output logic [1:0][SIZE_W-1:0] s_awsize,
    output logic [1:0][BURST_W-1:0] s_awburst,
    output logic [1:0][3:0] s_awcache,
    output logic [1:0][2:0] s_awprot,
    output logic [1:0][3:0] s_awqos,

    // Slave-side W
    output logic [1:0] s_wvalid,
    input logic [1:0] s_wready,
    output logic [1:0][DATA_W-1:0] s_wdata,
    output logic [1:0][STRB_W-1:0] s_wstrb,
    output logic [1:0] s_wlast,

    // Slave-side B
    input logic [1:0] s_bvalid,
    output logic [1:0] s_bready,
    input logic [1:0][ID_W:0] s_bid,
    input logic [1:0][1:0] s_bresp,

    // Slave-side AR
    output logic [1:0] s_arvalid,
    input logic [1:0] s_arready,
    output logic [1:0][ID_W:0] s_arid,
    output logic [1:0][ADDR_W-1:0] s_araddr,
    output logic [1:0][LEN_W-1:0] s_arlen,
    output logic [1:0][SIZE_W-1:0] s_arsize,
    output logic [1:0][BURST_W-1:0] s_arburst,
    output logic [1:0][3:0] s_arcache,
    output logic [1:0][2:0] s_arprot,
    output logic [1:0][3:0] s_arqos,

    // Slave-side R
    input logic [1:0] s_rvalid,
    output logic [1:0] s_rready,
    input logic [1:0][ID_W:0] s_rid,
    input logic [1:0][DATA_W-1:0] s_rdata,
    input logic [1:0][1:0] s_rresp,
    input logic [1:0] s_rlast,

    // High while a master has an accepted AW whose W burst is incomplete.
    output logic [1:0] m_aw_block,
    output logic [1:0] m_aw_decode_error,
    output logic [1:0] m_ar_decode_error
);
    logic [1:0] aw_route_valid;
    logic [1:0] aw_route_ready;
    logic [1:0] m_aw_fire;

    // Enforce the W router's one-outstanding-write-per-master contract.
    always @* begin
        aw_route_valid = m_awvalid & ~m_aw_block;
        m_awready = aw_route_ready & ~m_aw_block;
        m_aw_fire = m_awvalid & m_awready;
    end

    axi_aw_router_2x2 #(
        .ADDR_W(ADDR_W), .ID_W(ID_W), .LEN_W(LEN_W),
        .SIZE_W(SIZE_W), .BURST_W(BURST_W),
        .BASE0(BASE0), .LIMIT0(LIMIT0), .BASE1(BASE1), .LIMIT1(LIMIT1)
    ) u_aw (
        .clk(clk), .rst_n(rst_n),
        .m_awvalid(aw_route_valid), .m_awready(aw_route_ready),
        .m_awid(m_awid), .m_awaddr(m_awaddr), .m_awlen(m_awlen),
        .m_awsize(m_awsize), .m_awburst(m_awburst), .m_awcache(m_awcache),
        .m_awprot(m_awprot), .m_awqos(m_awqos),
        .s_awvalid(s_awvalid), .s_awready(s_awready), .s_awid(s_awid),
        .s_awaddr(s_awaddr), .s_awlen(s_awlen), .s_awsize(s_awsize),
        .s_awburst(s_awburst), .s_awcache(s_awcache), .s_awprot(s_awprot),
        .s_awqos(s_awqos), .decode_error(m_aw_decode_error)
    );

    axi_w_router_2x2 #(
        .ADDR_W(ADDR_W), .DATA_W(DATA_W), .STRB_W(STRB_W),
        .BASE0(BASE0), .LIMIT0(LIMIT0), .BASE1(BASE1), .LIMIT1(LIMIT1)
    ) u_w (
        .clk(clk), .rst_n(rst_n),
        .m_aw_fire(m_aw_fire), .m_awaddr(m_awaddr), .m_aw_block(m_aw_block),
        .m_wvalid(m_wvalid), .m_wready(m_wready), .m_wdata(m_wdata),
        .m_wstrb(m_wstrb), .m_wlast(m_wlast),
        .s_wvalid(s_wvalid), .s_wready(s_wready), .s_wdata(s_wdata),
        .s_wstrb(s_wstrb), .s_wlast(s_wlast)
    );

    axi_b_router_2x2 #(.ID_W(ID_W)) u_b (
        .clk(clk), .rst_n(rst_n),
        .s_bvalid(s_bvalid), .s_bready(s_bready), .s_bid(s_bid),
        .s_bresp(s_bresp), .m_bvalid(m_bvalid), .m_bready(m_bready),
        .m_bid(m_bid), .m_bresp(m_bresp)
    );

    axi_ar_router_2x2 #(
        .ADDR_W(ADDR_W), .ID_W(ID_W), .LEN_W(LEN_W),
        .SIZE_W(SIZE_W), .BURST_W(BURST_W),
        .BASE0(BASE0), .LIMIT0(LIMIT0), .BASE1(BASE1), .LIMIT1(LIMIT1)
    ) u_ar (
        .clk(clk), .rst_n(rst_n),
        .m_arvalid(m_arvalid), .m_arready(m_arready), .m_arid(m_arid),
        .m_araddr(m_araddr), .m_arlen(m_arlen), .m_arsize(m_arsize),
        .m_arburst(m_arburst), .m_arcache(m_arcache), .m_arprot(m_arprot),
        .m_arqos(m_arqos), .s_arvalid(s_arvalid), .s_arready(s_arready),
        .s_arid(s_arid), .s_araddr(s_araddr), .s_arlen(s_arlen),
        .s_arsize(s_arsize), .s_arburst(s_arburst), .s_arcache(s_arcache),
        .s_arprot(s_arprot), .s_arqos(s_arqos), .decode_error(m_ar_decode_error)
    );

    axi_r_router_2x2 #(.ID_W(ID_W), .DATA_W(DATA_W)) u_r (
        .clk(clk), .rst_n(rst_n),
        .s_rvalid(s_rvalid), .s_rready(s_rready), .s_rid(s_rid),
        .s_rdata(s_rdata), .s_rresp(s_rresp), .s_rlast(s_rlast),
        .m_rvalid(m_rvalid), .m_rready(m_rready), .m_rid(m_rid),
        .m_rdata(m_rdata), .m_rresp(m_rresp), .m_rlast(m_rlast)
    );
endmodule
