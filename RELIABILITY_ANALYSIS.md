# What Netflix Means by “SQL Analysis Test”

This is **not** a LeetCode-style SQL quiz.

Netflix uses SQL to evaluate:

- **Analytical thinking**
- **Data judgment**
- **Ability to reason about user impact & reliability**
- **How you explore messy, real-world data**

They care as much about **how you think** as the final query.

---

## 1. What the Test Usually Looks Like

You’ll typically get:

- **1–3 realistic tables**
- A **business / reliability problem**
- **Open-ended questions** like:
  - “What’s happening?”
  - “Where would you look next?”
  - “How would you validate this?”

### Common table themes

- `playback_events` — stream start/stop/failure/buffer
- `device_sessions` — session-level device/env
- `errors` / `crashes`
- `device_metadata`
- `rollouts` or experiments

### Columns you’ll see

- `device_type`, `device_model`, `os_version`, `app_version`
- `event_time`, `event_date`, `event_type`
- `error_code`, `session_id`, `country` / `region`

---

## 2. Test Environment (This Repo)

After `docker compose up -d`, you have the content/watch tables (from the main README) **and** the reliability tables below.  
If you already had the DB running before the reliability files were added, recreate the DB so the new tables load:

```bash
docker compose down -v
docker compose up -d
```

Then you have these **practice tables** (exact columns for interview-style queries):

| Table              | Columns |
|--------------------|--------|
| `playback_events`  | `session_id`, `device_id`, `event_type`, `event_time`, `app_version` |
| `device_sessions`  | `session_id`, `device_type`, `device_model`, `os_version`, `country` |
| `errors`           | `session_id`, `error_code`, `event_time` |
| `crashes`          | `device_id`, `crash_time` |
| `rollouts`         | `app_version`, `rollout_date` |
| `devices`          | `device_id`, `manufacturer`, `model` |

Get device_type / device_model by joining `playback_events` → `device_sessions` (on `session_id`) or `playback_events` → `devices` (on `device_id`). Use `event_time::date` or `DATE_TRUNC('day', event_time)` for date filters.

**Scenario in the seed data:**

- **Baseline week:** 2025-12-25 → 2025-12-31 (mostly 4.2.1, normal failure rate).
- **“Last week”:** 2026-01-01 → 2026-01-07 — more failures; app_version **4.3.0** rolled out 2026-01-02.
- Some **device models** (e.g. Roku Ultra, Fire TV Stick) have higher failure rates; `errors` and `crashes` are populated for affected sessions/devices.

Use this to practice: slice by device (via JOINs), compare before/after, normalize by sessions/volume, correlate with rollouts.

---

## 3. Netflix-Style Test Cases (Open-Ended)

Practice answering as you would in an interview: **narrate your thinking**, then write SQL.

### Test case 1: Reliability regression

**Prompt:** “Playback failures increased last week. Investigate.”

- **What they want:** Slice by device cohort, look for regressions, avoid global averages.
- **Practice:** Write a query that breaks down failures by `device_type` and `device_model` for last week. Then add **before vs after** (e.g. same cohort in baseline week). Then **normalize by total events** (failure rate, not raw count).
- **Example “good” instinct:**  
  `GROUP BY device_type, device_model` with `event_date BETWEEN '2026-01-01' AND '2026-01-07'` and `event_type = 'failure'`, then extend to rates and baseline comparison.

### Test case 2: User impact focus

**Prompt:** “Which devices are most affected?”

- **What they want:** Not raw counts only — **rates** (e.g. failure rate per device model), and **sample size** (e.g. HAVING COUNT(*) > 1000 or a minimum volume).
- **Practice:** For each `device_model`, compute  
  `failure_rate = COUNT(CASE WHEN event_type = 'failure' THEN 1 END) * 1.0 / COUNT(*)`  
  and use `HAVING COUNT(*) > 1000` (or a lower threshold for this dataset) so you don’t over-interpret tiny cohorts.
- **Example sentence:** “I’m using failure rate and filtering to cohorts with enough volume so the rate is meaningful.”

### Test case 3: Rollout correlation

**Prompt:** “A new app version was released. Did it cause issues?”

- **What they want:** Cohort analysis by `app_version`, and **correlation with rollout timing** (use `rollouts`).
- **Practice:** Compute failure rate by `app_version` for last week. Then say: “I’d compare this against rollout timing and device cohorts to rule out confounders.”
- **Practice query:** `GROUP BY app_version` with failure rate; join or reference `rollouts` to see when 4.3.0 started.

### Test case 4: Where would you look next?

**Prompt:** “You see a spike in failures on Roku. What would you do next?”

- **What they want:** Next steps in analysis, not just one query.
- **Practice (verbal + optional SQL):** “I’d break down by `device_model`, `os_version`, and `app_version`; then check rollout calendar; then look at `error_code` mix and by country.”

### Test case 5: How would you validate this?

**Prompt:** “How would you validate that 4.3.0 caused the regression?”

- **What they want:** Data quality and causality thinking.
- **Practice (verbal):** “I’d check: same device/OS mix before and after; A/B or phased rollout if available; error_code distribution; and whether the increase is concentrated in the post-rollout window.”

---

## 4. What Netflix Is Really Scoring You On

### Strong signals

- You **normalize** (rates, not just counts).
- You **segment** (devices, OS, region, app_version).
- You **explain why** you’re running each query.
- You think about **next steps** and **validation**.
- You **question data quality** and confounders.

### Weak signals

- One giant query with no explanation.
- Global averages only.
- No rollout or cohort thinking.
- “The number is higher” with no context or rate.

---

## 5. How to Talk While Writing SQL

Say things like:

- “I want to first confirm if this is isolated or systemic.”
- “I’ll normalize by sessions / total events to avoid volume bias.”
- “If this shows a spike, my next step would be…”
- “I’d sanity-check sample sizes here with a HAVING clause.”

**This matters almost as much as the SQL.**

---

## 6. Device Reliability Angles to Use

- **Device cohort analysis** (device_type, device_model).
- **OS / firmware version skew.**
- **Gradual rollout effects** (rollouts table, time windows).
- **Partner-specific anomalies** (e.g. one OEM).
- **Long-tail devices** (small cohorts with high failure rate).

Example: *“I’d look for small cohorts with disproportionately high failure rates — those often indicate device-specific regressions.”*

---

## 7. SQL Patterns to Be Comfortable With

- `GROUP BY`, `HAVING`
- `CASE WHEN` (e.g. counting failures, bucketing)
- Window functions (`ROW_NUMBER`, `LAG`) — nice to have
- Time bucketing (`event_date`, `DATE_TRUNC`)
- Joining fact table with metadata (e.g. `rollouts`)
- Handling NULLs (e.g. `error_code`)

Netflix cares more about **clarity and judgment** than exotic syntax.

---

## 8. How to End Your Analysis (Big Netflix Signal)

Always end with **actionability**:

- *“Based on this, I’d pause the rollout for affected device cohorts and add targeted monitoring before resuming.”*

They want **decisions**, not just dashboards.

---

## 9. One Netflix SQL Mental Model

**“Slice first, normalize second, explain always, decide last.”**

1. **Slice** — Break down by device, app_version, time, region.
2. **Normalize** — Use rates (e.g. failures / total events), not just counts; consider sample size.
3. **Explain** — Why this query, what you’re checking, what could be misleading.
4. **Decide** — What you’d do next (monitoring, rollback, validation).

---

## 10. Running the Practice Queries

Connect to the same DB as in the main README (port **5433**). The reliability tables are in the same database:

```bash
docker exec -it netflix-sql-practice psql -U netflix -d netflix_db
```

Example checks:

```sql
-- Quick sanity check
SELECT event_date, event_type, app_version, device_model, COUNT(*)
FROM playback_events
WHERE event_date BETWEEN '2025-12-25' AND '2026-01-07'
GROUP BY 1, 2, 3, 4
ORDER BY 1, 2, 3, 4;
```

Example solutions that follow the mental model above are in **`solutions_reliability.sql`**. Try the test cases yourself first, then compare.
