-- Q3. Do people on monthly plans leave more often than people on longer plans?

SELECT
    plan,
    round(count(*) / 6.0)                                           AS subscribers_per_month,
    round(100.0 * count(*) / sum(count(*)) OVER (), 1)              AS pct_of_subscribers,
    round(100.0 * count(*) FILTER (WHERE left_this_month) / count(*), 2) AS churn_pct
FROM subscriber_months
WHERE month_start < DATE '2017-03-01'
GROUP BY plan
ORDER BY count(*) DESC;
