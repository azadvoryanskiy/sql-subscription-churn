-- Q1. How many paying subscribers are there each month, and is the base growing?

WITH monthly AS (
    SELECT
        month_start,
        count(*) AS subscribers
    FROM subscriber_months
    GROUP BY month_start
)
SELECT
    month_start,
    subscribers,
    subscribers - lag(subscribers) OVER (ORDER BY month_start)         AS change_vs_previous_month,
    round(100.0 * (subscribers - first_value(subscribers) OVER (ORDER BY month_start))
                / first_value(subscribers) OVER (ORDER BY month_start), 1) AS growth_since_sep_pct
FROM monthly
ORDER BY month_start;
