# Phase 12.5 audit — 6 September 2026

## Outcome and stop condition

| Area | Status | Evidence/meaning |
| --- | --- | --- |
| IDD integration architecture | COMPLETE | Dataset-independent contracts, factory, adapters and guarded workflow implemented |
| IDD dataset parsing | PENDING DATASET | No configured external dataset; no real annotations parsed |
| YOLOX smoke training | PENDING DATASET | Not executed; YOLOX capability is also missing |
| Full IDD training | NOT RUN | No dataset, trained artifact or supported GPU available |
| IDD validation | NOT RUN | No genuine validation predictions, mAP, AP, PR curves or overlays |
| IDD → canonical adapter | PASS | Image/schema/semantic tests only; **not** metric state estimation |

This is **not** an “IDD training complete” report. Work stops at the user's
missing-dataset boundary. There are no fabricated IDD images, annotations,
training losses, accuracy numbers, checkpoints or model-performance claims.

## Implemented scope

- Separate `ImageDetection` (pixels, class, confidence) and unchanged legacy
  `CanonicalActorDetection` (metric state) contracts.
- Shared canonical packet and class/confidence table; source selector under
  `integration/perception`, default `SIMULATED`. Existing phase entry points
  keep their original simulation path. The selector is not injected into frozen
  tracking, prediction, ACARG or planning code.
- External-root and symlink-aware path guards, official split handling,
  VOC XML parser, box validation, malformed-object reporting, actual-label
  class summaries, reference-based datastores and seeded within-split subsets.
- Central semantic aliases, preserving animal versus cattle and keeping
  unsupported pushcart/rider labels unknown. No assumed trainable ontology.
- MATLAB YOLOX transfer initialization, opt-in profiles, disk/compute guards,
  checkpoint/model versioning, weight-continuation resume, genuine-validation
  evaluation wrapper and real-image overlay/demo workflow.
- Explicit depth/calibration/sensor-fusion error boundary. No fabricated metric
  positions, velocities, physical CPA or pixel-to-world conversion.
- Architecture PNG, setup documentation, conditional tests and regression audit.

The real-data/training functions are **implemented but unvalidated against IDD
and the missing YOLOX add-on**. In particular, release-specific annotation layout,
YOLOX runtime API compatibility, checkpoint recovery and training/evaluation
outputs remain to be checked during a genuine smoke run. Weight continuation
does not restore optimizer/scheduler state. No segmentation or temporal image
tracking has been added.

## Environment and provenance

MATLAB R2026a Update 5 on macOS (Apple silicon). Computer Vision and Deep Learning
Toolbox are installed. `trainingOptions`, `imageDatastore`, `boxLabelDatastore`,
`objectDetectorTrainingData` and `evaluateObjectDetection` are available.
`yoloxObjectDetector` and `trainYOLOXObjectDetector` are absent. The Automated
Visual Inspection Library for Computer Vision Toolbox is not installed.
MATLAB-supported GPU count: **0**; this does not mean the Mac has no physical GPU.

Dataset variant is configured as `IDD_DETECTION`, but release/version and actual
train/validation/test counts are **unverified/unknown**, not inferred from a website.
No `dataset_class_summary.csv`, trained model, training checkpoint or detection
overlay was generated. The architecture PNG is the only illustrative image from
the new module and is explicitly not real-perception evidence.

Free disk space fluctuated materially during graphics-heavy regression. The
guard blocked tasks below 0.30 GiB and resumed work in a fresh MATLAB process
only after sufficient space was observed. No prior evidence or user files were
deleted; no IDD data, pretrained weights or add-ons were downloaded.

## Verification

| Suite | Latest verified result |
| --- | --- |
| testPerception | All existing checks passed |
| testTracking | All existing checks passed |
| testOccupancy | All existing checks passed |
| testPlanning | All existing checks passed |
| testACARG | 18 passed, 0 failed |
| testClosedLoop | 25 passed, 0 failed |
| testPhase8Scenarios | 30 passed, 0 failed |
| testPhase9Robustness | 35 passed, 0 failed |
| testRoadRunnerIntegration | 28 platform-independent passed; 12 runtime skipped on macOS |
| testPhase11Evaluation | 35 passed, 0 failed |
| testPhase12Demo | 35 passed, 0 failed |
| testIDDIntegration | 37 passed, 0 failed, 18 genuine-data/model checks skipped |

The IDD suite has **55 checks**. Numeric `SCHEMA_TEST` boxes exercise contracts,
not a fabricated IDD dataset. It verifies simulation-record preservation,
equivalent tracker/ACARG results on known simulation geometry, shared semantics,
no image Position/Velocity fields, the metric boundary, clipping, invalid boxes,
confidence, class mapping, training opt-in and disk guards.

All requested main entry points executed successfully after the storage and
audit-harness rechecks:

| Main | Final result |
| --- | --- |
| mainPhase6 | PASS |
| mainPhase7 | PASS |
| mainPhase8 | PASS |
| mainPhase9 | PASS |
| mainPhase10 | PASS — architecture complete; runtime pending on macOS |
| mainPhase11 | PASS — fresh evaluation/evidence generation |
| mainPhase12 | PASS — headless replay, no autonomy parameter changes |
| mainPhase12_5 | PASS — architecture complete, genuine data/training pending |

Phase 12 used only `visible='off'`, `animate=false`, `holdFinalFrame=false` to
make the replay suitable for batch validation. Final replay reached the goal
without a collision and verified its replay values. Successful execution of
`mainPhase12_5` means its graceful missing-data behavior passed, not that training ran.
MATLAB Code Analyzer inspected all 39 new `.m` files without reported syntax
errors; its 19 messages are style/unused-variable or suppression notices, retained
in [the analyzer log](code_analyzer.txt). Actual YOLOX runtime validation remains pending.

Evidence:

- [Consolidated final regression status](final_regression_summary.csv)
- [Initial full regression](regression_20260906_045748_028/regression_summary.csv)
- [RoadRunner/IDD recheck and remaining mains](regression_20260906_050429_649/regression_summary.csv)
- [Isolated legacy main-script recheck](regression_20260906_050544_825/regression_summary.csv)
- [IDD test details](integration_test_results.csv)
- [RoadRunner boundary recheck](roadrunner_boundary_recheck.txt)
- [Architecture diagram](idd_perception_architecture.png)

Audit findings resolved without editing frozen code/tests:

1. The existing RoadRunner independence audit scans all core `.m` files for
   runtime references. Moving the new source factory to `integration/perception`
   and the regression runner to `tests` restored **28/28** checks unchanged.
2. Legacy main scripts call `clear`; the audit runner now invokes them in a
   disposable workspace so they cannot erase audit status variables.
3. Initial console-log character/string serialization was corrected. ASCII logs
   were mechanically recovered with an exact encoding round-trip check; their
   original encoded versions are retained alongside them. This did not change
   test execution or assertions. Subsequent logs are directly readable.

Existing source/config/test files in Phases 2–12 were not changed. Pre-existing
Finder `.DS_Store` changes were left alone. New timestamped simulation evidence
was generated only by the requested regression suites/entry points.

## Required next step

Manually obtain the licensed **IDD-Detection** package from the
[official download portal](https://idd.insaan.iiit.ac.in/dataset/download/), and
extract it onto a sufficiently large external dataset volume. Set `cfg.idd.root`
to the directory containing **JPEGImages** and **Annotations**, with official
train/validation split lists (or explicit `trainList`/`valList` paths).

```matlab
cfg = config();
cfg.idd = getIDDConfig(struct('root', "/Volumes/Datasets/IDD_Detection"));
report = mainPhase12_5(cfg); % inspection only; no training/download opt-in
```

The path is an example, not an existing local dataset. Use the
[setup guide](../../perception/idd/README.md) for exact layout, label policy,
profile settings, storage guards, model loading and explicit smoke opt-in.
Install the [MathWorks YOLOX add-on](https://www.mathworks.com/help/vision/ref/yoloxobjectdetector.html)
before smoke training. DEVELOPMENT/FULL require a MATLAB-supported GPU and
sufficient storage; FULL additionally requires explicit profile selection and
enable flags. Even a trained RGB detector will not supply metric actor state.
