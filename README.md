# M.Tech-Thesis
# Multi-Objective Optimization and Control of an Indian-Calibrated BSM1/ASM3 Wastewater Treatment Plant

M.Tech thesis project — Discipline of Chemical Engineering, IIT Gandhinagar.

## Project status (22 Oct 2026)

The thesis now has two studies, and this repository holds both:

| Study | Where | Scale and conditions | Status |
|---|---|---|---|
| Reference case | `optimization/`, `init/`, `benchmark/` | BSM1 scale, standard BSM1 influent, 15 °C, decision variables KLa and Qintr (44-run design) | Done, kept as the reference |
| Plant-scale study | [`plant_scale_study/`](plant_scale_study/README.md) | Anjana WWTP scale (38,485 m³/d), Surat influent, 24 °C and 30 °C, decision variables KLa, Qintr and Qw, clarifier area 1,225 and 2,566 m² | In progress |

The reference case uses the BSM1 reference temperature, which is not a Surat condition, and its optima do not carry over to
24–30 °C (see Key Results). Controller design (objective 5 below) is planned; its scope is still to be decided.

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
Temperature-dependent kinetic parameters follow the exponential correction
implemented in `benchmark/asm3.c` (given in full under *Plant-scale study
formulation* below); `init/` holds the 20 °C parameter values.

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

**Optimization problems (reference case).** With x = (KLa, Qintr):

- *Single-objective:* `min OCI(x)` s.t. `SNH95(x) ≤ 4`, `TN(x) ≤ 18`,
  `x ∈ [KLa_lb, KLa_ub] × [Qintr_lb, Qintr_ub]`
- *Epsilon-constraint:* `min OCI(x)` s.t. `EQI(x) ≤ EQI_max`, same
  compliance and bound constraints, swept over a range of `EQI_max`
- *Multi-objective (NSGA-II):* `min [OCI(x), EQI(x)]` s.t. the same
  compliance and bound constraints, solved directly for the Pareto set

### Plant-scale study formulation

The plant-scale study (`plant_scale_study/`) uses the following. Everything here is taken from the scripts in this repository.

**Temperature law and nitrifier calibration.** In `asm3.c` (reactor temperature T from the influent temperature input, `TEMPMODEL = 0`),
each rate parameter given at 20 °C is corrected as

```
p(T) = p20 · exp( [ ln(p20 / p10) / 10 ] · (T − 20) )
```

where p10 is a value hard-coded in the source (μ_A: 0.35, b_A,O2: 0.05, b_A,NOX: 0.02, μ_H: 1.0, b_H,O2: 0.1, b_H,NOX: 0.05,
k_H: 2, k_STO: 2.5, b_STO,O2: 0.1, b_STO,NOX: 0.05). The slope therefore depends on p20 itself. For nitrifiers, lowering the
calibrated μ_A flattens its temperature slope (0.105 °C⁻¹ at μ_A = 1.0) while the decay rate keeps its own, so net growth
(μ_A − b_A) falls as the water warms. The scripts work around this by passing the model the input `p = μ20^(10/(T − 10))`, which
makes the code return the standard slope:

```
μ_A(T) = μ20 · exp( s · (T − 20) ),   s = ln(1 / 0.35) / 10 = 0.105 °C⁻¹
```

Calibration: μ_A(28 °C) = 0.68 d⁻¹ reproduces the measured effluent ammonia, so μ20 = 0.68 · exp(−0.105 · 8) ≈ 0.29 d⁻¹, giving
about 0.45 d⁻¹ at 24 °C and 0.83 d⁻¹ at 30 °C.

**Sludge age and nitrifier washout.** Sludge age is the solids inventory (reactors plus settler) divided by the solids leaving
through waste sludge and effluent:

```
SRT = M_TSS / ( Q_w · X_w + Q_e · X_e )
```

As a rule of thumb (it ignores substrate saturation), nitrifiers are retained only if the aerobic fraction f_aer of the sludge age
satisfies `f_aer · ( μ_A(T) − b_A(T) ) ≳ 1 / SRT`. Colder water lowers the left side, so it needs a longer sludge age, that is a smaller Q_w.

**Secondary clarifier.** BSM1 uses a 10-layer settler with the double-exponential settling velocity (`settler1d_asm3.c`):

```
v_s(X)  = min( v0_max , max( 0 , v0 · [ exp(−r_h (X − f_ns X_f)) − exp(−r_p (X − f_ns X_f)) ] ) )
v_in = Q_f / A ,   v_up = Q_e / A ,   v_dn = Q_u / A
J_s,i = v_s(X_i) · X_i                   (settling flux of layer i)
J_liquid = v_up · X above the feed layer,  v_dn · X below it
```

The flux passed between two layers is the smaller of their two settling fluxes; above the feed layer, while the lower layer's
concentration is at most X_t, it is the upper layer's flux. Parameters from `settler1dinit_asm3.m`: v0_max = 250 m/d, v0 = 474 m/d, r_h = 0.000576 m³/g, r_p = 0.00286 m³/g,
f_ns = 0.00228, X_t = 3000 g/m³, feed layer 5. The clarifier area A enters only through v_in, v_up and v_dn: a larger area lowers the
overflow velocity and the solids loading, so the same sludge inventory is held back more easily. The study compares A = 1,225 m²
(inferred) and A = 2,566 m² at a depth of 4 m.

**Evaluation window and effluent statistics.** Each run is 100 d at constant influent, then 14 d of dynamic influent; `perf_plant.m`
evaluates days 7–14 of the dynamic stage (7 d). With Q_e the effluent flow:

```
SNHavg = ∫ S_NH,e · Q_e dt / ∫ Q_e dt          (flow-weighted mean)
SNH95  = 95th percentile of the effluent ammonia S_NH,e(t)
TN95   = 95th percentile of  S_NO + S_NH + i_NSI S_I + i_NSS S_S + i_NXI X_I + i_NXS X_S + i_NBM (X_H + X_A)
TSS95  = 95th percentile of the effluent suspended solids
```

Strict limits: SNH95 ≤ 4 mg N/L, TN95 ≤ 18 mg/L, TSS95 ≤ 30 mg/L. Practical target: SNHavg ≤ 4 in place of SNH95.

**Cost and quality indices as reported by the scripts** (updated BSM1 versions `OCI_new` and `EQ_new` in `perf_plant.m`; T_e = 7 d):

```
OCI = 5·SP + AE + ME + PE + 3·EC                           (EC = 0: no external carbon)
AE  = (1 / (1.8·1000·T_e)) ∫ Σ_i S_O,sat,i · V_i · KLa_i(t) dt                         [kWh/d]
PE  = (1 / T_e) ∫ ( 0.004·Q_intr + 0.008·Q_r + 0.05·Q_w ) dt                            [kWh/d]
ME  = 24 · 0.005 · Σ_i V_i · (fraction of time with KLa_i < 20 d⁻¹)                     [kWh/d]
SP  = ( ∫ Q_w X_w dt + change in solids inventory of reactors and settler ) / T_e       [kg TSS/d]
EQ  = (1 / (1000·T_e)) ∫ ( 2·TSS_e + COD_e + 30·TKN_e + 10·S_NO,e + 2·BOD5_e ) · Q_e dt
```

**Decision variables.** x = (KLa, Qintr, Qw), with the same KLa in the three aerobic tanks (3 to 5):

| | KLa (d⁻¹) | Qintr (m³/d) | Qw (m³/d) |
|---|---|---|---|
| 24 °C | 50–180 | 20,000–110,000 | 100–600 |
| 30 °C | 50–180 | 20,000–110,000 | 100–1,100 |

**Response surfaces.** Variables are coded u = (x − lo) / (hi − lo) with the bounds above. For each response y:

```
y' = β0 + Σ β_i u_i + Σ β_ii u_i² + Σ_{i<j} β_ij u_i u_j
```

with y' = √y for SNH95, SNHavg and TN95 (chosen when it predicts better in leave-one-out), y' = y for OCI and EQI, and y' = ln y for
TSS95 using whichever of three forms predicts best: (1) quadratic in (KLa, Qintr, Qw); (2) quadratic in (KLa, Qintr, 1/Qw), since sludge
age goes as 1/Qw; (3) a linear model in [v, v², v³, κ, κ², κ·v] with v the coded 1/Qw and κ the coded KLa. Validation uses the
leave-one-out statistic, computed on the original scale for ammonia, TN95, OCI and EQI and on the log scale for TSS95:

```
Q² = 1 − PRESS / SS_tot ,    PRESS = Σ ( e_i / (1 − h_ii) )²
```

where e_i is the residual and h_ii the leverage of run i. Prediction uncertainty for a new run is the regression standard error s(x),
widened by `infl = max(1, LOO RMSE / in-sample RMSE)` so that it reflects how well the surface predicts runs it has not seen.

**Constrained optimum with a safety margin.** For a margin of k standard errors (`dfo_solve.m`, `fmincon` SQP from random starts):

```
strict (A):     min OCI(x)   s.t.  ŷ_j(x) + k·s_j(x) ≤ L_j   for j ∈ {SNH95, TN95, TSS95}
practical (D):  min OCI(x)   s.t.  same, with SNHavg in place of SNH95
lowest ammonia (G):  min SNH95(x)   s.t.  TN95 and TSS95 constraints,    x ∈ [lo, hi]
```

The objective is always the nominal prediction. If no point is feasible (modes B and E), the point minimising the worst relative violation
`max_j ( ŷ_j + k·s_j − L_j ) / L_j` is returned. The cost–ammonia front (`compare_area.m`) is `gamultiobj` on [OCI(x), SNH95(x)]
with the TSS95 and TN95 constraints held.

**Experimental design and infill.** The design is a maximin Latin hypercube of N = 30 points in the coded cube, chosen to maximise the
smallest distance between any two points:

```
max over designs U :   min_{i ≠ j} || u_i − u_j ||
```

Infill points (`opt_margin.m`) are the margin optima plus maximin-spaced points in the region where the surfaces are uncertain near
the limits. Before refitting, the surfaces fitted without the newest infill runs predict them (hold-out test): bias, RMS error and R²
on the unseen runs are reported.

**Robustness.** For a chosen x and the scenario set S = { dry, rain, storm, μ_A × 0.8, μ_A × 1.2 } (`robust_check.m`), the worst case is

```
g_j^max(x) = max over s ∈ S of  g_j(x, s) ,     robust if  g_j^max(x) ≤ L_j  for every limit j
```

**Planned or optional extensions (not implemented).** (a) An annualised clarifier capital cost, `C_cap = c_A · A · CRF`, to compare with
the OCI change when A grows; (b) temperature-dependent oxygen saturation S_O,sat(T) and KLa(T) = KLa,20 · θ^(T−20), which are constant or
commented out in the model today; (c) temperature as a fourth variable, y = f(KLa, Qintr, Qw, T), fitted on 24, 30 and 35 °C; (d) a
state-space model `x_{k+1} = A x_k + B u_k + E d_k` for aeration control, if a PI loop or MPC is built.

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

### Plant-scale study (Anjana scale, 24 °C and 30 °C, dry weather)

Details, scripts and data are in [`plant_scale_study/`](plant_scale_study/README.md). Limits: SNH95 ≤ 4 mg N/L, TN95 ≤ 18 mg/L,
TSS95 ≤ 30 mg/L (strict); the practical target uses average ammonia ≤ 4 mg N/L instead of SNH95.

**Calibration.** Nitrifier growth rate 0.68 d⁻¹ at 28 °C reproduces the measured effluent ammonia (model 15.2 vs plant 14.7 mg N/L);
the predicted sludge age of 7.2 d matches the reported 7–8 d, which was not used in the fit.

**Effect of clarifier area.** The same 30 operating points (KLa, Qintr, Qw) were simulated at two areas:

| Out of 30 runs | 24 °C, 1,225 m² | 24 °C, 2,566 m² | 30 °C, 1,225 m² | 30 °C, 2,566 m² |
|---|---|---|---|---|
| TSS95 ≤ 30 | 3 | 27 | 21 | 29 |
| Ammonia (average) and TN95 within limits | 0 | 4 | 3 | 3 |
| Practical target met | 0 | 2 | 0 | 2 |
| Strict limits met | 0 | 0 | 0 | 0 |
| Median change in SNH95 (mg N/L) | | −1.4 | | −1.0 |
| Median change in OCI | | +1,412 | | +1,318 |

At 1,225 m² (inferred), none of 57 simulated runs at 30 °C and none of 45 at 24 °C meet the practical target either. The larger
clarifier lowered TSS95 by 13–32 mg/L in every paired run.

**Design runs that meet the practical target at 2,566 m²** (the same two settings pass at both temperatures):

| Temperature | KLa | Qintr (m³/d) | Qw (m³/d) | SNHavg | TN95 | TSS95 | OCI |
|---|---|---|---|---|---|---|---|
| 24 °C | 136.5 | 105,900 | 150 | 3.87 | 14.3 | 28.5 | 19,576 |
| 24 °C | 150.7 | 89,100 | 167 | 3.48 | 16.2 | 20.0 | 21,547 |
| 30 °C | 136.5 | 105,900 | 200 | 3.37 | 15.3 | 18.6 | 20,347 |
| 30 °C | 150.7 | 89,100 | 234 | 3.20 | 16.0 | 17.8 | 21,680 |

These are simulated design points, not optimised ones, and none meets the strict ammonia limit (their SNH95 is 5.9–6.8 mg N/L).

**Response surfaces** (leave-one-out R² at 2,566 m², 24 °C / 30 °C): ammonia 0.94–0.95, TN95 0.86 / 0.84, OCI 0.87 / 0.90,
solids 0.33 / 0.70. The solids surface is the weak one, so its optima are checked by simulation.

**Still to run:** infill and hold-out tests at 2,566 m², robustness in rain and storm, and the final cost–quality front.

### Reference case (BSM1 scale, standard influent, 15 °C, dry weather)

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

These results are for 15 °C, the BSM1 reference temperature. Surat sewage is 23–35 °C (about 24 °C in January and 30 °C on
average), and with the nitrifier kinetics calibrated to the Anjana plant the 15 °C optima do not transfer. The plant-scale study
above redoes the analysis at 24 °C and 30 °C.

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
plant_scale_study/  Plant-scale study at 24 and 30 °C: scripts, results CSV, README
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
7. For the plant-scale study (24 and 30 °C), see `plant_scale_study/README.md`.

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
