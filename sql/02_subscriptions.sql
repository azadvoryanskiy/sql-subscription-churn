-- Step 2. Turn billing rows into subscriptions.
--
-- A subscription is one unbroken stretch of membership. It starts with a user's
-- first transaction, or with a transaction that comes more than 30 days after
-- their membership ran out. It ends on the expiry date of its last transaction.
--
-- Churn follows KKBox's own rule: the membership ran out and nothing new came in
-- within 30 days. The data stops on 31 Mar 2017, so a subscription that ends
-- after 1 Mar 2017 has no verdict yet.

CREATE OR REPLACE TABLE subscription_transactions AS
WITH ordered AS (
    SELECT
        *,
        row_number()     OVER w AS seq,
        lag(expire_date) OVER w AS previous_expire_date
    FROM transactions
    -- same-day rows: payments before cancellations
    WINDOW w AS (PARTITION BY user_id ORDER BY transaction_date, is_cancel, expire_date)
),
marked AS (
    SELECT
        *,
        CASE WHEN previous_expire_date IS NULL                     THEN 1   -- first ever
             WHEN transaction_date > previous_expire_date + 30     THEN 1   -- came back after a lapse
             ELSE 0 END AS starts_subscription
    FROM ordered
)
SELECT
    user_id,
    seq,
    sum(starts_subscription) OVER (PARTITION BY user_id ORDER BY seq) AS subscription_number,
    transaction_date,
    expire_date,
    plan_days,
    list_price,
    amount_paid,
    is_auto_renew,
    is_cancel,
    amount_paid > 0 AND NOT is_cancel AS is_payment
FROM marked;


CREATE OR REPLACE TABLE subscriptions AS
WITH s AS (
    SELECT
        user_id,
        subscription_number,
        min(transaction_date)                           AS start_date,
        min(transaction_date) FILTER (WHERE is_payment) AS first_payment_date,
        arg_max(expire_date, seq)                       AS end_date,
        arg_max(is_cancel, seq)                         AS ended_with_cancel,
        count(*) FILTER (WHERE is_payment)              AS payments
    FROM subscription_transactions
    GROUP BY user_id, subscription_number
)
SELECT
    *,
    end_date + 30 <= DATE '2017-03-31' AS churned,
    lead(start_date) OVER (PARTITION BY user_id ORDER BY subscription_number) AS next_start_date
FROM s;
