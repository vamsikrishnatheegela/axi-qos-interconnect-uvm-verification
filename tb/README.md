# UVM Testbench

Planned structure:

```text
tb/
  pkg/                 Transaction and shared verification types
  agents/
    axi_master_agent/  Master sequencer, driver, monitor
    axi_slave_agent/   Slave model/agent and monitor
  env/                 Environment, virtual sequencer, scoreboard, coverage
  sequences/            Directed and constrained-random sequences
  tests/                UVM test classes
  top/                  Simulation top and interface connections
```

Development rules:
- Monitors reconstruct transactions from accepted VALID/READY handshakes.
- The scoreboard checks completed transactions and response association.
- Drivers obey channel stability requirements under backpressure.
- Randomized traffic is constrained to the supported AXI4 subset.
- Every test documents its intent and expected checks.
- Test results are recorded only after an actual simulator run.

The environment will be built in layers so that each agent and scoreboard can be debugged independently.
