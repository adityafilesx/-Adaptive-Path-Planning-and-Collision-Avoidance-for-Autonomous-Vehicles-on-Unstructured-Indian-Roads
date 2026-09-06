# Phase 12.5: IDD image perception

This module adds a separate, opt-in MATLAB YOLOX front end. It does not alter
the existing simulation, tracker, ACARG, planner, controller or Phase 12 demo.
The dataset-independent architecture is implemented. Real IDD parsing,
training, inference and accuracy validation are **pending genuine data and
YOLOX capability**; their code has not been validated against a real dataset
on this machine. Architecture completion is not model completion.

## Get the correct dataset manually

Download **IDD-Detection**, subject to its official license/login, from the
[official IDD download portal](https://idd.insaan.iiit.ac.in/dataset/download/).
The [IIIT dataset catalogue](https://insaan.iiit.ac.in/datasets/) lists the
original detection package at approximately 22.8 GB. That is a published
download size, not an observed local image count or extraction-space estimate.
Allow additional room for extraction, checkpoints and trained models.

Use an external drive/dataset volume, **outside this repository**. Do not put
images under `SIH_Ps37`, even through a symlink to a repository directory.
No download, image copying or add-on installation is performed by this module.
Only `cfg.idd.root` or `IDD_ROOT` is inspected; the user's drive is not scanned.

The supported layout follows the official
[AutoNUE detection documentation](https://github.com/AutoNUE/public-code):

```text
<external IDD-Detection extraction>/
  JPEGImages/<capture category>/<drive sequence>/<image>.jpg
  Annotations/<capture category>/<drive sequence>/<image>.xml
  ImageSets/Main/train.txt       (or train.txt at the root)
  ImageSets/Main/val.txt         (or val.txt at the root)
  ImageSets/Main/test.txt        (optional)
```

The root must point to the directory **containing JPEGImages and Annotations**,
not to an archive, an image directory alone, or IDD segmentation/multimodal data.
If your official lists are elsewhere, set `trainList`, `valList`, `testList`
explicitly (absolute paths or relative to the dataset root). Each line must be
one relative image identifier, optionally including its extension. Class-specific
VOC lists with a second column are rejected. No random replacement split is made.
Different IDD variants/formats require a reviewed adapter, not silent conversion.

```matlab
addpath(genpath(pwd));
cfg = config();
cfg.idd = getIDDConfig(struct('root', "/Volumes/Datasets/IDD_Detection"));
report = mainPhase12_5(cfg);  % inspect only; training remains disabled
```

The path above is an example, not a claim that the volume exists. Alternatively,
set the `IDD_ROOT` environment variable and call `mainPhase12_5()`.
Default conversion needs 2 GiB free on the output volume; training needs 5 GiB,
FULL needs 10 GiB. These are minimum guards, not capacity guarantees. Set
`outputDir`/`checkpointDir` to a roomy external volume when appropriate.

## Contracts and source selection

`createPerceptionSource()` defaults to `SIMULATED`. `IDD_IMAGE` and `ROADRUNNER`
are dispatched at this boundary, never inside downstream algorithms.
The selector lives in `integration/perception`, keeping runtime references out
of core perception; the regression runner lives under `tests`.
Existing phase entry points continue their original direct simulation calls;
they are not rewired by this phase.

Every adapter returns a `CanonicalPerceptionPacket` with `Source`,
`CoordinateSpace`, `MetricReady`, `Detections`, `RequiredNextStage` and a shared
`Semantics` table (`DetectionID`, `Class`, `Confidence`, `IsDetected`). Numeric
simulation classes use the existing `cfg.tracking.classIDMap`; the original
metric records are unchanged. String simulation classes, including pushcart,
remain intact.

| Record | Geometry | Allowed downstream use |
| --- | --- | --- |
| `CanonicalActorDetection` | Existing Position/Velocity and uncertainty, metres/m/s | Existing metric tracking and autonomy |
| `ImageDetection` | BBox and BBoxCenter in pixels; no Position/Velocity | Class/confidence display; future calibrated state estimator |

Image records include original raw label, mapped class, confidence, image size,
frame name and source. `ClassID` indexes the **detector's class vocabulary**,
not official IDD ontology IDs. `DetectionID` is local to one frame, not a track ID.
Unknown timestamp is NaN. Boxes use one-based inclusive pixel coordinates:
`width = xmax-xmin+1`. Invalid/fully out-of-frame boxes are rejected; partial
boxes are clipped with a conversion report.

```matlab
source = createPerceptionSource("SIMULATED");
packet = source(struct('actorTruth', actorTruth, 'egoState', egoState), cfg);
% Only packet.MetricReady == true permits packet.Detections into metric tracking.
% packet.Semantics is shared with the image branch; it never supplies geometry.
```

`estimateActorStateFromVision` intentionally errors with
`IDD:MetricStateRequired`. No single-image CPA, metric velocity, depth, yaw or
physical dimensions are invented. ROADRUNNER accepts already calibrated metric
records only; this does not add RoadRunner runtime support on macOS. Optional
temporal image tracking, segmentation and sensor fusion are not implemented.

## Actual labels and split discipline

Classes are discovered from real XML `object/name` values. The provenance records
this **raw-label policy**, not an assumed official hierarchy level or benchmark
ontology. Configure `labelField` and `classHierarchy` together only after inspecting
the actual annotation release. `annotationVersion` starts `UNVERIFIED`.

The semantic aliases in `getIDDClassMapping` are not claims that labels occur:
autorickshaw → auto; person → pedestrian; motorcycle → motorcycle; animal → animal;
unsupported labels (including pushcart and rider) → unknown. Literal cattle can
map to cattle only if actually present; animal is never relabelled cattle.
Default trainable classes are recognized labels observed in TRAIN. Explicit
`targetLabels` must also occur in TRAIN. Excluded non-target classes are recorded.

Actual file counts, valid parsed counts, selected training/validation files,
raw labels, class frequencies, timestamp, MATLAB/toolbox versions and split paths
are recorded. Train/validation overlap and symlink duplicates are rejected. Test
annotations are never opened or used for tuning. Missing images/annotations and
malformed XML are logged. If any object is malformed, the whole image is excluded
to avoid training on incomplete positives. With `includeDifficult=false`, images
containing difficult objects are excluded for the same reason; this changes the
usable population and must be disclosed in comparisons. Empty valid annotations
remain genuine background images. Class summaries describe accepted records,
not rejected annotations or unverifiable published counts.

After genuine parsing, outputs include `dataset_class_summary.csv` and
`conversion_report.csv`. Their absence when data is missing is intentional.
Datastores reference original files; no duplicate image tree is created.
Subsets are uniform and seeded **within** official splits. No oversampling is used.
Augmentation uses mild brightness/contrast variation; optional reflection updates
every box consistently. It defaults off for road-direction semantics.

## YOLOX capability and training

This machine currently has Computer Vision and Deep Learning Toolbox, but no
`yoloxObjectDetector`, no `trainYOLOXObjectDetector`, no Automated Visual Inspection
Library add-on and zero MATLAB-supported GPUs. The environment report checks
functions, installed add-ons, toolboxes, disk space and available GPU count.

MATLAB YOLOX requires the
[Automated Visual Inspection Library for Computer Vision Toolbox](https://www.mathworks.com/help/vision/ref/yoloxobjectdetector.html).
Install it manually using MathWorks' documented procedure on a supported machine.
The training wrapper follows
[trainYOLOXObjectDetector](https://www.mathworks.com/help/vision/ref/trainyoloxobjectdetector.html).
No alternate framework/detector is silently substituted.

| Profile | Default train/validation subset | Epochs / batch | Purpose |
| --- | --- | --- | --- |
| SMOKE | 16 / 8 (hard limit 32 each) | 1 / 1 | Pipeline check, never final |
| DEVELOPMENT | 512 / 128 | 20 / 4 | Iteration, supported GPU required |
| FULL | Complete usable official splits | 80 / 8 | Explicit final training, supported GPU required |

SMOKE uses 320×320 input, FULL 640×640. A SMOKE callback stops after a default
180-second wall-time budget; a single slow iteration cannot be interrupted by
that callback. Budget termination is reported as STOPPED, not PASS. DEVELOPMENT
and FULL reject CPU-only operation. No hours/days of CPU training start by default.

After data, disk and capability checks pass, **explicit opt-in** is required:

```matlab
cfg.idd = getIDDConfig(struct('root', "/Volumes/Datasets/IDD_Detection", ...
    'profile', "SMOKE", 'enabled', true, 'runTraining', true, ...
    'allowWeightDownload', true));
report = mainPhase12_5(cfg);
```

`allowWeightDownload=true` permits MATLAB's pretrained nano-COCO initialization;
it does not download IDD. A compatible local `pretrainedDetectorFile` containing
a YOLOX `detector` with matching classes can be supplied instead. A COCO detector
alone is not IDD training. Local-file pretrained origin is user-supplied and must
be audited before any transfer-learning claim. Final training requires a freshly
configured `profile="FULL"` plus both explicit enable flags on suitable compute.

Checkpoints go to `results/idd/training/<run-id>/checkpoints/` (or the configured
external checkpoint root). Completed training calls save a known YOLOX-object
checkpoint. `resumeIDDYOLOXTraining(checkpointFile,cfg.idd)` continues its **weights**;
optimizer/scheduler state is reset. Bare-network checkpoints emitted by some
MATLAB versions are rejected, not silently wrapped. Exact interruption recovery
and installed add-on checkpoint compatibility remain pending real smoke validation.
No claim of bit-identical full-state resume is made.

Models are versioned under `results/idd/models/<run-id>/idd_yolox_detector.mat`;
existing model folders are never overwritten. They include detector, configuration,
hardware, dataset provenance, original trainingInfo, loss/learning-rate history,
epochs, iterations, duration and evaluation. Validation loss is available only if
the installed trainer returns it; AP is not substituted for loss. The semantic
mapping and per-class/global validation tables are also saved.

Evaluation uses real validation predictions and
[evaluateObjectDetection](https://www.mathworks.com/help/vision/ref/evaluateobjectdetection.html)
at IoU 0.50:0.05:0.95 with precision/recall curves and per-class AP summaries.
Subset scores must not be called full official benchmark results. Confusion is
explicitly marked not computed. Evaluation failure does not erase a completed
training checkpoint or become a fabricated metric.

```matlab
cfg.idd.detectorFile = "/path/to/models/SMOKE_<run-id>/idd_yolox_detector.mat";
demo = mainIDDPerceptionDemo(cfg);
```

The demo requires an IDD-trained artifact, selects up to 25 genuine validation
images for class coverage, draws raw-label → project-class + confidence, and
saves a source-image manifest. It never substitutes stock or fabricated images.
Dense-traffic, road type, illumination and small-object coverage need human review;
the script does not invent these scene attributes. A smoke model remains labelled
SMOKE. No competition-ready detection samples can be claimed before this runs.

## Verification and evidence

`testIDDIntegration` contains 55 checks: 37 independent contracts and 18 conditional
genuine-data/model checks. Numeric `SCHEMA_TEST` boxes test types and bounds only;
they are not fake IDD samples or model predictions. By default training tests skip.
For a real smoke test, supply the explicit SMOKE configuration above to
`testIDDIntegration(cfg.idd)`. Missing real data/models skip, actual configured
parsing failures fail. `runIDDRegressionAudit` runs the frozen prior suites and
mains in separate workspaces and records disk-blocked tasks explicitly. Phase 12
uses visibility/animation-only headless options; no autonomy settings are changed.

See `results/idd/PHASE12_5_AUDIT.md`, `integration_test_results.csv`, timestamped
status reports and regression logs for executed outcomes. The architecture PNG
is a diagram, not perception-performance evidence. No mAP, loss, training duration,
model artifact or IDD qualitative result is reported before genuine execution.
