#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/r_router_smoke
iverilog -g2012 -s axi_r_router_smoke_tb -o build/r_router_smoke/simv \
  rtl/rr_arbiter.sv rtl/axi_r_router_2x2.sv tb/axi_r_router_smoke_tb.sv
vvp build/r_router_smoke/simv
