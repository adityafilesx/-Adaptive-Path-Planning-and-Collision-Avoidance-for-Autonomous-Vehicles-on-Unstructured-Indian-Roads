# Phase 11 evaluation

This directory contains evaluation-only orchestration. It does not change perception, tracking, prediction, occupancy, ACARG, Hybrid A*, controller, vehicle dynamics, collision checking, or replanning implementation.

`FULL_ACARG` uses the frozen production configuration. `FIXED_MARGIN_BASELINE` is a copied configuration with unit global speed/safety scales, zero actor-specific adaptive inflation, unreachable ACARG entry thresholds, and disabled risk-change/urgency replanning. Periodic and path-safety replanning, collision checks, planner, Pure Pursuit, bicycle dynamics, actors, goals, timestep, and vehicle geometry remain unchanged. ACARG risk is retained as a non-controlling monitor so risk traces can be compared on baseline trajectories.

CPA and distance-only ablations are offline counterfactual scoring of identical tracked geometry. Confidence and class studies likewise preserve geometry and modify only the named conceptual factor.

Timing is measured with MATLAB wall clock on the development machine. ACARG cost is isolated by replaying stored tracks. `EquivalentMeanFrameWallClockMs` divides a measured whole-run time by frame count; it is not a true worst-frame trace and must not be presented as production ECU timing.

Every execution writes a new `results/phase11/run_TIMESTAMP/` directory. Only the current Phase 11 rerun tagged `POST_PHASE9_FIX` is authoritative for final benchmark metrics. Earlier Phase 8 artifacts are retained but are not silently mixed into the result.
