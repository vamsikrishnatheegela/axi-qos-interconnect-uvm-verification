# Verification Plan

## 1. Verification goals

Demonstrate protocol-compliant routing, transaction integrity, response association, arbitration behavior, backpressure safety, reset behavior, and forward progress under documented assumptions. Compare policies using identical traffic conditions.

## 2. UVM environment (planned)

- **AXI transaction:** address, ID, burst length/type, size, QoS, write payload/strobes, expected response metadata.
- **Master agent:** sequencer, driver, monitor; active mode for traffic generation and passive mode for observation.
- **Slave agent/model:** programmable READY behavior, memory model, response delay, response generation, and error injection where supported.
- **Virtual sequencer/sequences:** coordinate both masters and create contention across both slaves.
- **Scoreboard/reference model:** predict target decode, accepted transaction state, returned IDs/data/response, and completion accounting.
- **Coverage collector:** sample transaction attributes and contention/latency scenarios from monitored handshakes.
- **Assertions:** VALID/payload stability, legal response/last behavior, ownership consistency, and bounded progress under explicit assumptions.
- **Regression runner:** execute tests with recorded seeds and summarize pass/fail and coverage.

## 3. Directed test matrix

| ID | Scenario | Key checks |
|---|---|---|
| D01 | Single read from each master to S0 | Address routing, ID and data association |
| D02 | Single read from each master to S1 | Address routing, response routing |
| D03 | Single write to each slave | AW/W/B coordination and response |
| D04 | Concurrent read requests | Arbitration and read-path integrity |
| D05 | Concurrent write requests | Arbitration and write-path integrity |
| D06 | Simultaneous read and write | Independence of read/write paths where resources permit |
| D07 | AW before W and W before AW | Independent write-channel timing |
| D08 | Slave stalls AR/AW/W | VALID and payload stability; recovery |
| D09 | Master stalls R/B | Response stability and no premature loss |
| D10 | Different QoS values | Documented selection policy |
| D11 | Equal QoS contention | Deterministic tie-breaking / rotation |
| D12 | Continuous high QoS vs low QoS | Starvation behavior and policy-specific expectations |
| D13 | Burst reads/writes | Beat count, RLAST, WLAST, IDs and data integrity |
| D14 | Unmapped address | Defined error response and no wrong-slave access |
| D15 | Reset while idle | Reset state and clean first transaction |
| D16 | Reset with activity | Documented in-flight transaction/reset contract |
| D17 | Long randomized traffic | Scoreboard consistency and progress |
| D18 | Backpressure release after prolonged stall | Correct recovery without duplicate/lost transfers |

Test IDs will be updated as the supported feature set is frozen. A test is not complete merely because it compiles; it must have meaningful checks and a recorded result.

## 4. Assertions (planned)

At minimum, assertions or equivalent monitor checks should cover:

- Master and slave source stability while VALID && !READY.
- No response without a corresponding accepted request, subject to defined reset behavior.
- Correct destination and response ownership.
- Correct burst termination and beat accounting.
- No acceptance of two conflicting grants for one exclusive resource.
- Eventual completion only under explicit environmental assumptions.
- Bounded arbitration service only where the policy and assumptions mathematically support a bound.

Assertions must avoid false assumptions about AXI's independent channels and legal backpressure.

## 5. Functional coverage plan

Cover at least:

- Master index × slave index × read/write operation.
- QoS values or priority classes × winning requester.
- Arbitration tie vs non-tie.
- Contention level (one vs multiple eligible masters).
- Burst length and burst type supported by the implementation.
- Response codes supported by the implementation.
- Backpressure location and duration class.
- AW-before-W / W-before-AW ordering.
- Concurrent read/write activity.
- Reset phase (idle / active), according to the reset contract.
- Latency bins and service counts under contention.

Cross coverage should be targeted to meaningful combinations to avoid an unmanageable Cartesian explosion. Coverage goals will be set after the supported feature set is finalized.

## 6. Randomized and stress testing

Randomize addresses, IDs, burst properties, QoS, request gaps, response delays, and READY stalls within legal constraints. Use fixed seeds for reproducibility. Run multiple seeds after directed tests pass. Ensure the scoreboard and coverage sample accepted handshakes rather than merely generated requests.

## 7. Performance experiment methodology

For each arbitration policy:
1. Use the same test configuration and seed set.
2. Warm up or define a clear measurement window.
3. Collect per-transaction read/write latency.
4. Collect completed transactions and payload bytes per cycle.
5. Record per-master service counts and fairness metric.
6. Report mean, percentile, and maximum observed latency where sample size permits.
7. Report all relevant environmental assumptions, including slave response delay and backpressure model.
8. Save simulator version, UVM version, seed, test name, and configuration with results.

## 8. Exit criteria

- No unexplained compile/elaboration errors.
- All required directed tests pass.
- Scoreboard reports zero unexplained mismatches.
- Assertions have no unexplained failures.
- Randomized regression completes for documented seeds.
- Coverage gaps are reviewed and either closed or explicitly justified.
- Performance reports are generated from actual logs, not manually invented values.
