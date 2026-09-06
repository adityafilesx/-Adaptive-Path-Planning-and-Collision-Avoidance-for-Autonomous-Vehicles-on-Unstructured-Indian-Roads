# Phase 12.6 — all-scenario replay export

This is the MATLAB **closed-loop simulation evidence** branch, independent of
IDD dataset, YOLOX and GPU availability. It does not claim real-camera autonomy
or RoadRunner execution. User confirmation leaves `cfg.idd.root` unconfigured.

```matlab
addpath(genpath(pwd));
result = mainPhase12_6();
testScenarioVideoExport(result.videos.runDirectory);
```

The main entry reports IDD as pending and exports/revalidates all five Phase 8
scenarios and eight Phase 9 robustness scenarios. Defaults reuse the latest
saved complete/resumable manifest rather than rerun simulation. A renderer-1
manifest is rejected; use the current renderer-2 set.

```matlab
% Explicit existing run: validates completed clips and continues missing ones.
v = exportAllScenarioVideos(struct('runDirectory', "/path/to/run_directory"));

% New rendering from an existing replay inventory; no simulation rerun.
v = exportAllScenarioVideos(struct('reuseComplete',false, ...
    'replayInventoryFile', "/path/to/replay_inventory.csv"));
```

## Source fidelity

The source is a pinned Phase 11 MAT with `POST_PHASE9_FIX` and
`PHASE9_TIME_WEIGHTED_DISTANCE_V1` provenance. Its benchmark and robustness
records, not older standalone Phase 8 results, determine all outcomes.
The same source remains pinned even if regression subsequently generates a
newer Phase 11 evaluation.

Existing presentation frames/cache are reused read-only where their source and
complete logs match. Otherwise, one deterministic instrumentation run fills
missing path/prediction vertices and must exactly match original ego history,
actor history, full frame logs and metrics. Any mismatch stops export. Saved
compact replays reference the original source and preserve source timing rather
than replacing it with the instrumentation run's planner timings.

No frozen autonomy modules or Phase 12 functions are edited. Renderer 2 wraps
the original Phase 12 renderer and corrects a presentation-only ambiguity:
`pathReplaced=false` does not imply a failed initial plan. Replan captions now
use `planningSucceeded`, actual path safety and desired speed. Failed replanning
with a safe retained path is distinguished from a zero target-speed command.

## Encoding and evidence

Each video is 1440×900 at 10 fps, with a 1.5-second title and 3-second final card.
MP4/H.264 is used when MATLAB's writer supports it; otherwise Motion JPEG AVI is
explicitly selected. All source states are displayed at 1x simulation time.
Repeated raster frames fill the source sample interval; values are not interpolated.
The last replay sample gets one 0.1-second frame before the final card.
No wall-clock rendering delays are interpreted as simulation time.

Outputs:

- `results/phase12/videos/all_scenarios/<run_id>/phase8/`: five clips.
- `.../phase9/`: eight clips.
- `video_manifest.csv`: identity, source, outcome, physical result, timing,
  resolution, screenshot paths and renderer version.
- `VIDEO_INDEX.md`: challenge, what to notice, actual key/recovery timestamps,
  outcome, dominant-actor changes and limitations.
- Each clip has a `.timeline.csv`, `.events.csv` and `.mat` validation sidecar.
- `results/phase12/screenshots/all_scenarios/<run_id>/`: initial, highest-risk
  and final replay frame for each scenario — 39 required screenshots.

`validateScenarioVideo` decodes **every encoded frame**, checks frame count,
duration/resolution, verifies the timeline includes every saved log state,
compares manifest outcomes/metrics with the saved replay and checks screenshots.
It also compares the decoded title and final card with source-derived rendered
cards (text-region PSNR greater than 34 dB), checking encoded identity/outcome
rather than relying only on file names and sidecars.
`testScenarioVideoExport` additionally compares all 13 replay logs and metrics
against the original Phase 11 evidence, tests special-scenario events and rejects
corrupt manifest metadata. Video tests fail, not skip, when coverage is incomplete.

Free-space guards run before replay capture/export and every 20 simulation frames.
Existing clips are never overwritten. A failed partial clip without its sidecar
must be retained/moved to a clearly named incomplete-artifact folder before
retrying that filename; it cannot silently count as completed evidence.

## Interpretation notes

Urban remains **SAFE_TERMINATION** due to the safe planning failure guard.
Direction Reversal and STOP Recovery also end with source-classified safe
termination at the simulation horizon. Their recovery criteria can be met without
reaching the goal. Final cards show actual physical speed: a time-limit safe
termination is not a claim that the vehicle is stationary.

Confidence, uncertainty contributions, CPA, dominant actor, physical speed and
target speed are read from actual records. STOP does not imply instant braking
to rest. Governor entry/exit and recovery are shown by the recorded event timeline.
The road strip is schematic, not a fabricated road-surface model. The stable
viewport explicitly reports actors outside it; all source actors remain in the
replay. Old Cattle clips and Phase 11 evidence are retained unchanged.

The first all-scenario pass is marked `SUPERSEDED_PRESENTATION.md` because visual
QA found the inherited initial-plan caption ambiguity. Its verified replays are
reused, while renderer-2 clips form the final unique 13-scenario set.

## IDD readiness, without execution claims

`getIDDExecutionConfig` selects YOLOX-tiny for constrained SMOKE and YOLOX-small
for DEVELOPMENT/FULL. `validateIDDExecutionEnvironment` reports required
functions, toolboxes, Parallel Computing, GPU and execution environment.
`runIDDFullTraining` refuses CPU-only FULL execution and requires explicit flags,
disk space, real external data and a genuine completed smoke proof including
checkpoint, reload and inference. `mainPhase12_6` writes a safe disabled
GPU-profile configuration, not a trained model. No add-on, weights or dataset is
downloaded automatically. The real-data path still requires runtime validation
after the user supplies IDD and MATLAB YOLOX capability.

MATLAB API references: [VideoWriter](https://www.mathworks.com/help/matlab/ref/videowriter.html),
[YOLOX requirements](https://www.mathworks.com/help/vision/ref/yoloxobjectdetector.html).

## Completed evidence

The final renderer-2 run is `run_20260906_150800_374`: 13 validated MP4s and
39 scenario screenshots. See the [complete Phase 12.6 audit](../../results/phase12/phase12_6_audit/PHASE12_6_AUDIT.md)
and [video index](../../results/phase12/videos/all_scenarios/run_20260906_150800_374/VIDEO_INDEX.md).
The separate regression harness, not the export entry itself, ran all 22
required suites/entry points. No genuine IDD execution is claimed.
