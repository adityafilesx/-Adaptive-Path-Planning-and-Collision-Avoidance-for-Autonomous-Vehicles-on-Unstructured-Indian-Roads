# Adaptive Path Planning and Collision Avoidance for Unstructured Indian Roads

**Smart India Hackathon — SIH26037** · Sponsor: MathWorks · Category: Software · Theme: Smart Vehicles

A closed-loop MATLAB/Simulink/RoadRunner simulation of an autonomous vehicle navigating five challenging Indian-road scenarios — unmarked village road, unsignalized urban intersection, highway merge, dense market street, and sudden cattle crossing — with a class-aware, uncertainty-driven safety layer designed specifically for heterogeneous, low-lane-discipline traffic.

---

## Table of Contents
1. [Problem Statement](#problem-statement)
2. [Our Approach](#our-approach)
3. [System Architecture](#system-architecture)
4. [The Innovation — Adaptive Trust-Risk Governor (ATRG)](#the-innovation--adaptive-trust-risk-governor-atrg)
5. [Repository Structure](#repository-structure)
6. [Requirements](#requirements)
7. [Setup](#setup)
8. [How to Run](#how-to-run)
9. [Scenarios](#scenarios)
10. [Evaluation Metrics](#evaluation-metrics)
11. [Known Limitations](#known-limitations)
12. [References](#references)
13. [Team](#team)

---

## Problem Statement

Most autonomous-driving systems assume structured roads: clear lane markings, predictable traffic flow, and controlled intersections. Indian roads routinely violate all three — mixed vehicle types share the same space without lane discipline, pedestrians and animals cross unpredictably, and road edges are often unclear. SIH26037 asks for an adaptive path-planning system that perceives this environment, predicts short-term motion of diverse road users, and generates safe, collision-free, real-time-replannable paths validated across five representative Indian-road scenarios.

## Our Approach

We deliberately avoid custom-trained perception networks and external planning libraries. Every subsystem uses a MathWorks built-in component (Automated Driving Toolbox, Navigation Toolbox, Sensor Fusion and Tracking Toolbox, Stateflow, Vehicle Dynamics), so the team's engineering effort goes into **integration and system-level logic**, not reinventing algorithms already solved in the literature. Perception is simulation-based: we use ground-truth actor state from the simulator and deliberately inject realistic sensor uncertainty (positional noise, missed detections, classification uncertainty), rather than spending scarce build time training a computer-vision model.

## System Architecture

```
drivingScenario / RoadRunner Scene
            │
            ▼
  Simulated Imperfect Perception   (ground truth + injected noise/dropout)
            │
            ▼
  Class-Conditioned Kalman Prediction   (per-actor, per-class Q/R tuning)
            │
            ▼
  Dynamic Occupancy / Risk Map   (uncertainty ellipses → inflated exclusion zones)
            │
            ▼
  Adaptive Trust-Risk Governor (ATRG)   ← our innovation, see below
            │
            ▼
  Stateflow Decision Logic   (Drive / Yield / Cautious / Stop states)
            │
            ▼
  Hybrid A* Path Planner   (respects vehicle turning-radius constraints)
            │
            ▼
  Kinematic Bicycle Model   (path tracking, steering + velocity commands)
            │
            └──── feeds updated ego pose back into the scenario each timestep ↺
```

Four conceptual layers: **Sense** (perception, prediction) → **Reason** (occupancy map, governor, decision logic, planning) → **Act** (vehicle dynamics) → closed loop back to the scenario.

## The Innovation — Adaptive Trust-Risk Governor (ATRG)

Conventional planners use one fixed safety margin for every obstacle and replan on a fixed schedule. On Indian roads that's the wrong model — a cow, a pedestrian, and a car do not carry the same real-world crash risk, which is documented in Indian heterogeneous-traffic safety research, not assumed by us. ATRG is a lightweight supervisory layer that:

1. **Monitors trust** in each actor's Kalman-filter prediction in real time, using the filter's own residual/innovation statistics.
2. **Weights risk by actor class** using literature-informed multipliers (car/bus/truck lowest, cattle/pedestrian highest) rather than a flat margin.
3. **Maintains a decaying risk budget** that triggers discrete Stateflow mode changes (Normal → Cautious → Conservative-Stop) with hysteresis, and drives the occupancy map's `inflate()` radius and the vehicle's speed limit — **without any change to the Hybrid A* planner itself**.

This is honestly a **system-level combination of well-precedented ideas** (uncertainty-aware risk planning, event-triggered replanning, and empirically-informed class weighting), not a novel algorithm — and we present it to judges that way. The full research grounding, implementation plan, and validation experiment design live in `docs/innovation_research_report.md`.

## Repository Structure

```
/scenarios          drivingScenario scripts + RoadRunner scene files (2 required scenes)
/perception         ground-truth extraction + noise/dropout injection functions
/tracking           per-actor trackingKF setup, class-conditioned Q/R configuration
/prediction         short-horizon trajectory + covariance propagation
/planning           occupancy map construction, plannerHybridAStar wrapper
/decision           Stateflow chart(s): baseline (Drive/Yield/Stop) and ATRG-extended
/governor           computeTrustScore.m, computeRiskBudget.m, classRiskWeights.m, governorConfig.m
/vehicle            kinematic bicycle model, path-tracking controller
/simulink_models     .slx models wiring all stages together
/metrics            batch-run harness, logging, baseline-vs-enhanced comparison scripts
/docs               technical report, innovation research report, this README's source assets
```

## Requirements

| Component | Notes |
|---|---|
| MATLAB | R2023b or later recommended. **If using `idealGroundTruthSensor`, R2025a or later is required** — this block was introduced in R2025a. Default plan in this repo extracts ground truth manually via `drivingScenario` methods for version independence. |
| Automated Driving Toolbox | Scenario simulation, sensor modeling |
| Navigation Toolbox | `occupancyMap`, `inflate`, `plannerHybridAStar` |
| Sensor Fusion and Tracking Toolbox | `trackingKF` |
| Stateflow | Decision logic chart |
| Vehicle Dynamics Blockset (optional) | Only if extending beyond the kinematic bicycle model |
| RoadRunner + RoadRunner Scenario | Separate license from base MATLAB — confirm seat availability |
| Git | Version control; recommended IDE for `.m` script editing: any editor of choice (Simulink/Stateflow/RoadRunner still require their native desktop apps) |

## Setup

1. Clone this repository.
2. Confirm your MATLAB release and installed toolboxes match the table above (`ver` command in MATLAB lists installed toolboxes).
3. Open `simulink_models/main_pipeline.slx` (created during the build — see `docs/build_plan.md`).
4. Ensure RoadRunner is installed separately and licensed if you intend to run the two RoadRunner-based scenes; the other three scenarios run on plain `drivingScenario` scripts with no external application dependency.
5. Add all repo folders to your MATLAB path: `addpath(genpath(pwd))`.

## How to Run

```matlab
% Run a single scenario end-to-end (baseline, no ATRG)
runScenario('urban_intersection', 'governor', false);

% Run the same scenario with ATRG active
runScenario('urban_intersection', 'governor', true);

% Batch-run all five scenarios, multiple seeds, both configurations, for metrics
runAllScenariosBatch('seeds', 1:10, 'noiseLevels', [0.05 0.10 0.20]);
```

(Exact function signatures depend on your implementation — see `docs/build_plan.md` for the build sequence and `/metrics` for the batch-run harness.)

## Scenarios

| # | Scenario | Built via | Tests |
|---|---|---|---|
| 1 | Unmarked village road | RoadRunner (required scene) | Planning without lane references |
| 2 | Busy unsignalized intersection | RoadRunner (required scene) | Multi-agent negotiation, Stateflow yield logic |
| 3 | Highway merge, slow-moving vehicles | `drivingScenario` / Driving Scenario Designer | Speed-differential prediction |
| 4 | Dense market, mixed traffic | `drivingScenario` / Driving Scenario Designer | High-density, multi-class avoidance |
| 5 | Sudden cattle crossing | `drivingScenario` / Driving Scenario Designer | Fast trust-drop response, Conservative-Stop trigger |

## Evaluation Metrics

Collision rate · minimum time-to-collision (TTC) · near-miss count (TTC below threshold) · replanning latency and count · path length · path smoothness (curvature variance) · emergency braking events · scenario completion rate · robustness under increasing injected sensor noise. All metrics logged for both the **baseline** (fixed inflation, fixed replanning cadence) and **ATRG-enhanced** configurations for direct comparison — see `docs/innovation_research_report.md`, Part 6.

## Known Limitations

Stated plainly, per our own review process:
- Perception is entirely simulation-based (ground truth + injected noise); no real camera/LiDAR data or trained detector is used. This is a deliberate scope decision, not an oversight.
- ATRG's class-risk weights are literature-*informed*, not statistically fitted to a large real-world dataset — treat them as a defensible starting point, tuned against our own scenario logs.
- Validation is trend-level across a limited number of seeds per scenario, not statistically rigorous with confidence intervals.
- Results are simulation-only and do not claim to generalize to real sensors or real roads without further validation.

## References

- India Driving Dataset (IDD), IIIT Hyderabad — motivation for actor classes and unstructured-environment framing.
- MathWorks Automated Driving Toolbox, Navigation Toolbox, and RoadRunner documentation.
- Published research on uncertainty-aware/risk-based motion planning, event-triggered replanning, and heterogeneous mixed-traffic crash-risk studies in Indian conditions — full citations and discussion in `docs/innovation_research_report.md`.

## Team

_Add team member names, roles, and contact information here._