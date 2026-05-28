# Bear Creek Fire — EdgeWorks + reView Demo Guide
### For Sales Use

---

## What This Demo Shows

This is a **55-minute wildfire scenario compressed into a 5-minute walkthrough**. It demonstrates how EdgeWorks sensor units and the reView platform detect a wildfire, generate AI-driven recommendations, route approvals, and execute responses — all before a single asset is lost.

The headline outcome: **0 asset losses. 140 customers out for only 23 minutes.**

---

## Before You Start

1. Open `demo.html` in a modern browser (Chrome or Edge recommended).
2. Make sure you have an internet connection — the map tiles load from the web.
3. The demo starts paused at **T+00:00 (Ignition)**. Nothing moves until you press Play.

---

## Screen Layout

| Area | What It Shows |
|---|---|
| **Left panel** | Incident event feed — each event as it occurs |
| **Center map** | Live fire position, spread cone, wind arrows, at-risk assets |
| **Right panel** | Support assets in the area + assets currently at risk |
| **Bottom bar** | Timeline playback controls |
| **Map banner** | Large-text summary of the current event (great for presentations) |

---

## Playback Controls

| Button | Action |
|---|---|
| **▶ Play/Pause** | Start or pause the automated walkthrough |
| **◀ / ▶▶** | Step backward or forward one event at a time |
| **speed** | Cycle through 1×, 2×, 4× playback speeds |
| **Timeline dots** | Click any dot to jump directly to that event |

> **Tip for demos:** Use **step-by-step mode (◀ / ▶▶)** so you control the pace and can talk through each event. Use **auto-play at 2×** for a quick overview with a time-pressed prospect.

---

## The 10-Step Story — What to Say at Each Step

### Step 1 — T+00:00 · Ignition
**What happens:** EdgeWorks-Ridge-North thermal camera sees a 312°C hotspot. The `fire_detector_v3` model fires at 0.94 confidence.

**What to say:** *"The moment a hotspot appears, EdgeWorks sees it. One sensor, sub-second detection, 94% confidence before any human is involved."*

---

### Step 2 — T+00:03 · Smoke Corroborated
**What happens:** EdgeWorks-Valley-West PM2.5 jumps from 8 to 95 µg/m³. A second AI model (`smoke_classifier_v2`) independently confirms.

**What to say:** *"Three minutes in, a second unit — miles away — confirms with air quality data. This is multi-sensor corroboration happening automatically. No radio calls, no manual checklist."*

---

### Step 3 — T+00:05 · First Spread Estimate
**What happens:** Wind arrows appear on all 5 EdgeWorks units. A spread cone projects the fire northeast. The hospital, school, and town center light up as at-risk (orange/red on the map).

**What to say:** *"Five units report wind from the southwest. reView calculates a spread vector — 60° northeast at 1.2 m/s — and immediately flags the assets in the cone. The IC hasn't picked up a phone yet."*

> **Point to the map:** Show the spread cone and the assets that glow red in the right panel.

---

### Step 4 — T+00:12 · First Recommendation Approved
**What happens:** REC-FIRE-001 is generated and approved: evacuate east sector, prep crews northeast, put ATCO on standby for the power line.

**What to say:** *"reView drafts a recommendation. The IC approves it in one click. From detection to approved action plan — 12 minutes."*

---

### Step 5 — T+00:28 · Wind Shift ⚠ (The Key Moment)
**What happens:** The EW-RIDGE-N anemometer shows wind direction jumping from 240° to 305° in 90 seconds. Speed increases from 15 to 22 km/h. The timeline dot for this step is larger and orange — it's a **wind shift event**.

**What to say:** *"This is the moment that kills people. The wind shifts 65 degrees in 90 seconds. A crew following the old plan is now in the path of the fire. EdgeWorks catches it in real time."*

> **Pause here.** This is your biggest wow moment. Let it land before clicking forward.

---

### Step 6 — T+00:30 · New Spread Estimate (SSE)
**What happens:** All 5 units corroborate the shift. The spread cone swings south-southeast. The right panel asset list completely changes — South Hamlet, Water Treatment, and the substation are now at risk. The hospital and school are now safe.

**What to say:** *"Two minutes after the wind shift, the entire risk picture has flipped. The old evacuation route is now the danger zone. A new spread cone, new at-risk assets, new plan — automatically."*

---

### Step 7 — T+00:32 · REC-FIRE-002 Supersedes REC-FIRE-001
**What happens:** A new recommendation is generated that overrides the first one. Actions: de-energize LINE-NE-7, isolate GAS-REG-3, open the south feeder on the substation, relocate staging area, evacuate via HWY-11-S. Two candidate actions were automatically rejected.

**What to say:** *"reView doesn't just update a map — it generates a new action plan, marks the old one superseded, and shows you exactly which two options it rejected and why. Full audit trail, one decision point."*

---

### Step 8 — T+00:35 · Approvals and Executions
**What happens:** Human IC approves the evacuation and crew actions. ATCO's envelope approval auto-triggers for the asset isolations (pre-authorized by REGCOND). Five execution orders fan out simultaneously.

**What to say:** *"Some actions need a human — the IC signs off on evacuation. Others are pre-authorized within operating envelopes — the utility doesn't need to call anyone to isolate a gas regulator when the conditions are already met. The system knows the difference."*

---

### Step 9 — T+00:55 · Stabilization
**What happens:** Wind holds steady at 310°. The thermal perimeter stops advancing. Air quality at Town-East starts improving.

**What to say:** *"The situation stabilizes. The system is still watching — every sensor still reporting — but the crisis window has passed."*

---

### Step 10 — T+01:30 · Regulatory Audit Packet
**What happens:** A complete audit record is generated: 2 recommendations (1 superseded), 3 approvals, 8 executions, 0 asset loss, 140 customers out for 23 minutes.

**What to say:** *"This is what the regulator gets. Every decision, every data point, every approval — timestamped and traceable. Not a report written after the fact. A live record of exactly what happened and why."*

---

## Map Interactions (Use During Q&A)

- **Click any EdgeWorks unit (blue square)** — shows sensor readings at that moment
- **Click any at-risk asset (orange/red shape)** — shows the threat details and recommended actions
- **Map style buttons (top-right of map)** — switch between Satellite, Topo, and Dark basemap
- **Close the banner (×)** — removes the large overlay to show more of the map; click the pill to bring it back

---

## Closing the Demo

End on the audit step and say:

*"90 minutes. Zero asset losses. Full regulatory record. The difference between this outcome and a bad one was a 90-second wind shift that the system caught automatically and re-planned around — faster than any human could."*

---

## Common Questions

**"Is this real data?"**
The scenario is based on realistic wildfire parameters for a mountain valley environment in western Canada. The sensor readings, spread rates, and response timings are calibrated to real-world values.

**"How many EdgeWorks units does this take?"**
This scenario uses 5 units covering a ~15 km² area. Coverage scales with terrain and asset density.

**"Who approves the recommendations?"**
It depends on the action type. Life-safety actions (evacuation, crew movement) always require human IC approval. Infrastructure actions within pre-authorized envelopes (REGCOND) can be auto-approved. The demo shows both.

**"What if the wind hadn't shifted?"**
Step through without the shift — the original plan holds and the northeast assets stay protected. The point is that the system handles *both* scenarios correctly and automatically.
