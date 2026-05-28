// =============================================================================
// Wildfire Coordination Scenario - Cypher Load Script
// Companion: designs/wildFire/wildfireStory.md
// Run schema.cypher first.
//
// Sections:
//   A. Bootstrap        - grid, region, cubes, sensors, interfaces, assets,
//                         operators, regulations
//   B. Timeline events  - readings, detections, fire, wind obs, spread,
//                         risk zones, AT_RISK_FROM edges, recommendations,
//                         approvals, executions, results, audit
//
// Scenario start: 2026-08-15T14:00:00Z (Bear Creek, Alberta - synthetic)
// =============================================================================


// =============================================================================
// SECTION A - BOOTSTRAP
// =============================================================================

// --- Grid + Region ---
MERGE (g:Grid {id: 'GRID-WILDFIRE-AB-FOOTHILLS'})
  ON CREATE SET g.name = 'Alberta Foothills Wildfire Coordination Grid';
MERGE (r:Region {id: 'REGION-BEAR-VALLEY'})
  ON CREATE SET r.name = 'Bear Creek Valley',
                r.lat = 49.60, r.lng = -114.50,
                r.areaKm2 = 180.0,
                r.fuelType = 'mixed_conifer_grass',
                r.fireSeason = 'active';
MATCH (g:Grid {id: 'GRID-WILDFIRE-AB-FOOTHILLS'}), (r:Region {id: 'REGION-BEAR-VALLEY'})
MERGE (r)-[:IN]->(g);


// --- Cubes (5 EdgeWorks boxes) ---
MERGE (c:Cube {id: 'EW-RIDGE-N'})
  ON CREATE SET c += {id:'EW-RIDGE-N', name:'North Ridge Sentinel',
    role:'upwind_sentinel', regionId:'REGION-BEAR-VALLEY',
    lat:49.6210, lng:-114.5120, elevM:1650, model:'EW-BOX-2',
    uplink:'lte_primary_sat_failover'};
MERGE (c:Cube {id: 'EW-RIDGE-S'})
  ON CREATE SET c += {id:'EW-RIDGE-S', name:'South Ridge Sentinel',
    role:'opposite_sentinel', regionId:'REGION-BEAR-VALLEY',
    lat:49.5790, lng:-114.4890, elevM:1580, model:'EW-BOX-2',
    uplink:'comms_tower_2'};
MERGE (c:Cube {id: 'EW-VALLEY-W'})
  ON CREATE SET c += {id:'EW-VALLEY-W', name:'West Valley Floor',
    role:'ground_truth', regionId:'REGION-BEAR-VALLEY',
    lat:49.6000, lng:-114.5300, elevM:1340, model:'EW-BOX-2',
    uplink:'lte_primary'};
MERGE (c:Cube {id: 'EW-TOWN-E'})
  ON CREATE SET c += {id:'EW-TOWN-E', name:'Town East Edge',
    role:'community_facing', regionId:'REGION-BEAR-VALLEY',
    lat:49.6050, lng:-114.4800, elevM:1310, model:'EW-BOX-2',
    uplink:'fiber'};
MERGE (c:Cube {id: 'EW-SUB-A'})
  ON CREATE SET c += {id:'EW-SUB-A', name:'ATCO Substation Site',
    role:'asset_protection', regionId:'REGION-BEAR-VALLEY',
    lat:49.5980, lng:-114.4750, elevM:1325, model:'EW-BOX-2',
    uplink:'fiber'};

MATCH (c:EdgeWorks), (r:Region {id:'REGION-BEAR-VALLEY'})
WHERE c.regionId = 'REGION-BEAR-VALLEY'
MERGE (c)-[:IN]->(r);


// --- Per-cube substrate (Subsystem -> Component -> Sensors + Interfaces) ---
// Pattern repeated for each of the 5 cubes.
UNWIND [
  'EW-RIDGE-N','EW-RIDGE-S','EW-VALLEY-W','EW-TOWN-E','EW-SUB-A'
] AS cid
MATCH (c:Cube {id: cid})
// Subsystem
MERGE (sub:Subsystem {id: cid + ':SUB-SENSOR-PAYLOAD'})
  ON CREATE SET sub.name = 'Sensor Payload', sub.cubeId = cid
MERGE (c)-[:HAS_SUBSYSTEM]->(sub)
// Component
MERGE (comp:Component {id: cid + ':COMP-SENSOR-ARRAY'})
  ON CREATE SET comp.name = 'Sensor Array', comp.subsystemId = sub.id
MERGE (sub)-[:HAS_COMPONENT]->(comp)
// Interfaces (the four canonical kinds)
MERGE (iSig:Interface {id: cid + ':IFACE-sigInt'})
  ON CREATE SET iSig.kind = 'sigInt', iSig.cubeId = cid
MERGE (comp)-[:HOSTS]->(iSig)
MERGE (iAi:Interface {id: cid + ':IFACE-aiInt'})
  ON CREATE SET iAi.kind = 'aiInt', iAi.cubeId = cid
MERGE (comp)-[:HOSTS]->(iAi)
MERGE (iOps:Interface {id: cid + ':IFACE-opsInt'})
  ON CREATE SET iOps.kind = 'opsInt', iOps.cubeId = cid
MERGE (comp)-[:HOSTS]->(iOps)
MERGE (iFin:Interface {id: cid + ':IFACE-finInt'})
  ON CREATE SET iFin.kind = 'finInt', iFin.cubeId = cid
MERGE (comp)-[:HOSTS]->(iFin)
// Sensors (sigInt-exposed)
MERGE (sAn:Sensor {id: cid + ':SENSOR-anemometer'})
  ON CREATE SET sAn += {kind:'anemometer', units:'m/s+deg', cubeId:cid}
MERGE (comp)-[:HAS_SENSOR]->(sAn)
MERGE (sAn)-[:EXPOSED_VIA]->(iSig)
MERGE (sTh:Sensor {id: cid + ':SENSOR-thermo_hygro'})
  ON CREATE SET sTh += {kind:'thermo_hygro', units:'C+pct', cubeId:cid}
MERGE (comp)-[:HAS_SENSOR]->(sTh)
MERGE (sTh)-[:EXPOSED_VIA]->(iSig)
MERGE (sPm:Sensor {id: cid + ':SENSOR-pm_sensor'})
  ON CREATE SET sPm += {kind:'pm_sensor', units:'ug/m3', cubeId:cid}
MERGE (comp)-[:HAS_SENSOR]->(sPm)
MERGE (sPm)-[:EXPOSED_VIA]->(iSig)
MERGE (sTc:Sensor {id: cid + ':SENSOR-thermal_cam'})
  ON CREATE SET sTc += {kind:'thermal_cam', units:'C', cubeId:cid}
MERGE (comp)-[:HAS_SENSOR]->(sTc)
MERGE (sTc)-[:EXPOSED_VIA]->(iSig)
MERGE (sOp:Sensor {id: cid + ':SENSOR-optical_cam'})
  ON CREATE SET sOp += {kind:'optical_cam', units:'rgb_frame', cubeId:cid}
MERGE (comp)-[:HAS_SENSOR]->(sOp)
MERGE (sOp)-[:EXPOSED_VIA]->(iSig);


// --- Assets at risk ---
MERGE (a:Asset:Community {id:'TOWN-BEAR'})
  ON CREATE SET a += {id:'TOWN-BEAR', subtype:'Community',
    name:'Town of Bear Creek', regionId:'REGION-BEAR-VALLEY',
    lat:49.6040, lng:-114.4830, population:612,
    sensitivity:'high', protectionPriority:1};
MERGE (a:Asset:Substation {id:'SUB-BEAR-1'})
  ON CREATE SET a += {id:'SUB-BEAR-1', subtype:'Substation',
    name:'Bear Creek 138/25 kV Substation', operator:'ATCO',
    regionId:'REGION-BEAR-VALLEY', lat:49.5985, lng:-114.4755,
    kv:138.0, sensitivity:'high', protectionPriority:2};
MERGE (a:Asset:TransmissionLine {id:'LINE-NE-7'})
  ON CREATE SET a += {id:'LINE-NE-7', subtype:'TransmissionLine',
    name:'138 kV Line NE-7', operator:'ATCO',
    regionId:'REGION-BEAR-VALLEY',
    endA_lat:49.6210, endA_lng:-114.5050,
    endB_lat:49.5800, endB_lng:-114.4700,
    kv:138.0, sensitivity:'medium', protectionPriority:3};
MERGE (a:Asset:GasFacility {id:'GAS-REG-3'})
  ON CREATE SET a += {id:'GAS-REG-3', subtype:'GasFacility',
    name:'Gas Regulating Station 3', operator:'ATCO',
    regionId:'REGION-BEAR-VALLEY', lat:49.5950, lng:-114.4810,
    pressureClass:'high', sensitivity:'critical', protectionPriority:1};
MERGE (a:Asset:Highway {id:'HWY-11-N'})
  ON CREATE SET a += {id:'HWY-11-N', subtype:'Highway',
    name:'Highway 11 North Segment', regionId:'REGION-BEAR-VALLEY',
    start_lat:49.6040, start_lng:-114.4830,
    end_lat:49.6400, end_lng:-114.4800,
    role:'primary_evac_north', sensitivity:'medium', protectionPriority:2};
MERGE (a:Asset:Highway {id:'HWY-11-S'})
  ON CREATE SET a += {id:'HWY-11-S', subtype:'Highway',
    name:'Highway 11 South Segment', regionId:'REGION-BEAR-VALLEY',
    start_lat:49.6040, start_lng:-114.4830,
    end_lat:49.5650, end_lng:-114.4850,
    role:'alternate_evac_south', sensitivity:'medium', protectionPriority:2};
MERGE (a:Asset:StagingArea {id:'STAGE-1'})
  ON CREATE SET a += {id:'STAGE-1', subtype:'StagingArea',
    name:'Initial Firefighter Staging - West',
    regionId:'REGION-BEAR-VALLEY', lat:49.6020, lng:-114.5180,
    crewCount:24, sensitivity:'medium', protectionPriority:2};
MERGE (a:Asset:CommsAsset {id:'COMMS-TOWER-2'})
  ON CREATE SET a += {id:'COMMS-TOWER-2', subtype:'CommsAsset',
    name:'Repeater Tower 2 (cube uplink)',
    regionId:'REGION-BEAR-VALLEY', lat:49.5870, lng:-114.4900,
    servesCubes:['EW-RIDGE-S'], sensitivity:'high',
    protectionPriority:2};
CREATE (:Asset {id:'BEAR-HOSPITAL', name:'Bear Creek Health Centre', subtype:'Hospital',
               operator:'Alberta Health Services', lat:49.629, lng:-114.476,
               sensitivity:'critical', protectionPriority:1});
CREATE (:Asset {id:'BEAR-SCHOOL', name:'Bear Creek K-12 School', subtype:'School',
               operator:'Crowsnest Pass School District', lat:49.625, lng:-114.491,
               sensitivity:'high', protectionPriority:1, capacity:380});
CREATE (:Asset {id:'SOUTH-HAMLET', name:'South Valley Hamlet', subtype:'Community',
               operator:'Municipal', lat:49.594, lng:-114.492,
               sensitivity:'high', protectionPriority:2, population:140});
CREATE (:Asset {id:'HWY-3', name:'Crowsnest Highway 3', subtype:'Highway',
               operator:'Alberta Transportation', lat:49.610, lng:-114.500,
               sensitivity:'medium', role:'primary E-W artery', dailyTraffic:3200});
CREATE (:Asset {id:'WATER-TREAT', name:'Bear Creek Water Works', subtype:'Utility',
               operator:'Bear Creek Municipal Services', lat:49.601, lng:-114.506,
               sensitivity:'high', capacityM3perDay:2400});

// --- Support assets (firefighting and evacuation infrastructure) ---
CREATE (:Asset {id:'FIRE-HALL-W',   name:'Fire Hall — West',          subtype:'FireStation',   operator:'Bear Creek Fire Dept',        lat:49.612, lng:-114.543, sensitivity:'medium'});
CREATE (:Asset {id:'REC-CTR-N',     name:'Reception Centre — North',  subtype:'EvacReception', operator:'Emergency Management Alberta', lat:49.635, lng:-114.452, sensitivity:'medium', capacity:400});
CREATE (:Asset {id:'HELIPAD-1',     name:'Helipad Alpha',             subtype:'Helipad',       operator:'AB Wildfire Air Operations',  lat:49.607, lng:-114.525, sensitivity:'medium'});
CREATE (:Asset {id:'TANKER-FILL-1', name:'Tanker Fill — Valley',      subtype:'TankerFill',    operator:'Bear Creek Fire Dept',        lat:49.622, lng:-114.445, sensitivity:'low'});
CREATE (:Asset {id:'FIRE-HALL-S',   name:'Fire Hall — South',         subtype:'FireStation',   operator:'Bear Creek Fire Dept',        lat:49.575, lng:-114.500, sensitivity:'medium'});
CREATE (:Asset {id:'REC-CTR-W',     name:'Reception Centre — West',   subtype:'EvacReception', operator:'Emergency Management Alberta', lat:49.600, lng:-114.548, sensitivity:'medium', capacity:250});
CREATE (:Asset {id:'HELIPAD-2',     name:'Helipad Beta',              subtype:'Helipad',       operator:'AB Wildfire Air Operations',  lat:49.587, lng:-114.523, sensitivity:'medium'});
CREATE (:Asset {id:'FUEL-CACHE-S',  name:'Fuel Cache South',          subtype:'FuelDepot',     operator:'AB Wildfire',                 lat:49.580, lng:-114.478, sensitivity:'low'});

MATCH (a:Asset), (r:Region {id:'REGION-BEAR-VALLEY'})
WHERE a.regionId = 'REGION-BEAR-VALLEY'
MERGE (a)-[:IN]->(r);

// COMMS-TOWER-2 hosts the uplink for EW-RIDGE-S
MATCH (a:Asset {id:'COMMS-TOWER-2'}), (c:Cube {id:'EW-RIDGE-S'})
MERGE (c)-[:UPLINKED_VIA]->(a);


// --- Operators ---
MERGE (o:Operator {id:'OP-IC-001'})
  ON CREATE SET o += {id:'OP-IC-001', name:'Incident Commander - Bear Creek',
    role:'incident_commander', authority:'emergency_management'};
MERGE (o:Operator {id:'OP-ATCO-001'})
  ON CREATE SET o += {id:'OP-ATCO-001', name:'ATCO Control Center Operator',
    role:'utility_operator', authority:'atco_ops'};
MERGE (o:Operator {id:'OP-MUNI-001'})
  ON CREATE SET o += {id:'OP-MUNI-001', name:'Bear Creek Municipal Dispatch',
    role:'municipal_dispatch', authority:'municipal_alerting'};


// --- Regulations and conditions ---
MERGE (r:Regulation {id:'REG-WILDFIRE-2026'})
  ON CREATE SET r += {id:'REG-WILDFIRE-2026', name:'Alberta Wildfire Coordination Standard 2026',
    authority:'Alberta Wildfire Management'};
MERGE (rc:RegulatoryCondition {id:'REGCOND-ASSET-IN-FIRE-ENVELOPE'})
  ON CREATE SET rc += {id:'REGCOND-ASSET-IN-FIRE-ENVELOPE',
    rule:'critical asset inside active fire envelope triggers auto-isolate envelope approval',
    triggerType:'spatial_membership'};
MATCH (rc:RegulatoryCondition {id:'REGCOND-ASSET-IN-FIRE-ENVELOPE'}),
      (r:Regulation {id:'REG-WILDFIRE-2026'})
MERGE (rc)-[:UNDER]->(r);


// =============================================================================
// SECTION B - TIMELINE
// =============================================================================
//
// All times absolute. Scenario T0 = 2026-08-15T14:00:00Z
//
//   t=0    14:00:00   Ignition detected (EW-RIDGE-N thermal)
//   t=3    14:03:00   Smoke corroboration (EW-VALLEY-W)
//   t=5    14:05:00   Initial wind readings, SpreadEstimate-001 (NE)
//                     RiskZone-001, AT_RISK_FROM edges turned on
//   t=12   14:12:00   REC-FIRE-001, APP-FIRE-001, EX-FIRE-001-{A,B,C}
//   t=28   14:28:00   WIND SHIFT detected (EW-RIDGE-N first)
//   t=30   14:30:00   SpreadEstimate-002 (SSE), RiskZone-002
//                     prior AT_RISK_FROM edges closed (activeTo), new ones opened
//   t=32   14:32:00   REC-FIRE-002 SUPERSEDES REC-FIRE-001 (+ rejected candidates)
//   t=35   14:35:00   APP-FIRE-002, EX-FIRE-002-{A,B,C,D,E} + results
//   t=55   14:55:00   Stabilization observation
//   t=90   15:30:00   AUDIT-BEAR-2026-001
//
// =============================================================================


// --- t=0 14:00:00 IGNITION ---
// Reading: thermal cam max scene temp on EW-RIDGE-N
MERGE (rd:Reading {id:'RD-RN-TC-000'})
  ON CREATE SET rd += {id:'RD-RN-TC-000', at: datetime('2026-08-15T14:00:00Z'),
    tag:'thermal_cam.maxC', value:312.0, units:'C',
    lat:49.6175, lng:-114.5080};
MATCH (s:Sensor {id:'EW-RIDGE-N:SENSOR-thermal_cam'}), (rd:Reading {id:'RD-RN-TC-000'})
MERGE (s)-[:PRODUCES]->(rd);

// Detection: aiInt fire_detector on EW-RIDGE-N
MERGE (d:Detection {id:'DET-RN-FIRE-000'})
  ON CREATE SET d += {id:'DET-RN-FIRE-000', at: datetime('2026-08-15T14:00:05Z'),
    model:'fire_detector_v3', kind:'fire',
    confidence:0.94, present:true};
MATCH (i:Interface {id:'EW-RIDGE-N:IFACE-aiInt'}), (d:Detection {id:'DET-RN-FIRE-000'})
MERGE (i)-[:EMITS]->(d);
MATCH (d:Detection {id:'DET-RN-FIRE-000'}), (rd:Reading {id:'RD-RN-TC-000'})
MERGE (d)-[:DERIVED_FROM]->(rd);

// Fire node
MERGE (f:Fire {id:'FIRE-BEAR-001'})
  ON CREATE SET f += {id:'FIRE-BEAR-001', name:'Bear Creek Fire 001',
    detectedAt: datetime('2026-08-15T14:00:05Z'),
    ignitionLat:49.6175, ignitionLng:-114.5080,
    cause:'unknown', status:'active'};
MATCH (d:Detection {id:'DET-RN-FIRE-000'}), (f:Fire {id:'FIRE-BEAR-001'})
MERGE (d)-[:CONFIRMS]->(f);
MATCH (f:Fire {id:'FIRE-BEAR-001'}), (r:Region {id:'REGION-BEAR-VALLEY'})
MERGE (f)-[:IN]->(r);


// --- t=3 14:03:00 SMOKE CORROBORATION ---
MERGE (rd:Reading {id:'RD-VW-PM-003'})
  ON CREATE SET rd += {id:'RD-VW-PM-003', at: datetime('2026-08-15T14:03:00Z'),
    tag:'pm_sensor.pm25', value:95.0, units:'ug/m3'};
MATCH (s:Sensor {id:'EW-VALLEY-W:SENSOR-pm_sensor'}), (rd:Reading {id:'RD-VW-PM-003'})
MERGE (s)-[:PRODUCES]->(rd);

MERGE (d:Detection {id:'DET-VW-SMOKE-003'})
  ON CREATE SET d += {id:'DET-VW-SMOKE-003', at: datetime('2026-08-15T14:03:10Z'),
    model:'smoke_classifier_v2', kind:'smoke',
    confidence:0.88, present:true, density_class:'med'};
MATCH (i:Interface {id:'EW-VALLEY-W:IFACE-aiInt'}), (d:Detection {id:'DET-VW-SMOKE-003'})
MERGE (i)-[:EMITS]->(d);
MATCH (d:Detection {id:'DET-VW-SMOKE-003'}), (rd:Reading {id:'RD-VW-PM-003'})
MERGE (d)-[:DERIVED_FROM]->(rd);
MATCH (d:Detection {id:'DET-VW-SMOKE-003'}), (f:Fire {id:'FIRE-BEAR-001'})
MERGE (d)-[:CORROBORATES]->(f);


// --- t=5 14:05:00 INITIAL WIND READINGS + FIRST SPREAD ESTIMATE ---
// Wind observations from each cube. Pre-shift: WSW (~240 deg), light.
UNWIND [
  {id:'WIND-RN-005', cube:'EW-RIDGE-N', dir_deg:240.0, speed_mps:4.2},
  {id:'WIND-VW-005', cube:'EW-VALLEY-W', dir_deg:235.0, speed_mps:3.3},
  {id:'WIND-RS-005', cube:'EW-RIDGE-S', dir_deg:245.0, speed_mps:3.9},
  {id:'WIND-TE-005', cube:'EW-TOWN-E',  dir_deg:238.0, speed_mps:2.8},
  {id:'WIND-SA-005', cube:'EW-SUB-A',   dir_deg:242.0, speed_mps:2.6}
] AS w
MERGE (wo:WindObservation {id: w.id})
  ON CREATE SET wo += {id:w.id, at: datetime('2026-08-15T14:05:00Z'),
    dir_deg:w.dir_deg, speed_mps:w.speed_mps, cubeId:w.cube}
WITH wo, w
MATCH (s:Sensor {id: w.cube + ':SENSOR-anemometer'})
MERGE (s)-[:PRODUCES]->(wo);

// SpreadEstimate-001: vector NE (~060 deg), ~1.2 m/s
MERGE (se:SpreadEstimate {id:'SPREAD-001'})
  ON CREATE SET se += {id:'SPREAD-001', at: datetime('2026-08-15T14:05:30Z'),
    vector_deg:60.0, rate_mps:1.2,
    coneHalfAngleDeg:25.0, horizonMin:30,
    rationale:'pre-shift; consistent WSW wind across 5 cubes'};
// Link contributing wind observations
MATCH (se:SpreadEstimate {id:'SPREAD-001'}), (wo:WindObservation)
WHERE wo.id IN ['WIND-RN-005','WIND-VW-005','WIND-RS-005','WIND-TE-005','WIND-SA-005']
MERGE (wo)-[:CONTRIBUTES_TO]->(se);
// Link to fire it pertains to
MATCH (se:SpreadEstimate {id:'SPREAD-001'}), (f:Fire {id:'FIRE-BEAR-001'})
MERGE (se)-[:PROJECTS]->(f);

// RiskZone-001 (NE cone)
MERGE (rz:WildfireRiskZone {id:'RZ-001'})
  ON CREATE SET rz += {id:'RZ-001', at: datetime('2026-08-15T14:05:30Z'),
    activeFrom: datetime('2026-08-15T14:05:30Z'),
    activeTo: datetime('2026-08-15T14:30:00Z'),
    centerLat:49.6175, centerLng:-114.5080,
    bearing_deg:60.0, lengthKm:5.0, halfWidthKm:1.8,
    label:'NE spread cone (pre-shift)'};
MATCH (se:SpreadEstimate {id:'SPREAD-001'}), (rz:WildfireRiskZone {id:'RZ-001'})
MERGE (se)-[:DEFINES]->(rz);

// AT_RISK_FROM edges (initial set: TOWN-BEAR, LINE-NE-7, HWY-11-N)
MATCH (a:Asset {id:'TOWN-BEAR'}), (f:Fire {id:'FIRE-BEAR-001'})
MERGE (a)-[r:AT_RISK_FROM {zoneId:'RZ-001'}]->(f)
  ON CREATE SET r.activeFrom = datetime('2026-08-15T14:05:30Z'),
                r.activeTo   = datetime('2026-08-15T14:30:00Z'),
                r.score      = 0.78,
                r.reason     = 'within NE spread cone, pre-shift';
MATCH (a:Asset {id:'LINE-NE-7'}), (f:Fire {id:'FIRE-BEAR-001'})
MERGE (a)-[r:AT_RISK_FROM {zoneId:'RZ-001'}]->(f)
  ON CREATE SET r.activeFrom = datetime('2026-08-15T14:05:30Z'),
                r.activeTo   = datetime('2026-08-15T14:30:00Z'),
                r.score      = 0.71,
                r.reason     = 'line crosses NE spread cone';
MATCH (a:Asset {id:'HWY-11-N'}), (f:Fire {id:'FIRE-BEAR-001'})
MERGE (a)-[r:AT_RISK_FROM {zoneId:'RZ-001'}]->(f)
  ON CREATE SET r.activeFrom = datetime('2026-08-15T14:05:30Z'),
                r.activeTo   = datetime('2026-08-15T14:30:00Z'),
                r.score      = 0.65,
                r.reason     = 'north segment within cone';

MATCH (a:Asset {id:'BEAR-HOSPITAL'}), (f:Fire {id:'FIRE-BEAR-001'})
MERGE (a)-[r:AT_RISK_FROM {zoneId:'RZ-001'}]->(f)
  ON CREATE SET r.activeFrom = datetime('2026-08-15T14:05:30Z'),
                r.activeTo   = datetime('2026-08-15T14:30:00Z'),
                r.score      = 0.85,
                r.reason     = 'health centre in NE spread cone; critical evacuation priority';

MATCH (a:Asset {id:'BEAR-SCHOOL'}), (f:Fire {id:'FIRE-BEAR-001'})
MERGE (a)-[r:AT_RISK_FROM {zoneId:'RZ-001'}]->(f)
  ON CREATE SET r.activeFrom = datetime('2026-08-15T14:05:30Z'),
                r.activeTo   = datetime('2026-08-15T14:30:00Z'),
                r.score      = 0.77,
                r.reason     = 'school within NE spread cone; 380 students at risk';

MATCH (a:Asset {id:'HWY-3'}), (f:Fire {id:'FIRE-BEAR-001'})
MERGE (a)-[r:AT_RISK_FROM {zoneId:'RZ-001'}]->(f)
  ON CREATE SET r.activeFrom = datetime('2026-08-15T14:05:30Z'),
                r.activeTo   = datetime('2026-08-15T14:30:00Z'),
                r.score      = 0.60,
                r.reason     = 'eastern valley approach in NE spread corridor';

// IN_ZONE membership edges
MATCH (a:Asset), (rz:WildfireRiskZone {id:'RZ-001'})
WHERE a.id IN ['TOWN-BEAR','LINE-NE-7','HWY-11-N']
MERGE (a)-[m:IN_ZONE]->(rz)
  ON CREATE SET m.activeFrom = datetime('2026-08-15T14:05:30Z'),
                m.activeTo   = datetime('2026-08-15T14:30:00Z');


// --- t=12 14:12:00 FIRST RECOMMENDATION + APPROVAL + EXECUTIONS ---
MERGE (rec:DispatchRecommendation {id:'REC-FIRE-001'})
  ON CREATE SET rec += {id:'REC-FIRE-001',
    proposedAt: datetime('2026-08-15T14:12:00Z'),
    accepted:true, supersedesId:null,
    summary:'Preventive evacuation east sector + NE crew prep + ATCO standby on LINE-NE-7',
    horizonMin:30};
MATCH (rec:DispatchRecommendation {id:'REC-FIRE-001'}),
      (se:SpreadEstimate {id:'SPREAD-001'})
MERGE (rec)-[:DERIVED_FROM]->(se);
MATCH (rec:DispatchRecommendation {id:'REC-FIRE-001'}),
      (f:Fire {id:'FIRE-BEAR-001'})
MERGE (rec)-[:ADDRESSES]->(f);

MERGE (app:Approval {id:'APP-FIRE-001'})
  ON CREATE SET app += {id:'APP-FIRE-001',
    at: datetime('2026-08-15T14:12:30Z'),
    approverType:'human', approverId:'OP-IC-001', status:'approved'};
MATCH (app:Approval {id:'APP-FIRE-001'}), (rec:DispatchRecommendation {id:'REC-FIRE-001'})
MERGE (app)-[:APPROVES]->(rec);
MATCH (app:Approval {id:'APP-FIRE-001'}), (op:Operator {id:'OP-IC-001'})
MERGE (op)-[:ISSUED]->(app);

// Execution actions
MERGE (ex:ExecutionAction {id:'EX-FIRE-001-A'})
  ON CREATE SET ex += {id:'EX-FIRE-001-A', at: datetime('2026-08-15T14:13:00Z'),
    action:'evacuation_order', target:'TOWN-BEAR.east_sector',
    channel:'municipal_alerting'};
MERGE (ex:ExecutionAction {id:'EX-FIRE-001-B'})
  ON CREATE SET ex += {id:'EX-FIRE-001-B', at: datetime('2026-08-15T14:13:00Z'),
    action:'crew_redeploy', target:'STAGE-1->NE_flank',
    channel:'fire_dispatch'};
MERGE (ex:ExecutionAction {id:'EX-FIRE-001-C'})
  ON CREATE SET ex += {id:'EX-FIRE-001-C', at: datetime('2026-08-15T14:13:00Z'),
    action:'atco_standby_deenergize', target:'LINE-NE-7',
    channel:'atco_scada'};
MATCH (ex:ExecutionAction), (app:Approval {id:'APP-FIRE-001'})
WHERE ex.id IN ['EX-FIRE-001-A','EX-FIRE-001-B','EX-FIRE-001-C']
MERGE (ex)-[:EXECUTES]->(app);

// Execution results (confirmations)
MERGE (er:ExecutionResult {id:'ER-FIRE-001-A'})
  ON CREATE SET er += {id:'ER-FIRE-001-A', at: datetime('2026-08-15T14:14:10Z'),
    status:'success', note:'alert broadcast acknowledged by 588/612 endpoints'};
MERGE (er:ExecutionResult {id:'ER-FIRE-001-B'})
  ON CREATE SET er += {id:'ER-FIRE-001-B', at: datetime('2026-08-15T14:17:00Z'),
    status:'success', note:'crew movement confirmed by IC ground'};
MERGE (er:ExecutionResult {id:'ER-FIRE-001-C'})
  ON CREATE SET er += {id:'ER-FIRE-001-C', at: datetime('2026-08-15T14:13:45Z'),
    status:'success', note:'ATCO acknowledges standby on LINE-NE-7'};
MATCH (er:ExecutionResult {id:'ER-FIRE-001-A'}), (ex:ExecutionAction {id:'EX-FIRE-001-A'})
MERGE (er)-[:CONFIRMS]->(ex);
MATCH (er:ExecutionResult {id:'ER-FIRE-001-B'}), (ex:ExecutionAction {id:'EX-FIRE-001-B'})
MERGE (er)-[:CONFIRMS]->(ex);
MATCH (er:ExecutionResult {id:'ER-FIRE-001-C'}), (ex:ExecutionAction {id:'EX-FIRE-001-C'})
MERGE (er)-[:CONFIRMS]->(ex);

// Hospital and school evacuation (REC-FIRE-001, APP-FIRE-001)
MATCH (app:Approval {id:'APP-FIRE-001'})
MERGE (ex:ExecutionAction {id:'EX-FIRE-001-D'})
  ON CREATE SET ex.action='evacuation_order', ex.target='BEAR-HOSPITAL',
                ex.channel='municipal_alerting', ex.at=datetime('2026-08-15T14:13:00Z')
MERGE (ex)-[:EXECUTES]->(app);

MERGE (er:ExecutionResult {id:'ER-FIRE-001-D'})
  ON CREATE SET er.status='success', er.note='health centre evacuation order issued; staff activating protocol',
                er.at=datetime('2026-08-15T14:15:30Z')
MERGE (er)-[:CONFIRMS]->(ex);

MATCH (app:Approval {id:'APP-FIRE-001'})
MERGE (ex:ExecutionAction {id:'EX-FIRE-001-E'})
  ON CREATE SET ex.action='evacuation_order', ex.target='BEAR-SCHOOL',
                ex.channel='municipal_alerting', ex.at=datetime('2026-08-15T14:13:00Z')
MERGE (ex)-[:EXECUTES]->(app);

MERGE (er:ExecutionResult {id:'ER-FIRE-001-E'})
  ON CREATE SET er.status='success', er.note='school lockdown initiated; 380 students accounted for',
                er.at=datetime('2026-08-15T14:18:00Z')
MERGE (er)-[:CONFIRMS]->(ex);

// NE flank support — activated on APP-FIRE-001
MATCH (app:Approval {id:'APP-FIRE-001'})
MERGE (ex:ExecutionAction {id:'EX-FIRE-001-F'})
  ON CREATE SET ex.action='mobilize_support', ex.target='FIRE-HALL-W + HELIPAD-1 + REC-CTR-N + TANKER-FILL-1',
                ex.channel='fire_dispatch', ex.at=datetime('2026-08-15T14:13:00Z'),
                ex.note='NE flank support package activated'
MERGE (ex)-[:EXECUTES]->(app);

MERGE (er:ExecutionResult {id:'ER-FIRE-001-F'})
  ON CREATE SET er.status='success', er.note='all 4 NE support assets activated and reporting',
                er.at=datetime('2026-08-15T14:16:00Z')
MERGE (er)-[:CONFIRMS]->(ex);


// --- t=28 14:28:00 WIND SHIFT (EW-RIDGE-N first) ---
// Anemometer readings rotate from ~240 -> ~305 deg, speed climbs.
UNWIND [
  {id:'WIND-RN-028', cube:'EW-RIDGE-N',  at:'2026-08-15T14:28:00Z', dir_deg:305.0, speed_mps:6.1, note:'first cube to detect shift'},
  {id:'WIND-VW-029', cube:'EW-VALLEY-W', at:'2026-08-15T14:29:00Z', dir_deg:300.0, speed_mps:5.4, note:'confirms within 60s'},
  {id:'WIND-RS-029', cube:'EW-RIDGE-S',  at:'2026-08-15T14:29:30Z', dir_deg:310.0, speed_mps:7.8, note:'strongest reading'},
  {id:'WIND-TE-030', cube:'EW-TOWN-E',   at:'2026-08-15T14:30:00Z', dir_deg:298.0, speed_mps:4.2, note:'sheltered, lags'},
  {id:'WIND-SA-030', cube:'EW-SUB-A',    at:'2026-08-15T14:30:00Z', dir_deg:302.0, speed_mps:4.0, note:'sheltered, lags'}
] AS w
MERGE (wo:WindObservation {id: w.id})
  ON CREATE SET wo += {id:w.id, at: datetime(w.at),
    dir_deg:w.dir_deg, speed_mps:w.speed_mps, cubeId:w.cube,
    note:w.note}
WITH wo, w
MATCH (s:Sensor {id: w.cube + ':SENSOR-anemometer'})
MERGE (s)-[:PRODUCES]->(wo);


// --- t=30 14:30:00 NEW SPREAD ESTIMATE + RISK ZONE ---
MERGE (se:SpreadEstimate {id:'SPREAD-002'})
  ON CREATE SET se += {id:'SPREAD-002', at: datetime('2026-08-15T14:30:30Z'),
    vector_deg:160.0, rate_mps:1.8,
    coneHalfAngleDeg:22.0, horizonMin:45,
    rationale:'wind rotated WSW->NW; spread vector swings to SSE; RH drop noted'};
MATCH (se:SpreadEstimate {id:'SPREAD-002'}), (wo:WindObservation)
WHERE wo.id IN ['WIND-RN-028','WIND-VW-029','WIND-RS-029','WIND-TE-030','WIND-SA-030']
MERGE (wo)-[:CONTRIBUTES_TO]->(se);
MATCH (se:SpreadEstimate {id:'SPREAD-002'}), (f:Fire {id:'FIRE-BEAR-001'})
MERGE (se)-[:PROJECTS]->(f);

MERGE (rz:WildfireRiskZone {id:'RZ-002'})
  ON CREATE SET rz += {id:'RZ-002', at: datetime('2026-08-15T14:30:30Z'),
    activeFrom: datetime('2026-08-15T14:30:30Z'),
    centerLat:49.6175, centerLng:-114.5080,
    bearing_deg:160.0, lengthKm:6.5, halfWidthKm:1.8,
    label:'SSE spread cone (post-shift)'};
MATCH (se:SpreadEstimate {id:'SPREAD-002'}), (rz:WildfireRiskZone {id:'RZ-002'})
MERGE (se)-[:DEFINES]->(rz);

// New AT_RISK_FROM set: SUB-BEAR-1, GAS-REG-3, HWY-11-S, COMMS-TOWER-2, STAGE-1
MATCH (a:Asset {id:'SUB-BEAR-1'}), (f:Fire {id:'FIRE-BEAR-001'})
MERGE (a)-[r:AT_RISK_FROM {zoneId:'RZ-002'}]->(f)
  ON CREATE SET r.activeFrom = datetime('2026-08-15T14:30:30Z'),
                r.score      = 0.82,
                r.reason     = 'substation directly in SSE spread cone';
MATCH (a:Asset {id:'GAS-REG-3'}), (f:Fire {id:'FIRE-BEAR-001'})
MERGE (a)-[r:AT_RISK_FROM {zoneId:'RZ-002'}]->(f)
  ON CREATE SET r.activeFrom = datetime('2026-08-15T14:30:30Z'),
                r.score      = 0.89,
                r.reason     = 'critical gas asset in SSE cone';
MATCH (a:Asset {id:'HWY-11-S'}), (f:Fire {id:'FIRE-BEAR-001'})
MERGE (a)-[r:AT_RISK_FROM {zoneId:'RZ-002'}]->(f)
  ON CREATE SET r.activeFrom = datetime('2026-08-15T14:30:30Z'),
                r.score      = 0.58,
                r.reason     = 'south evac segment edge of cone';
MATCH (a:Asset {id:'COMMS-TOWER-2'}), (f:Fire {id:'FIRE-BEAR-001'})
MERGE (a)-[r:AT_RISK_FROM {zoneId:'RZ-002'}]->(f)
  ON CREATE SET r.activeFrom = datetime('2026-08-15T14:30:30Z'),
                r.score      = 0.74,
                r.reason     = 'tower south of fire, in cone';
MATCH (a:Asset {id:'STAGE-1'}), (f:Fire {id:'FIRE-BEAR-001'})
MERGE (a)-[r:AT_RISK_FROM {zoneId:'RZ-002'}]->(f)
  ON CREATE SET r.activeFrom = datetime('2026-08-15T14:30:30Z'),
                r.score      = 0.66,
                r.reason     = 'staging area now upwind-adjacent to spread';

MATCH (a:Asset {id:'SOUTH-HAMLET'}), (f:Fire {id:'FIRE-BEAR-001'})
MERGE (a)-[r:AT_RISK_FROM {zoneId:'RZ-002'}]->(f)
  ON CREATE SET r.activeFrom = datetime('2026-08-15T14:30:30Z'),
                r.score      = 0.74,
                r.reason     = 'community directly in SSE spread cone post-shift';

MATCH (a:Asset {id:'WATER-TREAT'}), (f:Fire {id:'FIRE-BEAR-001'})
MERGE (a)-[r:AT_RISK_FROM {zoneId:'RZ-002'}]->(f)
  ON CREATE SET r.activeFrom = datetime('2026-08-15T14:30:30Z'),
                r.score      = 0.68,
                r.reason     = 'water intake threatened by SSE spread and ember transport';

MATCH (a:Asset {id:'HWY-3'}), (f:Fire {id:'FIRE-BEAR-001'})
MERGE (a)-[r:AT_RISK_FROM {zoneId:'RZ-002'}]->(f)
  ON CREATE SET r.activeFrom = datetime('2026-08-15T14:30:30Z'),
                r.score      = 0.55,
                r.reason     = 'western valley approach affected by SSE spread';

// New IN_ZONE memberships
MATCH (a:Asset), (rz:WildfireRiskZone {id:'RZ-002'})
WHERE a.id IN ['SUB-BEAR-1','GAS-REG-3','HWY-11-S','COMMS-TOWER-2','STAGE-1']
MERGE (a)-[m:IN_ZONE]->(rz)
  ON CREATE SET m.activeFrom = datetime('2026-08-15T14:30:30Z');


// --- t=32 14:32:00 REC-FIRE-002 SUPERSEDES REC-FIRE-001 ---
MERGE (rec:DispatchRecommendation {id:'REC-FIRE-002'})
  ON CREATE SET rec += {id:'REC-FIRE-002',
    proposedAt: datetime('2026-08-15T14:32:00Z'),
    accepted:true, supersedesId:'REC-FIRE-001',
    summary:'De-energize LINE-NE-7, isolate GAS-REG-3, open SUB-BEAR-1 south feeder, relocate STAGE-1, switch evac to HWY-11-S',
    horizonMin:45};
MATCH (rec:DispatchRecommendation {id:'REC-FIRE-002'}),
      (prev:DispatchRecommendation {id:'REC-FIRE-001'})
MERGE (rec)-[:SUPERSEDES]->(prev);
MATCH (rec:DispatchRecommendation {id:'REC-FIRE-002'}),
      (se:SpreadEstimate {id:'SPREAD-002'})
MERGE (rec)-[:DERIVED_FROM]->(se);
MATCH (rec:DispatchRecommendation {id:'REC-FIRE-002'}),
      (f:Fire {id:'FIRE-BEAR-001'})
MERGE (rec)-[:ADDRESSES]->(f);

// Rejected candidates with CONSIDERED_BY edges into the chosen plan
MERGE (cand:DispatchRecommendation {id:'REC-CAND-FIRE-002-A'})
  ON CREATE SET cand += {id:'REC-CAND-FIRE-002-A',
    proposedAt: datetime('2026-08-15T14:31:50Z'),
    accepted:false,
    summary:'Hold current position; monitor wind for 10 minutes'};
MERGE (cand:DispatchRecommendation {id:'REC-CAND-FIRE-002-B'})
  ON CREATE SET cand += {id:'REC-CAND-FIRE-002-B',
    proposedAt: datetime('2026-08-15T14:31:55Z'),
    accepted:false,
    summary:'Evacuate west sector of TOWN-BEAR'};
MATCH (cand:DispatchRecommendation {id:'REC-CAND-FIRE-002-A'}),
      (chosen:DispatchRecommendation {id:'REC-FIRE-002'})
MERGE (cand)-[c:CONSIDERED_BY {rank:2, rejected:true,
        reason:'wind shift already corroborated by 3 cubes; delay unsafe'}]->(chosen);
MATCH (cand:DispatchRecommendation {id:'REC-CAND-FIRE-002-B'}),
      (chosen:DispatchRecommendation {id:'REC-FIRE-002'})
MERGE (cand)-[c:CONSIDERED_BY {rank:3, rejected:true,
        reason:'west sector not in spread cone; would scatter limited crews'}]->(chosen);


// --- t=35 14:35:00 APPROVAL + EXECUTIONS ---
// IC approves human portions
MERGE (app:Approval {id:'APP-FIRE-002'})
  ON CREATE SET app += {id:'APP-FIRE-002',
    at: datetime('2026-08-15T14:35:00Z'),
    approverType:'human', approverId:'OP-IC-001', status:'approved'};
MATCH (app:Approval {id:'APP-FIRE-002'}), (rec:DispatchRecommendation {id:'REC-FIRE-002'})
MERGE (app)-[:APPROVES]->(rec);
MATCH (app:Approval {id:'APP-FIRE-002'}), (op:Operator {id:'OP-IC-001'})
MERGE (op)-[:ISSUED]->(app);

// ATCO envelope approval for the asset-protection actions (auto, triggered by REGCOND)
MERGE (app:Approval {id:'APP-FIRE-002-ENV'})
  ON CREATE SET app += {id:'APP-FIRE-002-ENV',
    at: datetime('2026-08-15T14:35:05Z'),
    approverType:'envelope', approverId:'OP-ATCO-001',
    status:'approved', envelope:'asset_in_fire_envelope'};
MATCH (app:Approval {id:'APP-FIRE-002-ENV'}), (rec:DispatchRecommendation {id:'REC-FIRE-002'})
MERGE (app)-[:APPROVES]->(rec);
MATCH (rc:RegulatoryCondition {id:'REGCOND-ASSET-IN-FIRE-ENVELOPE'}),
      (app:Approval {id:'APP-FIRE-002-ENV'})
MERGE (rc)-[:TRIGGERED {at: datetime('2026-08-15T14:35:00Z')}]->(app);

// Executions
UNWIND [
  {id:'EX-FIRE-002-A', action:'deenergize',    target:'LINE-NE-7',  channel:'atco_scada',         appId:'APP-FIRE-002-ENV'},
  {id:'EX-FIRE-002-B', action:'isolate_valve', target:'GAS-REG-3',  channel:'gas_scada',          appId:'APP-FIRE-002-ENV'},
  {id:'EX-FIRE-002-C', action:'open_breaker',  target:'SUB-BEAR-1.south_feeder', channel:'atco_scada', appId:'APP-FIRE-002-ENV'},
  {id:'EX-FIRE-002-D', action:'crew_relocate', target:'STAGE-1->west_of_HWY-11', channel:'fire_dispatch', appId:'APP-FIRE-002'},
  {id:'EX-FIRE-002-E', action:'evac_reroute',  target:'HWY-11-S',   channel:'municipal_alerting', appId:'APP-FIRE-002'}
] AS x
MERGE (ex:ExecutionAction {id: x.id})
  ON CREATE SET ex += {id:x.id, at: datetime('2026-08-15T14:35:30Z'),
    action:x.action, target:x.target, channel:x.channel}
WITH ex, x
MATCH (app:Approval {id: x.appId})
MERGE (ex)-[:EXECUTES]->(app);

// Execution results
UNWIND [
  {id:'ER-FIRE-002-A', exId:'EX-FIRE-002-A', at:'2026-08-15T14:36:10Z', status:'success', note:'line de-energized; breakers open both ends'},
  {id:'ER-FIRE-002-B', exId:'EX-FIRE-002-B', at:'2026-08-15T14:36:45Z', status:'success', note:'block valve closed; downstream pressure decay nominal'},
  {id:'ER-FIRE-002-C', exId:'EX-FIRE-002-C', at:'2026-08-15T14:36:20Z', status:'success', note:'south feeder isolated; ~140 customers on outage'},
  {id:'ER-FIRE-002-D', exId:'EX-FIRE-002-D', at:'2026-08-15T14:42:00Z', status:'success', note:'crew arrived new staging point'},
  {id:'ER-FIRE-002-E', exId:'EX-FIRE-002-E', at:'2026-08-15T14:38:00Z', status:'success', note:'evac reroute broadcast; HWY-11-N closed at km 4'}
] AS r
MERGE (er:ExecutionResult {id: r.id})
  ON CREATE SET er += {id:r.id, at: datetime(r.at), status:r.status, note:r.note}
WITH er, r
MATCH (ex:ExecutionAction {id: r.exId})
MERGE (er)-[:CONFIRMS]->(ex);

// South hamlet and water works (REC-FIRE-002, APP-FIRE-002)
MATCH (app:Approval {id:'APP-FIRE-002'})
MERGE (ex:ExecutionAction {id:'EX-FIRE-002-F'})
  ON CREATE SET ex.action='evacuation_order', ex.target='SOUTH-HAMLET',
                ex.channel='municipal_alerting', ex.at=datetime('2026-08-15T14:35:30Z')
MERGE (ex)-[:EXECUTES]->(app);

MERGE (er:ExecutionResult {id:'ER-FIRE-002-F'})
  ON CREATE SET er.status='success', er.note='south hamlet evacuation broadcast; 140 residents notified',
                er.at=datetime('2026-08-15T14:37:00Z')
MERGE (er)-[:CONFIRMS]->(ex);

MATCH (app:Approval {id:'APP-FIRE-002'})
MERGE (ex:ExecutionAction {id:'EX-FIRE-002-G'})
  ON CREATE SET ex.action='intake_shutdown', ex.target='WATER-TREAT',
                ex.channel='municipal_services', ex.at=datetime('2026-08-15T14:35:30Z')
MERGE (ex)-[:EXECUTES]->(app);

MERGE (er:ExecutionResult {id:'ER-FIRE-002-G'})
  ON CREATE SET er.status='success', er.note='intake valves closed; reservoir at 72% capacity; backup supply active',
                er.at=datetime('2026-08-15T14:39:00Z')
MERGE (er)-[:CONFIRMS]->(ex);

// SSE flank support — activated on APP-FIRE-002
MATCH (app:Approval {id:'APP-FIRE-002'})
MERGE (ex:ExecutionAction {id:'EX-FIRE-002-H'})
  ON CREATE SET ex.action='mobilize_support', ex.target='FIRE-HALL-S + HELIPAD-2 + REC-CTR-W + FUEL-CACHE-S',
                ex.channel='fire_dispatch', ex.at=datetime('2026-08-15T14:35:30Z'),
                ex.note='SSE flank support package activated; NE package stood down'
MERGE (ex)-[:EXECUTES]->(app);

MERGE (er:ExecutionResult {id:'ER-FIRE-002-H'})
  ON CREATE SET er.status='success', er.note='all 4 SSE support assets activated; NE pack demobilised',
                er.at=datetime('2026-08-15T14:40:00Z')
MERGE (er)-[:CONFIRMS]->(ex);


// --- t=55 14:55:00 STABILIZATION ---
MERGE (rd:Reading {id:'RD-TE-PM-055'})
  ON CREATE SET rd += {id:'RD-TE-PM-055', at: datetime('2026-08-15T14:55:00Z'),
    tag:'pm_sensor.pm25', value:62.0, units:'ug/m3', trend:'falling'};
MATCH (s:Sensor {id:'EW-TOWN-E:SENSOR-pm_sensor'}), (rd:Reading {id:'RD-TE-PM-055'})
MERGE (s)-[:PRODUCES]->(rd);

MERGE (d:Detection {id:'DET-STABLE-055'})
  ON CREATE SET d += {id:'DET-STABLE-055', at: datetime('2026-08-15T14:55:00Z'),
    model:'spread_estimator_v1', kind:'spread_stabilized',
    confidence:0.81, present:true,
    note:'wind holding 310 deg across all 5 cubes; thermal perimeter not advancing'};
MATCH (i:Interface {id:'EW-RIDGE-S:IFACE-aiInt'}), (d:Detection {id:'DET-STABLE-055'})
MERGE (i)-[:EMITS]->(d);
MATCH (d:Detection {id:'DET-STABLE-055'}), (f:Fire {id:'FIRE-BEAR-001'})
MERGE (d)-[:UPDATES]->(f);


// --- t=90 15:30:00 AUDIT ---
MERGE (au:AuditRecord {id:'AUDIT-BEAR-2026-001'})
  ON CREATE SET au += {id:'AUDIT-BEAR-2026-001',
    at: datetime('2026-08-15T15:30:00Z'),
    kind:'wildfire_incident',
    summary:'Bear Creek Fire 001 - ignition to stabilization; 2 recommendations, 1 superseded; gas + substation isolated; no asset loss; ~140 customer outage 23 min',
    regulationId:'REG-WILDFIRE-2026'};
MATCH (au:AuditRecord {id:'AUDIT-BEAR-2026-001'}), (f:Fire {id:'FIRE-BEAR-001'})
MERGE (au)-[:DOCUMENTS]->(f);
MATCH (au:AuditRecord {id:'AUDIT-BEAR-2026-001'}), (rec:DispatchRecommendation)
WHERE rec.id IN ['REC-FIRE-001','REC-FIRE-002']
MERGE (au)-[:DOCUMENTS]->(rec);
MATCH (au:AuditRecord {id:'AUDIT-BEAR-2026-001'}), (app:Approval)
WHERE app.id IN ['APP-FIRE-001','APP-FIRE-002','APP-FIRE-002-ENV']
MERGE (au)-[:DOCUMENTS]->(app);
MATCH (au:AuditRecord {id:'AUDIT-BEAR-2026-001'}), (ex:ExecutionAction)
WHERE ex.id STARTS WITH 'EX-FIRE-'
MERGE (au)-[:DOCUMENTS]->(ex);
MATCH (au:AuditRecord {id:'AUDIT-BEAR-2026-001'}), (er:ExecutionResult)
WHERE er.id STARTS WITH 'ER-FIRE-'
MERGE (au)-[:DOCUMENTS]->(er);

// =============================================================================
// End of load
// =============================================================================
