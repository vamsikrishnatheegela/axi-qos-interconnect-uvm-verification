// Parameterized AXI4 interface for the interconnect project.
// This interface exposes standard AXI4 channel signals. It does not
// itself implement routing, buffering, or protocol state.
interface axi4_if #(
    parameter integer ADDR_W = 32,
    parameter integer DATA_W = 32,
    parameter integer ID_W   = 4
) (
    input logic ACLK,
    input logic ARESETn
);
    localparam integer STRB_W = DATA_W / 8;
    localparam integer LEN_W  = 8;
    localparam integer SIZE_W = 3;
    localparam integer BURST_W = 2;
    localparam integer RESP_W = 2;

    // Write address channel
    logic [ID_W-1:0]   AWID;
    logic [ADDR_W-1:0] AWADDR;
    logic [LEN_W-1:0]  AWLEN;
    logic [SIZE_W-1:0] AWSIZE;
    logic [BURST_W-1:0] AWBURST;
    logic              AWVALID;
    logic              AWREADY;
    logic [3:0]        AWCACHE;
    logic [2:0]        AWPROT;
    logic [3:0]        AWQOS;

    // Write data channel
    logic [DATA_W-1:0] WDATA;
    logic [STRB_W-1:0] WSTRB;
    logic              WLAST;
    logic              WVALID;
    logic              WREADY;

    // Write response channel
    logic [ID_W-1:0]   BID;
    logic [RESP_W-1:0] BRESP;
    logic              BVALID;
    logic              BREADY;

    // Read address channel
    logic [ID_W-1:0]   ARID;
    logic [ADDR_W-1:0] ARADDR;
    logic [LEN_W-1:0]  ARLEN;
    logic [SIZE_W-1:0] ARSIZE;
    logic [BURST_W-1:0] ARBURST;
    logic              ARVALID;
    logic              ARREADY;
    logic [3:0]        ARCACHE;
    logic [2:0]        ARPROT;
    logic [3:0]        ARQOS;

    // Read data/response channel
    logic [ID_W-1:0]   RID;
    logic [DATA_W-1:0] RDATA;
    logic [RESP_W-1:0] RRESP;
    logic              RLAST;
    logic              RVALID;
    logic              RREADY;

    // Master-side modport: a master drives requests and accepts responses.
    modport master (
        input ACLK, ARESETn,
        output AWID, AWADDR, AWLEN, AWSIZE, AWBURST, AWVALID,
        output AWCACHE, AWPROT, AWQOS,
        input AWREADY,
        output WDATA, WSTRB, WLAST, WVALID,
        input WREADY,
        input BID, BRESP, BVALID,
        output BREADY,
        output ARID, ARADDR, ARLEN, ARSIZE, ARBURST, ARVALID,
        output ARCACHE, ARPROT, ARQOS,
        input ARREADY,
        input RID, RDATA, RRESP, RLAST, RVALID,
        output RREADY
    );

    // Slave-side modport: a slave accepts requests and returns responses.
    modport slave (
        input ACLK, ARESETn,
        input AWID, AWADDR, AWLEN, AWSIZE, AWBURST, AWVALID,
        input AWCACHE, AWPROT, AWQOS,
        output AWREADY,
        input WDATA, WSTRB, WLAST, WVALID,
        output WREADY,
        output BID, BRESP, BVALID,
        input BREADY,
        input ARID, ARADDR, ARLEN, ARSIZE, ARBURST, ARVALID,
        input ARCACHE, ARPROT, ARQOS,
        output ARREADY,
        output RID, RDATA, RRESP, RLAST, RVALID,
        input RREADY
    );

endinterface
