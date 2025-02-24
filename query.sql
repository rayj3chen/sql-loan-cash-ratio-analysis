WITH LoanPoolDetails AS (
    SELECT
        lp.pool_id,
        l.loan_id,
        l.loan_amount,
        l.outstanding_amount,
        l.cash_equivalent,
        l.loan_date
    FROM
        Loan_Pool lp
    JOIN
        Loans l ON lp.loan_id = l.loan_id
),
CumulativeCashRatio AS (
    SELECT
        pool_id,
        loan_id,
        loan_amount,
        outstanding_amount,
        cash_equivalent,
        loan_date,
        SUM(cash_equivalent) OVER (PARTITION BY pool_id ORDER BY loan_date) AS cumulative_cash_equivalent,
        SUM(outstanding_amount) OVER (PARTITION BY pool_id ORDER BY loan_date) AS cumulative_outstanding,
        (SUM(cash_equivalent) OVER (PARTITION BY pool_id ORDER BY loan_date) / 
        SUM(outstanding_amount) OVER (PARTITION BY pool_id ORDER BY loan_date)) AS cumulative_cash_ratio
    FROM
        LoanPoolDetails
)
SELECT
    pool_id,
    loan_id,
    loan_amount,
    outstanding_amount,
    cash_equivalent,
    loan_date,
    cumulative_cash_equivalent,
    cumulative_outstanding,
    cumulative_cash_ratio,
    CASE
        WHEN cumulative_cash_ratio < 0.3 THEN 'Swap Loan'
        ELSE 'Keep Loan'
    END AS swap_decision
FROM
    CumulativeCashRatio
ORDER BY
    pool_id, loan_date;
