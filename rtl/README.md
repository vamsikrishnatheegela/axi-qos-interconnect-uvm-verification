# RTL

## Implemented building blocks

- `axi4_if.sv`: parameterized AXI4 channel interface.
- `rr_arbiter.sv`: round-robin arbiter.
- `axi_address_decoder.sv`: two-window address decoder.
- `axi_ar_router_2x2.sv`: read-address routing with arbitration and ID tagging.
- `axi_r_router_2x2.sv`: read-response routing, ID restoration, and burst ownership.
- `axi_aw_router_2x2.sv`: write-address routing with arbitration and ID tagging.
- `axi_w_router_2x2.sv`: write-data routing with destination tracking, backpressure, and WLAST-based burst ownership.
- `axi_b_router_2x2.sv`: write-response routing and ID restoration.
- `axi_interconnect_2x2.sv`: integrated 2-master × 2-slave routing fabric for AW/W/B and AR/R.

## Current integration contract and limitations

The integrated W path supports **one outstanding write burst per master**. The top-level gates AW requests while that master has an accepted AW whose W burst has not completed. The W router captures the destination on the AW handshake, waits for that acceptance before forwarding W, and releases the slot on an accepted WLAST. W payload is not buffered internally.

Downstream IDs have one extra master-tag bit. The response routers use that tag to return B/R responses to the correct master and strip the tag before exposing the original ID.

Unmapped AW/AR requests are exposed through decode-error outputs and are not accepted by the address routers. A complete AXI DECERR response path is not yet implemented. The integrated smoke test exercises mapped, single-beat transactions; it does not prove full AXI4 compliance or multi-beat end-to-end behavior.

## Directed tests

Run from the repository root:

```bash
bash scripts/run_rtl_smoke.sh
bash scripts/run_ar_router_smoke.sh
bash scripts/run_r_router_smoke.sh
bash scripts/run_aw_router_smoke.sh
bash scripts/run_w_router_smoke.sh
bash scripts/run_b_router_smoke.sh
bash scripts/run_interconnect_smoke.sh
```

These are directed smoke tests. Passing them does not establish complete AXI4 compliance.
