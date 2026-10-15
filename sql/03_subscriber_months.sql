-- Step 3. One row per paying subscriber per month.
--
-- For the 1st of each month: who had a paid subscription running, what plan
-- they were on that day, and whether the subscription ended during that month
-- and stayed ended (churn).
--
-- The window is the last six months with a known outcome, Sep 2016 - Feb 2017.
-- 1 Mar 2017 is included only to count subscribers on that day.

CREATE OR REPLACE TABLE subscriber_months AS
WITH months AS (
    SELECT unnest(generate_series(DATE '2016-09-01', DATE '2017-03-01', INTERVAL 1 MONTH))::DATE AS month_start
),
plans AS (
    -- a plan row is the current plan from its own date until the next one
    SELECT
        user_id,
        subscription_number,
        plan_days,
        is_auto_renew,
        transaction_date AS valid_from,
        lead(transaction_date, 1, DATE '9999-12-31')
            OVER (PARTITION BY user_id, subscription_number ORDER BY seq) AS valid_to
    FROM subscription_transactions
    WHERE NOT is_cancel
)
SELECT
    m.month_start,
    s.user_id,
    s.subscription_number,
    CASE WHEN p.plan_days IN (30, 31) THEN 'Monthly'
         WHEN p.plan_days > 31        THEN 'Longer than a month'
         ELSE 'Shorter than a month' END                      AS plan,
    CASE WHEN p.is_auto_renew THEN 'Auto-renew' ELSE 'Manual' END AS renewal,
    CASE WHEN mb.channel_code IN (3, 4, 7, 9) THEN 'Channel ' || mb.channel_code
         ELSE 'Other or unknown' END                          AS channel,
    s.churned
        AND s.end_date < m.month_start + INTERVAL 1 MONTH     AS left_this_month
FROM months AS m
JOIN subscriptions AS s
    ON  s.first_payment_date <= m.month_start      -- has paid at least once
    AND s.end_date           >= m.month_start      -- still running on the 1st
JOIN plans AS p
    ON  p.user_id = s.user_id
    AND p.subscription_number = s.subscription_number
    AND p.valid_from <= m.month_start
    AND m.month_start < p.valid_to
LEFT JOIN members AS mb
    ON mb.user_id = s.user_id;
