# Unmarked Indian Village Road — scene specification

## Purpose

Reproduce the validated Phase 8 `Unmarked Village Road` behavior in a realistic environment and demonstrate that perception, ACARG, occupancy, Hybrid A*, and closed-loop control do not depend on lane markings.

## Geometry and environment

- Local world: metres; canonical +X follows the ego route, +Y is lateral, +Z is up.
- Model at least X = -10 to 100 m and Y = -25 to 25 m.
- Paved road: approximately 100 m long, nominally 9 m wide, bidirectional, no painted center or edge lines.
- Add small, believable edge irregularities while retaining collision-free space represented by the MATLAB occupancy world.
- Use dirt shoulders, sparse village buildings, vegetation, utility/roadside props, and informal pedestrian space without a formal sidewalk.
- Use visual context appropriate to an Indian village, but do not add active logical actors beyond the manifest unless a new manifest/benchmark is approved.

## Ego and goal

- Actor name: `EgoVehicle`.
- Spawn: X=0 m, Y=0 m, Z=0 m, canonical yaw=0 rad, speed=0 m/s.
- Goal marker (not a second controller): X=85 m, Y=0 m, canonical yaw=0 rad.
- MATLAB-authoritative target speed comes from Phase 8 configuration; RoadRunner must not run a competing vehicle dynamics model.

## Logical actors and trajectory

| ID | RoadRunner name | Canonical class | Spawn (m) | Velocity (m/s) | Yaw | Size L×W×H (m) |
|---:|---|---|---|---|---:|---|
| 301 | `VillagePushcart301` | `pushcart` | [60, 16, 0] | [0.5, -1.5, 0] | -1.249046 rad | 2.0×1.0×1.5 |

Give actor 301 a straight constant-velocity path for at least 26 s. Preferred visual asset is a pushcart/vendor cart. A bicycle-style proxy is acceptable; the adapter class remains `pushcart`.

## Phase 8 correspondence

Scenario name, ego state, goal, actor ID/class/state/dimensions, 26 s horizon, and 0.2 s timestep come directly from `createVillageRoadScenario.m`. The road appearance may be richer than the MATLAB occupancy map, but logical behavior must correspond.

## Expected autonomy behavior

ACARG should evaluate the slow laterally approaching road user, enter caution when risk warrants, and adjust safety extent/speed. Hybrid A* should maintain or modify a collision-free route without using lanes. Pure Pursuit and the kinematic bicycle model remain authoritative; acceptable outcomes are safe completion or a justified safe stop, with no collision or knowingly unsafe forward command.

## Visual assets

- Required generic: paved road surface, dirt shoulder, low buildings, vegetation, ego vehicle.
- Preferred: pushcart/vendor-cart model and Indian roadside props.
- Fallback: RoadRunner bicycle actor scaled/logically dimensioned as specified. Never change ACARG class because of the proxy mesh.

## Validation

- [ ] File names and actor names/IDs exactly match `villageRoad.json`.
- [ ] No lane markings and no signal/lane decision logic.
- [ ] Ego/goal and actor initial pose/velocity match within runtime tolerances.
- [ ] Actor count, IDs, and canonical classes have zero mismatches.
- [ ] Pose, yaw, velocity, and 0.2 s clock checks pass.
- [ ] Screenshot, synchronized diagnostic view, ACARG/replan evidence, outcome, and metrics are saved.
