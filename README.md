# Cumulative SQL for Loan Pool Cash Ratio Analysis

## Overview
This project demonstrates advanced SQL techniques to analyze a pool of loans and make decisions based on the **cumulative cash ratio**. The cash ratio is calculated as the ratio of cumulative cash equivalents to cumulative outstanding loan amounts. Loans are marked for swapping if their cumulative cash ratio falls below a specified threshold (e.g., 0.3).

This practice is designed to help you:
- Understand **window functions** and **cumulative calculations** in SQL.
- Use **Common Table Expressions (CTEs)** to break down complex queries.
- Apply **decision-making logic** using `CASE` statements.
- Work with financial data to solve real-world problems.

---

## Tools and Technologies
- **Visual Studio Code (VSCode)**: A lightweight, powerful code editor.
- **SQLite**: A lightweight, file-based database.
- **SQLite VSCode Extension**: A VSCode extension to interact with SQLite databases.

---

## Setup Instructions

### 1. Install Visual Studio Code
If you don’t already have VSCode installed, download and install it from [here](https://code.visualstudio.com/).

### 2. Install SQLite VSCode Extension
1. Open VSCode.
2. Go to the Extensions Marketplace (`Ctrl+Shift+X` or `Cmd+Shift+X` on macOS).
3. Search for **SQLite** and install the extension by **Alexey Novikov**.

### 3. Install SQLite
SQLite is a lightweight, file-based database. You can install it as follows:
- **Windows**: Download the precompiled binaries from the [SQLite website](https://www.sqlite.org/download.html) and add the executable to your system PATH.
- **macOS/Linux**: SQLite is usually pre-installed. You can check by running `sqlite3 --version` in your terminal. If not installed, use your package manager (e.g., `brew install sqlite` on macOS).

---

## Database Setup

### 1. Create a SQLite Database
1. Open VSCode.
2. Open the Command Palette (`Ctrl+Shift+P` or `Cmd+Shift+P` on macOS).
3. Search for **SQLite: Open Database** and select it.
4. Choose **Create New Database** and save it as `loan_pool.db`.

### 2. Create Tables
Run the following SQL commands to create the `Loans` and `Loan_Pool` tables:

```sql
-- Create Loans Table
CREATE TABLE Loans (
    loan_id INTEGER PRIMARY KEY,
    loan_amount DECIMAL(10, 2),
    outstanding_amount DECIMAL(10, 2),
    cash_equivalent DECIMAL(10, 2),
    loan_date DATE
);

-- Create Loan_Pool Table
CREATE TABLE Loan_Pool (
    pool_id INTEGER,
    loan_id INTEGER,
    PRIMARY KEY (pool_id, loan_id),
    FOREIGN KEY (loan_id) REFERENCES Loans(loan_id)
);
```
### 3. Insert into Loans Table

```sql
INSERT INTO Loans (loan_id, loan_amount, outstanding_amount, cash_equivalent, loan_date) VALUES
(101, 100000, 80000, 20000, '2023-01-01'),
(102, 150000, 120000, 30000, '2023-02-01'),
(103, 200000, 150000, 50000, '2023-03-01'),
(104, 50000, 40000, 60000, '2023-04-01'),
(105, 100000, 80000, 100000, '2023-05-01'),
(201, 50000, 40000, 10000, '2023-01-01'),
(202, 100000, 80000, 20000, '2023-02-01'),
(203, 200000, 150000, 50000, '2023-03-01'),
(204, 300000, 250000, 300000, '2023-04-01'),
(205, 400000, 350000, 400000, '2023-05-01');

-- Insert into Loan_Pool Table
INSERT INTO Loan_Pool (pool_id, loan_id) VALUES
(1, 101),
(1, 102),
(1, 103),
(1, 104),
(1, 105),
(2, 201),
(2, 202),
(2, 203),
(2, 204),
(2, 205);
```
### 4. run query.sql and sample output
```sql
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
```
Sample output:
pool_id | loan_id | loan_amount | outstanding_amount | cash_equivalent | loan_date  | cumulative_cash_equivalent | cumulative_outstanding | cumulative_cash_ratio | swap_decision
--------|---------|-------------|--------------------|-----------------|------------|----------------------------|------------------------|-----------------------|---------------
1       | 101     | 100,000     | 80,000             | 20,000          | 2023-01-01 | 20,000                     | 80,000                 | 0.25                  | Swap Loan
1       | 102     | 150,000     | 120,000            | 30,000          | 2023-02-01 | 50,000                     | 200,000                | 0.25                  | Swap Loan
1       | 103     | 200,000     | 150,000            | 50,000          | 2023-03-01 | 100,000                    | 350,000                | 0.29                  | Swap Loan
1       | 104     | 50,000      | 40,000             | 60,000          | 2023-04-01 | 160,000                    | 390,000                | 0.41                  | Keep Loan
1       | 105     | 100,000     | 80,000             | 100,000         | 2023-05-01 | 260,000                    | 470,000                | 0.55                  | Keep Loan
2       | 201     | 50,000      | 40,000             | 10,000          | 2023-01-01 | 10,000                     | 40,000                 | 0.25                  | Swap Loan
2       | 202     | 100,000     | 80,000             | 20,000          | 2023-02-01 | 30,000                     | 120,000                | 0.25                  | Swap Loan
2       | 203     | 200,000     | 150,000            | 50,000          | 2023-03-01 | 80,000                     | 270,000                | 0.30                  | Keep Loan
2       | 204     | 300,000     | 250,000            | 300,000         | 2023-04-01 | 380,000                    | 520,000                | 0.73                  | Keep Loan
2       | 205     | 400,000     | 350,000            | 400,000         | 2023-05-01 | 780,000                    | 870,000                | 0.90                  | Keep Loan
