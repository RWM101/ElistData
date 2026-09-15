-- PART 1
-- 1. What is the date of the earliest and latest order, returned in one query?
SELECT MIN(purchase_ts) AS earliest_order,
  MAX(purchase_ts) AS latest_order
FROM core.orders;

-- 2. What is the average order value for purchases made in USD? What about average order value for purchases made in USD in 2019?
SELECT AVG(usd_price)
FROM core.orders
WHERE CURRENCY LIKE 'USD'
  AND EXTRACT(year FROM purchase_ts) = 2019;

-- 3. Return the id, loyalty program status, and account creation date for customers who made an account on desktop or mobile. Rename the columns to more descriptive names.
SELECT id AS customer_id,
  loyalty_program AS loyalty_member,
  created_on AS account_creation_date
FROM core.customers
WHERE account_creation_method IN ('desktop', 'mobile');

-- 4. What are all the unique products that were sold in AUD on website, sorted alphabetically?
SELECT DISTINCT product_name
FROM core.orders
WHERE currency = 'AUD'
  AND purchase_platform = 'website';

-- 5. What are the first 10 countries in the North American region, sorted in descending alphabetical order?
SELECT country_code
FROM core.geo_lookup
WHERE region = 'NA'
ORDER BY country_code DESC
LIMIT 10;



-- PART 2
-- 1. What is the total number of orders by shipping month, sorted from most recent to oldest?
WITH month_list AS (
  SELECT purchase_ts,
    EXTRACT (month FROM purchase_ts) AS month,
  FROM core.orders
)

SELECT month, COUNT(month)
FROM month_list
GROUP BY month
ORDER BY month DESC;



-- 2. What is the average order value by year? Can you round the results to 2 decimals?
SELECT EXTRACT(year FROM purchase_ts) AS year,
  ROUND(AVG(usd_price),2)
FROM core.orders
GROUP BY 1
ORDER BY 1;

-- 3. Create a helper column `is_refund`  in the `order_status`  table that returns 1 if there is a refund, 0 if not. Return the first 20 records.
SELECT *,
  CASE WHEN refund_ts is NOT NULL THEN 1 ELSE 0 END AS is_refund
FROM core.order_status
LIMIT 20;

-- 4. Return the product IDs and product names of all Apple products.
SELECT DISTINCT product_id,
  product_name
FROM core.suppliers
WHERE product_name LIKE '%Apple%'
  OR product_name LIKE '%Macbook%'
ORDER BY product_name;

-- 5. Calculate the time to ship in days for each order and return all original columns from the table.
SELECT *,
  EXTRACT(day FROM ship_ts - purchase_ts) AS ship_time
FROM core.order_status;
