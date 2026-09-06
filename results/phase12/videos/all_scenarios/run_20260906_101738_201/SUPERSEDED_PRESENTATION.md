# Superseded presentation — retain replays, not judge-facing videos

These first-pass videos decoded successfully and matched source outcomes, but
visual QA found an inherited initial-plan caption that incorrectly said
“PLAN FAILED / BRAKING” when the plan had succeeded. This is a presentation bug,
not a changed simulation result. Renderer version 2 corrects captions using
`planningSucceeded` and the actual speed/path-safety command.

The exact-verified replay MAT files in this directory remain authoritative
inputs for re-export. Use the later renderer-version-2 manifest/video index as
the final 13-video set. This first-pass set is retained for auditability and
must not be counted as additional unique scenario coverage.
