# Operating-point optimisation of an Indian activated-sludge plant (BSM1/ASM3), Surat case study

MATLAB/Simulink scripts and results from an M.Tech thesis in progress (status: 22 Oct 2026). The thesis asks whether the
BSM1 benchmark plant with the ASM3 model, adapted to the Anjana wastewater treatment plant in Surat, can be used to find
operating settings that meet effluent limits at Indian temperatures (24 °C and 30 °C), and what limits it.

## What is and is not in this folder

Included: the experiment and analysis scripts, the calibration checks, the design-of-experiments results as one CSV, and the raw
printed output of the two latest steps. The `.mat` result files are ignored by `.gitignore`.

The BSM1/ASM3 model files are in `../benchmark/` and the init files in `../init/`. The scripts expect a flat folder: copy every `.m`
file from `matlab/*/` next to the model files and `run_plant_point.m`.

Note: `../init/asm3init.m` is the earlier version (`f_XI = 0.14`). The plant-scale runs here use `f_XI = 0.20` and the Surat v3
influent built by `matlab/calibration/build_surat_influent_v3.m`; replace the init file with the current local copy before reproducing them.

## Plant set-up

| Item | Value |
|---|---|
| Plant | Anjana WWTP, Surat: 38,485 m³/d, biological volume 26,250 m³ (2 anoxic + 3 aerobic tanks), return flow 21,186 m³/d |
| Influent | Rebuilt from the published settled-sewage composition (Lopez-Vazquez et al. 2013, J. Water Sanit. Hyg. Dev. 3(1)); dry, rain and storm profiles from BSM1 |
| Clarifier | 1,225 m² (inferred, not documented) and 2,566 m² (tested) |
| Protocol | 100 d constant influent (ode15s), then 14 d dynamic (ode45) |
| Evaluation | Days 7–14 of the dynamic stage (7 d); SNH95, TN95 and TSS95 are 95th percentiles, SNHavg is flow-weighted |
| Decision variables | Aeration KLa, internal recycle Qintr, waste sludge flow Qw |
| Limits | SNH95 ≤ 4 mg N/L, TN95 ≤ 18 mg/L, TSS95 ≤ 30 mg/L (strict). Practical target: average ammonia SNHavg ≤ 4 instead of SNH95 |

Calibration: nitrifier growth rate fitted to 0.68 d⁻¹ at 28 °C so that effluent ammonia matches the measured 14.7 mg N/L
(model 15.2); the predicted sludge age of 7.2 d matches the reported 7–8 d (not used in the fit). The temperature correction in
`asm3.c` makes the slope depend on the parameter value; the scripts work around it by passing `p = mu20^(10/(T-10))`
(`sim_point.m` does this; `matlab/calibration/mu_slope_test.m` tests how sensitive the 24 °C conclusion is to the assumed slope). The runner also sets the return-flow constant directly, because the model block
ignores the workspace variable.

## Method and run order

1. `design_runs.m`: 30-run maximin Latin hypercube over KLa, Qintr, Qw at each temperature and clarifier area.
2. `opt_margin.m`: quadratic response surfaces (square-root scale for ammonia and TN, log scale for solids), leave-one-out
   validation, constrained optimisation with a safety margin of k standard errors, proposal of infill points.
3. `infill_runs.m`: simulates the proposed points; `opt_margin.m` is then run again as a hold-out test and refit.
4. `compare_area.m`: the same 30 operating points at two clarifier areas, surface optima and a cost-versus-ammonia front.
5. `robust_check.m`: chosen points in dry, rain and storm weather and with the growth rate scaled by 0.8 and 1.2.
6. `front_oci_eqi_tn.m`: operating cost, effluent quality and total-nitrogen front, checked with real-model runs.

Surface code is in `matlab/surfaces/` (`dfo_*.m`); `design_fit_optimize_v2.m` is the earlier fit that the margin analysis builds on.

## Results so far

All values are dry weather. `results/design_runs.csv` holds the four designs (24 and 30 °C, 1,225 and 2,566 m²; the
24 °C / 1,225 m² set has 26 of 30 runs).

- At 1,225 m², none of 57 simulated runs at 30 °C and none of 45 at 24 °C meet the practical target or the strict limits. The
  surfaces were optimistic at the settings they chose.
- At 2,566 m², 2 of 30 design runs meet the practical target at each temperature (runs 6 and 27, the same settings at both
  temperatures); none meet the strict limits. The best simulated SNH95 with solids within the limit is 4.94 (24 °C) and 4.36
  (30 °C), both with TN95 of 20–21 mg/L.
- The larger clarifier lowered TSS95 by 13–32 mg/L in every paired run, lowered median SNH95 by 1.4 (24 °C) and 1.0 (30 °C)
  mg N/L, and raised operating cost by about 1,300–1,400 OCI units at the same settings.
- Surface quality at 2,566 m² (leave-one-out R², 24 °C / 30 °C): ammonia (SNH95 and SNHavg) 0.94–0.95 at both temperatures, TN95 0.86 / 0.84, OCI 0.87 / 0.90,
  solids 0.33 / 0.70. The solids surface is the weak one.
- Running the 100-day stage with `ode15s` cut a simulation from about 287 s to 62 s (about 4.6×) with identical results.

Still to run: infill and hold-out tests at 2,566 m², the weather and growth-rate robustness check, and the final front.

## Limitations

- The 1,225 m² clarifier area is inferred; results are stated relative to it.
- The calibration rests on one tuned value at one temperature; the temperature dependence is the standard slope, not validated.
- Oxygen saturation is constant across temperatures, and each run holds temperature constant.
- Reported effluent solids and sludge concentration are not fully reproduced (model TSS and MLSS are below the measured values).
- The scripts were developed interactively in MATLAB and have no automated tests.

## References

- Lopez-Vazquez et al. (2013), J. Water Sanit. Hyg. Dev. 3(1): Anjana WWTP, ASM3 + ADM1.
- IWA Benchmark Simulation Model No. 1 (BSM1) and ASM3 (Lund University benchmark distribution).

No licence has been added yet; all rights are reserved until one is chosen.
