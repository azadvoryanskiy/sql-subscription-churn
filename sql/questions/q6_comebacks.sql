-- Q6. Of the people who leave, how many come back within 90 days?
--
-- People who left in Sep-Dec 2016, so that everyone has 90 days of data after
-- their membership ended. Back = a new transaction within those 90 days.

SELECT
    CASE WHEN s.ended_with_cancel       THEN 'Cancelled'
         WHEN sm.renewal = 'Auto-renew' THEN 'Auto-renew stopped, no cancellation'
         ELSE 'Manual payer did not pay again' END                       AS how_they_left,
    count(*)                                                             AS people_who_left,
    count(*) FILTER (WHERE s.next_start_date <= s.end_date + 90)         AS back_within_90_days,
    round(100.0 * count(*) FILTER (WHERE s.next_start_date <= s.end_date + 90)
                / count(*), 1)                                           AS pct_back,
    median(s.next_start_date - s.end_date)
        FILTER (WHERE s.next_start_date <= s.end_date + 90)              AS median_days_away
FROM subscriber_months AS sm
JOIN subscriptions AS s USING (user_id, subscription_number)
WHERE sm.left_this_month
  AND sm.month_start BETWEEN DATE '2016-09-01' AND DATE '2016-12-01'
GROUP BY how_they_left
ORDER BY people_who_left DESC;
