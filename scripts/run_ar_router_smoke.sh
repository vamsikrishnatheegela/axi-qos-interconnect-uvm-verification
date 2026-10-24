#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/ar_router_smoke
iverilog -g2012 -s axi_ar_router_smoke_tb -o build/ar_router_smoke/simv \
  rtl/rr_arbiter.sv rtl/axi_ar_router_2x2.sv tb/axi_ar_router_smoke_tb.sv
vvp build/ar_router_smoke/simv
