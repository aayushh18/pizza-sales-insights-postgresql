select version();

select * from orders;

select * from order_details;

select * from pizza_types;

select * from pizzas;

--Retrieve the total number of orders placed.

SELECT
	COUNT(ORDER_ID) AS TOTAL_ORDERS
FROM
	ORDERS;

	
--Calculate the total revenue generated from pizza sales.

SELECT 
    ROUND(SUM(order_details.quantity * pizzas.price)::NUMERIC, 2) AS total_sales
FROM 
    order_details
JOIN 
    pizzas ON pizzas.pizza_id = order_details.pizza_id;


--Identify the highest-priced pizza.

SELECT 
    pizza_types.name, pizzas.price
FROM 
    pizza_types
JOIN 
    pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
ORDER BY 
    pizzas.price DESC
LIMIT 1;

--Identify the most common pizza size ordered.

SELECT
	PIZZAS.SIZE,
	COUNT(ORDER_DETAILS.ORDER_DETAILS_ID) AS ORDER_COUNT
FROM
	PIZZAS
	JOIN ORDER_DETAILS ON PIZZAS.PIZZA_ID = ORDER_DETAILS.PIZZA_ID
GROUP BY
	PIZZAS.SIZE
ORDER BY
	ORDER_COUNT DESC;

--List the top 5 most ordered pizza types along with their quantities.
	
SELECT 
    pizza_types.name,
    SUM(order_details.quantity) AS quantity
FROM 
    pizza_types
JOIN 
    pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
JOIN 
    order_details ON order_details.pizza_id = pizzas.pizza_id
GROUP BY 
    pizza_types.name
ORDER BY 
    quantity DESC
LIMIT 5;


--Join the necessary tables to find the total quantity of each pizza category ordered.

SELECT 
    pizza_types.category,
    SUM(order_details.quantity) AS quantity
FROM 
    pizza_types
JOIN 
    pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
JOIN 
    order_details ON order_details.pizza_id = pizzas.pizza_id
GROUP BY 
    pizza_types.category
ORDER BY 
    quantity DESC;


--Determine the distribution of orders by hour of the day.

SELECT 
    EXTRACT(HOUR FROM time::time) AS order_hour,
    COUNT(order_id) AS order_count
FROM 
    orders
GROUP BY 
    order_hour
ORDER BY 
    order_hour;

--Join relevant tables to find the category-wise distribution of pizzas.

SELECT 
    pizza_types.category, 
    COUNT(DISTINCT pizzas.pizza_id) AS pizza_count
FROM 
    pizzas
JOIN 
    pizza_types 
ON 
    pizzas.pizza_type_id = pizza_types.pizza_type_id
GROUP BY 
    pizza_types.category
ORDER BY 
    pizza_count DESC;


--Group the orders by date and calculate the average number of pizzas ordered per day.

SELECT 
    orders.date, 
    COUNT(order_details.order_id) AS total_pizzas_ordered,
    COUNT(DISTINCT orders.date) AS total_days,
    ROUND(COUNT(order_details.order_id) / COUNT(DISTINCT orders.date)::numeric, 2) AS avg_pizzas_per_day
FROM 
    orders
JOIN 
    order_details 
ON 
    orders.order_id = order_details.order_id
GROUP BY 
    orders.date
ORDER BY 
    orders.date;


--Determine the top 3 most ordered pizza types based on revenue.

	SELECT 
    pizza_types.name AS pizza_type,
    SUM(order_details.quantity * pizzas.price) AS revenue
FROM 
    order_details
JOIN 
    pizzas ON order_details.pizza_id = pizzas.pizza_id
JOIN 
    pizza_types ON pizzas.pizza_type_id = pizza_types.pizza_type_id
GROUP BY 
    pizza_types.name
ORDER BY 
    revenue DESC
LIMIT 3;


--Analyze the cumulative revenue generated over time.
WITH order_revenue AS (
    SELECT 
        orders.order_id,
        -- Combine date and time to form a full timestamp
        CONCAT(orders.date, ' ', orders.time) AS order_time,
        SUM(order_details.quantity * pizzas.price) AS revenue
    FROM 
        order_details
    JOIN 
        orders ON order_details.order_id = orders.order_id
    JOIN 
        pizzas ON order_details.pizza_id = pizzas.pizza_id
    GROUP BY 
        orders.order_id, orders.date, orders.time
),
cumulative_revenue AS (
    SELECT 
        order_time,
        revenue,
        SUM(revenue) OVER (ORDER BY order_time) AS cumulative_revenue
    FROM 
        order_revenue
)
SELECT 
    order_time, 
    revenue,
    cumulative_revenue
FROM 
    cumulative_revenue
ORDER BY 
    order_time;

--Determine the top 3 most ordered pizza types based on revenue for each pizza category.

WITH pizza_revenue AS (
    SELECT 
        pizza_types.category,
        pizza_types.name AS pizza_name,  -- Correcting this to use pizza_types.name
        SUM(order_details.quantity * pizzas.price) AS revenue
    FROM 
        order_details
    JOIN 
        pizzas ON order_details.pizza_id = pizzas.pizza_id
    JOIN 
        pizza_types ON pizzas.pizza_type_id = pizza_types.pizza_type_id
    GROUP BY 
        pizza_types.category, pizza_types.name  -- Adjusted to use pizza_types.name
),
ranked_pizzas AS (
    SELECT 
        category,
        pizza_name,
        revenue,
        ROW_NUMBER() OVER (PARTITION BY category ORDER BY revenue DESC) AS rank
    FROM 
        pizza_revenue
)
SELECT 
    category,
    pizza_name,
    revenue
FROM 
    ranked_pizzas
WHERE 
    rank <= 3
ORDER BY 
    category, revenue DESC;


	
