--1--
WITH RankedOrders AS (
    SELECT 
        c.customer_name,
        o.order_id,
        o.order_date,
        ROW_NUMBER() OVER (PARTITION BY o.customer_id ORDER BY o.order_date DESC) AS rn
    FROM 
        orders o
    JOIN 
        customers c ON o.customer_id = c.customer_id
)
SELECT 
    customer_name,
    order_id,
    order_date
FROM 
    RankedOrders
WHERE 
    rn IN (1, 2)
ORDER BY 
    customer_name ASC, 
    rn ASC;

--2--
WITH CustomerProfit AS (
    SELECT 
        c.region,
        c.customer_name,
        SUM(o.profit) AS total_profit
    FROM 
        customers c
    JOIN 
        orders o ON c.customer_id = o.customer_id
    GROUP BY 
        c.region, 
        c.customer_name
)
SELECT 
    region,
    customer_name,
    total_profit,
    RANK() OVER (PARTITION BY region ORDER BY total_profit DESC) AS rank,
    DENSE_RANK() OVER (PARTITION BY region ORDER BY total_profit DESC) AS dense_rank
FROM 
    CustomerProfit
ORDER BY 
    region ASC, 
    total_profit DESC;
--3--
WITH CustomerSales AS (
    SELECT 
        c.customer_name,
        SUM(o.sales) AS total_sales
    FROM 
        customers c
    JOIN 
        orders o ON c.customer_id = o.customer_id
    GROUP BY 
        c.customer_name
)
SELECT 
    customer_name,
    total_sales,
    NTILE(4) OVER (ORDER BY total_sales DESC) AS quartile
FROM 
    CustomerSales
ORDER BY 
    total_sales DESC;
--4--
WITH MonthlySales AS (
    SELECT 
        DATE_TRUNC('month', order_date) AS month,
        SUM(sales) AS monthly_sales
    FROM 
        orders
    GROUP BY 
        DATE_TRUNC('month', order_date)
)
SELECT 
    month,
    monthly_sales,
    LAG(monthly_sales, 1) OVER (ORDER BY month) AS prev_month_sales,
    LEAD(monthly_sales, 1) OVER (ORDER BY month) AS next_month_sales
FROM 
    MonthlySales
ORDER BY 
    month ASC;
--5--
WITH ProductSales AS (
    SELECT 
        p.category,
        p.product_name,
        SUM(o.sales) AS product_sales
    FROM 
        orders o
    JOIN 
        products p ON o.product_id = p.product_id
    GROUP BY 
        p.category, 
        p.product_name
)
SELECT 
    category,
    product_name,
    product_sales,
    SUM(product_sales) OVER (PARTITION BY category) AS category_total,
    ROUND(
        product_sales * 100.0 / SUM(product_sales) OVER (PARTITION BY category), 
        2
    ) AS pct_of_category
FROM 
    ProductSales
ORDER BY 
    category ASC, 
    pct_of_category DESC;
--6--
WITH CustomerOrders AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        MAX(o.order_date) AS last_order_date,
        MAX(MAX(o.order_date)) OVER () AS latest_order_date
    FROM 
        customers c
    JOIN 
        orders o ON c.customer_id = o.customer_id
    GROUP BY 
        c.customer_id, 
        c.customer_name
)
SELECT 
    customer_id,
    customer_name,
    last_order_date
FROM 
    CustomerOrders
WHERE 
    last_order_date < latest_order_date - INTERVAL '90 days'
ORDER BY 
    last_order_date ASC;
--7--
WITH MonthlySales AS (
    SELECT 
        DATE_TRUNC('month', order_date) AS month,
        SUM(sales) AS monthly_sales
    FROM 
        orders
    GROUP BY 
        DATE_TRUNC('month', order_date)
),
SalesComparison AS (
    SELECT 
        month,
        monthly_sales,
        LAG(monthly_sales, 1) OVER (ORDER BY month) AS prev_month_sales
    FROM 
        MonthlySales
)
SELECT 
    month,
    monthly_sales,
    prev_month_sales,
    (monthly_sales - prev_month_sales) AS sales_change,
    ROUND(
        ((monthly_sales - prev_month_sales) * 100.0 / prev_month_sales), 
        2
    ) AS growth_percentage
FROM 
    SalesComparison
ORDER BY 
    month ASC;
--8--
WITH FirstPurchase AS (
    SELECT 
        customer_id,
        DATE_TRUNC('month', MIN(order_date)) AS first_month
    FROM 
        orders
    GROUP BY 
        customer_id
)
SELECT 
    COUNT(DISTINCT fp.customer_id) AS returning_customers_count
FROM 
    FirstPurchase fp
WHERE 
    fp.first_month = '2024-06-01'
    AND EXISTS (
        SELECT 1 
        FROM orders o 
        WHERE o.customer_id = fp.customer_id 
          AND DATE_TRUNC('month', o.order_date) > fp.first_month
    );