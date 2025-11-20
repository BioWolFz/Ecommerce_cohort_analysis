USE ecommerce_cohort_analysis;
Create table customers (
	customer_id varchar(10) UNIQUE NOT NULL Primary Key,
    first_name varchar(100) NOT NULL,
    last_name Varchar(100) NOT NULL
    );
Create table orders (
	order_id Varchar(10) UNIQUE NOT NULL Primary Key,
    customer_id Varchar(10),
    order_date date NOT NULL,
    order_value decimal(10,2) NOT NULL,
    Foreign key (customer_id) References customers(customer_id)
);
Insert INTO customers(customer_id, first_name, last_name) Values
		('C1', 'Alice', 'Smith'),
        ('C2', 'Bob', 'Johnson'),
        ('C3', 'Charlie', 'Brown')
;
Insert INTO orders(order_id, customer_id, order_date, order_value) Values
		('O1', 'C1', '2025-01-05',50),
        ('O2', 'C2', '2025-01-12',75),
        ('O3', 'C3', '2025-02-01',30),
        ('O4', 'C1', '2025-02-15',20),
        ('O5', 'C2', '2025-03-08',100),
        ('O6', 'C1', '2025-04-20',45),
        ('O7', 'C3', '2025-04-25',60),
        ('O8', 'C2', '2025-05-10',15)
;

-- Finding acquisition date
With customer_cohort AS(
Select
	order_id,
    customer_id,
    order_date,
    Min(order_date) Over (partition by customer_id) AS acquisition_date
From orders)
Select * from customer_cohort;

-- Calculating cohort index along with acquisition date
With customer_cohort AS(
Select
	customer_id,
    order_date,
    Min(order_date) Over (Partition by customer_id) As acquisition_date
From orders
),
retention_index AS(
Select
	*,
	period_diff(
		Date_Format(order_date, '%Y%m'),
        Date_Format(acquisition_date, '%Y%m')) AS cohort_index
From customer_cohort
)
select * From retention_index;

-- The Full Query (acquisition_date, cohort_index, customer count per cohort index)
With customer_cohort AS(
Select
	customer_id,
    order_date,
    Min(order_date) Over (Partition by customer_id) As acquisition_date
From orders
),
retention_index AS(
Select
	*,
	period_diff(
		Date_Format(order_date, '%Y%m'),
        Date_Format(acquisition_date, '%Y%m')) AS cohort_index
From customer_cohort
)
Select
	Date_Format(acquisition_date, '%Y-%m') AS cohort_month,
    cohort_index,
    Count(Distinct customer_id) AS total_customers
FROM retention_index
GROUP BY 1, 2
Order By 1, 2;    

-- Customer Retention Percentage
With customer_cohort AS(
Select
	customer_id,
    order_date,
    Min(order_date) Over (Partition by customer_id) As acquisition_date
From orders
),
retention_index AS(
Select
	*,
	period_diff(
		Date_Format(order_date, '%Y%m'),
        Date_Format(acquisition_date, '%Y%m')) AS cohort_index
From customer_cohort
),
cohort_data AS(
	Select
		Date_Format(acquisition_date, '%Y%m') AS cohort_month,
        cohort_index,
        COUNT(DISTINCT( customer_id)) AS total_customers
	From retention_index
    GROUP BY 1, 2
)
Select
	cohort_month,
    cohort_index,
    total_customers,
    FIRST_VALUE(total_customers) OVER
		(Partition By cohort_month Order by cohort_index) AS cohort_size,
    (ROUND(total_customers * 100) / FIRST_VALUE(total_customers) Over
		(Partition By cohort_month Order by cohort_index)
	) AS retention_rate_percentage
FROM cohort_data
Order BY 1, 2