# RTL

## Implemented building blocks

- `axi4_if.sv`: parameterized AXI4 channel interface.
- `rr_arbiter.sv`: round-robin arbiter; pointer advances on the configured acceptance event.
- `axi_address_decoder.sv`: two-window address decoder.
- `axi_ar_router_2x2.sv`: read-address routing with arbitration and ID tagging.
- `axi_r_router_2x2.sv`: read-response routing, ID restoration, and burst ownership.
- `axi_aw_router_2x2.sv`: write-address routing with arbitration and ID tagging.
- `axi_w_router_2x2.sv`: write-data routing with destination tracking, backpressure, and WLAST-based burst ownership.
- `axi_b_router_2x2.sv`: write-response routing and ID restoration.

## W-router contract and current limitation

The first W-router version supports **one outstanding write burst per master**. It records the destination when the corresponding AW handshake is reported via `m_aw_fire`, and blocks a new AW while that burst is active through `m_aw_block`. The top-level integration must use `m_aw_block` to suppress AWVALID, and drive `m_aw_fire` from the actual AW handshake. W data is not forwarded before the AW handshake. Once a W burst starts, ownership remains fixed until an accepted WLAST. There is no internal W-data FIFO.

The router blocks are not yet a complete integrated interconnect. Decode-error response generation, top-level wiring, end-to-end transaction testing, QoS arbitration, and UVM verification remain to be implemented.

## Directed smoke tests

Run individual module tests from the repository root:

```bash
bash scripts/run_rtl_smoke.sh
bash scripts/run_ar_router_smoke.sh
bash scripts/run_r_router_smoke.sh
bash scripts/run_aw_router_smoke.sh
bash scripts/run_w_router_smoke.sh
bash scripts/run_b_router_smoke.sh
```

These tests cover selected directed cases only; passing them does not establish full AXI4 compliance.

