# Unsignalized Indian Urban Intersection — scene specification

## Purpose

Reproduce the Phase 8 `Unsignalized Urban Intersection` crossing conflicts in a visually realistic mixed-traffic setting. The challenge is geometric and predictive; no traffic-signal or lane-rule decision logic is added.

## Geometry and environment

- Local world: metres; canonical +X is the ego approach/exit, +Y is the crossing direction, +Z is up.
- Model at least X = -10 to 115 m and Y = -35 to 35 m.
- Create an unsignalized cross intersection near the two conflict X locations, with realistic 8–12 m road widths and imperfect lane discipline.
- Add urban frontage, roadside activity, signs/utility props, parked visual props, pedestrians, and two-wheelers for appearance. Extra objects must be static/nonlogical unless added to a future canonical manifest.
- Do not add signal phases, priority rules, or a second decision system.

## Ego and goal

- Actor name: `EgoVehicle`.
- Spawn: [0,0,0], canonical yaw 0 rad, speed 0 m/s.
- Goal: [100,0,0], canonical yaw 0 rad.
- Phase 8 target speed is 7.5 m/s; MATLAB controls actual ego motion through the validated bicycle model.

## Logical actors and trajectories

| ID | RoadRunner name | Canonical class | Spawn (m) | Velocity (m/s) | Yaw | Size L×W×H (m) |
|---:|---|---|---|---|---:|---|
| 401 | `CrossingCar401` | `car` | [65,18,0] | [0,-2.2,0] | -π/2 | 4.7×1.8×1.5 |
| 402 | `CrossingAuto402` | `auto` | [90,-18,0] | [0,2.2,0] | +π/2 | 3.2×1.5×1.5 |

Assign both actors straight constant-velocity crossing paths for at least 24 s. Use a genuine auto-rickshaw mesh if available; otherwise use a compact-vehicle proxy while retaining ID 402, dimensions, and canonical class `auto`.

## Phase 8 correspondence

Scenario name, actor IDs/classes/states/dimensions, ego/goal, 24 s horizon, 0.2 s timestep, and occupancy lateral limits come from `createUrbanIntersectionScenario.m`. Visual geometry need not equal occupancy cells exactly, but logical conflicts must be close enough for behavior comparison.

## Expected autonomy behavior

ACARG should identify crossing risk, slow or enter a more conservative state when thresholds warrant, and request replanning as appropriate. Hybrid A* may reroute geometrically around predicted conflict occupancy. No RoadRunner signal or lane agent should override MATLAB ego state.

## Validation

- [ ] File names and actor names/IDs exactly match `urbanIntersection.json`.
- [ ] Intersection is unsignalized and actors cross at the specified states.
- [ ] Ego/goal and both actors pass position/yaw/speed correspondence.
- [ ] Auto visual fallback does not alter canonical class.
- [ ] Actor count, IDs, and classes have zero mismatches.
- [ ] 0.2 s synchronization stays within 0.05 s.
- [ ] Capture initial state, ACARG transition, replan, synchronized ego, outcome, and runtime metrics.
