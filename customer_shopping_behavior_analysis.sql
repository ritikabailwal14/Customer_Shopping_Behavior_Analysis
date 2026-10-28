SELECT * 
FROM customer 
LIMIT 20;

--Q1. How does the total and average amount vary by gender?
SELECT
	gender, 
	SUM(purchase_amount) AS total_purchase_amount,
	ROUND(AVG(purchase_amount), 2) AS average_purchase_amount
FROM customer
GROUP BY gender
ORDER BY total_purchase_amount DESC;

--Q2. What is the average age of customers in the dataset?
SELECT 
	ROUND(AVG(age), 2) AS average_customer_age
FROM customer;

--Q3. How does the total and average purchase amount vary across different age groups?
SELECT 
	age_group,
	COUNT(*) AS number_of_records,
	SUM(purchase_amount) AS total_purchase_amount,
	ROUND(AVG(purchase_amount), 2) AS average_purchase_amount
FROM customer
GROUP BY age_group
ORDER BY MIN(age);

--Q4. Which items are the most commonly purchased by customers?
WITH item_counts AS (
	SELECT
		item_purchased,
		count(*) AS purchase_count
	FROM customer
	GROUP BY item_purchased
)
SELECT 
	item_purchased, 
	purchase_count
FROM item_counts
WHERE purchase_count = (
	SELECT 
		MAX (purchase_count)
	FROM item_counts
)
ORDER BY item_purchased;

--Q5. Which 5 products have the highest average customer review ratings?
SELECT 
	item_purchased, 
	ROUND(AVG(review_rating::numeric), 2) AS "Average Product Rating"
FROM customer
GROUP BY item_purchased
ORDER BY AVG(review_rating) DESC
LIMIT 5;

--Q6.How do the total and average purchase amount vary across product categories?
SELECT
	category,
	COUNT(*) AS number_of_records,
	SUM(purchase_amount) AS total_purchase_amount,
	ROUND(AVG(purchase_amount), 2) AS average_purchase_amount	
FROM customer
GROUP BY category
ORDER BY total_purchase_amount DESC;

--Q7. What are the top 3 most purchased products within each category?
WITH item_counts AS (
	SELECT 
		category,
		item_purchased,
		COUNT(customer_id) as total_orders,
		ROW_NUMBER() OVER(PARTITION BY category ORDER BY COUNT(customer_id) DESC) AS item_rank
	FROM customer
	GROUP BY category, item_purchased
)
SELECT 
	item_rank, 
	category, 
	item_purchased, 
	total_orders
FROM item_counts
WHERE item_rank <= 3

--Q8. What are the most commonly used payment methods among customers?
SELECT 
	payment_method,
	COUNT(*) AS payment_count
FROM customer
GROUP BY payment_method
ORDER BY payment_count DESC;

--Q9. Do subscribed customers spend more? Compare average and total purchase amount between subscribers and non-subscribers.
SELECT
	subscription_status,
	COUNT(customer_id) AS total_customers,
	ROUND(AVG(purchase_amount), 2) AS avg_purchase_amount,
	ROUND(SUM(purchase_amount), 2) AS total_purchase_amount
FROM customer
GROUP BY subscription_status
ORDER BY total_purchase_amount, avg_purchase_amount DESC;

--Q10.  How many customers used a discounts, and how did their total and average purchase amounts compare with those who did not use discount?
SELECT
	discount_applied,
	COUNT(*) AS number_of_customers,
	ROUND(
		COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
		2
	) AS percentage_of_customers,
	SUM(purchase_amount) AS total_purchase_amount,
	ROUND(AVG(purchase_amount),2) AS average_purchase_amount
FROM customer
GROUP BY discount_applied
ORDER BY discount_applied DESC;

--Q11. Which customers used a discount but still spent more than average purchase amount?
SELECT 
	customer_id, 
	purchase_amount
FROM customer
WHERE discount_applied = 'Yes' AND purchase_amount >= (SELECT AVG(purchase_amount) FROM customer)

--Q12. Which 5 products have the highest percentage of purchases with discounts applied?
SELECT
    item_purchased,
    COUNT(*) AS total_purchases,
    SUM(CASE
        WHEN discount_applied = 'Yes' THEN 1
        ELSE 0
    END) AS discounted_purchases,
    ROUND(
        100.0 * SUM(CASE
            WHEN discount_applied = 'Yes' THEN 1
            ELSE 0
        END) / COUNT(*),
        2
    ) AS discount_usage_percentage
FROM customer
GROUP BY item_purchased
ORDER BY discount_usage_percentage DESC
LIMIT 5;

--Q13. How many customers subscribed customers used a discounts for their purchases?
SELECT 
	COUNT(*) AS subscribed_customers_using_discount
FROM customer
WHERE subscription_status = 'Yes'
	AND discount_applied = 'Yes';

--Q14. How do the total and average purchase amount vary across different seasons?
SELECT
	season,
	COUNT(*) AS number_of_records,
	SUM(purchase_amount) AS total_purchase_amount,
	ROUND(AVG(purchase_amount), 2) AS average_purchase_amount
FROM customer
GROUP BY season
ORDER BY total_purchase_amount DESC;

--Q15. What is the total purchase amount and percentage contribution of each clothing size (XL, L, M, S)
SELECT 
	size,
	COUNT(*) AS number_of_records,
	SUM(purchase_amount) AS total_purchase_amount,
	ROUND(
		100.0 * SUM(purchase_amount)
		/ SUM(SUM(purchase_amount)) OVER(),
		2
	) AS contribution_percentage
FROM customer
WHERE category = 'Clothing'
GROUP BY size
ORDER BY total_purchase_amount DESC;

--Q16. How do the total and average purchase amounts vary across different locations?
SELECT
    location,
    COUNT(*) AS customer_count,
    SUM(purchase_amount) AS total_purchase_amount,
    ROUND(AVG(purchase_amount), 2) AS average_purchase_amount
FROM customer
GROUP BY location
ORDER BY total_purchase_amount DESC;

--Q17. What is the most common shipping type for customers with a review rating above 4?
SELECT
	shipping_type,
	COUNT(*) AS customer_count
FROM customer
WHERE review_rating > 4
GROUP BY shipping_type
ORDER BY customer_count DESC
LIMIT 1;

--Q18. Segment customers into New, Returning, and Loyal based on their total number of previous purchases, and show the count of each segment.
WITH customer_type AS (
	SELECT 
		customer_id, 
		previous_purchases, 
		CASE 
			WHEN previous_purchases BETWEEN 1 AND 5 THEN 'New'
			WHEN previous_purchases BETWEEN 6 AND 10 THEN 'Returning'
			ELSE 'Loyal'
		END AS customer_segment,
		CASE 
			WHEN previous_purchases BETWEEN 1 AND 5 THEN '1-5 purchases'
			WHEN previous_purchases BETWEEN 6 AND 10 THEN '6-10 purchases'
			WHEN previous_purchases >= 11 THEN '11+ purchases'
		END AS previous_purchase_range
	FROM customer
)
SELECT 
	customer_segment, 
	previous_purchase_range,
	COUNT (*) AS "Number of Customers",
	ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage_of_customers
FROM customer_type
GROUP BY 
	customer_segment, 
	previous_purchase_range
ORDER BY 
	CASE customer_segment
		WHEN 'New' THEN 1
		WHEN 'Returning' THEN 2
		WHEN 'Loyal' THEN 3
	END;
	
-- Q19. How does the total and average purchase amount vary across customer segments (New, Returning, and Loyal)?
WITH customer_segments AS (
    SELECT
        customer_id,
        purchase_amount,
        CASE
            WHEN previous_purchases BETWEEN 1 AND 5 THEN 'New'
            WHEN previous_purchases BETWEEN 6 AND 10 THEN 'Returning'
            WHEN previous_purchases >= 11 THEN 'Loyal'
        END AS customer_segment
    FROM customer
)
SELECT
    customer_segment,
    COUNT(*) AS number_of_customers,
    SUM(purchase_amount) AS total_purchase_amount,
    ROUND(AVG(purchase_amount), 2) AS average_purchase_amount
FROM customer_segments
GROUP BY customer_segment
ORDER BY
    CASE customer_segment
        WHEN 'New' THEN 1
        WHEN 'Returning' THEN 2
        WHEN 'Loyal' THEN 3
    END;

--Q20. Are the customers who are repeat buyers (more than 5 previous purchases) are also likely to subscribe?
SELECT
    CASE
        WHEN previous_purchases > 5
            THEN 'Repeat Buyers: More than 5 Previous Purchases'
        ELSE 'Other Customers: 5 or Fewer Previous Purchases'
    END AS customer_group,

    COUNT(*) AS customer_count,

    SUM(
        CASE
            WHEN subscription_status = 'Yes' THEN 1
            ELSE 0
        END
    ) AS subscribers,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN subscription_status = 'Yes' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS subscription_rate_percentage

FROM customer
GROUP BY
    CASE
        WHEN previous_purchases > 5
            THEN 'Repeat Buyers: More than 5 Previous Purchases'
        ELSE 'Other Customers: 5 or Fewer Previous Purchases'
    END
ORDER BY
    MIN(previous_purchases) DESC;

