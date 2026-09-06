# Milestone 1 audit — genuine IDD bring-up

Audit date: 2026-09-07. MATLAB execution: 2026-09-06, as recorded in the
timestamped status and regression files. Project: `/Users/aditya1981/Downloads/SIH_Ps37`.

**Milestone 1 is NOT COMPLETE.** The genuine-data portion stopped cleanly because
the IDD root is unconfigured. YOLOX support is also absent, and local free disk
is below the smoke-training guard. No licensed dataset was downloaded, no raw
images were copied into the repository, and no real-data results were fabricated.

Dataset-independent bring-up and tests completed. All 13 required regression
suites passed; unavailable genuine-data and RoadRunner-runtime checks remain
explicit skips. Full IDD training and final quantitative evaluation are outside
this milestone and were not started.

## Executed status

| Stage | Actual result |
| --- | --- |
| IDD dataset configuration | NOT CONFIGURED |
| Genuine IDD parsing | NOT RUN |
| Annotation validation | NOT RUN |
| Training datastore | NOT RUN |
| YOLOX environment | INCOMPLETE / MISSING |
| Supported GPU | NOT AVAILABLE |
| Smoke training | PENDING YOLOX SUPPORT; also blocked by missing data and disk headroom |
| Model save/reload | NOT RUN |
| Genuine inference | NOT RUN |
| IDD → canonical image detections | NOT RUN on genuine detections; schema contracts pass |
| Full IDD training | NOT PART OF MILESTONE 1 |
| Core regression | 13/13 suites PASS, with stated conditional skips |

## Required 34-item audit

1. **Actual IDD root:** empty string. `IDD_ROOT` was also empty. No configured
   external directory was found or scanned. The example external SSD path below
   is not asserted to exist.
2. **Dataset variant:** configured target `IDD_DETECTION`, annotation format
   `VOC_XML`; no downloaded variant/release verified.
3. **Genuine image count:** UNKNOWN / NOT MEASURED, not an invented zero.
4. **Genuine annotation count:** UNKNOWN / NOT MEASURED.
5. **Train image count:** UNKNOWN / NOT MEASURED.
6. **Validation image count:** UNKNOWN / NOT MEASURED.
7. **Genuine discovered classes:** NONE DISCOVERED because parsing did not run.
8. **Instance counts per class:** NOT AVAILABLE. No class inventory or dataset
   summary was generated from assumed labels/counts.
9. **Project class mapping:** existing centralized mapping retained and tested,
   including autorickshaw → auto, person → pedestrian, unknown fallback and
   no promotion of animal into cattle. These are mapping contracts, not evidence
   that labels occur in a local dataset. Actual-label mapping proof is pending.
10. **Invalid annotation count:** UNKNOWN / NOT MEASURED; genuine XML was not
    parsed. No annotation validation report claiming zero errors was fabricated.
11. **Annotation overlay count:** 0 genuine annotation-check overlays. Also
    0 genuine augmentation-check images. Both await the external dataset.
12. **Datastore status:** NOT RUN. Existing reference-based datastore machinery
    reused; source-image/label/box checks await real files.
13. **YOLOX availability:** `yoloxObjectDetector` and `trainYOLOXObjectDetector`
    both absent; required Automated Visual Inspection Library for Computer
    Vision Toolbox add-on absent. No substitute detector or automatic add-on
    installation. [MathWorks requirement](https://www.mathworks.com/help/vision/ref/yoloxobjectdetector.html).
14. **Deep Learning Toolbox:** AVAILABLE. `trainingOptions` resolves to the
    installed MATLAB function; its path is recorded in the environment report.
15. **Computer Vision Toolbox:** AVAILABLE. Parallel Computing Toolbox also
    AVAILABLE. These toolboxes alone do not establish YOLOX availability.
16. **GPU:** no MATLAB-supported GPU available; available count 0, GPU name
    `NONE`. This is MATLAB capability, not a claim that the Mac lacks graphics
    hardware.
17. **Selected smoke model:** prepared `tiny-coco` transfer-learning profile.
    No YOLOX model initialized; no pretrained weights downloaded.
18. **Smoke subset size:** actual selected subset NONE. Prepared limits are
    32 train and 32 validation images, seed 125, sampled within official splits.
    Existing sampling is uniform/seeded, not claimed to be stratified or to
    guarantee every class. At least 20 held-out validation images are required
    by the new evidence checks.
19. **Smoke epochs/iterations:** 0 executed. Prepared maximum one epoch by
    default, batch one, 320×320×3 input, learning rate 1e-4 and SGDM. No loss,
    iteration count or accuracy invented.
20. **Training execution environment:** NOT EXECUTED. Configuration requests
    `auto`; available fallback is CPU only, subject to practical smoke limits.
    No full-dataset CPU job launched. Entry measured 3.70 GiB available versus
    the existing 5 GiB smoke-training guard; post-regression shell check showed
    approximately 3.3 GiB. Free space is dynamic. Guards remain enabled.
21. **Training duration:** N/A; no training executed.
22. **Checkpoint status:** NONE produced.
23. **Saved smoke detector path:** NONE.
24. **Model reload status:** NOT RUN.
25. **Genuine inference status:** NOT RUN.
26. **Inference overlay count:** 0. No synthetic or unrelated road images used
    as IDD evidence.
27. **Example genuine detections:** NONE AVAILABLE. No boxes, confidences or
    classes invented as detector output.
28. **Canonical mapping proof:** independent schema/semantic tests PASS;
    genuine IDD → YOLOX → canonical image packet proof NOT RUN.
29. **No fabricated metric state:** confirmed by schema/adapter tests. Image
    records remain pixel bboxes/classes/confidences; no guessed metric position,
    velocity, yaw or dimensions are supplied to ACARG/CPA. A future calibrated
    state estimator is explicitly required.
30. **testIDDIntegration:** **47 passed, 0 failed, 18 skipped**, 65 total.
    Ten added checks cover milestone smoke configuration, no FULL/DEVELOPMENT,
    tiny model, no geometric augmentation/resume, disk guards, external-root
    override and exact environment capability fields. The 18 existing genuine
    data/model cases skip because data is unconfigured, not falsely pass.
    [Integration results](integration_test_results.csv) and
    [regression log](regression_20260906_220702_769/testIDDIntegration.txt).
31. **Full core regression:** all 13 requested suites PASS:
    testPerception, testTracking, testOccupancy, testPlanning, testACARG,
    testClosedLoop, testPhase8Scenarios, testPhase9Robustness,
    testRoadRunnerIntegration, testPhase11Evaluation, testPhase12Demo,
    testIDDIntegration and testScenarioVideoExport. RoadRunner: 28 static checks
    PASS, 12 runtime checks SKIPPED, 0 FAIL. Video suite: 40 PASS, 0 FAIL.
    [Regression summary](regression_20260906_220702_769/regression_summary.csv).
32. **Existing evidence preservation:** PASS, 491 files checked, no mismatches.
    Baseline SHA-256/byte-size verification covers pre-existing Phase 11/12 files, including the 13 final scenario
    videos and 39 screenshots. See [verification](evidence_verification.json)
    and [baseline](evidence_baseline.json). Finder `.DS_Store` and derived replay
    cache are excluded. The required Phase 11 regression produced one new
    timestamped run, not repeated exports. No scenario videos were regenerated
    or deleted. Core autonomy/config/scenario/Phase 12 rendering source remains
    unchanged. Existing IDD integration-result/architecture artifacts were
    refreshed by the existing test harness; these are not claimed immutable.
33. **Remaining blockers:** manually obtained licensed IDD-Detection and a
    configured external root; required MATLAB YOLOX add-on/functions; safe local
    training headroom; actual short-run CPU feasibility or supported GPU.
    All new real-data checks/training branches still require validation on
    genuine files. No actual parser/class/overlay/model success is claimed.
34. **Readiness for Milestone 2:** NOT READY for full training. Complete real
    data parsing, source/annotation/augmentation checks, genuine smoke training,
    checkpoint reload and held-out inference first. No Milestone 2 work,
    hyperparameter tuning, final mAP optimization, segmentation, depth,
    RoadRunner runtime, report/slides or demo editing begun.

## Exact configuration and rerun instructions

The shared autonomy [config.m](../../../config.m) is frozen and intentionally
has no persistent IDD field. The isolated empty-root default is in
[getIDDConfig.m](../../../perception/idd/getIDDConfig.m), line 4. Prefer setting
`cfg.idd.root` in your calling script or MATLAB Command Window:

```matlab
cd('/Users/aditya1981/Downloads/SIH_Ps37');
addpath(genpath(pwd));
cfg.idd.root = "/Volumes/ExternalSSD/datasets/IDD_Detection";
result = mainMilestone1IDD(cfg); % Inspect/validate; training remains disabled.
```

Replace the example with the real external extraction containing `JPEGImages`
and `Annotations`. Retain official train/validation lists; do not create a random
replacement split. No raw dataset belongs in this repository. Setting `IDD_ROOT`
instead of passing `cfg.idd.root` is also supported.

The [environment report](environment_report.txt) and
[status snapshot](milestone1Status_20260906_220643_898.mat) record the executed
missing-prerequisite branch. No dataset provenance/class-count/annotation CSVs
were created without data. This is intentional, not missing fabricated evidence.

Install the missing YOLOX component manually using MathWorks' instructions when
appropriate. Supply sufficient training headroom without deleting authoritative
evidence. CPU smoke, if practical, remains bounded and opt-in. The existing
180-second callback budget cannot interrupt a single slow training iteration.

## Implementation delivered, distinct from execution proof

- [mainMilestone1IDD.m](../../../mainMilestone1IDD.m): capability/disk/root
  preflight, clean missing-data stop, source-backed validation before optional
  smoke, checkpoint reload, held-out inference and honest status reporting.
- [getIDDMilestone1Config.m](../../../perception/idd/getIDDMilestone1Config.m):
  isolated tiny-model SMOKE profile and guardrails; core config unchanged.
- [validateIDDMilestoneData.m](../../../perception/idd/validateIDDMilestoneData.m):
  references existing genuine records/datastores; prepares 20 ground-truth,
  20 source/datastore consistency and 10 augmentation checks when data exists.
  Per-split inventory derives from accepted actual annotations; rejected/difficult
  and clipping issues remain explicit. Test annotations are not used.
- Existing environment structure extended compatibly with `TrainYOLOXAvailable`,
  `TrainingOptionsAvailable`, `YOLOXAddonAvailable` and `Reason`.
- [Evidence checker](../../../tests/verifyIDDMilestoneEvidence.cjs): refuses
  baseline overwrite and verifies preserved Phase 11/12 files.

The real-data branch is implemented but **unexecuted against genuine IDD**.
No automatic fake fixture was substituted to call it tested. Annotation and
augmentation overlays require visual inspection once genuine data becomes
available. Future smoke overlays are explicitly labelled
`SMOKE MODEL - NOT FINAL ACCURACY`; any inherited smoke-subset evaluation is
diagnostic only, never a final benchmark result.

Image-to-world boundary: IDD RGB → YOLOX → raw/mapped class, pixel bbox,
confidence → **future calibrated state estimator required** → metric
position/velocity/yaw and CPA-ready state. That estimator is not part of this work.

Stopped for user review at the current Milestone 1 prerequisite boundary.
