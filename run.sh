cd /home/robina/rli/test/sql && docker compose up -d
sleep 8 && docker exec postgres-sql-practice psql -U practice -d practice_db -c "\dt" -c "SELECT COUNT(*) FROM users;" -c "SELECT title, content_type FROM content LIMIT 3;"
docker exec postgres-sql-practice psql -U practice -d practice_db -f - 2>/dev/null << 'INIT'
\i /docker-entrypoint-initdb.d/03-schema_reliability.sql
INIT
cd /home/robina/rli/test/sql && cat schema_reliability.sql | docker exec -i postgres-sql-practice psql -U practice -d practice_db
cd /home/robina/rli/test/sql && cat seed_reliability.sql | docker exec -i postgres-sql-practice psql -U practice -d practice_db
docker exec postgres-sql-practice psql -U practice -d practice_db -c "
SELECT device_type, device_model,
  COUNT(*) AS total_events,
  COUNT(CASE WHEN event_type = 'failure' THEN 1 END) AS failures,
  ROUND(COUNT(CASE WHEN event_type = 'failure' THEN 1 END) * 1.0 / NULLIF(COUNT(*), 0), 4) AS failure_rate
FROM playback_events
WHERE event_date BETWEEN '2026-01-01' AND '2026-01-07'
GROUP BY device_type, device_model
HAVING COUNT(*) > 100
ORDER BY failure_rate DESC
LIMIT 8;
"

