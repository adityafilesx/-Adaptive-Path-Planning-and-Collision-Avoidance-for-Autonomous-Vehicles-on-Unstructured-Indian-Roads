# All-scenario video index

MATLAB closed-loop simulation evidence. Not IDD perception or RoadRunner footage.

Every clip uses 10 fps, 1440 x 900, 1x simulation time, a 1.5-second title and a 3.0-second final card.

All saved states are shown; visual frame repetition does not interpolate risk or physical motion. `.timeline.csv` files map each encoded frame to its simulation state.

## 01 — Unmarked Village Road

[Watch video](phase8/01_village_road.mp4)

- Tests: A slow cart and laterally ambiguous pedestrian constrain a narrow unmarked travel corridor without lane assumptions.
- Watch: Mixed traffic and adaptive risk.
- Highest risk: **0.656 at simulation 13.8 s** (video 15.3 s).
- Outcome: **GOAL_REACHED**; goal 1, safe termination 0, collision 0.
- Reason: Goal reached.
- Replans: 15; governor states: NORMAL -> CAUTIOUS.
- Dominant actor changes observed: 0.
- Replay: `/Users/aditya1981/Downloads/SIH_Ps37/results/phase12/videos/all_scenarios/run_20260906_101738_201/replays/01_village_road.mat`
- Authoritative source: `/Users/aditya1981/Downloads/SIH_Ps37/results/phase11/run_20260906_050810_702/phase11Evaluation_20260906_050810_702.mat`
- Validation: VALIDATED, 24.2 video seconds, 242 encoded frames.

## 02 — Unsignalized Urban Intersection

[Watch video](phase8/02_urban_intersection.mp4)

- Tests: Two crossing actors create predicted conflicts without signal logic.
- Watch: Safe planning failure guard.
- Highest risk: **0.429 at simulation 10.4 s** (video 11.9 s).
- Outcome: **SAFE_TERMINATION**; goal 0, safe termination 1, collision 0.
- Reason: Safely stopped after repeated planning failures.
- Replans: 11; governor states: NORMAL -> CAUTIOUS.
- Dominant actor changes observed: 0.
- Judge note: **Planner could not find a safe continuation → safe planning failure guard**, not a forced goal or an unhandled software error.
- Replay: `/Users/aditya1981/Downloads/SIH_Ps37/results/phase12/videos/all_scenarios/run_20260906_101738_201/replays/02_urban_intersection.mat`
- Authoritative source: `/Users/aditya1981/Downloads/SIH_Ps37/results/phase11/run_20260906_050810_702/phase11Evaluation_20260906_050810_702.mat`
- Validation: VALIDATED, 15.6 video seconds, 156 encoded frames.

## 03 — Highway Slow-Vehicle Merge

[Watch video](phase8/03_highway_merge.mp4)

- Tests: A slow lead vehicle and moving lateral constraint create a merge conflict.
- Watch: Prediction-aware merge.
- Highest risk: **0.658 at simulation 10.4 s** (video 11.9 s).
- Outcome: **GOAL_REACHED**; goal 1, safe termination 0, collision 0.
- Reason: Goal reached.
- Replans: 7; governor states: NORMAL -> CAUTIOUS.
- Dominant actor changes observed: 8.
- First dominant-actor change: 0.6 s.
- Replay: `/Users/aditya1981/Downloads/SIH_Ps37/results/phase12/videos/all_scenarios/run_20260906_101738_201/replays/03_highway_merge.mat`
- Authoritative source: `/Users/aditya1981/Downloads/SIH_Ps37/results/phase11/run_20260906_050810_702/phase11Evaluation_20260906_050810_702.mat`
- Validation: VALIDATED, 21.8 video seconds, 218 encoded frames.

## 04 — Dense Mixed-Traffic Market

[Watch video](phase8/04_dense_market.mp4)

- Tests: Pedestrian and slow-car traffic generate simultaneous heterogeneous risks.
- Watch: Dense traffic and safe progress.
- Highest risk: **0.655 at simulation 14.8 s** (video 16.3 s).
- Outcome: **GOAL_REACHED**; goal 1, safe termination 0, collision 0.
- Reason: Goal reached.
- Replans: 9; governor states: NORMAL -> CAUTIOUS.
- Dominant actor changes observed: 0.
- Replay: `/Users/aditya1981/Downloads/SIH_Ps37/results/phase12/videos/all_scenarios/run_20260906_101738_201/replays/04_dense_market.mat`
- Authoritative source: `/Users/aditya1981/Downloads/SIH_Ps37/results/phase11/run_20260906_050810_702/phase11Evaluation_20260906_050810_702.mat`
- Validation: VALIDATED, 27.2 video seconds, 272 encoded frames.

## 05 — Sudden Cattle Crossing

[Watch video](phase8/05_cattle_crossing.mp4)

- Tests: Cattle approaches from outside the route and creates a sharp crossing risk.
- Watch: Crossing vulnerability and adaptive envelopes.
- Highest risk: **0.704 at simulation 13.2 s** (video 14.7 s).
- Outcome: **GOAL_REACHED**; goal 1, safe termination 0, collision 0.
- Reason: Goal reached.
- Replans: 8; governor states: NORMAL -> CAUTIOUS -> CONSERVATIVE_STOP.
- Dominant actor changes observed: 0.
- Replay: `/Users/aditya1981/Downloads/SIH_Ps37/results/phase12/videos/all_scenarios/run_20260906_101738_201/replays/05_cattle_crossing.mat`
- Authoritative source: `/Users/aditya1981/Downloads/SIH_Ps37/results/phase11/run_20260906_050810_702/phase11Evaluation_20260906_050810_702.mat`
- Validation: VALIDATED, 22.4 video seconds, 224 encoded frames.

## 06 — Confidence Drop

[Watch video](phase9/06_confidence_drop.mp4)

- Tests: A continuous pedestrian track receives low-confidence measurements, then recovers.
- Watch: Confidence and uncertainty awareness.
- Highest risk: **0.641 at simulation 9.6 s** (video 11.1 s).
- Outcome: **GOAL_REACHED**; goal 1, safe termination 0, collision 0.
- Reason: Goal reached.
- Replans: 5; governor states: NORMAL -> CAUTIOUS.
- Source recovery criterion first met at 7.0 s (video 8.5 s); recovery does not necessarily mean goal completion.
- Dominant actor changes observed: 0.
- Replay: `/Users/aditya1981/Downloads/SIH_Ps37/results/phase12/videos/all_scenarios/run_20260906_101738_201/replays/06_confidence_drop.mat`
- Authoritative source: `/Users/aditya1981/Downloads/SIH_Ps37/results/phase11/run_20260906_050810_702/phase11Evaluation_20260906_050810_702.mat`
- Validation: VALIDATED, 20.2 video seconds, 202 encoded frames.

## 07 — Temporary Detection Loss

[Watch video](phase9/07_detection_loss.mp4)

- Tests: A moving auto is missed for six frames and later reappears with the same ID.
- Watch: Missed detections and track uncertainty.
- Highest risk: **0.589 at simulation 4.8 s** (video 6.3 s).
- Outcome: **GOAL_REACHED**; goal 1, safe termination 0, collision 0.
- Reason: Goal reached.
- Replans: 7; governor states: NORMAL -> CAUTIOUS.
- Source recovery criterion first met at 5.0 s (video 6.5 s); recovery does not necessarily mean goal completion.
- Dominant actor changes observed: 0.
- Replay: `/Users/aditya1981/Downloads/SIH_Ps37/results/phase12/videos/all_scenarios/run_20260906_101738_201/replays/07_detection_loss.mat`
- Authoritative source: `/Users/aditya1981/Downloads/SIH_Ps37/results/phase11/run_20260906_050810_702/phase11Evaluation_20260906_050810_702.mat`
- Validation: VALIDATED, 20.2 video seconds, 202 encoded frames.

## 08 — Sudden Direction Reversal

[Watch video](phase9/08_direction_reversal.mp4)

- Tests: A pedestrian initially moves away, reverses, and crosses toward the ego corridor.
- Watch: Direction-sensitive CPA.
- Highest risk: **0.693 at simulation 12.6 s** (video 14.1 s).
- Outcome: **SAFE_TERMINATION**; goal 0, safe termination 1, collision 0.
- Reason: Maximum simulation time reached safely.
- Replans: 38; governor states: NORMAL -> CAUTIOUS.
- Source recovery criterion first met at 12.2 s (video 13.7 s); recovery does not necessarily mean goal completion.
- Dominant actor changes observed: 0.
- Limitation: ended at the simulation horizon, not at the goal. Final physical speed 6.00 m/s; do not call this a stationary stop.
- Replay: `/Users/aditya1981/Downloads/SIH_Ps37/results/phase12/videos/all_scenarios/run_20260906_101738_201/replays/08_direction_reversal.mat`
- Authoritative source: `/Users/aditya1981/Downloads/SIH_Ps37/results/phase11/run_20260906_050810_702/phase11Evaluation_20260906_050810_702.mat`
- Validation: VALIDATED, 28.6 video seconds, 286 encoded frames.

## 09 — Multiple Simultaneous Risks

[Watch video](phase9/09_multiple_risks.mp4)

- Tests: A car and pedestrian create overlapping, actor-specific crossing risks.
- Watch: Scene-wide dominant risk selection.
- Highest risk: **0.694 at simulation 3.8 s** (video 5.3 s).
- Outcome: **GOAL_REACHED**; goal 1, safe termination 0, collision 0.
- Reason: Goal reached.
- Replans: 16; governor states: NORMAL -> CAUTIOUS.
- Source recovery criterion first met at 26.0 s (video 27.5 s); recovery does not necessarily mean goal completion.
- Dominant actor changes observed: 5.
- First dominant-actor change: 2.8 s.
- Replay: `/Users/aditya1981/Downloads/SIH_Ps37/results/phase12/videos/all_scenarios/run_20260906_101738_201/replays/09_multiple_risks.mat`
- Authoritative source: `/Users/aditya1981/Downloads/SIH_Ps37/results/phase11/run_20260906_050810_702/phase11Evaluation_20260906_050810_702.mat`
- Validation: VALIDATED, 30.6 video seconds, 306 encoded frames.

## 10 — Temporary Path Obstruction

[Watch video](phase9/10_temporary_obstruction.mp4)

- Tests: A long crossing vehicle temporarily invalidates the active route and then clears.
- Watch: Temporary path obstruction.
- Highest risk: **0.477 at simulation 14.2 s** (video 15.7 s).
- Outcome: **GOAL_REACHED**; goal 1, safe termination 0, collision 0.
- Reason: Goal reached.
- Replans: 13; governor states: NORMAL -> CAUTIOUS.
- Source recovery criterion first met at 8.2 s (video 9.7 s); recovery does not necessarily mean goal completion.
- Dominant actor changes observed: 0.
- Replay: `/Users/aditya1981/Downloads/SIH_Ps37/results/phase12/videos/all_scenarios/run_20260906_101738_201/replays/10_temporary_obstruction.mat`
- Authoritative source: `/Users/aditya1981/Downloads/SIH_Ps37/results/phase11/run_20260906_050810_702/phase11Evaluation_20260906_050810_702.mat`
- Validation: VALIDATED, 24.6 video seconds, 246 encoded frames.

## 11 — Replan Failure Recovery

[Watch video](phase9/11_replan_failure_recovery.mp4)

- Tests: A laterally moving vehicle wall first blocks distant planning, then the active path, and clears.
- Watch: Failed planning, braking and later recovery.
- Highest risk: **0.660 at simulation 7.4 s** (video 8.9 s).
- Outcome: **GOAL_REACHED**; goal 1, safe termination 0, collision 0.
- Reason: Goal reached.
- Replans: 7; governor states: NORMAL -> CAUTIOUS.
- Source recovery criterion first met at 9.0 s (video 10.5 s); recovery does not necessarily mean goal completion.
- Dominant actor changes observed: 8.
- First dominant-actor change: 1.6 s.
- Replay: `/Users/aditya1981/Downloads/SIH_Ps37/results/phase12/videos/all_scenarios/run_20260906_101738_201/replays/11_replan_failure_recovery.mat`
- Authoritative source: `/Users/aditya1981/Downloads/SIH_Ps37/results/phase11/run_20260906_050810_702/phase11Evaluation_20260906_050810_702.mat`
- Validation: VALIDATED, 32.6 video seconds, 326 encoded frames.

## 12 — Conservative Stop Recovery

[Watch video](phase9/12_stop_recovery.mp4)

- Tests: Two crossing risks force a genuine stop and then clear without a manual state reset.
- Watch: STOP hysteresis and physical braking.
- Highest risk: **0.757 at simulation 13.6 s** (video 15.1 s).
- Outcome: **SAFE_TERMINATION**; goal 0, safe termination 1, collision 0.
- Reason: Maximum simulation time reached safely.
- Replans: 23; governor states: NORMAL -> CAUTIOUS -> CONSERVATIVE_STOP.
- Source recovery criterion first met at 8.4 s (video 9.9 s); recovery does not necessarily mean goal completion.
- Dominant actor changes observed: 2.
- First dominant-actor change: 22.8 s.
- Limitation: ended at the simulation horizon, not at the goal. Final physical speed 6.00 m/s; do not call this a stationary stop.
- Replay: `/Users/aditya1981/Downloads/SIH_Ps37/results/phase12/videos/all_scenarios/run_20260906_101738_201/replays/12_stop_recovery.mat`
- Authoritative source: `/Users/aditya1981/Downloads/SIH_Ps37/results/phase11/run_20260906_050810_702/phase11Evaluation_20260906_050810_702.mat`
- Validation: VALIDATED, 30.6 video seconds, 306 encoded frames.

## 13 — Rapid Risk Fluctuation

[Watch video](phase9/13_rapid_risk_fluctuation.mp4)

- Tests: A pedestrian reverses near risk thresholds to exercise governor hysteresis.
- Watch: Hysteresis under changing risk.
- Highest risk: **0.660 at simulation 9.4 s** (video 10.9 s).
- Outcome: **GOAL_REACHED**; goal 1, safe termination 0, collision 0.
- Reason: Goal reached.
- Replans: 10; governor states: NORMAL -> CAUTIOUS.
- Source recovery criterion first met at 16.8 s (video 18.3 s); recovery does not necessarily mean goal completion.
- Dominant actor changes observed: 0.
- Replay: `/Users/aditya1981/Downloads/SIH_Ps37/results/phase12/videos/all_scenarios/run_20260906_101738_201/replays/13_rapid_risk_fluctuation.mat`
- Authoritative source: `/Users/aditya1981/Downloads/SIH_Ps37/results/phase11/run_20260906_050810_702/phase11Evaluation_20260906_050810_702.mat`
- Validation: VALIDATED, 21.4 video seconds, 214 encoded frames.

