-- Q4. Auto-renew or manual renewal: where do we lose more?
--
-- Longer plans are always paid up front by hand, so they are their own group.

WITH grouped AS (
    SELECT
        CASE WHEN plan = 'Monthly' AND renewal = 'Auto-renew' THEN 'Monthly, auto-renew'
             WHEN plan = 'Monthly'                            THEN 'Monthly, manual'
             WHEN plan = 'Longer than a month'                THEN 'Longer plan, paid up front'
             ELSE 'Shorter than a month' END AS payment_setup,
        left_this_month
    FROM subscriber_months
    WHERE month_start < DATE '2017-03-01'
)
SELECT
    payment_setup,
    round(count(*) / 6.0)                                                AS subscribers_per_month,
    round(100.0 * count(*) / sum(count(*)) OVER (), 1)                   AS pct_of_subscribers,
    count(*) FILTER (WHERE left_this_month)                              AS left_in_six_months,
    round(100.0 * count(*) FILTER (WHERE left_this_month)
                / sum(count(*) FILTER (WHERE left_this_month)) OVER (), 1) AS pct_of_leavers,
    round(100.0 * count(*) FILTER (WHERE left_this_month) / count(*), 2) AS churn_pct
FROM grouped
GROUP BY payment_setup
ORDER BY count(*) DESC;
