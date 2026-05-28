// =============================================================================
// Wildfire Scenario - Demo Queries
// Run after schema.cypher + load.cypher.
// =============================================================================


// -----------------------------------------------------------------------------
// Q1. Which assets are at risk RIGHT NOW (at a given timestamp)?
//     Drives the booth "red edges" view.
// -----------------------------------------------------------------------------
// Replace $now with the moment you want to inspect, e.g.:
//   :param now => datetime('2026-08-15T14:20:00Z');     // before the shift
//   :param now => datetime('2026-08-15T14:40:00Z');     // after the shift
MATCH (a:Asset)-[r:AT_RISK_FROM]->(f:Fire)
WHERE r.activeFrom <= $now
  AND (r.activeTo IS NULL OR r.activeTo >= $now)
RETURN f.id  AS fire,
       a.id  AS asset,
       a.subtype AS subtype,
       r.score AS score,
       r.reason AS reason,
       r.zoneId AS zone
ORDER BY r.score DESC;


// -----------------------------------------------------------------------------
// Q2. The wind-shift moment: how did each cube see it?
// -----------------------------------------------------------------------------
MATCH (c:Cube)<-[:HAS_SUBSYSTEM*0..]-(c)
WITH c
MATCH (c)-[:HAS_SUBSYSTEM]->(:Subsystem)-[:HAS_COMPONENT]->(:Component)
      -[:HAS_SENSOR]->(s:Sensor {kind:'anemometer'})-[:PRODUCES]->(wo:WindObservation)
WHERE wo.at >= datetime('2026-08-15T14:27:00Z')
  AND wo.at <= datetime('2026-08-15T14:31:00Z')
RETURN c.id AS cube, wo.at AS at, wo.dir_deg AS dir_deg,
       wo.speed_mps AS speed_mps, wo.note AS note
ORDER BY wo.at;


// -----------------------------------------------------------------------------
// Q3. Full provenance for the new (post-shift) recommendation.
//     Walks: REC -> SpreadEstimate -> contributing WindObservations -> Sensors -> Cubes.
// -----------------------------------------------------------------------------
MATCH (rec:DispatchRecommendation {id:'REC-FIRE-002'})
      -[:DERIVED_FROM]->(se:SpreadEstimate)
      <-[:CONTRIBUTES_TO]-(wo:WindObservation)
      <-[:PRODUCES]-(s:Sensor)
      <-[:HAS_SENSOR]-(:Component)
      <-[:HAS_COMPONENT]-(:Subsystem)
      <-[:HAS_SUBSYSTEM]-(c:Cube)
RETURN rec.id, se.id, se.vector_deg, se.rate_mps,
       wo.id, wo.dir_deg, wo.speed_mps,
       s.id, c.id
ORDER BY wo.at;


// -----------------------------------------------------------------------------
// Q4. Rejected alternatives for the chosen plan.
// -----------------------------------------------------------------------------
MATCH (rej:DispatchRecommendation)-[c:CONSIDERED_BY]->(ok:DispatchRecommendation {id:'REC-FIRE-002'})
RETURN rej.id AS candidate, c.rank, c.reason, rej.summary;


// -----------------------------------------------------------------------------
// Q5. End-to-end audit chain for one execution.
//     Pick any execution id, e.g. 'EX-FIRE-002-B' (the gas isolation).
// -----------------------------------------------------------------------------
MATCH (er:ExecutionResult)-[:CONFIRMS]->(ex:ExecutionAction {id:'EX-FIRE-002-B'})
MATCH (ex)-[:EXECUTES]->(app:Approval)-[:APPROVES]->(rec:DispatchRecommendation)
MATCH (rec)-[:DERIVED_FROM]->(se:SpreadEstimate)
OPTIONAL MATCH (rec)-[:SUPERSEDES]->(prev:DispatchRecommendation)
RETURN ex.id, ex.action, ex.target,
       app.id, app.approverType, app.approverId,
       rec.id, rec.summary,
       prev.id AS supersedes,
       se.id,  se.vector_deg, se.rate_mps,
       er.id,  er.status, er.note;


// -----------------------------------------------------------------------------
// Q6. The supersede chain for this incident.
// -----------------------------------------------------------------------------
MATCH p = (newer:DispatchRecommendation)-[:SUPERSEDES*]->(older:DispatchRecommendation)
WHERE newer.id STARTS WITH 'REC-FIRE-'
RETURN [n IN nodes(p) | n.id] AS chain,
       newer.proposedAt AS newerAt;


// -----------------------------------------------------------------------------
// Q7. Cube health view (which cubes detected which kind of thing).
// -----------------------------------------------------------------------------
MATCH (c:Cube)-[:HAS_SUBSYSTEM]->(:Subsystem)-[:HAS_COMPONENT]->(:Component)
      -[:HOSTS]->(i:Interface)-[:EMITS]->(d:Detection)
RETURN c.id AS cube, i.kind AS interface, d.kind AS detection,
       d.confidence, d.at
ORDER BY d.at;


// -----------------------------------------------------------------------------
// Q8. Regulator packet: everything the AuditRecord documents.
// -----------------------------------------------------------------------------
MATCH (au:AuditRecord {id:'AUDIT-BEAR-2026-001'})-[:DOCUMENTS]->(n)
RETURN labels(n) AS labels, n.id AS id,
       coalesce(n.summary, n.note, n.action, n.kind, '') AS detail
ORDER BY labels;


// -----------------------------------------------------------------------------
// Q9. Booth one-shot: BEFORE vs AFTER side-by-side counts.
// -----------------------------------------------------------------------------
MATCH (a:Asset)-[r:AT_RISK_FROM]->(:Fire {id:'FIRE-BEAR-001'})
WITH r.zoneId AS zone, collect(a.id) AS assets
RETURN zone, assets, size(assets) AS n
ORDER BY zone;


// -----------------------------------------------------------------------------
// Q10. Which assets had their risk status FLIP across the wind shift?
//      (in pre-shift set XOR post-shift set)
// -----------------------------------------------------------------------------
MATCH (a:Asset)-[:AT_RISK_FROM {zoneId:'RZ-001'}]->(:Fire {id:'FIRE-BEAR-001'})
WITH collect(a.id) AS pre
MATCH (a:Asset)-[:AT_RISK_FROM {zoneId:'RZ-002'}]->(:Fire {id:'FIRE-BEAR-001'})
WITH pre, collect(a.id) AS post
RETURN
  [x IN pre  WHERE NOT x IN post] AS dropped_off,
  [x IN post WHERE NOT x IN pre]  AS newly_at_risk,
  [x IN post WHERE x IN pre]      AS still_at_risk;
