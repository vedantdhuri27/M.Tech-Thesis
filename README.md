# M.Tech-Thesis
# Multi-Objective Optimization and Control of an Indian-Calibrated BSM1/ASM3 Wastewater Treatment Plant

M.Tech thesis project — Discipline of Chemical Engineering, IIT Gandhinagar.

## Problem Statement

Wastewater treatment plants (WWTPs) must simultaneously satisfy regulatory
effluent-quality limits and minimize operating cost (aeration energy, pumping
energy, sludge handling). The standard BSM1/ASM3 benchmark — the widely used
reference model for evaluating WWTP control strategies — is parameterized
for European influent characteristics, kinetics, and temperature ranges.
Operating strategies (aeration rate, internal recycle flow, etc.) optimized
on this default benchmark are not guaranteed to be valid, optimal, or even
compliant for a real Indian WWTP, whose influent strength, temperature, and
hydraulic conditions differ substantially. This project calibrates the
benchmark to an actual Indian plant (Anjana WWTP, Surat) and re-examines the
cost–quality trade-off and controller design under those conditions.

## Objective

1. Calibrate the ASM3 kinetics and influent characterization to Indian
   operating conditions (Arrhenius temperature correction, revised influent
   fractions), rather than relying on the European-default benchmark.
2. Quantify the trade-off between operating cost (OCI) and effluent quality
   (EQI) as a function of aeration rate (KLa) and internal recycle flow
   (Qintr) using a response-surface (RSM) design.
3. Find the cost-minimizing operating point subject to regulatory compliance
   (SNH95 ≤ 4 mg N/L, TN ≤ 18 mg N/L).
4. Trace the full OCI–EQI Pareto front (not just a single optimum) using both
   an epsilon-constraint search and a global multi-objective search
   (NSGA-II), and validate the surrogate-predicted front against full
   nonlinear dynamic BSM1 simulations.
5. Design and closed-loop test a Model Predictive Controller (MPC) around
   the selected operating point.

## Methodology

The work proceeds in five stages:

1. **Calibration** — the ASM3 kinetic parameters and influent
   characterization in the BSM1 benchmark are adjusted for Indian conditions
   (Arrhenius-corrected rate constants, revised influent COD/N fractions
   based on Anjana WWTP, Surat data), producing a Surat-calibrated variant of
   the standard benchmark.
2. **Design of experiments (RSM)** — a grid of simulations is run over KLa
   and Qintr; quadratic response-surface models are fitted to predict OCI,
   EQI, SNH95, and TN as smooth functions of the two decision variables.
3. **Constrained single-objective optimization** — `fmincon` (SQP) is used
   to find the OCI-minimizing (KLa, Qintr) subject to the compliance
   constraints, using the fitted RSM surfaces.
4. **Multi-objective optimization** — the OCI–EQI trade-off is traced two
   ways: (a) an epsilon-constraint sweep (minimize OCI subject to a moving
   EQI cap) and (b) a global NSGA-II search (`gamultiobj`) that returns the
   full Pareto front directly. Selected points on the front are re-verified
   by running the actual nonlinear dynamic BSM1 simulation (not just the RSM
   surrogate) to confirm the surrogate predictions and check real compliance
   margins via 95th-percentile effluent statistics.
5. **Control design** — the plant is linearized around the selected
   operating point via step-test perturbation, and a Model Predictive
   Controller is designed and tested in closed loop under a realistic
   influent disturbance.

## Mathematical / Model Formulation

**Process model.** The biological reactions are described by the Activated
Sludge Model No. 3 (ASM3, Gujer et al., 2000) with 13 state variables per
reactor (S_O2, S_I, S_S, S_NH4, S_N2, S_NOX, S_ALK, X_I, X_S, X_H, X_STO,
X_A, X_SS) plus temperature, embedded in the standard 5-reactor
BSM1 tank-in-series configuration with a 10-layer secondary settler.
Temperature-dependent kinetic parameters follow an Arrhenius-type
correction, k(T) = k_20 · θ^(T−20), recalibrated for Indian operating
temperatures (see `init/` for the specific coefficients used).

**Operational Cost Index (OCI).** Following the BSM1/BSM2 definition, OCI is
a weighted sum of the plant's energy and sludge-handling costs:

```
OCI = w_SP · SP + w_AE · AE + w_PE · PE + w_ME · ME + w_CS · CS
```

where SP = sludge production for disposal, AE = aeration energy, PE =
pumping energy (Qintr, Qr, Qw), ME = mixing energy, and CS = external carbon
source addition; weights follow the standard BSM1 definition (see
`perf_plant.m` for the exact coefficients as implemented).

**Effluent Quality Index (EQI).** EQI is the flow- and time-weighted average
pollutant load over the evaluation period:

```
EQI = (1 / (1000 · T)) · ∫ [ β_TSS·TSS(t) + β_COD·COD(t) + β_BOD·BOD5(t)
                            + β_TKN·TKN(t) + β_NO·S_NO(t) ] · Q(t) dt
```

integrated over the evaluation window T, with standard BSM1 weighting
coefficients β (see `perf_plant.m`).

**Optimization problems.** With x = (KLa, Qintr):

- *Single-objective:* `min OCI(x)` s.t. `SNH95(x) ≤ 4`, `TN(x) ≤ 18`,
  `x ∈ [KLa_lb, KLa_ub] × [Qintr_lb, Qintr_ub]`
- *Epsilon-constraint:* `min OCI(x)` s.t. `EQI(x) ≤ EQI_max`, same
  compliance and bound constraints, swept over a range of `EQI_max`
- *Multi-objective (NSGA-II):* `min [OCI(x), EQI(x)]` s.t. the same
  compliance and bound constraints, solved directly for the Pareto set

## Software/Toolboxes Used

- MATLAB (R2021a or later recommended) + Simulink
- Optimization Toolbox (`fmincon`)
- Global Optimization Toolbox (`gamultiobj`, NSGA-II)
- Control System Toolbox (linearization, MPC)
- Statistics and Machine Learning Toolbox (RSM/quadratic model fitting)
- The official BSM1 Simulink benchmark files (`benchmark.mdl`/`benchmarkss.mdl`)
  are included under `benchmark/`, sourced from the IWA/COST Benchmark
  Simulation Models working group; see [Acknowledgments](#acknowledgments).

## Key Results

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

## Figures/Plots

Key figures are in `figures/`:

- `final_OCI_surface.png`, `final_EQI_surface.png`, `final_SNH95_surface.png`,
  `final_TNavg_surface.png` — fitted RSM response surfaces over (KLa, Qintr)
- `final_SNH95_contour_v2.png` — SNH95 compliance boundary contour
- `final_family_of_optima.png`, `final_OCI_vs_EQI_boundary.png` — OCI vs. EQI
  trade-off and optimum comparison
- `nsga_front.png` — full NSGA-II Pareto front (OCI vs. EQI)
- `cross_validation.png` — epsilon-constraint points overlaid on the
  NSGA-II front
- `SNH_validation_plot.png`, `TN_validation_plot.png` — real dynamic
  simulation vs. regulatory limits at the validated operating points

Example embed (adjust path if your figures live elsewhere):

```markdown
![NSGA-II Pareto Front](figures/nsga_front.png)
```

## Repository Structure

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

## How to Run the Code

1. Add `benchmark/` to your MATLAB path (contains the official BSM1 `.mdl`/`.slx` files).
2. Run an init script from `init/` to set plant parameters and initial
   conditions (the Surat-calibrated init file for the calibrated model).
3. Run the steady-state → dynamic simulation sequence (`simulation/run_perf_plant.m`),
   then call `perf_plant` to compute OCI/EQI/compliance statistics.
4. To reproduce the RSM grid and fitted surrogate models, run
   `optimization/rsm_fit_models.m` against `data/BSM1_ASM3_Indian_Results.xlsx`.
5. To reproduce the Pareto front, run either
   `optimization/pareto_front_OCI_EQI.m` (epsilon-constraint) or
   `optimization/gamultiobj_OCI_EQI.m` (NSGA-II, recommended — see Key Results).
6. For the controller design, run `mpc/step_test_linearization.m` followed by
   `mpc/mpc_closed_loop_test.m`.

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
