-- Netflix-style SQL Practice Schema
-- Tables commonly used in Netflix data/SQL interviews

-- Users (subscription, sign-up)
DROP TABLE IF EXISTS watching_activity CASCADE;
DROP TABLE IF EXISTS reviews CASCADE;
DROP TABLE IF EXISTS subscriptions CASCADE;
DROP TABLE IF EXISTS content CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS revenue CASCADE;
DROP TABLE IF EXISTS departments CASCADE;

CREATE TABLE users (
    user_id         SERIAL PRIMARY KEY,
    email           VARCHAR(255) NOT NULL UNIQUE,
    sign_up_date    DATE NOT NULL,
    country         VARCHAR(2) NOT NULL DEFAULT 'US',
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Subscription plans (Basic, Standard, Premium)
CREATE TABLE subscriptions (
    subscription_id     SERIAL PRIMARY KEY,
    user_id             INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    plan_type           VARCHAR(20) NOT NULL CHECK (plan_type IN ('Basic', 'Standard', 'Premium', 'Ad-supported')),
    start_date          DATE NOT NULL,
    end_date            DATE,
    monthly_price_usd    DECIMAL(6,2) NOT NULL,
    UNIQUE(user_id, start_date)
);

-- Content catalog (movies, TV shows)
CREATE TABLE content (
    content_id      SERIAL PRIMARY KEY,
    title           VARCHAR(500) NOT NULL,
    content_type    VARCHAR(20) NOT NULL CHECK (content_type IN ('Movie', 'TV Show')),
    genre           VARCHAR(50),
    release_year    INTEGER,
    duration_min    INTEGER,  -- for movies; for TV shows can be avg episode length
    added_date      DATE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Watching activity (streaming events)
CREATE TABLE watching_activity (
    activity_id     SERIAL PRIMARY KEY,
    user_id         INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    content_id      INTEGER NOT NULL REFERENCES content(content_id) ON DELETE CASCADE,
    watch_date      DATE NOT NULL,
    hours_watched   DECIMAL(5,2) NOT NULL CHECK (hours_watched >= 0),
    completed       BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User reviews/ratings
CREATE TABLE reviews (
    review_id       SERIAL PRIMARY KEY,
    user_id         INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    content_id      INTEGER NOT NULL REFERENCES content(content_id) ON DELETE CASCADE,
    stars           INTEGER NOT NULL CHECK (stars BETWEEN 1 AND 5),
    review_date     DATE NOT NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, content_id)
);

-- Departments & revenue (for revenue/analytics questions)
CREATE TABLE departments (
    dept_id         SERIAL PRIMARY KEY,
    dept_name       VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE revenue (
    revenue_id      SERIAL PRIMARY KEY,
    dept_id         INTEGER NOT NULL REFERENCES departments(dept_id),
    amount_usd      DECIMAL(12,2) NOT NULL,
    revenue_date    DATE NOT NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for common interview query patterns
CREATE INDEX idx_users_sign_up ON users(sign_up_date);
CREATE INDEX idx_subscriptions_user_plan ON subscriptions(user_id, plan_type);
CREATE INDEX idx_content_type_genre ON content(content_type, genre);
CREATE INDEX idx_watching_user_date ON watching_activity(user_id, watch_date);
CREATE INDEX idx_watching_content ON watching_activity(content_id);
CREATE INDEX idx_reviews_content ON reviews(content_id);
CREATE INDEX idx_reviews_user ON reviews(user_id);
CREATE INDEX idx_revenue_dept_date ON revenue(dept_id, revenue_date);
