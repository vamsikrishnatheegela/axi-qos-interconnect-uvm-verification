# Scripts

This directory will contain reproducible compile, test, regression, and report-generation scripts once the simulator/toolchain is confirmed.

Scripts should:
- fail on compile or test errors;
- preserve simulator exit status;
- record test names and random seeds;
- write generated files under a build/results directory;
- avoid hard-coded local absolute paths;
- never include simulator credentials or license secrets.
