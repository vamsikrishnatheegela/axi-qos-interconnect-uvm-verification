# Toolchain Notes

This file records the real environment used to compile and run the project.

## Record before implementation

Fill these fields after inspecting the machine:

- OS/distribution:
- Simulator and version:
- SystemVerilog support:
- UVM version and library path:
- Available license/features:
- Waveform viewer:
- Build/run command:
- Date verified:

## Simulator compatibility

The testbench will use SystemVerilog and UVM. Simulator support varies by version and license, so no simulator is assumed to be available until checked locally. Some simulators may support RTL compilation but lack a UVM-capable licensed configuration.

Potential simulator paths include Questa/ModelSim with an appropriate UVM-capable license, or another simulator with suitable SystemVerilog/UVM support. Open-source simulators may be useful for parts of the RTL but should not be assumed to support a complete UVM environment.

## Reproducibility

For each regression run, preserve:
- simulator version and relevant compile options;
- UVM version;
- test name and random seed;
- parameter/configuration values;
- command used;
- exit status;
- summary log and coverage report, if supported.

Do not publish license keys, license server credentials, or other secrets in this repository.
