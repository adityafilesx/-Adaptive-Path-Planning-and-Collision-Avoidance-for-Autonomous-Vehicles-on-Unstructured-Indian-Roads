# Phase 10 RoadRunner integration

RoadRunner runtime is unavailable on macOS. The Phase 2–9 MATLAB autonomy stack and all Phase 10 architecture tests continue to run there; runtime checks must report `SKIPPED`, not `PASS`.

Runtime execution requires a RoadRunner-supported Windows 11 x64 or Linux x86-64 machine, MATLAB, RoadRunner, RoadRunner Scenario, and Automated Driving Toolbox with valid licenses. The MATLAB `roadrunner`, `openScene`, `openScenario`, `createSimulation`, `ActorSimulation`, `getAttribute`, and `setAttribute` interfaces must be available.

## Portable configuration

Do not commit a personal absolute path. Configure the RoadRunner project root by one of these methods, in precedence order:

1. Set `cfg.roadrunner.projectRoot` and `cfg.roadrunner.enabled=true` in the calling session.
2. Set the environment variable `SIH_ROADRUNNER_PROJECT_ROOT`.
3. Create an uncommitted `roadrunnerLocalConfig.m` on the MATLAB path:

```matlab
function value = roadrunnerLocalConfig()
value = struct('projectRoot', 'D:\RoadRunnerProjects\SIH_Phase10');
end
```

The path shown is only an example. Keep the local file outside version control.

## Expected generated project layout

```text
<configured project root>/
  Assets/
  Scenes/
    VillageRoad.rrscene
    UrbanIntersection.rrscene
  Scenarios/
    VillageRoad.rrscenario
    UrbanIntersection.rrscenario
```

RoadRunner must create the project and the `.rrscene`/`.rrscenario` files. Do not rename text, JSON, MAT, or placeholder files to those extensions. Repository folders `project/`, `assets/`, `exports/`, and `validation/` contain instructions/evidence only and are not a fake RoadRunner project.

## Run

From MATLAB on the target machine:

```matlab
projectRoot = fileparts(pwd); % replace with the repository root if needed
addpath(genpath(projectRoot));
setupRoadRunnerWindows
run('tests/testRoadRunnerIntegration.m')
phase10Result = mainPhase10;
```

Author and save the primary scenes in priority order: Village, then Urban. Follow [SCENE_AUTHORING_CHECKLIST.md](SCENE_AUTHORING_CHECKLIST.md) and the files in `specs/`. Runtime evidence belongs in `validation/`; exports belong in `exports/`.

## Integration contract

RoadRunner is a scene host and visualizer, not a planner. The initial mode is `MATLAB_AUTHORITATIVE`: the validated Phase 7 bicycle model owns ego state and the adapter writes it to the RoadRunner actor. `ROADRUNNER_AUTHORITATIVE` is an interface-ready future mode for reading actor motion while MATLAB still owns perception, tracking, ACARG, occupancy, planning, control, and ego response.

Canonical coordinates use metres, +X longitudinal, +Y lateral, +Z up, yaw zero along +X, and positive yaw counter-clockwise. RoadRunner uses metres and +Z up, but an actor at zero yaw faces +Y. The adapter applies this documented heading offset and a manifest-configurable orthonormal world transform. XY positions refer to the actor centre; vertical origin depends on the RoadRunner asset and is not used by current collision logic.

Simulation time—not wall clock—is compared every 0.2 s. The runtime smoke test replays a short ego-state sequence produced by the existing closed-loop stack, advances RoadRunner with explicit `Step` commands, reads ego pose/velocity back, and checks each frame. Drift over 0.05 s fails synchronization validation.
