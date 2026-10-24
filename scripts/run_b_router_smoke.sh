#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/b_router_smoke
iverilog -g2012 -s axi_b_router_smoke_tb -o build/b_router_smoke/simv \
  rtl/rr_arbiter.sv rtl/axi_b_router_2x2.sv tb/axi_b_router_smoke_tb.sv
vvp build/b_router_smoke/simv
