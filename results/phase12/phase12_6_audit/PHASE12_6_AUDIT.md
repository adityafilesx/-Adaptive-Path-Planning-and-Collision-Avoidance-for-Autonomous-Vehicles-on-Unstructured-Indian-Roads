# Phase 12.6 final audit

Date: 2026-09-06. Project: `/Users/aditya1981/Downloads/SIH_Ps37`.

**Status A — SCENARIO VIDEO EVIDENCE COMPLETE:** 5/5 Phase 8, 8/8 Phase 9,
13/13 validated MP4s, 39 scenario screenshots. All 40 new video tests pass.
All 22 required regression suites/entry points pass, with genuine-data and
platform-dependent skips explicitly retained.

**Status B — IDD PERCEPTION EXECUTION PENDING:** IDD dataset NOT CONFIGURED;
YOLOX UNAVAILABLE; supported GPU NOT AVAILABLE; genuine IDD parsing, training,
inference and evaluation PENDING. This follows the user's explicit instruction
to leave the external dataset root unconfigured and finish videos independently.

These videos are **MATLAB closed-loop simulation evidence**, not real IDD
perception or RoadRunner footage. Phase 13 has not begun.

## Final video set

Use only renderer-2 run `run_20260906_150800_374` for the final scenario set.
All clips are MP4/H.264, 1440 × 900, 10 fps, with a 1.5-second title,
1× simulation playback and a 3-second final card. Every saved simulation state
is represented; repeated visual frames preserve source sampling intervals.
The complete set contains 3,200 decoded frames and 320.0 video seconds.

| ID | Phase | Scenario / video | Actual outcome | Video seconds |
| --- | --- | --- | --- | ---: |
| 01 | 8 | [Unmarked Village Road](../videos/all_scenarios/run_20260906_150800_374/phase8/01_village_road.mp4) | GOAL_REACHED | 24.2 |
| 02 | 8 | [Unsignalized Urban Intersection](../videos/all_scenarios/run_20260906_150800_374/phase8/02_urban_intersection.mp4) | SAFE_TERMINATION | 15.6 |
| 03 | 8 | [Highway Slow-Vehicle Merge](../videos/all_scenarios/run_20260906_150800_374/phase8/03_highway_merge.mp4) | GOAL_REACHED | 21.8 |
| 04 | 8 | [Dense Mixed-Traffic Market](../videos/all_scenarios/run_20260906_150800_374/phase8/04_dense_market.mp4) | GOAL_REACHED | 27.2 |
| 05 | 8 | [Sudden Cattle Crossing](../videos/all_scenarios/run_20260906_150800_374/phase8/05_cattle_crossing.mp4) | GOAL_REACHED | 22.4 |
| 06 | 9 | [Confidence Drop](../videos/all_scenarios/run_20260906_150800_374/phase9/06_confidence_drop.mp4) | GOAL_REACHED | 20.2 |
| 07 | 9 | [Temporary Detection Loss](../videos/all_scenarios/run_20260906_150800_374/phase9/07_detection_loss.mp4) | GOAL_REACHED | 20.2 |
| 08 | 9 | [Sudden Direction Reversal](../videos/all_scenarios/run_20260906_150800_374/phase9/08_direction_reversal.mp4) | SAFE_TERMINATION | 28.6 |
| 09 | 9 | [Multiple Simultaneous Risks](../videos/all_scenarios/run_20260906_150800_374/phase9/09_multiple_risks.mp4) | GOAL_REACHED | 30.6 |
| 10 | 9 | [Temporary Path Obstruction](../videos/all_scenarios/run_20260906_150800_374/phase9/10_temporary_obstruction.mp4) | GOAL_REACHED | 24.6 |
| 11 | 9 | [Replan Failure Recovery](../videos/all_scenarios/run_20260906_150800_374/phase9/11_replan_failure_recovery.mp4) | GOAL_REACHED | 32.6 |
| 12 | 9 | [Conservative Stop Recovery](../videos/all_scenarios/run_20260906_150800_374/phase9/12_stop_recovery.mp4) | SAFE_TERMINATION | 30.6 |
| 13 | 9 | [Rapid Risk Fluctuation](../videos/all_scenarios/run_20260906_150800_374/phase9/13_rapid_risk_fluctuation.mp4) | GOAL_REACHED | 21.4 |

All 13 source scenarios report no observed collision. Urban's actual planning
failure guard is preserved: goal not reached, safe termination, no collision.
Direction Reversal and STOP Recovery terminate at their simulation horizons;
neither is relabeled as goal completion or a stationary final stop. Source
recovery times are distinct from goal-completion times.

## Complete requested audit: 48 items

1. **Genuine IDD dataset:** NOT CONFIGURED; no licensed data supplied.
2. **Actual root:** empty/unconfigured. The user's future example
   `/Volumes/ExternalSSD/datasets/IDD_Detection` is not an existing configured
   dataset claim. The selected external root must directly contain `JPEGImages`
   and `Annotations`; raw images will not be copied into the repository.
3. **Dataset variant:** IDD-Detection/VOC-XML is the configured target, not a
   verified downloaded release. Actual release/version remains unverified.
4. **Actual image counts:** PENDING; no counts invented.
5. **Actual annotation counts:** PENDING.
6. **Actual discovered labels:** PENDING genuine annotation parsing.
7. **Class distribution:** PENDING; no synthetic class-balance evidence produced.
8. **Project mappings:** centralized Phase 12.5 mapper retained. Genuine
   discovered-label mapping CSV remains pending; no unsupported cattle/pushcart
   classes manufactured.
9. **YOLOX environment:** UNAVAILABLE. `yoloxObjectDetector` and
   `trainYOLOXObjectDetector` are absent. MATLAB R2026a Update 5 on Apple-silicon
   macOS has Computer Vision, Deep Learning and Parallel Computing toolboxes;
   required YOLOX add-on functionality is absent. No automatic installation or
   weight download was attempted.
10. **GPU:** supported GPU NOT AVAILABLE (`gpuDeviceCount` availability check
    returns zero). No supported training-device name is claimed.
11. **SMOKE:** NOT RUN / PENDING genuine dataset and YOLOX. No completed
    backpropagation/checkpoint/reload/inference proof is claimed.
12. **FULL:** PENDING GPU EXECUTION, also requiring genuine data, YOLOX and a
    completed SMOKE proof. No CPU-only FULL training launched.
13. **Final detector path:** NONE; no genuine trained detector produced.
14. **Training configuration:** disabled, GPU-targeted profile saved to
    [gpu_ready_full_configuration.mat](../../idd/gpu_ready_full_configuration.mat).
    New Phase 12.6 defaults select `tiny-coco` for SMOKE and `small-coco` for
    DEVELOPMENT/FULL. FULL uses 640×640×3 input, batch 8, 80 configured epochs,
    learning rate 1e-4, SGDM, complete intended train/validation splits and seed
    125. These are prepared settings, not empirically validated hyperparameters.
    Configuration includes augmentation, disk guards and opt-in flags; training
    remains disabled. See [runIDDFullTraining.m](../../../runIDDFullTraining.m)
    for GPU, genuine-data and completed-SMOKE guards and migration instructions.
15. **Training duration:** N/A; no training executed.
16. **Global detection metrics:** PENDING, not zero and not estimated.
17. **Per-class detection metrics:** PENDING.
18. **Autorickshaw performance:** PENDING.
19. **Pedestrian performance:** PENDING.
20. **Two-wheeler performance:** PENDING.
21. **Car performance:** PENDING.
22. **Bus/truck performance:** PENDING.
23. **Animal performance:** PENDING genuine label availability and evaluation.
24. **Genuine IDD overlays:** 0. The 50-example annotation validation, 20+
    inference overlays and competition-overlay selection remain pending; no
    artificial images or XML annotations were substituted.
25. **Canonical mapping proof:** architecture/schema tests pass; genuine
    image → YOLOX → mapped-class/confidence/bbox proof remains PENDING.
26. **No fake world coordinates:** confirmed in image-schema tests. Image
    detections remain non-metric and are not fed directly into metric CPA.
    This is a PERCEPTION VALIDATION BRANCH, not closed-loop IDD autonomy.
27. **Phase 8 generated:** 5/5.
28. **Five Phase 8 files:** IDs 01–05 in the linked table above.
29. **Phase 9 generated:** 8/8.
30. **Eight Phase 9 files:** IDs 06–13 in the linked table above.
31. **Total video count:** 13 unique final-set scenario videos. Historical
    Cattle clips and the superseded first rendering are not counted again.
32. **Video validation:** 13/13 PASS. All encoded frames decoded; positive size,
    duration, expected frame count, 10 fps and 1440×900 checked. Timeline covers
    every source log state at its actual time. Source-derived title/final cards
    match the decoded text region at PSNR >34 dB. Replay logs and metrics are
    separately compared to the original authoritative Phase 11 records.
    See [video_validation_summary.csv](video_validation_summary.csv).
33. **Screenshots:** 39 required images, all 1440×900: initial, highest-risk and
    final replay state for every scenario under
    `results/phase12/screenshots/all_scenarios/run_20260906_150800_374/`.
    Additional decoded-card QA images are separate, not counted toward 39.
34. **Urban:** validated SAFE_TERMINATION. Final card explains SAFE PLANNING
    FAILURE GUARD / planner could not find a safe continuation. Source reason:
    “Safely stopped after repeated planning failures.” The final physical speed
    is nevertheless **1.97 m/s** in the source and on the card: the source's
    termination label/reason does not establish a completed stationary stop.
    No forced goal outcome or zero-speed value was substituted.
35. **Confidence Drop:** validated; actual confidence falls and returns, with
    confidence/uncertainty contributions, risk, envelopes and response drawn
    from replay. Recovery criterion at simulation 7.0 s; peak risk later at
    9.6 s, so the highest-risk screenshot is not claimed to be the confidence dip.
36. **Direction Reversal:** validated; actor lateral velocity changes sign.
    CPA and risk response use source values. Recovery criterion at 12.2 s;
    final outcome remains horizon SAFE_TERMINATION, not goal reached.
37. **STOP Recovery:** validated; real CONSERVATIVE_STOP state, zero desired
    speed, nonzero physical speed during braking, and subsequent exit are
    tested. Recovery criterion at 8.4 s; final horizon SAFE_TERMINATION retained.
38. **Manifest:** [video_manifest.csv](../videos/all_scenarios/run_20260906_150800_374/video_manifest.csv).
    Includes all requested columns plus source provenance, screenshot paths,
    true timing, termination reason and renderer version.
39. **Index:** [VIDEO_INDEX.md](../videos/all_scenarios/run_20260906_150800_374/VIDEO_INDEX.md).
    Every scenario has its challenge, watch points, source/video key times,
    recovery where applicable, outcome and ACARG interpretation.
40. **Phase 11 preservation:** all captured baseline files unchanged in size
    and SHA-256. New timestamped regression outputs are retained separately.
41. **Phase 12 preservation:** same verification, including old videos and
    screenshots. Combined baseline covers 195 files; no mismatch. See
    [verification](existing_evidence_verification.json) and
    [hash baseline](existing_evidence_sha256.json). Derived replay cache,
    `.DS_Store`, this audit directory and new all-scenario outputs are excluded
    from the original-evidence baseline. Cache is regenerable instrumentation.
42. **Frozen core:** no tracked MATLAB autonomy source changed. No behavioral
    edits to simulation, tracking, prediction, occupancy, ACARG/CPA, planning,
    replanning, controllers, dynamics or collision detection. No edits to the
    original Phase 12 renderer/tests. New wrapper corrects only presentation
    captions; false `pathReplaced` alone no longer means initial plan failure.
43. **testIDDIntegration:** 37 passed, 0 failed, 18 legitimate genuine-data/
    execution skips. [Log](regression_20260906_150927_503/testIDDIntegration.txt).
44. **testScenarioVideoExport:** 40 passed, 0 failed, no video skips.
    [Log](regression_20260906_201211_627/testScenarioVideoExport.txt).
45. **Full regression:** 22/22 task statuses PASS. All 13 requested test suites
    and all 9 entry points completed. RoadRunner architecture: 28 PASS;
    runtime: 12 SKIPPED, 0 FAIL. IDD skips as item 43. See the consolidated
    [regression_summary.csv](regression_summary.csv), including per-task logs.
    `mainPhase12_6` honestly reports that it does not itself run the separate
    regression audit; PASS here is grounded in the harness results.
46. **RoadRunner:** runtime PENDING WINDOWS/LINUX. No runtime launched and no
    3D validation claim made on macOS.
47. **Remaining limitations:** genuine IDD parsing, actual labels/splits,
    50-sample annotation/augmentation checks, training, metrics, genuine
    overlays and canonical inference proof all await external data/capability.
    GPU-ready code is architecture, not executed training proof. These are
    schematic 2D MATLAB replays, not real-camera driving evidence. Two
    robustness scenarios end at the horizon without reaching their goals.
    Urban's planning-failure guard ends with a recorded nonzero physical speed;
    its wording is not evidence of a stationary stop (item 34).
    Available local storage was approximately 4.6 GiB after final tests;
    FULL configuration requires at least 10 GiB and was not launched.
48. **Phase 13 readiness:** video evidence is ready for user review; IDD
    execution is not complete. No technical report, slides, pitch, final
    submission packaging, RoadRunner runtime or new autonomy algorithms begun.
    Stopped after this Phase 12.6 audit as requested.

## Provenance and implementation notes

Authoritative source used for all videos:
`results/phase11/run_20260906_050810_702/phase11Evaluation_20260906_050810_702.mat`,
with `POST_PHASE9_FIX` and `PHASE9_TIME_WEIGHTED_DISTANCE_V1` markers. Later
regression-generated runs do not silently replace this pinned source.

Where original presentation vertices were absent, deterministic instrumentation
was run once and required exact equality of ego/actor histories, full log and
metrics before retaining its display geometry. Existing matching Cattle replay
data was reused. Final export reused those saved verified replays, without
rerunning simulations for visual changes.

The first 13-video rendering is retained under `run_20260906_101738_201` and
marked `SUPERSEDED_PRESENTATION.md`: visual QA found the inherited initial-plan
caption ambiguity. Its `replays/` directory is still referenced by the final
manifest and must be retained. The final renderer-2 set corrects that caption.
Explicit comma-delimited CSV reads also prevent MATLAB's path-heavy delimiter
autodetection from losing an inventory row. No original evidence was deleted.

Implementation and rerun instructions: [scenario_video/README.md](../../../demo/scenario_video/README.md).
The collection helper [collectFinalEvidence.m](collectFinalEvidence.m) merges
the two completed regression runs and extracts decoded cards without changing
any source log or video.

Visual QA inspected the final Village title/card, Urban and STOP encoded final
cards, the encoded Confidence Drop dip, and replay highest-risk screenshots for
Confidence Drop, Direction Reversal, Multiple Risks and STOP Recovery. Labels,
source values, braking/target distinction and outcome cards were legible.
Decoded Urban and STOP cards are retained under [visual_qa](visual_qa/).
