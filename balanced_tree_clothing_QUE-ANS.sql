USE balanced_tree_clothing;

SELECT * FROM product_details;
SELECT * FROM product_hierarchy;
SELECT * FROM product_prices;
SELECT * FROM sales;

		-- High Level Sales Analysis --
	
-- 1. What was the total quantity sold for all products?
SELECT 
	SUM(qty) AS total_sales
FROM sales;

-- 2. What is the total generated revenue for all products before discounts?
SELECT 
	SUM(qty*price) AS revenue_generated
FROM sales;

-- 3. What was the total discount amount for all products?
SELECT 
	SUM(qty*price*discount/100) AS discount_amount
FROM sales;

			-- Transaction Analysis --
            
-- 1. How many unique transactions were there?
SELECT 
	COUNT(DISTINCT txn_id) AS transactions_cnt
FROM sales;

-- 2. What is the average unique products purchased in each transaction?
WITH CTE AS(
SELECT 
	txn_id,
	COUNT(DISTINCT prod_id) AS prod_cnt
FROM sales
GROUP BY txn_id)

SELECT ROUND(AVG(prod_cnt)) AS avg_prod_count
FROM CTE;

-- 3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?
#TODO

-- 4. What is the average discount value per transaction?
WITH CTE AS(
SELECT 
	txn_id,
	SUM(qty*price*discount/100) AS sales_per_txn
FROM sales
GROUP BY txn_id)

SELECT ROUND(AVG(sales_per_txn),2) AS avg_discount
FROM CTE;

-- 5. What is the percentage split of all transactions for members vs non-members?
SELECT 
    CASE WHEN member_ = 't' THEN 'member' ELSE 'not_a_member' END AS membership,
	ROUND((COUNT(*)/(SELECT COUNT(*) FROM sales)) * 100, 2) AS members_share
FROM sales
GROUP BY member_;

-- 6. What is the average revenue for member transactions and non-member transactions?
SELECT 
    CASE WHEN member_ = 't' THEN 'member' ELSE 'not_a_member' END AS membership,
    ROUND(AVG((qty*price) - (qty*price*discount/100)),2) AS avg_revenue
FROM sales
GROUP BY member_;


				-- Product Analysis --
                
-- 1. What are the top 3 products by total revenue before discount?
SELECT 
	product_name,
    SUM(sales.qty*sales.price) AS revenue_generated
FROM sales
JOIN product_details ON sales.prod_id = product_details.product_id
GROUP BY product_name
ORDER BY revenue_generated DESC
LIMIT 3;

-- 2. What is the total quantity, revenue and discount for each segment?
SELECT 
	segment_name,
	SUM(qty) AS quantity,
    ROUND(SUM((qty*sales.price)),2) AS revenue_generated,
    ROUND(SUM(qty*sales.price*discount/100),2) AS discount
FROM sales JOIN product_details ON sales.prod_id = product_details.product_id
GROUP BY segment_name
ORDER BY revenue_generated DESC;

-- 3. What is the top selling product for each segment?
WITH CTE AS(
SELECT 
	segment_name,
    product_name,
	SUM(qty) AS quantity,
    ROUND(SUM((qty*sales.price)),2) AS revenue_generated,
    ROUND(SUM(qty*sales.price*discount/100),2) AS discount
FROM sales JOIN product_details ON sales.prod_id = product_details.product_id
GROUP BY segment_name, product_name
ORDER BY revenue_generated DESC)

SELECT * FROM CTE ct1
WHERE revenue_generated = (SELECT MAX(revenue_generated)
FROM CTE ct2 WHERE ct1.segment_name = ct2.segment_name);

-- 4. What is the total quantity, revenue and discount for each category?
SELECT 
	category_name,
	SUM(qty) AS quantity,
    ROUND(SUM((qty*sales.price)),2) AS revenue_generated,
    ROUND(SUM(qty*sales.price*discount/100),2) AS discount
FROM sales JOIN product_details ON sales.prod_id = product_details.product_id
GROUP BY category_name
ORDER BY revenue_generated DESC;

-- 5. What is the top selling product for each category?
WITH CTE AS(
SELECT 
	category_name,
    product_name,
	SUM(qty) AS quantity,
    ROUND(SUM((qty*sales.price)),2) AS revenue_generated,
    ROUND(SUM(qty*sales.price*discount/100),2) AS discount
FROM sales JOIN product_details ON sales.prod_id = product_details.product_id
GROUP BY category_name, product_name
ORDER BY revenue_generated DESC)

SELECT * FROM CTE ct1
WHERE revenue_generated = (SELECT MAX(revenue_generated)
FROM CTE ct2 WHERE ct1.category_name = ct2.category_name);

-- 6. What is the percentage split of revenue by product for each segment?
WITH CTE AS(
SELECT 
	segment_name,
    ROUND(SUM(qty * sales.price)) AS revenue_per_segment
FROM sales JOIN product_details ON sales.prod_id = product_details.product_id
GROUP BY segment_name
ORDER BY segment_name),

CTE1 AS(
SELECT 
	segment_name,
	product_name,
    ROUND(SUM(qty * sales.price)) AS revenue_per_product
FROM sales JOIN product_details ON sales.prod_id = product_details.product_id
GROUP BY segment_name, product_name
ORDER BY segment_name)

SELECT 
	segment_name,
    product_name,
    ROUND((revenue_per_product/revenue_per_segment)*100,2) AS percent_split
FROM CTE JOIN CTE1 USING(segment_name) ;

 -- OR --
WITH CTE AS(
SELECT 
	segment_name,
	product_name,
    ROUND(SUM(qty * sales.price)) AS product_revenue
FROM sales JOIN product_details ON sales.prod_id = product_details.product_id
GROUP BY segment_name, product_name
ORDER BY segment_name)

SELECT *, 
ROUND(product_revenue*100/SUM(product_revenue) OVER(PARTITION BY segment_name),2) AS percent_split
FROM CTE;

-- 7. What is the percentage split of revenue by segment for each category?
WITH CTE AS(
SELECT 
	segment_name,
	category_name,
    ROUND(SUM(qty * sales.price)) AS product_revenue
FROM sales JOIN product_details ON sales.prod_id = product_details.product_id
GROUP BY segment_name, category_name
ORDER BY segment_name)

SELECT *, 
ROUND(product_revenue*100/SUM(product_revenue) OVER(PARTITION BY category_name),2) AS percent_split
FROM CTE;

-- 8. What is the percentage split of total revenue by category?
SELECT 
	category_name,
    ROUND((SUM(qty*sales.price)/ (SELECT SUM((qty*sales.price)) FROM sales))*100,2) AS percent_split
FROM sales JOIN product_details ON sales.prod_id = product_details.product_id
GROUP BY category_name
ORDER BY percent_split DESC;

/*
9. What is the total transaction “penetration” for each product? 
(hint: penetration = number of transactions where at least 1 quantity of a product was purchased 
divided by total number of transactions)
*/
SELECT 
	DISTINCT product_name,
    ROUND(COUNT(DISTINCT txn_id)*100/(SELECT COUNT(DISTINCT txn_id) FROM sales),2) AS penetration
FROM sales JOIN product_details ON sales.prod_id = product_details.product_id
GROUP BY product_name
ORDER BY penetration DESC;



