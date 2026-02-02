-- Sample data for practice tables
-- Scenario: multiple devices, app versions 4.2.1 and 4.3.0, sessions with playback/errors, some device crashes

-- devices(device_id, manufacturer, model)
INSERT INTO devices (device_id, manufacturer, model) VALUES
('d1', 'Apple', 'iPhone 15'),
('d2', 'Samsung', 'Galaxy S23'),
('d3', 'Roku', 'Roku Ultra'),
('d4', 'Amazon', 'Fire TV Stick'),
('d5', 'Sony', 'Android TV'),
('d6', 'Apple', 'iPhone 14'),
('d7', 'Google', 'Chromecast'),
('d8', 'Samsung', 'Smart TV Tizen');

-- rollouts(app_version, rollout_date)
INSERT INTO rollouts (app_version, rollout_date) VALUES
('4.2.1', '2025-11-01'),
('4.3.0', '2026-01-02');

-- device_sessions(session_id, device_type, device_model, os_version, country)
INSERT INTO device_sessions (session_id, device_type, device_model, os_version, country) VALUES
('s1', 'phone', 'iPhone 15', 'iOS 17.2', 'US'),
('s2', 'phone', 'iPhone 15', 'iOS 17.2', 'US'),
('s3', 'phone', 'Galaxy S23', 'Android 14', 'US'),
('s4', 'tv', 'Roku Ultra', 'Roku OS 12', 'US'),
('s5', 'tv', 'Roku Ultra', 'Roku OS 12', 'US'),
('s6', 'tv', 'Fire TV Stick', 'Fire OS 8', 'US'),
('s7', 'tv', 'Fire TV Stick', 'Fire OS 8', 'US'),
('s8', 'tv', 'Android TV', 'Android TV 12', 'US'),
('s9', 'phone', 'iPhone 14', 'iOS 16.6', 'US'),
('s10', 'phone', 'iPhone 15', 'iOS 17.2', 'UK'),
('s11', 'tv', 'Roku Ultra', 'Roku OS 12', 'UK'),
('s12', 'tv', 'Chromecast', 'Cast 4.0', 'US'),
('s13', 'phone', 'Galaxy S23', 'Android 14', 'CA'),
('s14', 'tv', 'Smart TV Tizen', 'Tizen 7', 'US'),
('s15', 'phone', 'iPhone 15', 'iOS 17.2', 'US'),
('s16', 'tv', 'Roku Ultra', 'Roku OS 11', 'US'),
('s17', 'tv', 'Fire TV Stick', 'Fire OS 7', 'US'),
('s18', 'phone', 'Galaxy S23', 'Android 13', 'US'),
('s19', 'tv', 'Android TV', 'Android TV 11', 'US'),
('s20', 'phone', 'iPhone 15', 'iOS 17.2', 'US');

-- playback_events(session_id, device_id, event_type, event_time, app_version)
-- Map: s1,s2,s9,s10,s15,s20 -> d1 or d6 (iPhone); s3,s13,s18 -> d2; s4,s5,s11,s16 -> d3; s6,s7,s17 -> d4; s8,s19 -> d5; s12 -> d7; s14 -> d8
INSERT INTO playback_events (session_id, device_id, event_type, event_time, app_version) VALUES
('s1', 'd1', 'play', '2026-01-01 10:00:00', '4.2.1'),
('s1', 'd1', 'complete', '2026-01-01 11:30:00', '4.2.1'),
('s2', 'd1', 'play', '2026-01-02 09:00:00', '4.3.0'),
('s2', 'd1', 'failure', '2026-01-02 09:15:00', '4.3.0'),
('s3', 'd2', 'play', '2026-01-01 14:00:00', '4.2.1'),
('s3', 'd2', 'complete', '2026-01-01 15:00:00', '4.2.1'),
('s4', 'd3', 'play', '2026-01-02 20:00:00', '4.3.0'),
('s4', 'd3', 'failure', '2026-01-02 20:05:00', '4.3.0'),
('s4', 'd3', 'play', '2026-01-02 20:10:00', '4.3.0'),
('s4', 'd3', 'complete', '2026-01-02 21:00:00', '4.3.0'),
('s5', 'd3', 'play', '2026-01-03 19:00:00', '4.3.0'),
('s5', 'd3', 'failure', '2026-01-03 19:02:00', '4.3.0'),
('s6', 'd4', 'play', '2026-01-02 21:00:00', '4.3.0'),
('s6', 'd4', 'failure', '2026-01-02 21:10:00', '4.3.0'),
('s7', 'd4', 'play', '2026-01-04 18:00:00', '4.3.0'),
('s7', 'd4', 'buffer', '2026-01-04 18:05:00', '4.3.0'),
('s7', 'd4', 'complete', '2026-01-04 19:00:00', '4.3.0'),
('s8', 'd5', 'play', '2026-01-01 12:00:00', '4.2.1'),
('s8', 'd5', 'complete', '2026-01-01 13:00:00', '4.2.1'),
('s9', 'd6', 'play', '2026-01-02 08:00:00', '4.3.0'),
('s9', 'd6', 'complete', '2026-01-02 09:00:00', '4.3.0'),
('s10', 'd1', 'play', '2026-01-03 10:00:00', '4.3.0'),
('s10', 'd1', 'complete', '2026-01-03 11:00:00', '4.3.0'),
('s11', 'd3', 'play', '2026-01-04 20:00:00', '4.3.0'),
('s11', 'd3', 'failure', '2026-01-04 20:03:00', '4.3.0'),
('s12', 'd7', 'play', '2026-01-01 16:00:00', '4.2.1'),
('s12', 'd7', 'complete', '2026-01-01 17:00:00', '4.2.1'),
('s13', 'd2', 'play', '2026-01-05 14:00:00', '4.3.0'),
('s13', 'd2', 'complete', '2026-01-05 15:00:00', '4.3.0'),
('s14', 'd8', 'play', '2026-01-02 19:00:00', '4.3.0'),
('s14', 'd8', 'complete', '2026-01-02 20:30:00', '4.3.0'),
('s15', 'd1', 'play', '2025-12-28 10:00:00', '4.2.1'),
('s15', 'd1', 'complete', '2025-12-28 11:00:00', '4.2.1'),
('s16', 'd3', 'play', '2025-12-30 20:00:00', '4.2.1'),
('s16', 'd3', 'complete', '2025-12-30 21:00:00', '4.2.1'),
('s17', 'd4', 'play', '2025-12-29 21:00:00', '4.2.1'),
('s17', 'd4', 'failure', '2025-12-29 21:05:00', '4.2.1'),
('s18', 'd2', 'play', '2026-01-06 11:00:00', '4.3.0'),
('s18', 'd2', 'complete', '2026-01-06 12:00:00', '4.3.0'),
('s19', 'd5', 'play', '2026-01-05 13:00:00', '4.3.0'),
('s19', 'd5', 'buffer', '2026-01-05 13:10:00', '4.3.0'),
('s19', 'd5', 'complete', '2026-01-05 14:00:00', '4.3.0'),
('s20', 'd1', 'play', '2026-01-07 09:00:00', '4.3.0'),
('s20', 'd1', 'complete', '2026-01-07 10:00:00', '4.3.0');

-- Sessions for bulk playback (required before playback_events FK)
INSERT INTO device_sessions (session_id, device_type, device_model, os_version, country)
SELECT 's_vol_' || g, 'phone', 'iPhone 15', 'iOS 17.2', 'US' FROM generate_series(1, 200) g;
INSERT INTO device_sessions (session_id, device_type, device_model, os_version, country)
SELECT 's_vol_' || g, 'tv', 'Roku Ultra', 'Roku OS 12', 'US' FROM generate_series(201, 450) g;

-- More volume for aggregation practice
INSERT INTO playback_events (session_id, device_id, event_type, event_time, app_version)
SELECT 's_vol_' || g, 'd1', CASE WHEN g % 10 = 0 THEN 'failure' ELSE 'play' END, '2026-01-01'::timestamp + (g || ' minutes')::interval, CASE WHEN g % 2 = 0 THEN '4.3.0' ELSE '4.2.1' END
FROM generate_series(1, 200) g;
INSERT INTO playback_events (session_id, device_id, event_type, event_time, app_version)
SELECT 's_vol_' || g, 'd3', CASE WHEN g % 5 = 0 THEN 'failure' ELSE 'play' END, '2026-01-02'::timestamp + (g || ' minutes')::interval, '4.3.0'
FROM generate_series(201, 450) g;

-- errors(session_id, error_code, event_time)
INSERT INTO errors (session_id, error_code, event_time) VALUES
('s2', 'DRM_FAILURE', '2026-01-02 09:15:00'),
('s4', 'BUFFER_TIMEOUT', '2026-01-02 20:05:00'),
('s5', 'DRM_FAILURE', '2026-01-03 19:02:00'),
('s6', 'BUFFER_TIMEOUT', '2026-01-02 21:10:00'),
('s11', 'DRM_FAILURE', '2026-01-04 20:03:00'),
('s17', 'DRM_FAILURE', '2025-12-29 21:05:00');

-- crashes(device_id, crash_time)
INSERT INTO crashes (device_id, crash_time) VALUES
('d3', '2026-01-03 19:05:00'),
('d4', '2026-01-04 18:30:00'),
('d3', '2026-01-05 21:00:00');
