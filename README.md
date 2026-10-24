# AXI QoS Interconnect with UVM Verification

Design and UVM-based verification of a multi-master, multi-slave AXI4 interconnect featuring QoS-aware arbitration, configurable priorities, independent read/write routing, backpressure handling, fairness analysis, and latency/throughput benchmarking.

> **Project status:** Planning and repository setup. RTL and UVM components will be added and validated incrementally. No test or performance result is claimed until it has been run and recorded.

## Objectives

- Build a parameterized **2-master × 2-slave AXI4** interconnect as the initial configuration.
- Implement address decoding, read/write channel routing, response routing, and legal handling of AXI VALID/READY backpressure.
- Compare round-robin arbitration with a configurable QoS-aware policy.
- Develop a reusable SystemVerilog/UVM environment with agents, sequences, monitors, assertions, a reference model, scoreboard, and functional coverage.
- Measure latency, throughput, fairness, and forward progress using reproducible workloads.
- Document design decisions, simulator commands, test outcomes, limitations, and results.

## Initial scope and assumptions

- Protocol target: **AXI4 memory-mapped**, not AXI-Lite and not AXI3.
- Initial topology: 2 masters and 2 slaves; parameters should permit future scaling.
- Independent read and write channel paths, subject to resource conflicts and the chosen outstanding-transaction policy.
- The initial implementation will explicitly define supported burst types, data/address widths, ID widths, address map, maximum outstanding transactions, and error response behavior.
- QoS policy must define tie-breaking and starvation behavior; priority alone is not a fairness guarantee.
- Deadlock checks will state environmental assumptions. A slave that holds READY low forever can prevent progress and must not be misreported as an internal deadlock.

## Repository map

```text
rtl/                  Synthesizable RTL and packages
tb/                   SystemVerilog/UVM testbench
  agents/              AXI master/slave agents
  env/                 Environment, virtual sequencer, scoreboard
  sequences/            Directed and constrained-random sequences
  tests/                UVM tests
assertions/            Protocol and forward-progress properties
docs/                  Architecture, verification plan, results
scripts/               Reproducible compile/run/regression helpers
results/               Generated logs and reports (not committed by default)
```

## Planned milestones

1. Freeze interface, address map, and supported AXI subset.
2. Compile interface/package skeleton with the selected simulator.
3. Implement and unit-test address decode and channel routing.
4. Add round-robin arbitration and baseline directed tests.
5. Add QoS arbitration and policy-specific tests.
6. Build UVM agents, sequences, monitors, scoreboard, and assertions.
7. Add coverage closure and stress tests for backpressure, bursts, IDs, and reset.
8. Add performance instrumentation and compare policies using the same traffic seeds.
9. Publish validated results, waveforms, and known limitations.

## Toolchain

The exact simulator and UVM version will be recorded in [Toolchain Notes](docs/toolchain.md). Simulator compatibility is not assumed: compile commands and supported language features will be chosen after checking the available installation.

## Documentation

- [Architecture and design contract](docs/architecture.md)
- [Verification plan](docs/verification_plan.md)
- [Toolchain notes](docs/toolchain.md)
- [RTL status](rtl/README.md)
- [UVM testbench status](tb/README.md)

## Results policy

Only measured results from reproducible runs belong in the results table. Until implementation and simulations are complete, metrics are **TBD** rather than estimated or invented.

| Policy | Tests passed | Functional coverage | Mean latency | Max observed latency | Throughput | Fairness |
|---|---:|---:|---:|---:|---:|---:|
| Round-robin | TBD | TBD | TBD | TBD | TBD | TBD |
| QoS-aware | TBD | TBD | TBD | TBD | TBD | TBD |

## License

MIT. See [LICENSE](LICENSE).
