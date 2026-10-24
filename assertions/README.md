# Assertions

Assertions will be added alongside the relevant interface and RTL. Initial targets:

- VALID and payload remain stable while stalled.
- Response ownership matches accepted requests.
- Burst beat accounting and last-beat behavior are consistent.
- Arbitration grants are mutually exclusive where resources are shared.
- Forward-progress properties are bounded and enabled only under explicit fairness and slave-response assumptions.

Assertions must account for reset and AXI channel independence. Avoid assuming a slave must respond while the environment intentionally holds it stalled.
