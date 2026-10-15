-- Step 1. Load the raw KKBox files into typed tables.
--
-- One row of transactions = one billing event for one user: a payment, a free
-- trial, or a cancellation. Each row carries the date the membership now runs to.
--
-- The history is split across two files that do not overlap, so both are read.

CREATE OR REPLACE TABLE transactions AS
SELECT DISTINCT                                   -- drops exact duplicate rows
    msno                                             AS user_id,
    payment_plan_days                                AS plan_days,
    plan_list_price                                  AS list_price,
    actual_amount_paid                               AS amount_paid,
    is_auto_renew = 1                                AS is_auto_renew,
    is_cancel = 1                                    AS is_cancel,
    strptime(transaction_date, '%Y%m%d')::DATE       AS transaction_date,
    strptime(membership_expire_date, '%Y%m%d')::DATE AS expire_date
FROM read_csv(
    ['data/raw/transactions.csv', 'data/raw/transactions_v2.csv'],
    header = true,
    columns = {
        'msno': 'VARCHAR',
        'payment_method_id': 'INTEGER',
        'payment_plan_days': 'INTEGER',
        'plan_list_price': 'INTEGER',
        'actual_amount_paid': 'INTEGER',
        'is_auto_renew': 'INTEGER',
        'transaction_date': 'VARCHAR',
        'membership_expire_date': 'VARCHAR',
        'is_cancel': 'INTEGER'
    }
)
WHERE membership_expire_date >= '20130101'        -- 1970-01-01 and similar junk dates
ORDER BY user_id, transaction_date;


-- One row per user. The sign-up channel is the only profile field that is
-- filled in for almost everyone; KKBox publishes it as a code, not a name.
CREATE OR REPLACE TABLE members AS
SELECT
    msno           AS user_id,
    registered_via AS channel_code
FROM read_csv(
    'data/raw/members_v3.csv',
    header = true,
    columns = {
        'msno': 'VARCHAR',
        'city': 'INTEGER',
        'bd': 'INTEGER',
        'gender': 'VARCHAR',
        'registered_via': 'INTEGER',
        'registration_init_time': 'VARCHAR'
    }
)
WHERE msno IN (SELECT user_id FROM transactions);   -- only people who ever had a transaction
