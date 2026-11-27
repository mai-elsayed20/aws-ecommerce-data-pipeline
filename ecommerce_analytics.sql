-- Task 29: Calculate total sales, orders, customers, products, quantity sold, and profit.

SELECT
    SUM(f.net_sales) AS total_sales,
    COUNT(DISTINCT f.order_id) AS total_orders,
    COUNT(DISTINCT f.customer_key) AS total_customers,
    COUNT(DISTINCT f.product_key) AS total_products,
    SUM(f.quantity) AS total_quantity_sold,
    SUM(
        f.net_sales - (f.quantity * p.cost)
    ) AS total_profit
FROM ecom_db.fact_order_detail AS f
JOIN ecom_db.dim_product AS p
    ON f.product_key = p.product_key;


-- Task 30: Calculate monthly sales, orders, quantity, and profit.

SELECT
    d.year,
    d.month,
    d.month_name,
    SUM(f.net_sales) AS sales,
    COUNT(DISTINCT f.order_id) AS orders,
    SUM(f.quantity) AS quantity,
    SUM(
        f.net_sales - (f.quantity * p.cost)
    ) AS profit
FROM ecom_db.fact_order_detail AS f
JOIN ecom_db.dim_product AS p
    ON f.product_key = p.product_key
JOIN ecom_db.dim_date AS d
    ON f.date_key = d.date_key
GROUP BY
    d.year,
    d.month,
    d.month_name
ORDER BY
    d.year,
    d.month;


-- Task 31: Sales by category

SELECT
    c.category_name,
    SUM(f.net_sales) AS total_sales
FROM ecom_db.fact_order_detail AS f
JOIN ecom_db.dim_product AS p
    ON f.product_key = p.product_key
JOIN ecom_db.dim_category AS c
    ON p.category_key = c.category_key
GROUP BY
    c.category_name
ORDER BY
    total_sales DESC;    

-- Task 31: Sales by product

SELECT
    p.product_id,
    p.product_name,
    SUM(f.net_sales) AS total_sales
FROM ecom_db.fact_order_detail AS f
JOIN ecom_db.dim_product AS p
    ON f.product_key = p.product_key
GROUP BY
    p.product_id,
    p.product_name
ORDER BY
    total_sales DESC;  

-- Task 31: Sales by customer

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    SUM(f.net_sales) AS total_sales
FROM ecom_db.fact_order_detail AS f
JOIN ecom_db.dim_customer AS c
    ON f.customer_key = c.customer_key
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY
    total_sales DESC;    

-- Task 32: Top 10 products

SELECT
    p.product_id,
    p.product_name,
    SUM(f.net_sales) AS total_sales
FROM ecom_db.fact_order_detail AS f
JOIN ecom_db.dim_product AS p
    ON f.product_key = p.product_key
GROUP BY
    p.product_id,
    p.product_name
ORDER BY
    total_sales DESC
LIMIT 10;    

-- Task 33: Top 10 customers

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    SUM(f.net_sales) AS total_sales
FROM ecom_db.fact_order_detail AS f
JOIN ecom_db.dim_customer AS c
    ON f.customer_key = c.customer_key
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY
    total_sales DESC
LIMIT 10;    
-- Task 34: Calculate average order value

SELECT
    AVG(order_total) AS average_order_value
FROM ecom_db.fact_order;

-- Task 35: Order status counts and value

SELECT
    s.order_status,
    COUNT(DISTINCT f.order_id) AS order_count,
    SUM(f.order_total) AS total_order_value
FROM ecom_db.fact_order AS f
JOIN ecom_db.dim_order_status AS s
    ON f.order_status_key = s.order_status_key
GROUP BY
    s.order_status
ORDER BY
    order_count DESC;

-- Task 36: Payment method analysis

SELECT
    pm.payment_method,
    COUNT(f.payment_id) AS transaction_count,
    SUM(f.payment_amount) AS total_amount,
    AVG(f.payment_amount) AS average_amount
FROM ecom_db.fact_payment AS f
JOIN ecom_db.dim_payment_method AS pm
    ON f.payment_method_key = pm.payment_method_key
GROUP BY
    pm.payment_method
ORDER BY
    total_amount DESC;    


-- Task 37: Shipment performance

SELECT
    COUNT(f.shipment_id) AS total_shipments,
    AVG(f.delivery_duration_days) AS average_delivery_days,
    MIN(f.delivery_duration_days) AS min_delivery_days,
    MAX(f.delivery_duration_days) AS max_delivery_days
FROM ecom_db.fact_shipment AS f;    

-- Task 38: Calculate running sales

SELECT
    d.year,
    d.month,
    d.month_name,
    SUM(SUM(f.net_sales)) OVER (
        ORDER BY d.year, d.month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_sales
FROM ecom_db.fact_order_detail AS f
JOIN ecom_db.dim_date AS d
    ON f.date_key = d.date_key
GROUP BY
    d.year,
    d.month,
    d.month_name
ORDER BY
    d.year,
    d.month;


-- Task 39: Calculate month-over-month sales growth

WITH monthly_sales AS (
    SELECT
        d.year,
        d.month,
        SUM(f.net_sales) AS total_sales
    FROM ecom_db.fact_order_detail AS f
    JOIN ecom_db.dim_date AS d
        ON f.date_key = d.date_key
    GROUP BY
        d.year,
        d.month
)

SELECT
    year,
    month,
    total_sales,
    LAG(total_sales) OVER (
        ORDER BY year, month
    ) AS previous_month_sales,
    ROUND(
        100.0 * (total_sales - LAG(total_sales) OVER (
            ORDER BY year, month
        ))
        / NULLIF(LAG(total_sales) OVER (
            ORDER BY year, month
        ), 0),
        2
    ) AS mom_growth_percentage
FROM monthly_sales
ORDER BY
    year,
    month;    

-- Task 40: Rank products within each category

WITH product_sales AS (
    SELECT
        c.category_name,
        p.product_id,
        p.product_name,
        SUM(f.net_sales) AS total_sales
    FROM ecom_db.fact_order_detail AS f
    JOIN ecom_db.dim_product AS p
        ON f.product_key = p.product_key
    JOIN ecom_db.dim_category AS c
        ON p.category_key = c.category_key
    GROUP BY
        c.category_name,
        p.product_id,
        p.product_name
),

ranked_products AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY category_name
            ORDER BY total_sales DESC
        ) AS product_rank
    FROM product_sales
)

SELECT
    category_name,
    product_id,
    product_name,
    total_sales,
    product_rank
FROM ranked_products
WHERE product_rank <= 3
ORDER BY
    category_name,
    product_rank;    


-- Task 41: Rank customers by sales

WITH customer_sales AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        SUM(f.net_sales) AS total_sales
    FROM ecom_db.fact_order_detail AS f
    JOIN ecom_db.dim_customer AS c
        ON f.customer_key = c.customer_key
    GROUP BY
        c.customer_id,
        c.first_name,
        c.last_name
)

SELECT
    customer_id,
    first_name,
    last_name,
    total_sales,
    RANK() OVER (
        ORDER BY total_sales DESC
    ) AS customer_rank
FROM customer_sales
ORDER BY
    customer_rank;
