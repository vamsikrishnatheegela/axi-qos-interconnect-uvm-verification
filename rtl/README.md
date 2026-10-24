# RTL

Planned synthesizable design files:

- AXI4 interface and shared type/parameter definitions.
- Address decoder and destination selection.
- Read address/response routing.
- Write address/data/response routing.
- Round-robin arbiter.
- QoS-aware arbiter.
- Top-level interconnect.
- Optional skid buffers or response tracking structures, if required by the chosen architecture.

Implementation order:
1. Freeze supported AXI4 subset and parameter values.
2. Add interface/package definitions and compile them.
3. Implement and test decode logic independently.
4. Implement arbitration and channel routing incrementally.
5. Integrate top-level and add assertions.

No synthesizable interconnect implementation is claimed yet. Each module will be added with its interface contract and a corresponding test.
