# Wildfire Scenario — reView ingestible dataset

**[▶ Run demo (dark)](https://data2usa.github.io/wideFireDemo/demo.html?mode=dark) · [Run demo (light)](https://data2usa.github.io/wideFireDemo/demo.html?mode=light)**

Synthetic data set for the **Bear Creek Fire** demo. Story is in [wildfireStory.md](wildfireStory.md).

## Files

| File              | Purpose                                                                 |
|-------------------|-------------------------------------------------------------------------|
| `wildfireStory.md`| Narrative + design rationale for the booth demo.                        |
| `schema.cypher`   | Uniqueness constraints + indexes. Run once.                             |
| `load.cypher`     | Bootstrap (cubes, sensors, assets) + the full timeline of events.       |
| `events.jsonl`    | Same timeline as a streaming event log (EWCL-style). One JSON per line. |
| `queries.cypher`  | Ten demo queries for the booth screen.                                  |

## Load order (Neo4j / Memgraph)

```
1. schema.cypher    # constraints + indexes
2. load.cypher      # all nodes + edges (bootstrap + timeline)
3. queries.cypher   # interactive demo queries
```

For a streaming demo (replay through reView's ingest pipeline), feed `events.jsonl` in order — each line maps onto the same node/edge that `load.cypher` creates statically.

## What's in the graph

**Equipment (static):**
- 1 Grid, 1 Region
- 5 Cubes (`EW-RIDGE-N`, `EW-RIDGE-S`, `EW-VALLEY-W`, `EW-TOWN-E`, `EW-SUB-A`)
- Per cube: 1 Subsystem → 1 Component → 5 Sensors (anemometer, thermo_hygro, pm_sensor, thermal_cam, optical_cam) and 4 Interfaces (sigInt, aiInt, opsInt, finInt)
- 8 Assets (community, substation, transmission line, gas reg station, 2 highway segments, staging area, comms tower)
- 3 Operators, 1 Regulation, 1 RegulatoryCondition

**Timeline (dynamic):**
- t=0   ignition detected by `EW-RIDGE-N` thermal cam
- t=3   smoke corroboration on `EW-VALLEY-W`
- t=5   5 wind observations + `SPREAD-001` (NE) + `RZ-001` + 3 `AT_RISK_FROM` edges
- t=12  `REC-FIRE-001` → `APP-FIRE-001` → 3 executions + results
- t=28  **wind shift** — new wind observations from all 5 cubes
- t=30  `SPREAD-002` (SSE) + `RZ-002` + 5 new `AT_RISK_FROM` edges; pre-shift edges close via `activeTo`
- t=32  `REC-FIRE-002` **SUPERSEDES** `REC-FIRE-001`; 2 rejected candidates with `CONSIDERED_BY` edges
- t=35  `APP-FIRE-002` (human) + `APP-FIRE-002-ENV` (envelope, triggered by `REGCOND-ASSET-IN-FIRE-ENVELOPE`) → 5 executions + results
- t=55  stabilization detection on `EW-RIDGE-S`
- t=90  `AUDIT-BEAR-2026-001` with `DOCUMENTS` edges to fire, recs, approvals, all executions and results

## Node counts (approx)

| Label                     | Count |
|---------------------------|------:|
| Grid                      | 1     |
| Region                    | 1     |
| Cube                      | 5     |
| Subsystem                 | 5     |
| Component                 | 5     |
| Interface                 | 20    |
| Sensor                    | 25    |
| Asset                     | 8     |
| Operator                  | 3     |
| Regulation                | 1     |
| RegulatoryCondition       | 1     |
| Reading                   | 3     |
| Detection                 | 3     |
| Fire                      | 1     |
| WindObservation           | 10    |
| SpreadEstimate            | 2     |
| WildfireRiskZone          | 2     |
| DispatchRecommendation    | 4 (2 accepted + 2 rejected) |
| Approval                  | 3     |
| ExecutionAction           | 8     |
| ExecutionResult           | 8     |
| AuditRecord               | 1     |

## The "wow" query

Run `Q1` from `queries.cypher` twice — first with `$now = 14:20:00Z`, then with `14:40:00Z` — and watch the at-risk asset set completely turn over. Same cubes, same fire, same graph — only the readings changed.

## How AT_RISK_FROM edges handle time

Edges carry `activeFrom` and (optionally) `activeTo` properties — `activeTo IS NULL` means "still active." This keeps the audit chain intact: we don't delete edges when the wind shifts, we close the old ones and open new ones. `Q10` shows the before/after diff.

## Variants (not yet generated)

The story lists four variants — `happy_path` (this file), `cube_offline`, `false_alarm`, `gas_isolation_fail`. To generate variant data, fork this directory and edit the relevant sections of `load.cypher` / `events.jsonl`.
