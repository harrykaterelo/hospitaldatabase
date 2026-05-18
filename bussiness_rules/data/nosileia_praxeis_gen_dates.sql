CREATE TABLE date_hours AS
WITH RECURSIVE
days AS (
    SELECT DATE('2024-01-01') AS d
    UNION ALL
    SELECT DATE_ADD(d, INTERVAL 1 DAY)
    FROM days
    WHERE d < '2025-5-12'
),
hours AS (
    SELECT 0 AS h
    UNION ALL
    SELECT h + 1
    FROM hours
    WHERE h < 23
)
SELECT
    TIMESTAMP(days.d, MAKETIME(hours.h, 0, 0)) AS datetime_value
FROM days
CROSS JOIN hours;