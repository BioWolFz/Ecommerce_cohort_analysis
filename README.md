#E-commerce Customer Retention Analysis (MySQL)

##Project Overview

This project focuses on a critical business metric: **Customer Retention**. Using a simulated dataset of 100 customers and 300 orders over 12 months, I utilized advanced SQL techniques to build a **Cohort Retention Table**. This table segments customers by their acquisition month and tracks their return rate over time, providing a clear visual representation of customer loyalty and business health.

**Key Skills Demonstrated:**
* **Advanced MySQL:** Mastery of Complex CTEs (Common Table Expressions).
* **Window Functions:** Using `MIN() OVER` and the advanced analytical function `FIRST_VALUE() OVER`.
* **Time Series Analysis:** Calculating month-over-month (MoM) differences using `PERIOD_DIFF()`.
* **Data Aggregation:** Using `GROUP BY` and `COUNT(DISTINCT)` to derive accurate cohort sizes.
* **Business Intelligence:** Translating raw transaction data into a key performance indicator (KPI).

---

##Methodology: The 4-Phase SQL Pipeline

The analysis was executed in four distinct phases using CTEs to ensure clarity and logical flow:

1.  **Customer Cohort Identification:** Used the `MIN() OVER` window function to stamp the customer's **acquisition month** onto every single order they ever placed.
2.  **Retention Index Calculation:** Used `PERIOD_DIFF()` to calculate the number of months between the acquisition date and the order date, generating the `cohort_index`.
3.  **Raw Counts Aggregation:** Grouped the data by `cohort_month` and `cohort_index` to count the unique number of customers (`total_customers`) present at each interval.
4.  **Retention Percentage Calculation:** Used the **`FIRST_VALUE() OVER`** window function to pull the initial cohort size (the count at Index 0) for the denominator, allowing for the final percentage calculation.

---

##Key Analytical Insight

The final retention table below clearly shows the retention rates for the 2024 calendar year, highlighting the stickiness of the customer base.



* **Observation:** The **2024-01** cohort, the largest with **21** customers, shows a retention rate of **52.38%** one month later (Index 1). This is a crucial benchmark for measuring the effectiveness of customer onboarding.
* **Business Value:** This table allows a company to instantly see which cohorts are performing best and identify the *break-even point* in months (where retention stabilizes), which is essential for calculating Customer Lifetime Value (CLV).

---

##Full SQL Query

This final query combines the four phases into a single, executed script.

```sql
WITH customer_cohort AS (
    -- 1. Identify Acquisition Date using the MIN() OVER Window Function
    SELECT customer_id, order_date,
        MIN(order_date) OVER (PARTITION BY customer_id) AS acquisition_date
    FROM orders
),
retention_index AS (
    -- 2. Calculate Cohort Index (Month Difference)
    SELECT
        customer_id,
        acquisition_date,
        PERIOD_DIFF(
            DATE_FORMAT(order_date, '%Y%m'),
            DATE_FORMAT(acquisition_date, '%Y%m')
        ) AS cohort_index
    FROM customer_cohort
),
cohort_data AS (
    -- 3. Aggregate to get Raw Counts
    SELECT
        DATE_FORMAT(acquisition_date, '%Y-%m') AS cohort_month,
        cohort_index,
        COUNT(DISTINCT customer_id) AS total_customers
    FROM retention_index
    GROUP BY 1, 2
)
-- 4. Final: Calculate Retention Rate Percentage using FIRST_VALUE() OVER
SELECT
    cohort_month,
    cohort_index,
    total_customers,
    -- Pulls the count from the row where cohort_index = 0 for the denominator
    FIRST_VALUE(total_customers) OVER (
        PARTITION BY cohort_month ORDER BY cohort_index
    ) AS cohort_size,
    -- Calculation: (total_customers / cohort_size) * 100
    ROUND(
        (total_customers * 100.0) / FIRST_VALUE(total_customers) OVER (
            PARTITION BY cohort_month ORDER BY cohort_index
        ), 2
    ) AS retention_rate_pct
FROM cohort_data
ORDER BY 1, 2;