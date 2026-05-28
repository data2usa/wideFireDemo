# Wildfire Coordination Scenario — EdgeWorks + reView

**Working title:** "Bear Creek Fire — wind-shift response, coordinated across the edge"
**Audience:** trade-show booth visitors, utility operators, emergency-management leads, ATCO Ventures
**Runtime:** ~6–10 minutes at the booth
**Use:** synthetic data set + reView graph demo

---

## 1. Why this scenario

The brownout demo proved EdgeWorks + reView can coordinate **electrical** assets under stress. Wildfire is the natural next demo because it shows the same platform answering a question utilities, municipalities, and emergency managers all share:

> **"The wind just shifted. Who is at risk now, and what do we do about it?"**

The scenario is deliberately simple:

- A handful of EdgeWorks cubes deployed across a fire-prone valley
- A small set of sensors per cube (anemometer, temp/RH, smoke, thermal cam)
- One fire ignition
- One **wind-shift event** part way through the timeline
- The reView graph re-computes the risk envelope and re-routes the response

Everything else — assets, recommendations, approvals, executions — re-uses the node/edge vocabulary already established in the NECL brownout scenario.

---

## 2. The setting — Bear Creek Valley

A small foothills community in Alberta, surrounded by mixed forest, with a single utility substation, a gas regulating station, a 138 kV line, and one paved evacuation highway. Five EdgeWorks cubes are deployed across the valley:

| Cube ID         | Location              | Role                                  |
|-----------------|-----------------------|---------------------------------------|
| `EW-RIDGE-N`  | North ridge, 1,650 m  | Upwind sentinel — first to see weather changes |
| `EW-RIDGE-S`  | South ridge, 1,580 m  | Opposite sentinel — confirms wind shifts |
| `EW-VALLEY-W` | West valley floor     | Smoke / PM2.5 ground truth, thermal sweep |
| `EW-TOWN-E`   | East edge of town     | Community-facing air quality + alerts |
| `EW-SUB-A`    | ATCO substation site  | Asset-protection cube (utility-owned) |

These five cubes give the demo enough geographic spread that a wind shift produces a visibly different risk pattern across the graph — but few enough nodes to keep a booth graph readable.

---

## 3. The cube and its sensors (mapped to the four-interface model)

Every cube exposes the same canonical interfaces defined in the EdgeWorks taxonomy (`sigInt`, `finInt`, `aiInt`, `opsInt`). For wildfire, the sensor payload per cube is:

**`sigInt` — raw signal-level telemetry**
- `anemometer` — wind speed (m/s) and wind direction (° from N)
- `thermo_hygro` — air temperature (°C), relative humidity (%)
- `pm_sensor` — PM2.5 (µg/m³), PM10 (µg/m³)
- `thermal_cam` — max scene temperature (°C), hotspot bounding boxes
- `optical_cam` — RGB frame (used by the on-cube classifier)

**`aiInt` — AI-derived outputs (on-cube inference)**
- `fire_detector` — `fire_present: bool`, `confidence: 0..1`
- `smoke_classifier` — `smoke_present: bool`, `density_class: light|med|heavy`
- `spread_estimator` — `vector_deg: float`, `rate_mps: float` (derived from wind + RH + fuel-dryness proxy)

**`opsInt` — operational state**
- `cube_health` — battery, solar charge state, link quality to upstream
- `sensor_health` — per-sensor alarm flags (e.g., anemometer iced over)

**`finInt` — economic / consumption**
- `power_draw_w` — cube power consumption (used for solar/battery budget)
- (Not central to the demo, but present so the model is consistent with the rest of EdgeWorks.)

The graph treats each of these as an **Interface** node hanging off the Cube node, exactly as in the brownout scenario.

---

## 4. The assets at risk

Each asset is a node in the graph with a known location and a known sensitivity to fire/heat/smoke. The scenario now covers **13 assets** spread across the valley:

| Asset ID          | Type                | Notes                                                    |
|-------------------|---------------------|----------------------------------------------------------|
| `TOWN-BEAR`       | Community           | ~600 residences; primary protected entity                |
| `SUB-BEAR-1`      | Substation (ATCO)   | 138/25 kV, feeds the town and valley                     |
| `LINE-NE-7`       | Transmission line   | 138 kV, north-south through the valley                   |
| `GAS-REG-3`       | Gas regulating stn  | High-pressure, fenced compound                           |
| `HWY-11-N`        | Highway (north)     | Primary egress north under pre-shift conditions          |
| `HWY-11-S`        | Highway (south)     | Alternate egress south; becomes primary after wind shift |
| `STAGE-1`         | Firefighter staging | Initial position west of the fire                        |
| `COMMS-TOWER-2`   | Comms repeater      | Provides cube uplink for `EW-RIDGE-S`                  |
| `BEAR-HOSPITAL`   | Hospital            | Bear Creek Health Centre — 28 beds, emergency dept; critical priority |
| `BEAR-SCHOOL`     | School              | Bear Creek K-12 School — 380 students, 42 staff; priority evacuation |
| `SOUTH-HAMLET`    | Community           | South Valley Hamlet — 140 residents; directly in SSE cone after shift |
| `HWY-3`           | Highway (E-W)       | Crowsnest Highway 3 — main east-west artery; ~3 200 vehicles/day     |
| `WATER-TREAT`     | Utility             | Bear Creek Water Works — 2 400 m³/day; ember contamination risk      |

Every asset has an `AT_RISK_FROM` edge candidate to any active fire — the graph turns it on or off based on the **current** wind-driven spread vector.

The addition of the hospital, school, south hamlet, and water works makes the human-safety dimension of the scenario explicit and gives the booth audience assets they immediately care about. `HWY-3` is the cross-valley artery; its closure affects all routing options in both the NE and SSE phases.

---

## 4a. Support assets (firefighting and evacuation infrastructure)

Eight support assets are pre-positioned in the valley and activated/redeployed as the fire evolves. Unlike the protected assets above, these are not *at risk from* the fire — they are the response infrastructure that *follows* the risk envelope as conditions change.

**NE flank package (active pre-shift):**
- `FIRE-HALL-W` — Fire Hall West: pumper crew on NE flank standby
- `REC-CTR-N` — Reception Centre North: evacuee muster point for east sector (capacity 400)
- `HELIPAD-1` — Helipad Alpha: air tanker coordination for NE operations
- `TANKER-FILL-1` — Tanker Fill Valley: water resupply point for NE ground crews

**SSE flank package (activated post-shift):**
- `FIRE-HALL-S` — Fire Hall South: pumper crew for SSE coverage
- `REC-CTR-W` — Reception Centre West: evacuee muster point for South Hamlet (capacity 250)
- `HELIPAD-2` — Helipad Beta: air tanker coordination for SSE operations
- `FUEL-CACHE-S` — Fuel Cache South: forward fuel depot for relocated crew

At T+28 when the wind shift is detected, the NE package begins redeployment while the SSE package activates. By T+30 the transition is complete — the support infrastructure follows the risk envelope. This is captured in graph as `ExecutionAction` nodes `EX-FIRE-001-F` (NE mobilisation) and `EX-FIRE-002-H` (SSE mobilisation + NE stand-down).

---

## 5. The story — timeline

All times are minutes from ignition (`t=0`). Everything is synthetic but plausible.

### t = 0 — Ignition
- `EW-RIDGE-N` thermal camera sees a hotspot at 312°C on the north slope.
- On-cube `fire_detector` fires: `fire_present=true, confidence=0.94`.
- A `Fire` node `FIRE-BEAR-001` is created in the graph and linked back to the cube/sensor/reading that detected it.

### t = 3 — Confirmation
- `EW-VALLEY-W` `pm_sensor` shows PM2.5 climbing from 8 → 95 µg/m³.
- `smoke_classifier` on `EW-VALLEY-W`: `smoke_present=true, density_class=med`.
- Two independent cubes now corroborate the fire → confidence promoted on the `FIRE-BEAR-001` node.

### t = 5 — Initial wind vector and first risk envelope
- Cubes report consistent wind:
  - `EW-RIDGE-N`: 15 km/h from **240°** (WSW)
  - `EW-VALLEY-W`: 12 km/h from **235°**
  - `EW-RIDGE-S`: 14 km/h from **245°**
- `spread_estimator` (run on the central reView reasoner using the cube readings) returns a spread vector pointing **NE** at ~1.2 m/s.
- The graph turns on `AT_RISK_FROM` edges:
  - `TOWN-BEAR` ← `FIRE-BEAR-001` (NE of fire, in spread cone; score 0.78)
  - `LINE-NE-7` ← `FIRE-BEAR-001` (score 0.71)
  - `HWY-11-N` ← `FIRE-BEAR-001` (north segment; score 0.65)
  - `BEAR-HOSPITAL` ← `FIRE-BEAR-001` (health centre in NE cone; score 0.85 — highest priority)
  - `BEAR-SCHOOL` ← `FIRE-BEAR-001` (380 students in NE cone; score 0.77)
  - `HWY-3` ← `FIRE-BEAR-001` (eastern valley approach in NE corridor; score 0.60)
- First recommendation `REC-FIRE-001`:
  1. Evacuate east sector of `TOWN-BEAR` (preventive)
  2. Evacuation order for `BEAR-HOSPITAL` (critical care priority)
  3. Evacuation order / lockdown for `BEAR-SCHOOL` (380 students)
  4. Pre-position crews from `STAGE-1` toward NE flank
  5. Notify ATCO ops — prepare to de-energize `LINE-NE-7` if flame front advances within 500 m

### t = 12 — Approval and execution
- Incident commander approves `REC-FIRE-001` → `APP-FIRE-001`.
- Execution actions fan out:
  - `EX-FIRE-001-A` — evacuation order via municipal alerting
  - `EX-FIRE-001-B` — crew redeployment
  - `EX-FIRE-001-C` — ATCO standby on `LINE-NE-7`
- Each execution gets a confirmation edge from a downstream system (the same `ExecutionResult → CONFIRMS → ExecutionAction` pattern as the brownout demo).

### t = 28 — **The wind shifts** (this is the headline graph moment)
- `EW-RIDGE-N` anemometer is first to register the change: wind direction rotates from **240° → 305°** (WSW → NW) over 90 seconds, speed bumps from 15 → 22 km/h.
- `EW-VALLEY-W` confirms within 60 seconds (it's downwind of the ridge).
- `EW-RIDGE-S` confirms shortly after with a stronger reading: 28 km/h from **310°**.
- `EW-TOWN-E` and `EW-SUB-A` lag — they're sheltered by terrain — which is itself a useful tell that this is a real terrain-driven shift, not a sensor glitch.
- The graph now has **divergent wind readings across cubes**, and the reasoner uses the spatial layout to interpolate a new spread vector.

### t = 30 — New risk envelope, new at-risk assets
- `spread_estimator` re-runs → new spread vector points **SSE** at ~1.8 m/s (faster, drier air).
- The graph flips `AT_RISK_FROM` edges:
  - **Drops:** `HWY-11-N` (north segment), `BEAR-HOSPITAL`, `BEAR-SCHOOL`, NE flank of `TOWN-BEAR`
  - **Adds:** `SUB-BEAR-1`, `GAS-REG-3`, `HWY-11-S` (south segment), `COMMS-TOWER-2`, `SOUTH-HAMLET`, `WATER-TREAT`
  - **`HWY-3`** remains at risk — now as the western valley approach in the SSE spread corridor
- `STAGE-1` itself is now upwind-adjacent and flagged — the crew staging area is no longer safe.
- `SOUTH-HAMLET` (140 residents) is directly in the SSE cone — the highest-urgency new addition after the shift.
- `WATER-TREAT` faces ember contamination risk; intake shutdown protocol is available via SCADA.

This is the visual moment for the booth: **the same fire node, the same cube nodes, but a completely different set of red edges** when the wind shifts.

### t = 32 — Re-plan
- Reasoner produces `REC-FIRE-002` that **SUPERSEDES** `REC-FIRE-001`:
  1. De-energize `LINE-NE-7` (no longer in the spread cone, but a precautionary isolate)
  2. **Isolate `GAS-REG-3`** — close upstream block valve via remote SCADA
  3. **Open the substation breaker at `SUB-BEAR-1`** to shed the south feeder (protect the substation, accept localized outage)
  4. Relocate crews from `STAGE-1` to a new staging point west of the highway
  5. Switch evacuation route from `HWY-11-N` to `HWY-11-S` (still clear of the new spread cone)
  6. **Evacuation order for `SOUTH-HAMLET`** — 140 residents via municipal alerting
  7. **Intake shutdown for `WATER-TREAT`** — close intake valves, activate backup supply
- Each rejected candidate (e.g., "hold position", "evacuate west") is kept on the graph as a `CONSIDERED_BY` edge with the reason — same provenance pattern as the brownout demo.

### t = 35 — Approval, execution, confirmations
- IC approves `REC-FIRE-002`.
- ATCO ops approves the de-energize + breaker-open under their envelope (auto, because the substation is now inside an active fire envelope — a `RegulatoryCondition`-style rule).
- `GAS-REG-3` block valve closes; confirmation comes back via the gas SCADA system.
- Crew relocation acknowledged.

### t = 55 — Stabilize
- Wind holds steady at ~310°; cubes report consistent readings across the valley.
- PM2.5 on `EW-TOWN-E` peaks and starts to fall.
- Fire perimeter, as observed by the thermal cameras on `EW-RIDGE-N` and `EW-RIDGE-S`, stops advancing south.

### t = 90 — Audit
- A `WildfireIncidentAudit` node (`AUDIT-BEAR-2026-001`) is created.
- It links to: the fire, every cube/sensor reading that contributed, both recommendations, both approvals, every execution action and its confirmation, and the wind-shift event itself.
- An emergency-management regulator can replay the entire incident from the graph alone.

---

## 6. What the graph looks like

Node families (re-using the EdgeWorks/NECL vocabulary):

- **Equipment side:** `Box (Cube)`, `Subsystem`, `Component`, `Interface (sigInt|aiInt|opsInt|finInt)`
- **Observation side:** `Reading`, `Detection`, `Fire`, `WindObservation`, `SpreadEstimate`
- **Asset side:** `Asset` (with subtypes `Community`, `Substation`, `TransmissionLine`, `GasFacility`, `Highway`, `StagingArea`, `CommsAsset`)
- **Risk side:** `RiskZone`, `AT_RISK_FROM` edges
- **Decision side:** `Recommendation`, `Approval`, `ExecutionAction`, `ExecutionResult`, `AuditRecord`
- **Governance:** `RegulatoryCondition` (e.g., "asset inside active fire envelope → auto-approve isolate")

The headline edges to highlight in the demo:

```
(Cube)-[:HOSTS]->(Interface)-[:PRODUCES]->(Reading)
(Reading)-[:CONTRIBUTES_TO]->(SpreadEstimate)
(SpreadEstimate)-[:DEFINES]->(RiskZone)
(Asset)-[:AT_RISK_FROM]->(Fire)            // toggled by RiskZone membership
(Recommendation)-[:DERIVED_FROM]->(SpreadEstimate)
(Recommendation)-[:SUPERSEDES]->(Recommendation)
(Approval)-[:APPROVES]->(Recommendation)
(ExecutionAction)-[:EXECUTES]->(Approval)
(ExecutionResult)-[:CONFIRMS]->(ExecutionAction)
(AuditRecord)-[:DOCUMENTS]->(Fire)
```

---

## 7. The "wow" moment for the booth

There are really only two slides to remember:

1. **Before the wind shift:** the graph lights up `TOWN-BEAR`, `LINE-NE-7`, `HWY-11-N`, `BEAR-HOSPITAL`, `BEAR-SCHOOL`, and `HWY-3` as at-risk. Evacuation orders go out for the hospital and school. Crews move NE.
2. **After the wind shift:** the *same* graph, with new readings from the *same* cubes, lights up `SUB-BEAR-1`, `GAS-REG-3`, `HWY-11-S`, `COMMS-TOWER-2`, `STAGE-1`, `SOUTH-HAMLET`, `WATER-TREAT`, and `HWY-3` (now the western approach). The previous at-risk assets fade. A new recommendation appears, supersedes the old one, and fans out into approvals and executions — including evacuation of South Hamlet and shutdown of the water intake.

The visitor sees that **the cubes did not change, the assets did not change, the graph did not change — only the readings changed — and yet the entire response plan re-organized itself**. That's the EdgeWorks + reView pitch in one screen.

---

## 8. What we'd build to demo this

For the trade-show data set, we need:

1. **Cube + sensor YAML** for the five cubes — re-use the BRS YAML pattern; add sensor types listed in §3.
2. **A synthetic telemetry stream** (`events.jsonl` style, like the brownout demo) covering t=0 → t=90, with the wind shift baked in at t=28.
3. **An asset list** (§4) as a small CSV or YAML, with coordinates so the spread cone can be computed geometrically.
4. **A reView graph load script** (Cypher) that ingests the YAML + telemetry + assets and turns on/off the `AT_RISK_FROM` edges as the wind vector changes.
5. **Two pre-baked Cypher queries** to drive the booth visualization:
   - `q_assets_at_risk_now.cypher` — show currently-red edges
   - `q_decision_chain.cypher` — for any execution, walk back to the cube readings that justified it
6. **A 60-second auto-loop** for the booth screen that replays the timeline and pauses on the wind-shift moment.

Variants we can offer (mirroring the brownout demo's variant pattern):

- `happy_path` — the timeline above
- `cube_offline` — `EW-RIDGE-N` loses its uplink during the wind shift; `EW-RIDGE-S` and `EW-VALLEY-W` still detect it (resilience story)
- `false_alarm` — `EW-VALLEY-W` thermal cam triggers on a hot rock; second-cube corroboration prevents a bad recommendation (precision story)
- `gas_isolation_fail` — `GAS-REG-3` block valve doesn't confirm; a follow-up recommendation supersedes and dispatches a field crew (failure-handling story)

---

## 9. What this proves at the booth

- EdgeWorks cubes work as a **distributed sensor mesh**, not just per-site telemetry.
- reView turns that mesh into a **single, queryable picture of risk** that updates as conditions change.
- The **same graph model** handles utility brownouts and wildfire response — one vocabulary, many scenarios.
- Decisions are **auditable end-to-end**: every red edge traces back to a cube, a sensor, a reading, a time.
- The platform is **operationally honest**: when the wind shifts, the response re-plans; when a cube goes offline, the others carry the case.

---

— End of story document —
