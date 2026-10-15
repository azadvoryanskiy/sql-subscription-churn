-- Q5. Which sign-up channels bring subscribers who stay?
--
-- The last column repeats the churn rate for monthly auto-renew subscribers
-- only, so channels can be compared on the same payment setup.

SELECT
    channel,
    round(count(*) / 6.0)                                                AS subscribers_per_month,
    round(100.0 * count(*) FILTER (WHERE left_this_month) / count(*), 1) AS churn_pct,
    round(100.0 * count(*) FILTER (WHERE plan = 'Monthly' AND renewal = 'Manual')
                / count(*), 1)                                           AS pct_monthly_manual,
    round(100.0 * count(*) FILTER (WHERE left_this_month AND plan = 'Monthly' AND renewal = 'Auto-renew')
                / count(*) FILTER (WHERE plan = 'Monthly' AND renewal = 'Auto-renew'), 1)
                                                                         AS churn_pct_auto_renew_only
FROM subscriber_months
WHERE month_start < DATE '2017-03-01'
GROUP BY channel
ORDER BY churn_pct DESC;
