-- Netflix SQL Analysis Test — Example solutions
-- Tables: playback_events(session_id, device_id, event_type, event_time, app_version)
--         device_sessions(session_id, device_type, device_model, os_version, country)
--         errors(session_id, error_code, event_time), crashes(device_id, crash_time)
--         rollouts(app_version, rollout_date), devices(device_id, manufacturer, model)
-- Mental model: Slice first, normalize second, explain always, decide last.

-- =============================================================================
-- Test case 1: Reliability regression — "Playback failures increased last week."
-- =============================================================================

-- Step 1: Slice by device cohort (JOIN device_sessions for device_type, device_model)
SELECT
  ds.device_type,
  ds.device_model,
  COUNT(*) AS failures
FROM playback_events pe
JOIN device_sessions ds ON pe.session_id = ds.session_id
WHERE pe.event_type = 'failure'
  AND pe.event_time::date BETWEEN '2026-01-01' AND '2026-01-07'
GROUP BY ds.device_type, ds.device_model
ORDER BY failures DESC;

-- Step 2: Normalize by total events (failure rate)
SELECT
  ds.device_type,
  ds.device_model,
  COUNT(*) AS total_events,
  COUNT(CASE WHEN pe.event_type = 'failure' THEN 1 END) AS failures,
  ROUND(
    COUNT(CASE WHEN pe.event_type = 'failure' THEN 1 END) * 1.0 / NULLIF(COUNT(*), 0),
    4
  ) AS failure_rate
FROM playback_events pe
JOIN device_sessions ds ON pe.session_id = ds.session_id
WHERE pe.event_time::date BETWEEN '2026-01-01' AND '2026-01-07'
GROUP BY ds.device_type, ds.device_model
HAVING COUNT(*) > 50
ORDER BY failure_rate DESC;

-- Step 3: Compare before vs after (baseline week vs last week)
WITH last_week AS (
  SELECT
    ds.device_type,
    ds.device_model,
    COUNT(*) AS total,
    COUNT(CASE WHEN pe.event_type = 'failure' THEN 1 END) * 1.0 / NULLIF(COUNT(*), 0) AS failure_rate
  FROM playback_events pe
  JOIN device_sessions ds ON pe.session_id = ds.session_id
  WHERE pe.event_time::date BETWEEN '2026-01-01' AND '2026-01-07'
  GROUP BY ds.device_type, ds.device_model
),
baseline_week AS (
  SELECT
    ds.device_type,
    ds.device_model,
    COUNT(*) AS total,
    COUNT(CASE WHEN pe.event_type = 'failure' THEN 1 END) * 1.0 / NULLIF(COUNT(*), 0) AS failure_rate
  FROM playback_events pe
  JOIN device_sessions ds ON pe.session_id = ds.session_id
  WHERE pe.event_time::date BETWEEN '2025-12-25' AND '2025-12-31'
  GROUP BY ds.device_type, ds.device_model
)
SELECT
  l.device_type,
  l.device_model,
  b.total AS baseline_events,
  b.failure_rate AS baseline_rate,
  l.total AS last_week_events,
  l.failure_rate AS last_week_rate,
  ROUND((l.failure_rate - b.failure_rate)::numeric, 4) AS rate_delta
FROM last_week l
JOIN baseline_week b ON l.device_type = b.device_type AND l.device_model = b.device_model
WHERE l.total > 50
ORDER BY rate_delta DESC;

-- =============================================================================
-- Test case 2: User impact — "Which devices are most affected?"
-- =============================================================================
SELECT
  ds.device_model,
  COUNT(*) AS total_events,
  COUNT(CASE WHEN pe.event_type = 'failure' THEN 1 END) AS failures,
  ROUND(
    COUNT(CASE WHEN pe.event_type = 'failure' THEN 1 END) * 1.0 / NULLIF(COUNT(*), 0),
    4
  ) AS failure_rate
FROM playback_events pe
JOIN device_sessions ds ON pe.session_id = ds.session_id
WHERE pe.event_time::date BETWEEN '2026-01-01' AND '2026-01-07'
GROUP BY ds.device_model
HAVING COUNT(*) > 50
ORDER BY failure_rate DESC;

-- =============================================================================
-- Test case 3: Rollout correlation — "Did the new app version cause issues?"
-- =============================================================================
SELECT
  pe.app_version,
  COUNT(*) AS total_events,
  COUNT(CASE WHEN pe.event_type = 'failure' THEN 1 END) AS failures,
  ROUND(
    COUNT(CASE WHEN pe.event_type = 'failure' THEN 1 END) * 1.0 / NULLIF(COUNT(*), 0),
    4
  ) AS failure_rate
FROM playback_events pe
WHERE pe.event_time::date BETWEEN '2026-01-01' AND '2026-01-07'
GROUP BY pe.app_version
ORDER BY pe.app_version;

SELECT app_version, rollout_date FROM rollouts ORDER BY rollout_date;

-- =============================================================================
-- Test case 4: "Where would you look next?" — errors and crashes
-- =============================================================================
-- Error codes by session (e.g. for Roku)
SELECT e.session_id, e.error_code, e.event_time, ds.device_model
FROM errors e
JOIN device_sessions ds ON e.session_id = ds.session_id
WHERE ds.device_model = 'Roku Ultra'
ORDER BY e.event_time;

-- Crashes by device (join devices for manufacturer, model)
SELECT c.device_id, d.manufacturer, d.model, c.crash_time
FROM crashes c
JOIN devices d ON c.device_id = d.device_id
ORDER BY c.crash_time;

-- =============================================================================
-- Test case 5: Validate (failure rate by app_version and week)
-- =============================================================================
SELECT
  pe.app_version,
  DATE_TRUNC('week', pe.event_time)::date AS week_start,
  COUNT(*) AS total,
  ROUND(
    COUNT(CASE WHEN pe.event_type = 'failure' THEN 1 END) * 1.0 / NULLIF(COUNT(*), 0),
    4
  ) AS failure_rate
FROM playback_events pe
WHERE pe.event_time::date BETWEEN '2025-12-25' AND '2026-01-07'
GROUP BY pe.app_version, DATE_TRUNC('week', pe.event_time)
ORDER BY pe.app_version, week_start;

-- =============================================================================
-- Extra: Practice JOINs across all 6 tables
-- =============================================================================
-- Sessions with at least one failure and their error codes
SELECT ds.session_id, ds.device_model, ds.country, pe.app_version,
       COUNT(CASE WHEN pe.event_type = 'failure' THEN 1 END) AS failures,
       (SELECT STRING_AGG(e.error_code, ', ') FROM errors e WHERE e.session_id = ds.session_id) AS error_codes
FROM playback_events pe
JOIN device_sessions ds ON pe.session_id = ds.session_id
WHERE pe.event_time::date BETWEEN '2026-01-01' AND '2026-01-07'
GROUP BY ds.session_id, ds.device_model, ds.country, pe.app_version
HAVING COUNT(CASE WHEN pe.event_type = 'failure' THEN 1 END) > 0
ORDER BY failures DESC;

-- Devices that have both playback events and at least one crash
SELECT d.device_id, d.manufacturer, d.model,
       COUNT(DISTINCT pe.event_id) AS playback_events,
       COUNT(DISTINCT c.crash_id) AS crash_count
FROM devices d
LEFT JOIN playback_events pe ON d.device_id = pe.device_id
LEFT JOIN crashes c ON d.device_id = c.device_id
GROUP BY d.device_id, d.manufacturer, d.model
HAVING COUNT(DISTINCT c.crash_id) > 0
ORDER BY crash_count DESC;
