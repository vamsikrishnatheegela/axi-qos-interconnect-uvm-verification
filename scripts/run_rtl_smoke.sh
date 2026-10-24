#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${ROOT_DIR}/build/rtl_smoke"
mkdir -p "${BUILD_DIR}"

if ! command -v iverilog >/dev/null 2>&1; then
    echo "ERROR: iverilog is not installed or not on PATH." >&2
    exit 127
fi
if ! command -v vvp >/dev/null 2>&1; then
    echo "ERROR: vvp is not installed or not on PATH." >&2
    exit 127
fi

iverilog -g2012 -Wall -s rtl_smoke_tb \
    -o "${BUILD_DIR}/rtl_smoke.vvp" \
    "${ROOT_DIR}/rtl/rr_arbiter.sv" \
    "${ROOT_DIR}/rtl/axi_address_decoder.sv" \
    "${ROOT_DIR}/tb/rtl_smoke_tb.sv"

vvp "${BUILD_DIR}/rtl_smoke.vvp"
