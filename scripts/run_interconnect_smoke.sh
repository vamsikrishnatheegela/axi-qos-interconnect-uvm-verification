#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/interconnect_smoke
iverilog -g2012 -s axi_interconnect_2x2_smoke_tb \
  -o build/interconnect_smoke/simv \
  rtl/rr_arbiter.sv \
  rtl/axi_address_decoder.sv \
  rtl/axi_ar_router_2x2.sv \
  rtl/axi_r_router_2x2.sv \
  rtl/axi_aw_router_2x2.sv \
  rtl/axi_w_router_2x2.sv \
  rtl/axi_b_router_2x2.sv \
  rtl/axi_interconnect_2x2.sv \
  tb/axi_interconnect_2x2_smoke_tb.sv
vvp build/interconnect_smoke/simv
