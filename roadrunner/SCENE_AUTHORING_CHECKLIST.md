# RoadRunner scene-authoring checklist

Only RoadRunner may generate `.rrscene` and `.rrscenario` files. Use the manifest names exactly, set actor IDs explicitly, and preserve the manifest coordinate transform. If an authored road uses a different origin or heading, update the manifest orthonormal `positionRotation` and `translation`, then rerun all static conversion tests before runtime validation.

## Village Road (priority 1)

- [ ] Create/open the configured genuine RoadRunner project.
- [ ] Build an approximately 100 m narrow two-way road, nominal paved width 9 m.
- [ ] Remove lane markings; use irregular edges and dirt shoulders.
- [ ] Add modest village buildings, roadside vegetation, informal pedestrian space, and visually Indian context without relying on unavailable custom assets.
- [ ] Place `EgoVehicle` at canonical `[0,0,0]`, facing +X, stationary.
- [ ] Place actor ID 301, `VillagePushcart301`, at `[60,16]` with velocity `[0.5,-1.5]` m/s.
- [ ] Use a pushcart/vendor-cart asset if genuinely available; otherwise use the declared bicycle proxy. Keep canonical class `pushcart` and 2.0 x 1.0 m dimensions.
- [ ] Assign a straight constant-velocity trajectory that approximates the Phase 8 crossing.
- [ ] Save `VillageRoad.rrscene` and create/save `VillageRoad.rrscenario`.
- [ ] Verify no lane-rule behavior is introduced; challenge remains geometric/predictive.

## Urban Intersection (priority 2)

- [ ] Build an unsignalized cross intersection spanning at least X=[-10,115] m and Y=[-30,30] m.
- [ ] Avoid strict lane discipline and signal logic; add roadside buildings, pedestrian activity, cars/two-wheelers as nonlogical visual context only if they cannot affect simulation truth.
- [ ] Place `EgoVehicle` at `[0,0,0]`, facing +X, stationary.
- [ ] Place ID 401 `CrossingCar401` at `[65,18]`, velocity `[0,-2.2]` m/s.
- [ ] Place ID 402 `CrossingAuto402` at `[90,-18]`, velocity `[0,2.2]` m/s.
- [ ] Use an auto-rickshaw visual asset if genuinely available; otherwise use the compact-vehicle proxy but keep canonical class `auto` and 3.2 x 1.5 m dimensions.
- [ ] Assign straight crossing trajectories and no signal-dependent decisions.
- [ ] Save `UrbanIntersection.rrscene` and create/save `UrbanIntersection.rrscenario`.

For both scenes, verify visual pose against the MATLAB initial state, then follow `WINDOWS_VALIDATION_CHECKLIST.md`.
