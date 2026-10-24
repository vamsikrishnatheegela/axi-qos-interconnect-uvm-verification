# Architecture and Design Contract

## 1. Goal

Implement a multi-master, multi-slave AXI4 memory-mapped interconnect and compare round-robin service against QoS-aware arbitration. Correctness and reproducibility take priority over premature optimization.

## 2. Initial topology

- 2 AXI masters: M0 and M1.
- 2 AXI slaves: S0 and S1.
- Independent AXI read path: AR/R.
- Independent AXI write path: AW/W/B.
- Address decoder selects a destination from the accepted address.
- Response routing associates each response with the originating master.

The topology is the first configuration, not a claim that the implementation is already parameterized or complete.

## 3. AXI4 channel contract

AXI4 has five independent channels:

| Channel | Direction | Purpose |
|---|---|---|
| AW | Master to interconnect/slave | Write address and control |
| W | Master to interconnect/slave | Write data, byte strobes, burst-last |
| B | Slave to master | Write response |
| AR | Master to interconnect/slave | Read address and control |
| R | Slave to master | Read data, response, burst-last |

A transfer occurs only on a rising clock edge where VALID and READY are both asserted. A source must hold VALID and payload stable while VALID=1 and READY=0. Channel independence must be preserved; AW and W may arrive in different cycles.

## 4. Design decisions to freeze before RTL

The following choices must be recorded in RTL parameters or a specification before integration:

- Clock/reset polarity and reset behavior.
- Address width, data width, ID width, and maximum burst length.
- Supported burst types and alignment rules.
- Address windows for S0 and S1, including unmapped-address behavior.
- Maximum outstanding reads and writes per master and per slave.
- Ordering guarantees and ID preservation/remapping policy.
- Write address/data association and handling of independent AW/W arrival.
- Arbitration granularity: transaction-level or beat-level, with AXI4 burst rules respected.
- QoS input interpretation, priority encoding, tie-breaking, and starvation policy.
- Backpressure buffering and any timing isolation/skid buffers.
- Error response behavior for invalid addresses.
- Reset treatment for in-flight transactions.

Do not silently assume that an AXI4 transaction may be arbitrated beat-by-beat between different masters. Once a burst is granted to a destination, the design must preserve the required burst integrity and ownership.

## 5. Address map (proposed initial map)

Use parameterized, non-overlapping address windows. Proposed defaults for a 32-bit address:

- S0: 0x0000_0000–0x0000_FFFF
- S1: 0x0001_0000–0x0001_FFFF
- Other addresses: decode error / defined error response

These defaults must be implemented and tested; they are not yet validated RTL behavior.

## 6. Arbitration policies

### Round-robin baseline
- Select among eligible requesters in rotating order.
- Advance the round-robin pointer according to the documented grant/acceptance event.
- Preserve a grant while required by the channel protocol and burst ownership.
- Define behavior when a selected requester withdraws a request before acceptance.

### QoS-aware policy
- Use the configured AXI QoS field and/or programmable requester priority.
- Specify whether arbitration is strict priority, weighted service, or priority plus aging.
- Define tie-breaking and when priority is sampled.
- Test continuous high-priority traffic against low-priority traffic.
- If bounded starvation is a requirement, implement and verify a mechanism that supports the stated bound; do not infer it from priority arbitration alone.

## 7. Forward progress and deadlock analysis

Progress claims require assumptions. For example, a test may assume every selected slave eventually asserts READY and eventually returns a response. Under those assumptions, properties can check that accepted transactions complete within a chosen bound. Separate tests must intentionally hold READY low to verify stable VALID/payload behavior and recovery after backpressure is released.

Potential internal hazards include circular resource dependencies, lost grants, response misrouting, unmatched AW/W state, and blocked response paths. Each must have a corresponding test or assertion where practical.

## 8. Performance measurement definitions

- **Request latency:** cycles from address-channel handshake to final response handshake. Report read and write latency separately.
- **End-to-end latency:** cycles from address acceptance to final R beat or B response acceptance.
- **Throughput:** completed payload bytes per cycle and transactions per cycle; state which is reported.
- **Maximum observed latency:** maximum in the finite measured run, not automatically a formal worst-case bound.
- **Fairness:** per-master service counts and a documented metric, such as Jain's fairness index, over a defined contention window.
- **Starvation:** no service while continuously eligible, evaluated against the policy's explicit assumptions and bound.

## 9. Definition of done

The design is complete only when the supported AXI subset is documented, compile/simulation commands are reproducible, directed and randomized tests pass, key assertions and coverage are exercised, and measured policy comparisons can be reproduced from saved configuration and seed information.
