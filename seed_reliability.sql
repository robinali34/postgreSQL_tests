-- Netflix SQL Analysis Test: Realistic messy data
-- Scenario: Playback failures increased last week (2026-01-01 to 2026-01-07).
-- New app_version 4.3.0 rolled out 2026-01-02. Some device models show regression.

-- Rollouts (app_version 4.3.0 rolled out during "problem week")
INSERT INTO rollouts (app_version, platform, rollout_start, rollout_end, target_pct) VALUES
('4.2.1', 'all', '2025-11-01', '2026-01-01', 100),
('4.3.0', 'all', '2026-01-02', NULL, 100);

-- Generate playback_events: baseline week (lower failures) + last week (higher failures, 4.3.0, device skew)
-- Device cohorts: iPhone 15 (low failure), Samsung S23 (low), Roku Ultra (HIGH failure last week), Fire TV Stick (HIGH), Android TV (medium)

-- Baseline week 2025-12-25 to 2025-12-31 (all on 4.2.1, normal failure rates)
INSERT INTO playback_events (session_id, event_time, event_date, event_type, device_type, device_model, os_version, app_version, country, error_code)
SELECT
  's_baseline_' || g || '_' || (random() * 1000)::int,
  '2025-12-25'::date + (random() * 6)::int * interval '1 day',
  '2025-12-25'::date + (random() * 6)::int,
  CASE WHEN random() < 0.02 THEN 'failure' ELSE 'play' END,
  d.device_type,
  d.device_model,
  d.os_version,
  '4.2.1',
  d.country,
  CASE WHEN random() < 0.02 THEN 'DRM_FAILURE' ELSE NULL END
FROM generate_series(1, 800) g
CROSS JOIN (
  VALUES
    ('phone', 'iPhone 15', 'iOS 17.2', 'US'),
    ('phone', 'Samsung S23', 'Android 14', 'US'),
    ('tv', 'Roku Ultra', 'Roku OS 12', 'US'),
    ('tv', 'Fire TV Stick', 'Fire OS 8', 'US'),
    ('tv', 'Android TV', 'Android TV 12', 'US')
) AS d(device_type, device_model, os_version, country);

-- Last week 2026-01-01 to 2026-01-07: mix of 4.2.1 (first 2 days) and 4.3.0 (from Jan 2), Roku/Fire TV with HIGH failure rate
INSERT INTO playback_events (session_id, event_time, event_date, event_type, device_type, device_model, os_version, app_version, country, error_code)
SELECT
  's_last_' || g || '_' || (random() * 1000)::int,
  '2026-01-01'::date + (random() * 6)::int * interval '1 day',
  '2026-01-01'::date + (random() * 6)::int,
  CASE
    WHEN d.device_model IN ('Roku Ultra', 'Fire TV Stick') AND random() < 0.12 THEN 'failure'
    WHEN d.device_model = 'Android TV' AND random() < 0.05 THEN 'failure'
    WHEN random() < 0.025 THEN 'failure'
    ELSE 'play'
  END,
  d.device_type,
  d.device_model,
  d.os_version,
  CASE WHEN '2026-01-01'::date + (random() * 6)::int >= '2026-01-02'::date THEN '4.3.0' ELSE '4.2.1' END,
  d.country,
  CASE WHEN random() < 0.08 THEN 'DRM_FAILURE' WHEN random() < 0.04 THEN 'BUFFER_TIMEOUT' ELSE NULL END
FROM generate_series(1, 1200) g
CROSS JOIN (
  VALUES
    ('phone', 'iPhone 15', 'iOS 17.2', 'US'),
    ('phone', 'Samsung S23', 'Android 14', 'US'),
    ('tv', 'Roku Ultra', 'Roku OS 12', 'US'),
    ('tv', 'Fire TV Stick', 'Fire OS 8', 'US'),
    ('tv', 'Android TV', 'Android TV 12', 'US')
) AS d(device_type, device_model, os_version, country);

-- Add more volume so some device_model cohorts exceed 1000 events (for HAVING COUNT(*) > 1000 practice)
INSERT INTO playback_events (session_id, event_time, event_date, event_type, device_type, device_model, os_version, app_version, country, error_code)
SELECT
  's_vol_' || g || '_' || (random() * 5000)::int,
  '2026-01-01'::date + (random() * 6)::int * interval '1 day',
  '2026-01-01'::date + (random() * 6)::int,
  CASE WHEN random() < 0.03 THEN 'failure' ELSE 'play' END,
  'phone',
  'iPhone 15',
  'iOS 17.2',
  CASE WHEN g % 2 = 0 THEN '4.3.0' ELSE '4.2.1' END,
  'US',
  NULL
FROM generate_series(1, 1500) g;

INSERT INTO playback_events (session_id, event_time, event_date, event_type, device_type, device_model, os_version, app_version, country, error_code)
SELECT
  's_vol_roku_' || g || '_' || (random() * 5000)::int,
  '2026-01-01'::date + (random() * 6)::int * interval '1 day',
  '2026-01-01'::date + (random() * 6)::int,
  CASE WHEN random() < 0.10 THEN 'failure' ELSE 'play' END,
  'tv',
  'Roku Ultra',
  'Roku OS 12',
  '4.3.0',
  'US',
  CASE WHEN random() < 0.06 THEN 'DRM_FAILURE' ELSE NULL END
FROM generate_series(1, 1200) g;
