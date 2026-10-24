# Architecture and Design Contract

## 1. Goal

Implement a 2-master × 2-slave AXI4 memory-mapped interconnect, then compare round-robin arbitration with a QoS-aware policy using reproducible tests and measurements.

## 2. Topology and channel paths

- Masters: M0 and M1.
- Slaves: S0 and S1.
- Read path: AR request routing and R response routing.
- Write path: AW request routing, W data routing, and B response routing.
- The address map selects the destination; the master-tag bit in downstream IDs associates responses with the originating master.

## 3. AXI4 channel contract

AXI4 has five independent channels:

| Channel | Direction | Purpose |
|---|---|---|
| AW | Master to interconnect/slave | Write address and control |
| W | Master to interconnect/slave | Write data, byte strobes, burst-last |
| B | Slave to master | Write response |
| AR | Master to interconnect/slave | Read address and control |
| R | Slave to master | Read data, response, burst-last |

A transfer occurs on a rising clock edge when VALID and READY are both asserted. A source must hold VALID and payload stable while VALID=1 and READY=0. AW and W may arrive in different cycles; the interconnect must not assume they handshake together.

## 4. Current RTL scope

The repository contains independently smoke-tested decoder/arbitration and AR, R, AW, W, and B routers, plus an integrated `axi_interconnect_2x2` module. The integrated smoke test is intended to check mapped, single-beat read and write transactions and ID tag/restore across the complete paths. Local simulation results must be recorded only after the user runs the supplied script.

### Write outstanding policy

The initial W router supports **one outstanding write burst per master**:
- `m_aw_block` gates new AW requests for a master until its accepted WLAST.
- The W router records the destination on the accepted AW handshake.
- W is not forwarded until the corresponding AW has been accepted.
- Ownership remains fixed from the first routed W beat through an accepted WLAST.
- The W router has no internal W-data FIFO and assumes compliant masters hold WVALID and payload stable during stalls.

A FIFO-based AW/W association mechanism is required before supporting multiple outstanding write bursts per master.

### ID mapping

Master-side IDs are `ID_W` bits. Address routers prepend the originating master bit, creating a downstream `ID_W+1`-bit ID. Response routers use the extra tag bit to route the response and return the original `ID_W`-bit ID to the master. The system-level contract assumes slaves preserve the downstream ID in their response.

### Decode misses

The address routers flag unmapped addresses and do not accept them. The integrated top-level exposes `m_aw_decode_error` and `m_ar_decode_error`, but does not yet generate a complete AXI DECERR response. Tests should currently use mapped addresses unless testing this limitation explicitly.

## 5. Address map

Default 32-bit windows:
- S0: 0x0000_0000–0x0000_FFFF
- S1: 0x0001_0000–0x0001_FFFF
- Other addresses: flagged decode error; DECERR response generation remains future work.

## 6. Arbitration

### Round-robin baseline
- Select among eligible requesters in rotating order.
- Advance priority on the documented acceptance event.
- Preserve selected ownership where required by channel backpressure or burst integrity.

### Planned QoS-aware policy
- Define whether arbitration is strict priority, weighted service, or priority plus aging.
- Specify how AXI QoS is sampled and how ties are broken.
- Test persistent high-priority traffic against low-priority traffic.
- Do not claim bounded starvation without a mechanism and a testable bound.

## 7. Forward progress and deadlock analysis

Progress claims require environmental assumptions. For example, assume selected slaves eventually assert READY and return responses. Test both persistent backpressure and recovery after READY is released. Check for lost grants, response misrouting, unmatched AW/W state, and blocked response paths.

## 8. Performance definitions

- **Request latency:** cycles from address-channel handshake to final response handshake.
- **End-to-end latency:** cycles from address acceptance to final R beat or B response acceptance.
- **Throughput:** completed payload bytes per cycle and/or transactions per cycle.
- **Maximum observed latency:** maximum in a finite measured run, not automatically a formal worst-case bound.
- **Fairness:** per-master service counts and a documented metric over a defined contention window.
- **Starvation:** no service while continuously eligible, evaluated under explicit assumptions and policy bounds.

## 9. Remaining work

1. Run and debug the integrated smoke test in the target simulator.
2. Add multi-beat end-to-end tests, concurrent master traffic, response backpressure, and reset cases.
3. Add defined DECERR responses for unmapped addresses.
4. Add protocol assertions and randomized testing.
5. Implement QoS-aware arbitration and compare it with the round-robin baseline.
6. Add UVM agents, scoreboard, functional coverage, and reproducible performance measurements.

Passing directed smoke tests is useful evidence, but is not equivalent to full AXI4 protocol compliance.
