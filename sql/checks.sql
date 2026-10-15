-- Checks. Each query must return zero rows. run.py stops if one does not.

-- 1. One row per subscriber per month.
SELECT month_start, user_id, count(*) AS n
FROM subscriber_months
GROUP BY month_start, user_id
HAVING count(*) > 1;

-- 2. A user's subscriptions never overlap.
SELECT user_id, subscription_number
FROM (
    SELECT *, lag(end_date) OVER (PARTITION BY user_id ORDER BY subscription_number) AS previous_end
    FROM subscriptions
)
WHERE start_date <= previous_end + 30;

-- 3. The months add up: subscribers + joined - left = subscribers a month later.
WITH monthly AS (
    SELECT month_start,
           count(*)                                AS subscribers,
           count(*) FILTER (WHERE left_this_month) AS left_during_month
    FROM subscriber_months
    GROUP BY month_start
),
joiners AS (
    SELECT date_trunc('month', first_payment_date - 1)::DATE AS month_start,
           count(*) AS joined_during_month
    FROM subscriptions
    WHERE end_date >= date_trunc('month', first_payment_date - 1) + INTERVAL 1 MONTH
    GROUP BY 1
),
balance AS (
    SELECT m.month_start,
           m.subscribers + j.joined_during_month - m.left_during_month AS expected_next,
           lead(m.subscribers) OVER (ORDER BY m.month_start)           AS actual_next
    FROM monthly AS m
    JOIN joiners AS j USING (month_start)
)
SELECT * FROM balance
WHERE actual_next IS NOT NULL AND expected_next <> actual_next;
