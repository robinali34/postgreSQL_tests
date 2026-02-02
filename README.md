# Netflix SQL Interview Practice

Local PostgreSQL environment for practicing SQL questions similar to **Netflix** data/analytics interviews. Netflix uses **Amazon Aurora (PostgreSQL-compatible)** and **MySQL** in production; this project uses **PostgreSQL 16** locally for practice (Aurora PostgreSQL compatible).

---

## Quick Start

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and Docker Compose
- Optional: a SQL client (DBeaver, pgAdmin, VS Code SQLTools, or `psql`)

### 1. Start the database

```bash
docker compose up -d
```

Wait until the container is healthy (schema and seed data load on first run):

```bash
docker compose ps
# postgres should show "healthy"
```

### 2. Connect

| Setting   | Value      |
|----------|------------|
| Host     | `localhost` |
| Port     | `5433` (host; container uses 5432) |
| Database | `netflix_db` |
| User     | `netflix`  |
| Password | `practice` |

**psql:**

```bash
docker exec -it netflix-sql-practice psql -U netflix -d netflix_db
```

**Connection string:**

```
postgresql://netflix:practice@localhost:5433/netflix_db
```

**Python script** (interactive REPL or run a query):

```bash
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
.venv/bin/python db.py                    # interactive
.venv/bin/python db.py "SELECT 1;"        # one query
.venv/bin/python db.py -f examples.sql    # run example queries
```

Uses `PGHOST=localhost`, `PGPORT=5433`, `PGUSER=netflix`, `PGPASSWORD=practice`, `PGDATABASE=netflix_db` by default; override with env vars.

**SQL examples to run with Python:**

| What | Command (one query) |
|------|----------------------|
| List content | `python db.py "SELECT title, content_type, genre FROM content LIMIT 10;"` |
| Hours per user (Jan 2024) | `python db.py "SELECT user_id, SUM(hours_watched) AS total FROM watching_activity WHERE watch_date >= '2024-01-01' AND watch_date < '2024-02-01' GROUP BY user_id ORDER BY total DESC LIMIT 5;"` |
| Avg rating per title | `python db.py "SELECT c.title, ROUND(AVG(r.stars)::numeric,2) AS avg_stars FROM content c JOIN reviews r ON c.content_id = r.content_id GROUP BY c.content_id, c.title ORDER BY avg_stars DESC LIMIT 5;"` |
| List devices | `python db.py "SELECT device_id, manufacturer, model FROM devices;"` |
| Failures by device (last week) | `python db.py "SELECT ds.device_model, COUNT(*) AS failures FROM playback_events pe JOIN device_sessions ds ON pe.session_id = ds.session_id WHERE pe.event_type = 'failure' AND pe.event_time::date BETWEEN '2026-01-01' AND '2026-01-07' GROUP BY ds.device_model;"` |
| Run all examples | `python db.py -f examples.sql` |

### 3. Stop the database

```bash
docker compose down
```

To reset data (recreate DB with fresh schema + seed):

```bash
docker compose down -v
docker compose up -d
```

---

## Schema Overview

| Table               | Purpose |
|---------------------|--------|
| `users`             | User accounts: `user_id`, `email`, `sign_up_date`, `country` |
| `subscriptions`     | Plan per user: `plan_type` (Basic/Standard/Premium/Ad-supported), `monthly_price_usd` |
| `content`           | Catalog: `title`, `content_type` (Movie/TV Show), `genre`, `release_year`, `duration_min` |
| `watching_activity` | Streaming: `user_id`, `content_id`, `watch_date`, `hours_watched`, `completed` |
| `reviews`           | Ratings: `user_id`, `content_id`, `stars` (1–5), `review_date` |
| `departments`       | Dept names (Streaming, Content, Marketing, etc.) |
| `revenue`           | Revenue by dept and date (for analytics-style questions) |

Relations: users → subscriptions, watching_activity, reviews; content → watching_activity, reviews; departments → revenue.

### Practice tables (playback, devices, sessions, errors, crashes, rollouts)

For Netflix’s **“SQL Analysis Test”** and general practice, the DB also has these tables with sample data:

| Table              | Columns |
|--------------------|--------|
| `playback_events`  | `session_id`, `device_id`, `event_type`, `event_time`, `app_version` (+ `event_id` PK) |
| `device_sessions`  | `session_id`, `device_type`, `device_model`, `os_version`, `country` |
| `errors`           | `session_id`, `error_code`, `event_time` (+ `error_id` PK) |
| `crashes`          | `device_id`, `crash_time` (+ `crash_id` PK) |
| `rollouts`         | `app_version`, `rollout_date` |
| `devices`          | `device_id`, `manufacturer`, `model` |

Relations: `device_sessions` → `playback_events`, `errors`; `devices` → `playback_events`, `crashes`. Use JOINs to slice by device_type/model, app_version, country, etc.

See **[RELIABILITY_ANALYSIS.md](RELIABILITY_ANALYSIS.md)** for the analysis-test mental model, open-ended prompts, and test cases; **`solutions_reliability.sql`** for example queries (using these tables).

---

## Interview Test Cases

Try to write the SQL yourself, then check `solutions.sql` or the hints below.

---

### Level 1: Basics (JOINs, GROUP BY, aggregates)

**1. Total hours watched per user (Jan 2024)**  
Output: `user_id`, `total_hours`. Only users with at least one watch in Jan 2024.

**2. Average rating (stars) per content title**  
Output: `title`, `avg_stars`, `review_count`. Order by `avg_stars` DESC.

**3. Number of users by subscription plan**  
Output: `plan_type`, `user_count`. Use current subscriptions (e.g. `end_date IS NULL`).

**4. Top 5 most-watched content by total hours**  
Output: `title`, `total_hours`. Consider only `watching_activity` in Jan 2024.

**5. Monthly revenue by department (Q1 2024)**  
Output: `dept_name`, `month` (e.g. 2024-01), `total_revenue_usd`. Sum `revenue.amount_usd` by dept and month.

---

### Level 2: Window functions & ranking

**6. Rank users by total hours watched (Jan 2024)**  
Output: `user_id`, `total_hours`, `rank` (1 = most hours). Use `RANK()` or `DENSE_RANK()`.

**7. For each user, their top content by hours watched**  
Output: `user_id`, `content_id`, `title`, `hours_watched`, `rank_in_user` (1 = top for that user). Use a window like `ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY hours_watched DESC)`.

**8. Week-over-week change in total hours watched**  
For each week in Jan 2024, output: `week_start`, `total_hours`, `prev_week_hours`, `change_vs_prev_week`. Use `LAG()`.

**9. Running total of revenue by department and date**  
Output: `dept_name`, `revenue_date`, `amount_usd`, `running_total` (sum of amount up to that date within the department). Use `SUM() OVER (PARTITION BY dept_id ORDER BY revenue_date)`.

**10. Users who signed up in the same month**  
For each `sign_up_date` month, list `user_id`, `email`, and `sign_ups_in_month`. Use `COUNT(*) OVER (PARTITION BY date_trunc('month', sign_up_date))`.

---

### Level 3: Harder logic & multi-step

**11. “VIP” users: top 10% by hours watched in Jan 2024**  
Define “top 10%” using percent_rank or ntile. Output: `user_id`, `total_hours`, `percentile`.

**12. Content that has both high avg rating (e.g. ≥ 4.5) and at least 3 reviews**  
Output: `title`, `avg_stars`, `review_count`.

**13. Month-over-month growth rate of total revenue**  
Output: `month`, `total_revenue`, `prev_month_revenue`, `pct_growth`. Use `LAG()` and avoid division by zero.

**14. Churn-style: users with no watching_activity in the last 30 days of Jan 2024**  
Assume “last 30 days” = 2024-01-02 to 2024-01-31. List users who have activity before that window but none inside it (or define “active in Dec” and “inactive in Jan” as you prefer). Clarify in interview if needed.

**15. Second most popular content by hours per plan type**  
For each `plan_type`, rank content by total hours (from users on that plan) and return the 2nd place. Requires joining `watching_activity` → `users` → `subscriptions` and content, then `ROW_NUMBER() OVER (PARTITION BY plan_type ORDER BY SUM(hours_watched) DESC)` in a subquery/CTE.

---

## Tips for the interview

- **Clarify**: date ranges, “current” subscription, definition of “user” or “active.”
- **Start simple**: get one table or one join right, then add filters and aggregates.
- **Use CTEs** for readability when you have multiple steps (e.g. “total hours per user” then “rank”).
- **PostgreSQL**: use `DATE_TRUNC('month', date_col)`, `INTERVAL '30 days'`, `::date` casts; window functions and `FILTER` (e.g. `SUM(...) FILTER (WHERE ...)`) are fair game.
- **Edge cases**: NULLs, no rows (return 0 or empty?), ties in rankings.

---

## File layout

```
.
├── docker-compose.yml            # PostgreSQL 16 service
├── schema.sql                    # Content/watch tables (run on init)
├── seed.sql                      # Sample data for content/watch
├── schema_practice_tables.sql   # playback_events, device_sessions, errors, crashes, rollouts, devices
├── seed_practice_tables.sql      # Sample data for practice tables
├── solutions.sql                 # Example solutions (content/watch)
├── solutions_reliability.sql     # Example solutions (reliability / practice tables)
├── RELIABILITY_ANALYSIS.md      # SQL Analysis Test guide + test cases
├── db.py                         # Python script to run SQL (REPL or one-shot)
├── examples.sql                   # Example queries (run with: python db.py -f examples.sql)
├── requirements.txt              # psycopg2-binary for db.py
└── README.md                     # This file
```

---

## References

- [Netflix on Amazon Aurora (PostgreSQL)](https://aws.amazon.com/blogs/database/netflix-consolidates-relational-database-infrastructure-on-amazon-aurora-achieving-up-to-75-improved-performance/)
- [Netflix SQL-style interview prep](https://datalemur.com/questions?company=Netflix) (DataLemur)
- [PostgreSQL 16 docs](https://www.postgresql.org/docs/16/)

Good luck with your Netflix interview.
