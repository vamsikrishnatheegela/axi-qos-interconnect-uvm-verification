# AXI QoS Interconnect with UVM Verification

A staged RTL and verification project for a 2-master × 2-slave AXI4 memory-mapped interconnect, with a planned comparison between round-robin and QoS-aware arbitration.

> **Current status:** Channel router RTL and an integrated top-level have been added. Six channel/decoder smoke tests have passed in the user's local environment. The integrated end-to-end smoke test has been added but must still be run locally. No QoS, UVM, or performance result is claimed.

## Objectives

- Route independent AXI4 AW/W/B and AR/R channels.
- Preserve master identity through tagged downstream transaction IDs.
- Handle VALID/READY backpressure and maintain write-burst ownership.
- Define decode-error behavior, outstanding limits, and supported protocol subset.
- Add UVM verification, assertions, coverage, and reproducible latency/throughput/fairness analysis.
- Compare round-robin against a documented QoS-aware policy.

## Current implementation

- 2 masters × 2 slaves.
- Default S0 address window: `0x0000_0000–0x0000_FFFF`.
- Default S1 address window: `0x0001_0000–0x0001_FFFF`.
- Downstream IDs contain one extra master-tag bit; response routing strips it.
- One outstanding write burst per master, enforced by the integrated top-level.
- Unmapped addresses are flagged and not accepted; a full DECERR response path remains future work.
- Full multi-beat end-to-end verification, randomized tests, QoS arbitration, and UVM are not yet complete.

## Run the directed tests

From the repository root:

```bash
bash scripts/run_rtl_smoke.sh
bash scripts/run_ar_router_smoke.sh
bash scripts/run_r_router_smoke.sh
bash scripts/run_aw_router_smoke.sh
bash scripts/run_w_router_smoke.sh
bash scripts/run_b_router_smoke.sh
bash scripts/run_interconnect_smoke.sh
```

The first six smoke tests have passed locally. Run the final integration test before recording an integrated result.

## Repository map

```text
rtl/          RTL modules and AXI4 interface
tb/           Directed smoke tests; UVM environment is planned
assertions/   Protocol and forward-progress properties (planned)
docs/         Architecture, verification plan, toolchain notes
scripts/      Reproducible compile/run scripts
results/      Measured logs/reports; do not invent or estimate results
```

## Verification and results policy

Only record results after a reproducible simulation run. A passing smoke test covers selected scenarios and does not establish full AXI4 compliance.

| Policy | Tests passed | Functional coverage | Mean latency | Max observed latency | Throughput | Fairness |
|---|---:|---:|---:|---:|---:|---:|
| Round-robin | TBD | TBD | TBD | TBD | TBD | TBD |
| QoS-aware | TBD | TBD | TBD | TBD | TBD | TBD |

## Documentation

- [Architecture and design contract](docs/architecture.md)
- [Verification plan](docs/verification_plan.md)
- [Toolchain notes](docs/toolchain.md)
- [RTL status](rtl/README.md)
- [UVM testbench status](tb/README.md)

## License

MIT. See `LICENSE`.
