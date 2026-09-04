# Windows/Linux runtime validation checklist

- [ ] Use a RoadRunner-supported Windows 11 x64 or Linux x86-64 host.
- [ ] Install and license MATLAB R2026a-compatible RoadRunner, RoadRunner Scenario, and Automated Driving Toolbox.
- [ ] Open MATLAB and RoadRunner once to confirm licensing; do not let setup scripts install software.
- [ ] Clone/copy this repository without changing the integration manifests.
- [ ] Create a genuine RoadRunner project with `Assets`, `Scenes`, and `Scenarios` folders.
- [ ] Configure `cfg.roadrunner.projectRoot`, `SIH_ROADRUNNER_PROJECT_ROOT`, or an uncommitted `roadrunnerLocalConfig.m`.
- [ ] In MATLAB, run `addpath(genpath(projectRoot))` for this repository.
- [ ] Run `setupRoadRunnerWindows` and resolve every reported prerequisite.
- [ ] Run `run('tests/testRoadRunnerIntegration.m')`; runtime tests must execute, not skip.
- [ ] Author/open `VillageRoad.rrscene` and `VillageRoad.rrscenario` first.
- [ ] Assign actor name `EgoVehicle`; assign logical actor ID 301 and name `VillagePushcart301`.
- [ ] Run `mainPhase10` and verify project, scenario, simulation, actor read, ego write, coordinate, class, and clock checks.
- [ ] Repeat for `UrbanIntersection` with logical IDs 401 and 402.
- [ ] Confirm position error < 0.25 m, yaw error < 2 degrees, speed error < 0.25 m/s, and time drift <= 0.05 s.
- [ ] Confirm actor-count, ActorID, and class mismatch counts are zero.
- [ ] Capture for each primary scene: scene screenshot, actor setup, initial MATLAB state, synchronized ego state, ACARG state, replanning event, final outcome, and runtime summary.
- [ ] Save screenshots/logs under repository `roadrunner/validation/` with date, host, MATLAB/RoadRunner versions, and manifest key.
- [ ] Mark runtime `PASS` only after both primary scenarios execute successfully.
