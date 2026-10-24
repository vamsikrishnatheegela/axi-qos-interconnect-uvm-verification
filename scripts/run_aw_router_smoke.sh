#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/aw_router_smoke
iverilog -g2012 -s axi_aw_router_smoke_tb -o build/aw_router_smoke/simv \
  rtl/rr_arbiter.sv rtl/axi_aw_router_2x2.sv tb/axi_aw_router_smoke_tb.sv
vvp build/aw_router_smoke/simv
