-- Practice tables: structure for SQL practice
-- playback_events(session_id, device_id, event_type, event_time, app_version)
-- device_sessions(session_id, device_type, device_model, os_version, country)
-- errors(session_id, error_code, event_time)
-- crashes(device_id, crash_time)
-- rollouts(app_version, rollout_date)
-- devices(device_id, manufacturer, model)

DROP TABLE IF EXISTS crashes CASCADE;
DROP TABLE IF EXISTS errors CASCADE;
DROP TABLE IF EXISTS playback_events CASCADE;
DROP TABLE IF EXISTS device_sessions CASCADE;
DROP TABLE IF EXISTS rollouts CASCADE;
DROP TABLE IF EXISTS devices CASCADE;

CREATE TABLE devices (
    device_id     VARCHAR(32) PRIMARY KEY,
    manufacturer  VARCHAR(80) NOT NULL,
    model         VARCHAR(80) NOT NULL
);

CREATE TABLE rollouts (
    app_version   VARCHAR(20) PRIMARY KEY,
    rollout_date  DATE NOT NULL
);

CREATE TABLE device_sessions (
    session_id    VARCHAR(64) PRIMARY KEY,
    device_type   VARCHAR(20) NOT NULL,
    device_model  VARCHAR(80) NOT NULL,
    os_version    VARCHAR(40),
    country       VARCHAR(2) NOT NULL DEFAULT 'US'
);

CREATE TABLE playback_events (
    event_id      SERIAL PRIMARY KEY,
    session_id    VARCHAR(64) NOT NULL REFERENCES device_sessions(session_id) ON DELETE CASCADE,
    device_id     VARCHAR(32) NOT NULL REFERENCES devices(device_id) ON DELETE CASCADE,
    event_type    VARCHAR(20) NOT NULL CHECK (event_type IN ('play', 'failure', 'buffer', 'complete')),
    event_time    TIMESTAMP NOT NULL,
    app_version   VARCHAR(20) NOT NULL
);

CREATE TABLE errors (
    error_id      SERIAL PRIMARY KEY,
    session_id    VARCHAR(64) NOT NULL REFERENCES device_sessions(session_id) ON DELETE CASCADE,
    error_code    VARCHAR(40) NOT NULL,
    event_time    TIMESTAMP NOT NULL
);

CREATE TABLE crashes (
    crash_id      SERIAL PRIMARY KEY,
    device_id     VARCHAR(32) NOT NULL REFERENCES devices(device_id) ON DELETE CASCADE,
    crash_time    TIMESTAMP NOT NULL
);

CREATE INDEX idx_playback_session ON playback_events(session_id);
CREATE INDEX idx_playback_device ON playback_events(device_id);
CREATE INDEX idx_playback_event_time ON playback_events(event_time);
CREATE INDEX idx_playback_app_version ON playback_events(app_version);
CREATE INDEX idx_errors_session ON errors(session_id);
CREATE INDEX idx_errors_event_time ON errors(event_time);
CREATE INDEX idx_crashes_device ON crashes(device_id);
CREATE INDEX idx_crashes_time ON crashes(crash_time);
