# M.Tech-Thesis
# Multi-Objective Optimization and Control of an Indian-Calibrated BSM1/ASM3 Wastewater Treatment Plant

M.Tech thesis project — Discipline of Chemical Engineering, IIT Gandhinagar.

## Overview

This repository contains the simulation, optimization, and control code for a
BSM1/ASM3 wastewater treatment plant model calibrated to Indian operating
conditions (Anjana WWTP, Surat), rather than the standard European-default
benchmark. The project:

1. Calibrates the ASM3 kinetics and influent characterization to Indian
   conditions (Arrhenius temperature correction, revised influent fractions).
2. Builds a response-surface (RSM) model over aeration rate (KLa) and internal
   recycle flow (Qintr), predicting operating cost (OCI), effluent quality
   (EQI), and compliance metrics (SNH95, TN).
3. Solves a constrained optimization problem to minimize operating cost
   subject to regulatory compliance (SNH95 ≤ 4 mg N/L, TN ≤ 18 mg N/L).
4. Traces the full OCI–EQI Pareto front via epsilon-constraint search and a
   global NSGA-II search (`gamultiobj`), and validates surrogate-predicted
   optima against full nonlinear dynamic BSM1 simulations.
5. Designs and closed-loop tests a Model Predictive Controller (MPC) around
   the chosen operating point.

## Repository structure

```
benchmark/       Official BSM1 Simulink benchmark files (IWA/COST, see Acknowledgments)
init/            Plant initialization scripts (calibrated + default reference)
simulation/      Scripts to run BSM1 to steady state, then dynamic closed loop
optimization/    RSM fitting, constrained optimum, Pareto front (epsilon-constraint + NSGA-II)
mpc/             Step-test linearization and closed-loop MPC design/testing
data/            RSM design points, fitted-model coefficients, Pareto front results
figures/         Exported plots (response surfaces, Pareto front, validation)
docs/            Presentation slides / summary documents
```

## Requirements

- MATLAB (R2021a or later recommended) + Simulink
- Optimization Toolbox (`fmincon`)
- Global Optimization Toolbox (`gamultiobj`, NSGA-II)
- Control System Toolbox (linearization, MPC)
- Statistics and Machine Learning Toolbox (RSM/quadratic model fitting)
- The official BSM1 Simulink benchmark files (`benchmark.mdl`/`benchmarkss.mdl`)
  are included under `benchmark/`, sourced from the IWA/COST Benchmark
  Simulation Models working group; see [Acknowledgments](#acknowledgments).

## How to run

1. Add `benchmark/` to your MATLAB path (contains the official BSM1 `.mdl`/`.slx` files).
2. Run an init script from `init/` to set plant parameters and initial
   conditions (`asm3init_surat.m` for the calibrated model).
3. Run the steady-state → dynamic simulation sequence (`simulation/run_perf_plant.m`),
   then call `perf_plant` to compute OCI/EQI/compliance statistics.
4. To reproduce the RSM grid and fitted surrogate models, run
   `optimization/rsm_fit_models.m` against `data/BSM1_ASM3_Indian_Results.xlsx`.
5. To reproduce the Pareto front, run either
   `optimization/pareto_front_OCI_EQI.m` (epsilon-constraint) or
   `optimization/gamultiobj_OCI_EQI.m` (NSGA-II, recommended — see Results).
6. For the controller design, run `mpc/step_test_linearization.m` followed by
   `mpc/mpc_closed_loop_test.m`.

## Key results

| Operating point | KLa | Qintr (m³/d) | OCI | EQI | Notes |
|---|---|---|---|---|---|
| Baseline (Surat-calibrated) | 300 | 9,223 | 31,523.4 | 2,752.0 | Default fixed-aeration operation |
| EQI-optimal end (Pareto front) | 73.4 | 11,203 | 16,583.6 | 3,032.9 | Validated vs. real dynamic simulation |
| Recommended knee point | 66.3 | 16,695 | 16,110.2 | 3,092.3 | Best OCI/EQI compromise |
| OCI-optimal end (Pareto front) | 59.6 | 25,215 | 15,700.3 | 3,577.2 | SNH95=3.89 — tight compliance margin |

All optimized points reduce operating cost by roughly **47–50%** relative to
the baseline while satisfying SNH95 and TN regulatory limits; the Pareto
front (traced via NSGA-II) was cross-validated against an independent
epsilon-constraint search and against full nonlinear BSM1 simulations
(OCI agreement within 0.1%).

## Acknowledgments

The BSM1/ASM3 benchmark simulation framework (`benchmark/`) was originally
developed by the IWA/COST Benchmark Simulation Models working group (init
file template credited to Xavier Flores-Alsina, IEA, Lund University, 2010)
and is included here as distributed via the official IWA GitHub repository.
All calibration, optimization, and control code built on top of that
framework is original work for this thesis.

## Author

Vedant Dhuri — M.Tech Chemical Engineering, IIT Gandhinagar
Process Modeling, Control, and Optimization Research Group

## License

MIT License (or specify your department's preferred license) — see `LICENSE`.
