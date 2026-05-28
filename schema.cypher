// =============================================================================
// Wildfire Coordination Scenario - Graph Schema
// =============================================================================
//
// Companion: designs/wildFire/wildfireStory.md
// Re-uses node/edge vocabulary from NECL Brownout v1.1 where applicable.
//
// New / extended labels for wildfire:
//   (:EdgeWorks)                -- EdgeWorks unit (already in NECL substrate)
//   (:Subsystem)               -- four-tier physical model
//   (:Component)
//   (:Interface)               -- sigInt | aiInt | opsInt | finInt
//   (:Sensor)                  -- physical sensor attached to a Component
//   (:Reading)                 -- a single sensor sample at a timestamp
//   (:Detection)               -- an aiInt classification event
//   (:Fire)                    -- a confirmed fire incident
//   (:WindObservation)         -- normalized wind sample (speed_mps, dir_deg)
//   (:SpreadEstimate)          -- computed spread vector at a timestamp
//   (:WildfireRiskZone)        -- spatial risk envelope (re-used from NECL)
//   (:Asset)                   -- with subtype Community|Substation|TransmissionLine|
//                                 GasFacility|Highway|StagingArea|CommsAsset
//   (:DispatchRecommendation)  -- re-used (recommendation node)
//   (:Approval)                -- re-used
//   (:ExecutionAction)         -- re-used
//   (:ExecutionResult)         -- re-used
//   (:Operator)                -- re-used (IC, ATCO ops)
//   (:RegulatoryCondition)     -- re-used
//   (:AuditRecord)             -- re-used
//
// Edges (wildfire-specific in addition to NECL set):
//   (EdgeWorks)-[:HAS_SUBSYSTEM]->(Subsystem)
//   (Subsystem)-[:HAS_COMPONENT]->(Component)
//   (Component)-[:HOSTS]->(Interface)
//   (Component)-[:HAS_SENSOR]->(Sensor)
//   (Sensor)-[:EXPOSED_VIA]->(Interface)
//   (Sensor)-[:PRODUCES]->(Reading)
//   (Interface)-[:EMITS]->(Detection)
//   (Detection)-[:CONFIRMS]->(Fire)
//   (Reading)-[:CONTRIBUTES_TO]->(SpreadEstimate)
//   (WindObservation)-[:CONTRIBUTES_TO]->(SpreadEstimate)
//   (SpreadEstimate)-[:DEFINES]->(WildfireRiskZone)
//   (Asset)-[:AT_RISK_FROM {activeFrom, activeTo, score}]->(Fire)
//   (Asset)-[:IN_ZONE {activeFrom, activeTo}]->(WildfireRiskZone)
//   (DispatchRecommendation)-[:DERIVED_FROM]->(SpreadEstimate)
//   (DispatchRecommendation)-[:SUPERSEDES]->(DispatchRecommendation)
//   (DispatchRecommendation)-[:CONSIDERED_BY {rank,reason,rejected}]->(DispatchRecommendation)
//   (Approval)-[:APPROVES]->(DispatchRecommendation)
//   (ExecutionAction)-[:EXECUTES]->(Approval)
//   (ExecutionResult)-[:CONFIRMS]->(ExecutionAction)
//   (AuditRecord)-[:DOCUMENTS]->(Fire)
//   (AuditRecord)-[:DOCUMENTS]->(DispatchRecommendation)
//   (RegulatoryCondition)-[:TRIGGERED]->(AuditRecord)
//
// Neo4j 5.x. Memgraph block at end (commented).
// =============================================================================

// --- Uniqueness constraints ---
CREATE CONSTRAINT grid_id_wf            IF NOT EXISTS FOR (n:Grid)                REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT region_id_wf          IF NOT EXISTS FOR (n:Region)              REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT edgeworks_id_wf            IF NOT EXISTS FOR (n:EdgeWorks)                REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT subsystem_id_wf       IF NOT EXISTS FOR (n:Subsystem)           REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT component_id_wf       IF NOT EXISTS FOR (n:Component)           REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT interface_id_wf       IF NOT EXISTS FOR (n:Interface)           REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT sensor_id_wf          IF NOT EXISTS FOR (n:Sensor)              REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT reading_id_wf         IF NOT EXISTS FOR (n:Reading)             REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT detection_id_wf       IF NOT EXISTS FOR (n:Detection)           REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT fire_id_wf            IF NOT EXISTS FOR (n:Fire)                REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT wind_obs_id_wf        IF NOT EXISTS FOR (n:WindObservation)     REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT spread_id_wf          IF NOT EXISTS FOR (n:SpreadEstimate)      REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT riskzone_id_wf        IF NOT EXISTS FOR (n:WildfireRiskZone)    REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT asset_id_wf           IF NOT EXISTS FOR (n:Asset)               REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT operator_id_wf        IF NOT EXISTS FOR (n:Operator)            REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT rec_id_wf             IF NOT EXISTS FOR (n:DispatchRecommendation) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT approval_id_wf        IF NOT EXISTS FOR (n:Approval)            REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT exec_id_wf            IF NOT EXISTS FOR (n:ExecutionAction)     REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT exec_res_id_wf        IF NOT EXISTS FOR (n:ExecutionResult)     REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT audit_id_wf           IF NOT EXISTS FOR (n:AuditRecord)         REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT regcond_id_wf         IF NOT EXISTS FOR (n:RegulatoryCondition) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT regulation_id_wf      IF NOT EXISTS FOR (n:Regulation)          REQUIRE n.id IS UNIQUE;

// --- Time-series indexes ---
CREATE INDEX reading_at_wf       IF NOT EXISTS FOR (n:Reading)              ON (n.at);
CREATE INDEX detection_at_wf     IF NOT EXISTS FOR (n:Detection)            ON (n.at);
CREATE INDEX wind_at_wf          IF NOT EXISTS FOR (n:WindObservation)      ON (n.at);
CREATE INDEX spread_at_wf        IF NOT EXISTS FOR (n:SpreadEstimate)       ON (n.at);
CREATE INDEX fire_at_wf          IF NOT EXISTS FOR (n:Fire)                 ON (n.detectedAt);
CREATE INDEX riskzone_at_wf      IF NOT EXISTS FOR (n:WildfireRiskZone)     ON (n.at);
CREATE INDEX rec_at_wf           IF NOT EXISTS FOR (n:DispatchRecommendation) ON (n.proposedAt);
CREATE INDEX approval_at_wf      IF NOT EXISTS FOR (n:Approval)             ON (n.at);
CREATE INDEX exec_at_wf          IF NOT EXISTS FOR (n:ExecutionAction)      ON (n.at);
CREATE INDEX exec_res_at_wf      IF NOT EXISTS FOR (n:ExecutionResult)      ON (n.at);
CREATE INDEX audit_at_wf         IF NOT EXISTS FOR (n:AuditRecord)          ON (n.at);

// --- Lookup indexes ---
CREATE INDEX asset_subtype_wf    IF NOT EXISTS FOR (n:Asset)                ON (n.subtype);
CREATE INDEX edgeworks_role_wf        IF NOT EXISTS FOR (n:EdgeWorks)                 ON (n.role);
CREATE INDEX interface_kind_wf   IF NOT EXISTS FOR (n:Interface)            ON (n.kind);
CREATE INDEX sensor_kind_wf      IF NOT EXISTS FOR (n:Sensor)               ON (n.kind);
CREATE INDEX reading_tag_wf      IF NOT EXISTS FOR (n:Reading)              ON (n.tag);
CREATE INDEX rec_supersedes_wf   IF NOT EXISTS FOR (n:DispatchRecommendation) ON (n.supersedesId);

// =============================================================================
// MEMGRAPH equivalents (uncomment if using Memgraph)
// =============================================================================
// CREATE CONSTRAINT ON (n:EdgeWorks)              ASSERT n.id IS UNIQUE;
// CREATE CONSTRAINT ON (n:Subsystem)         ASSERT n.id IS UNIQUE;
// CREATE CONSTRAINT ON (n:Component)         ASSERT n.id IS UNIQUE;
// CREATE CONSTRAINT ON (n:Interface)         ASSERT n.id IS UNIQUE;
// CREATE CONSTRAINT ON (n:Sensor)            ASSERT n.id IS UNIQUE;
// CREATE CONSTRAINT ON (n:Reading)           ASSERT n.id IS UNIQUE;
// CREATE CONSTRAINT ON (n:Detection)         ASSERT n.id IS UNIQUE;
// CREATE CONSTRAINT ON (n:Fire)              ASSERT n.id IS UNIQUE;
// CREATE CONSTRAINT ON (n:WindObservation)   ASSERT n.id IS UNIQUE;
// CREATE CONSTRAINT ON (n:SpreadEstimate)    ASSERT n.id IS UNIQUE;
// CREATE CONSTRAINT ON (n:WildfireRiskZone)  ASSERT n.id IS UNIQUE;
// CREATE CONSTRAINT ON (n:Asset)             ASSERT n.id IS UNIQUE;
// CREATE CONSTRAINT ON (n:DispatchRecommendation) ASSERT n.id IS UNIQUE;
// CREATE CONSTRAINT ON (n:Approval)          ASSERT n.id IS UNIQUE;
// CREATE CONSTRAINT ON (n:ExecutionAction)   ASSERT n.id IS UNIQUE;
// CREATE CONSTRAINT ON (n:ExecutionResult)   ASSERT n.id IS UNIQUE;
// CREATE CONSTRAINT ON (n:AuditRecord)       ASSERT n.id IS UNIQUE;
// CREATE INDEX ON :Reading(at);
// CREATE INDEX ON :WindObservation(at);
// CREATE INDEX ON :SpreadEstimate(at);
// CREATE INDEX ON :Asset(subtype);
//
// =============================================================================
// End schema
// =============================================================================
