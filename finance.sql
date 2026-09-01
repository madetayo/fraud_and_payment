DROP DATABASE IF EXISTS finance;

CREATE DATABASE finance;

USE finance;

SELECT *
FROM dbo.customers;

SELECT *
FROM dbo.transactions;

--Find the total number of transactions
SELECT
	COUNT(transaction_id) AS total_transactions
FROM dbo.transactions;

-- Calculate total transaction value and average transaction value.
SELECT
	ROUND(SUM(amount_gbp), 2) AS total_transaction_value,
	ROUND(AVG(amount_gbp), 2) AS avg_transaction_value
FROM dbo.transactions;

-- Calculate total debit and total credit value separately
SELECT
	debit_credit,
	ROUND(SUM(amount_gbp),2) AS total_value
FROM dbo.transactions
GROUP BY debit_credit
ORDER BY SUM(amount_gbp);

--Find the top 10 customers by total transaction value
SELECT 
	 TOP 10 customer_id AS customer,
	 SUM(amount_gbp) AS total_transaction_value
FROM dbo.transactions
GROUP BY customer_id
ORDER BY SUM(amount_gbp) DESC;

-- Find the top 10 merchant categories by transaction value
SELECT 
	TOP 10 merchant_category,
	ROUND(SUM(amount_gbp), 2) AS total_transaction_value
FROM dbo.transactions
GROUP BY merchant_category
ORDER BY SUM(amount_gbp) DESC;

-- Calculate monthly transaction count and total value.

SELECT 
	DATENAME(month, transaction_datetime) AS month,
	COUNT(transaction_id) AS transaction_count,
	SUM(amount_gbp) AS total_transaction_value
FROM dbo.transactions
GROUP BY DATENAME(month, transaction_datetime)
ORDER BY COUNT(transaction_id) DESC;

--Calculate transaction count and value by customer region
SELECT 
	customer_region,
	COUNT(transaction_id) AS total_count,
	ROUND(SUM(amount_gbp), 2) AS total_transaction_value
FROM dbo.transactions
GROUP BY customer_region
ORDER BY COUNT(transaction_id) DESC;

-- Find the fraud rate by channel
 SELECT 
	channel,
	COUNT(fraud_flag) OVER()AS count_flag,
	COUNT(fraud_flag) OVER(PARTITION BY channel) AS channel_by_count_flag,
	ROUND(CAST(COUNT(fraud_flag) OVER(PARTITION BY channel) AS DECIMAL(10,2)) / CAST(COUNT(fraud_flag) OVER() AS DECIMAL(10,2)) * 100, 2) AS fraud_rate
FROM dbo.transactions
WHERE fraud_flag = 1;

--Find the fraud rate by merchant category
SELECT 
	merchant_category,
	COUNT(fraud_flag) OVER()AS count_flag,
	COUNT(fraud_flag) OVER(PARTITION BY merchant_category) AS channel_by_count_flag,
	ROUND(CAST(COUNT(fraud_flag) OVER(PARTITION BY merchant_category) AS DECIMAL(10,2)) / CAST(COUNT(fraud_flag) OVER() AS DECIMAL(10,2)) * 100, 2) AS fraud_rate
FROM dbo.transactions
WHERE fraud_flag = 1;

-- Find the top 20 fraudulent transactions by amount
SELECT 
	TOP 20 transaction_id,
	SUM(amount_gbp) total_fraudulent_amount
FROM dbo.transactions
WHERE fraud_flag = 1
GROUP BY transaction_id
ORDER BY SUM(amount_gbp) DESC;

-- Find customers with more than 20 transactions in a month
SELECT 
	customer_id,
	COUNT(transaction_id) AS transaction_count
FROM dbo.transactions
GROUP BY customer_id
HAVING COUNT(transaction_id) > 20
ORDER BY COUNT(transaction_id) DESC;

-- Find customers whose average transaction value is above the overall average
SELECT 
	customer_id,
	ROUND(AVG(amount_gbp), 2) avg_amount
FROM dbo.transactions
GROUP BY customer_id HAVING AVG(amount_gbp) > ( SELECT ROUND(AVG(amount_gbp), 2) FROM dbo.transactions)

-- Compare online, mobile, branch and ATM transaction volumes
SELECT 
	channel,
	COUNT(transaction_id) AS transaction_count
FROM dbo.transactions
GROUP BY channel
ORDER BY COUNT(transaction_id) DESC;

-- Calculate the percentage of transactions that are pending or reversed
WITH CTE_count_by_status AS
( SELECT 
	status,
	COUNT(status) AS total_count
FROM dbo.transactions
GROUP BY status
)
SELECT 
	status,
	ROUND(
	CAST(total_count AS DECIMAL(10,2))
	/ CAST(SUM(total_count) OVER() AS DECIMAL(10,2)) * 100, 2)
	AS transaction_pct
FROM CTE_count_by_status;

--Find the busiest transaction hour
SELECT 
	DATEPART(hour, transaction_datetime) AS transaction_hour,
	COUNT(transaction_id)
FROM dbo.transactions
GROUP BY DATEPART(hour, transaction_datetime)
ORDER BY COUNT(transaction_id) DESC;

----Find the weekday with the highest transaction value
SELECT 
	DATENAME(weekday, transaction_datetime) AS transaction_week_daya,
	ROUND(SUM(amount_gbp), 2) total_amount
FROM dbo.transactions
GROUP BY DATENAME(weekday, transaction_datetime)
ORDER BY SUM(amount_gbp) DESC;

-- Find customers with both debit and credit transactions
SELECT 
	customer_id
FROM dbo.transactions
WHERE debit_credit = 'Debit' AND debit_credit = 'Credit'

-- Rank merchant categories by monthly transaction value using a window function
SELECT 
	DATENAME(month, transaction_datetime) AS month,
	merchant_category,
	RANK() OVER(ORDER BY amount_gbp DESC) AS rank_value
FROM dbo.transactions;

--Calculate each region's percentage contribution to total transaction value
WITH CTE_total_amount_region AS
( SELECT 
	customer_region,
	SUM(amount_gbp) AS amount
FROM dbo.transactions
GROUP BY customer_region
)
SELECT
	customer_region,
	ROUND(amount / SUM(amount) OVER() * 100, 2) AS percentage_contribution
FROM CTE_total_amount_region;

-- Identify potentially high-risk transactions: amount > £1,000 OR Fraud_Flag = TRUE, and rank them by amount
SELECT 
	transaction_id
FROM dbo.transactions
WHERE amount_gbp > 1000 OR fraud_flag = 1;


	