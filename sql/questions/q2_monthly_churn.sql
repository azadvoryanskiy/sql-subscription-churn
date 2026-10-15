-- Q2. What share of subscribers leaves each month?
--
-- Left = subscribed on the 1st, membership ran out during the month, and no
-- new transaction within 30 days. Joined = first payment during the month and
-- still subscribed on the next 1st.

WITH leavers AS (
    SELECT
        month_start,
        count(*)                                  AS subscribers,
        count(*) FILTER (WHERE left_this_month)   AS left_during_month
    FROM subscriber_months
    WHERE month_start < DATE '2017-03-01'         -- March has no verdict yet
    GROUP BY month_start
),
joiners AS (
    SELECT
        date_trunc('month', first_payment_date - 1)::DATE AS month_start,
        count(*)                                          AS joined_during_month
    FROM subscriptions
    WHERE end_date >= date_trunc('month', first_payment_date - 1) + INTERVAL 1 MONTH
    GROUP BY 1
)
SELECT
    l.month_start,
    l.subscribers,
    j.joined_during_month,
    l.left_during_month,
    round(100.0 * l.left_during_month / l.subscribers, 2) AS churn_pct
FROM leavers AS l
JOIN joiners AS j USING (month_start)
ORDER BY l.month_start;
