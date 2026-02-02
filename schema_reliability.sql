-- SQL Analysis Test: Device / Playback Reliability
-- Tables: playback_events, rollouts (realistic 1–3 table setup)

DROP TABLE IF EXISTS playback_events CASCADE;
DROP TABLE IF EXISTS rollouts CASCADE;

CREATE TABLE playback_events (
    event_id       SERIAL PRIMARY KEY,
    session_id     VARCHAR(64) NOT NULL,
    event_time     TIMESTAMP NOT NULL,
    event_date     DATE NOT NULL,
    event_type     VARCHAR(20) NOT NULL CHECK (event_type IN ('play', 'failure', 'buffer', 'complete')),
    device_type    VARCHAR(20) NOT NULL,  -- phone, tv, tablet, web
    device_model   VARCHAR(80) NOT NULL,
    os_version     VARCHAR(40),
    app_version    VARCHAR(20) NOT NULL,
    country        VARCHAR(2) NOT NULL DEFAULT 'US',
    error_code     VARCHAR(40),          -- DRM_FAILURE, BUFFER_TIMEOUT, etc.
    duration_sec   INTEGER,
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE rollouts (
    rollout_id       SERIAL PRIMARY KEY,
    app_version      VARCHAR(20) NOT NULL,
    platform         VARCHAR(20) NOT NULL,  -- ios, android, web, all
    rollout_start    DATE NOT NULL,
    rollout_end      DATE,
    target_pct       INTEGER CHECK (target_pct BETWEEN 0 AND 100),
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_playback_event_date_type ON playback_events(event_date, event_type);
CREATE INDEX idx_playback_device ON playback_events(device_type, device_model);
CREATE INDEX idx_playback_app_version ON playback_events(app_version);
CREATE INDEX idx_playback_session ON playback_events(session_id);
CREATE INDEX idx_rollouts_version ON rollouts(app_version);
