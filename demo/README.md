# Phase 12: judge-facing MATLAB demo

Run from the project root with MATLAB R2026a and the project's existing toolboxes.
This is a diagnostic 2-D view, not RoadRunner footage or a real-world safety claim.

```matlab
addpath(genpath(pwd))
mainPhase12                                      % Cattle Crossing replay
mainPhase12(struct('mode','LIVE'))                % Real shared-loop simulation
mainPhase12(struct('mode','EXPORT'))              % MP4, screenshots, evidence
mainPhase12(struct('scenario','Confidence Drop')) % Secondary demo
mainPhase12(struct('showAdvancedExplanation',true,'showPerformance',true))
mainPhase12(struct('playbackSpeed',1))            % 1x simulation time
mainPhase12(struct('mode','EXPORT','visible','off','animate',false))
run('tests/testPhase12Demo.m')
```

`demoConfig()` owns presentation defaults. `mainPhase12` places them in its local
`cfg.demo`; supply any of those fields in the options struct. Autonomy settings in
`config.m` are not changed. `holdFinalFrame=true` keeps the window open. Closing
the window before completion cancels replay with a clear error.

## Architecture and fidelity

`loadDemoData` reads the newest timestamped Phase 11 evaluation. The original
Phase 11 logs contain all risk/control values, actor truth, and tracks, but omit
the active path and prediction vertices for intermediate frames.
`captureDemoData` fills that gap once through the existing simulator's opt-in
read-only presentation hook. It requires exact equality of ego history, actor
history, complete frame logs, and metrics before accepting the extra fields.
It never replaces the original evidence or its timing measurements.

Verified frames are cached under `results/phase12/cache/`, keyed by scenario and
checked against the source filename and full log. Subsequent REPLAY/EXPORT uses
saved frames without running a planner or recalculating risk. The first replay
after selecting a new Phase 11 source may take longer for this enrichment step.
LIVE always runs the shared simulator and renders each observer callback.
Rendering can make LIVE slower than real time; use REPLAY for consistent pacing.

`formatDemoState` copies values; `updateDemoFrame` renders them. Ellipses use the
same footprint geometry function, stored prediction covariance and logged
combined adaptive scale; they do not invent a larger presentation-only margin.
The ellipse shown is the current-time envelope, not the full future occupancy
union used by planning. Actor bodies use actual dimensions and yaw. Predictions
are distinguished from actor truth. The grey road strip is schematic context,
not a drivable-boundary constraint or imported scene. Canonical coordinates are
metres, +X forward, yaw in radians counterclockwise from +X.

Purple is the current planned path, replaced on actual planner updates. Teal is
the travelled trail. Replan messages last 0.8 simulation seconds and carry logged
reasons; full reasons remain in the event CSV. Risk and speed plots reveal only
frames up to the displayed timestamp. State is shown as text as well as colour.
The dominant actor is the logged maximum-risk actor, not the nearest actor.

`CONSERVATIVE_STOP` is a governor state, not a claim that physical speed instantly
becomes zero. Actual speed, desired speed and speed scale are separate. Unsafe
path braking is explicitly labeled. Collision is reported as observed so far;
only the final frame reports the completed outcome. Center-to-center distances
must not be described as physical vehicle-body clearance.

## Outputs and presentation use

Every run saves a timestamped summary MAT and event CSV beneath
`results/phase12`. EXPORT additionally writes timestamped directories:

- `videos/`: MPEG-4 when supported, otherwise Motion JPEG AVI; no external editor.
- `screenshots/`: A normal, B rising, C cautious, D largest envelope, E largest
  recorded lateral replan, F recovery, G final outcome. The summary records each
  actual frame/time/state/risk. These are selected events, not staged states.
- `figures/`: before/after **planned** paths, baseline-vs-ACARG **travelled** paths
  and outcomes, confidence evidence, and controlled CPA evidence; PNG and PDF.

The video duplicates exact simulation frames at 10 fps by default. At 0.5x,
0.2 simulation seconds occupy 0.4 video seconds; no new risk/state values are
interpolated. The final outcome adds one second when `holdFinalFrame=true`.
Interactive rendering may run slower on a busy machine; encoded video timing
is determined by timestamps, not wall-clock rendering duration.

Use the seven PNGs and four static PNG/PDF figures in later presentations.
The CPA figure reproduces the controlled geometry defined in
`runACARGAblation`, not a segment of the cattle replay. The confidence figure
uses Phase 11 values: confidence and measurement uncertainty vary together;
all four cases stay CAUTIOUS at speed scale 0.65. No STOP is fabricated.
Baseline comparison always refers to the paired Phase 11 cattle runs even when
the selected moving demo is Confidence Drop. Optional performance numbers are
labeled **Phase 11 global** and read from the selected source; they are neither
current-frame timings nor permanently hard-coded headline values.

RoadRunner runtime validation remains pending Windows/Linux. No RoadRunner,
Simulink graphics, Python, web dashboard, PPT, or video editor is required to run
Phase 12. The regression invokes earlier phases and may append new timestamped
benchmark results; it does not overwrite prior Phase 11 evidence.
