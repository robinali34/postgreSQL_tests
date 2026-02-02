-- SQL examples to run with:  python db.py -f examples.sql
-- Or copy-paste one query:  python db.py "SELECT ... ;"

-- ========== Content / watch schema ==========

-- List content (movies and TV shows)
SELECT content_id, title, content_type, genre, release_year
FROM content
ORDER BY release_year DESC
LIMIT 10;

-- Total hours watched per user (Jan 2024)
SELECT user_id, ROUND(SUM(hours_watched)::numeric, 2) AS total_hours
FROM watching_activity
WHERE watch_date >= '2024-01-01' AND watch_date < '2024-02-01'
GROUP BY user_id
ORDER BY total_hours DESC
LIMIT 5;

-- Average rating per content title
SELECT c.title, ROUND(AVG(r.stars)::numeric, 2) AS avg_stars, COUNT(r.review_id) AS review_count
FROM content c
JOIN reviews r ON c.content_id = r.content_id
GROUP BY c.content_id, c.title
ORDER BY avg_stars DESC
LIMIT 5;

-- Users by subscription plan (current)
SELECT plan_type, COUNT(DISTINCT user_id) AS user_count
FROM subscriptions
WHERE end_date IS NULL
GROUP BY plan_type
ORDER BY user_count DESC;

-- ========== Practice tables (playback, devices, errors, crashes) ==========

-- List devices
SELECT device_id, manufacturer, model FROM devices;

-- App version rollout dates
SELECT app_version, rollout_date FROM rollouts ORDER BY rollout_date;

-- Playback events: failures by device model (last week)
SELECT ds.device_model, COUNT(*) AS failures
FROM playback_events pe
JOIN device_sessions ds ON pe.session_id = ds.session_id
WHERE pe.event_type = 'failure'
  AND pe.event_time::date BETWEEN '2026-01-01' AND '2026-01-07'
GROUP BY ds.device_model
ORDER BY failures DESC;

-- Failure rate by device model (last week, min 10 events)
SELECT ds.device_model,
  COUNT(*) AS total_events,
  COUNT(CASE WHEN pe.event_type = 'failure' THEN 1 END) AS failures,
  ROUND(COUNT(CASE WHEN pe.event_type = 'failure' THEN 1 END) * 1.0 / NULLIF(COUNT(*), 0), 4) AS failure_rate
FROM playback_events pe
JOIN device_sessions ds ON pe.session_id = ds.session_id
WHERE pe.event_time::date BETWEEN '2026-01-01' AND '2026-01-07'
GROUP BY ds.device_model
HAVING COUNT(*) >= 10
ORDER BY failure_rate DESC;

-- Errors with session device info
SELECT e.session_id, e.error_code, e.event_time, ds.device_model, ds.country
FROM errors e
JOIN device_sessions ds ON e.session_id = ds.session_id
ORDER BY e.event_time DESC
LIMIT 10;

-- Crashes with device info
SELECT c.device_id, d.manufacturer, d.model, c.crash_time
FROM crashes c
JOIN devices d ON c.device_id = d.device_id
ORDER BY c.crash_time;
