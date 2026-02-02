-- SQL Practice - Example Solutions
-- Try solving in README first, then compare with these.

-- ========== LEVEL 1 ==========

-- 1. Total hours watched per user (Jan 2024)
SELECT user_id,
       SUM(hours_watched) AS total_hours
FROM watching_activity
WHERE watch_date >= '2024-01-01' AND watch_date < '2024-02-01'
GROUP BY user_id
ORDER BY total_hours DESC;

-- 2. Average rating per content title
SELECT c.title,
       ROUND(AVG(r.stars)::numeric, 2) AS avg_stars,
       COUNT(r.review_id) AS review_count
FROM content c
JOIN reviews r ON c.content_id = r.content_id
GROUP BY c.content_id, c.title
ORDER BY avg_stars DESC;

-- 3. Number of users by subscription plan (current)
SELECT s.plan_type,
       COUNT(DISTINCT s.user_id) AS user_count
FROM subscriptions s
WHERE s.end_date IS NULL
GROUP BY s.plan_type
ORDER BY user_count DESC;

-- 4. Top 5 most-watched content by total hours (Jan 2024)
SELECT c.title,
       SUM(w.hours_watched) AS total_hours
FROM watching_activity w
JOIN content c ON w.content_id = c.content_id
WHERE w.watch_date >= '2024-01-01' AND w.watch_date < '2024-02-01'
GROUP BY c.content_id, c.title
ORDER BY total_hours DESC
LIMIT 5;

-- 5. Monthly revenue by department (Q1 2024)
SELECT d.dept_name,
       DATE_TRUNC('month', r.revenue_date)::date AS month,
       SUM(r.amount_usd) AS total_revenue_usd
FROM revenue r
JOIN departments d ON r.dept_id = d.dept_id
WHERE r.revenue_date >= '2024-01-01' AND r.revenue_date < '2024-04-01'
GROUP BY d.dept_id, d.dept_name, DATE_TRUNC('month', r.revenue_date)
ORDER BY d.dept_name, month;

-- ========== LEVEL 2 ==========

-- 6. Rank users by total hours (Jan 2024)
WITH user_hours AS (
  SELECT user_id,
         SUM(hours_watched) AS total_hours
  FROM watching_activity
  WHERE watch_date >= '2024-01-01' AND watch_date < '2024-02-01'
  GROUP BY user_id
)
SELECT user_id,
       total_hours,
       RANK() OVER (ORDER BY total_hours DESC) AS rank
FROM user_hours
ORDER BY rank;

-- 7. Each user's top content by hours watched
WITH ranked AS (
  SELECT w.user_id,
         w.content_id,
         w.hours_watched,
         ROW_NUMBER() OVER (PARTITION BY w.user_id ORDER BY w.hours_watched DESC) AS rank_in_user
  FROM watching_activity w
)
SELECT r.user_id,
       r.content_id,
       c.title,
       r.hours_watched,
       r.rank_in_user
FROM ranked r
JOIN content c ON r.content_id = c.content_id
WHERE r.rank_in_user = 1
ORDER BY r.user_id;

-- 8. Week-over-week change in total hours
WITH weekly AS (
  SELECT DATE_TRUNC('week', watch_date)::date AS week_start,
         SUM(hours_watched) AS total_hours
  FROM watching_activity
  WHERE watch_date >= '2024-01-01' AND watch_date < '2024-02-01'
  GROUP BY DATE_TRUNC('week', watch_date)
),
with_prev AS (
  SELECT week_start,
         total_hours,
         LAG(total_hours) OVER (ORDER BY week_start) AS prev_week_hours
  FROM weekly
)
SELECT week_start,
       total_hours,
       prev_week_hours,
       total_hours - prev_week_hours AS change_vs_prev_week
FROM with_prev
ORDER BY week_start;

-- 9. Running total of revenue by department
SELECT d.dept_name,
       r.revenue_date,
       r.amount_usd,
       SUM(r.amount_usd) OVER (PARTITION BY r.dept_id ORDER BY r.revenue_date) AS running_total
FROM revenue r
JOIN departments d ON r.dept_id = d.dept_id
ORDER BY d.dept_name, r.revenue_date;

-- 10. Users who signed up in the same month (with count per month)
SELECT user_id,
       email,
       sign_up_date,
       COUNT(*) OVER (PARTITION BY DATE_TRUNC('month', sign_up_date)) AS sign_ups_in_month
FROM users
ORDER BY sign_up_date;

-- ========== LEVEL 3 ==========

-- 11. VIP users: top 10% by hours (Jan 2024)
WITH user_hours AS (
  SELECT user_id,
         SUM(hours_watched) AS total_hours
  FROM watching_activity
  WHERE watch_date >= '2024-01-01' AND watch_date < '2024-02-01'
  GROUP BY user_id
),
with_pct AS (
  SELECT user_id,
         total_hours,
         PERCENT_RANK() OVER (ORDER BY total_hours DESC) AS pct_rank
  FROM user_hours
)
SELECT user_id, total_hours, pct_rank
FROM with_pct
WHERE pct_rank < 0.10
ORDER BY total_hours DESC;

-- 12. Content with avg rating >= 4.5 and at least 3 reviews
SELECT c.title,
       ROUND(AVG(r.stars)::numeric, 2) AS avg_stars,
       COUNT(r.review_id) AS review_count
FROM content c
JOIN reviews r ON c.content_id = r.content_id
GROUP BY c.content_id, c.title
HAVING AVG(r.stars) >= 4.5 AND COUNT(r.review_id) >= 3
ORDER BY avg_stars DESC;

-- 13. Month-over-month revenue growth rate
WITH monthly AS (
  SELECT DATE_TRUNC('month', revenue_date)::date AS month,
         SUM(amount_usd) AS total_revenue
  FROM revenue
  GROUP BY DATE_TRUNC('month', revenue_date)
),
with_prev AS (
  SELECT month,
         total_revenue,
         LAG(total_revenue) OVER (ORDER BY month) AS prev_month_revenue
  FROM monthly
)
SELECT month,
       total_revenue,
       prev_month_revenue,
       ROUND(100.0 * (total_revenue - prev_month_revenue) / NULLIF(prev_month_revenue, 0), 2) AS pct_growth
FROM with_prev
ORDER BY month;

-- 14. Users with no activity in last 30 days of Jan (2024-01-02 to 2024-01-31)
WITH active_in_period AS (
  SELECT DISTINCT user_id
  FROM watching_activity
  WHERE watch_date BETWEEN '2024-01-02' AND '2024-01-31'
),
had_activity_before AS (
  SELECT DISTINCT user_id
  FROM watching_activity
  WHERE watch_date < '2024-01-02'
)
SELECT u.user_id, u.email
FROM users u
JOIN had_activity_before h ON u.user_id = h.user_id
LEFT JOIN active_in_period a ON u.user_id = a.user_id
WHERE a.user_id IS NULL
ORDER BY u.user_id;

-- 15. Second most popular content by plan type (by total hours from that plan's users)
WITH plan_content_hours AS (
  SELECT s.plan_type,
         w.content_id,
         SUM(w.hours_watched) AS total_hours
  FROM watching_activity w
  JOIN subscriptions s ON w.user_id = s.user_id AND s.end_date IS NULL
  GROUP BY s.plan_type, w.content_id
),
ranked AS (
  SELECT plan_type,
         content_id,
         total_hours,
         ROW_NUMBER() OVER (PARTITION BY plan_type ORDER BY total_hours DESC) AS rn
  FROM plan_content_hours
)
SELECT r.plan_type,
       c.title,
       r.total_hours,
       r.rn AS rank
FROM ranked r
JOIN content c ON r.content_id = c.content_id
WHERE r.rn = 2
ORDER BY r.plan_type;
