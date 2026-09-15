-- 1) What were the order counts, sales, and AOV for Macbooks sold in North America for each quarter across all years?
  -- Isolate Macbook products
  -- Join customer and geo_lookup data
  -- Isolate North America, and quarters from the purchase_ts.
SELECT date_trunc(orders.purchase_ts,quarter) AS quarter,
  COUNT(product_name) AS counts,
  ROUND(SUM(usd_price),2) AS sales,
  ROUND(AVG(usd_price),2) AS AOV
FROM core.orders
LEFT JOIN core.customers
  ON customers.id = orders.customer_id
LEFT JOIN core.geo_lookup
  ON customers.country_code = geo_lookup.country_code
WHERE product_name LIKE '%Macbook%'
  AND region = 'NA'
GROUP BY 1, region, product_name
ORDER BY 1 DESC;

-- 2) For products purchased in 2022 on the website or products purchased on mobile in any year, which region has the average highest time to deliver?
  -- Pull up orders list and isolate the year 2022 and the website
  -- Also pull up all mobile orders
  -- Calculate time to deliver for all results
SELECT geo_lookup.region, AVG(DATE_DIFF(order_status.delivery_ts,order_status.purchase_ts,day)) AS avg_ship_time
FROM core.orders
LEFT JOIN core.order_status
  ON orders.id = order_status.order_id
LEFT JOIN core.customers_orig
  ON orders.customer_id = customers_orig.id
LEFT JOIN core.geo_lookup
  ON customers_orig.country_code = geo_lookup.country_code
WHERE (purchase_platform = 'website' AND EXTRACT(year FROM orders.purchase_ts) = 2022)
  OR purchase_platform = 'mobile app'
GROUP BY 1
ORDER BY 2 DESC;

-- 3) What was the refund rate and refund count for each product overall?
  -- Pull in orders, and order_status to see refund information.
  -- Create helper column for each refund timestamp. Do a COUNT and SUM of this to get the average (refund rate) and count.
  -- Group by each product
SELECT CASE WHEN product_name = '27in"" 4k gaming monitor' THEN '27in 4K gaming monitor' ELSE product_name END AS product_clean,
  COUNT(CASE WHEN refund_ts IS NOT null THEN 1 ELSE 0 END) AS refund_count,
  ROUND(AVG(CASE WHEN refund_ts IS NOT null THEN 1 ELSE 0 END),2) AS refund_rate
FROM core.orders
LEFT JOIN core.order_status
  ON orders.id = order_status.order_id
GROUP BY 1
ORDER BY 3 DESC;

-- 4) Within each region, what is the most popular product?
  -- Tie region to the number of sales
  -- This needs to be a ranking for each region, not the single highest-selling item for each region. I'll need a CTE and a window function.
WITH sales_by_product AS (
  SELECT geo_lookup.region,
    CASE WHEN product_name = '27in"" 4k gaming monitor' THEN '27in 4K gaming monitor' ELSE product_name END AS product_clean,
    COUNT(DISTINCT orders.id) AS total_orders
  FROM core.orders
  LEFT JOIN core.customers
    ON customers.id = orders.customer_id
  LEFT JOIN core.geo_lookup
    ON customers.country_code = geo_lookup.country_code
  GROUP BY 1,2
  ORDER BY 3 DESC
),

ranking_list AS (
  SELECT *,
    ROW_NUMBER () OVER (PARTITION BY region ORDER BY total_orders DESC) AS rank
  FROM sales_by_product
)

SELECT *
FROM ranking_list
WHERE rank = 1;

-- 5) How does the time to make a purchase differ between loyalty customers vs. non-loyalty customers?
  -- Join order_status with customer info, creating a helper column for loyalty
  -- Use date_diff to calculate the days
  -- Maybe use an Average to reduce the values to a single value for loyalty/non-loyalty members.
SELECT loyalty_program,
  AVG(DATE_DIFF(order_status.purchase_ts,customers_orig.created_on,day)) AS days_to_orrder
FROM core.order_status
LEFT JOIN core.orders
  ON orders.id = order_status.order_id
LEFT JOIN core.customers_orig
  ON orders.customer_id = customers_orig.id
GROUP BY 1
ORDER BY 1 DESC;