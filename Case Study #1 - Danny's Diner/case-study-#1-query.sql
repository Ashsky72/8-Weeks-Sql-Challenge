--1. What is the total amount each customer spent at the restaurant?


SELECT
s.customer_id,
SUM(price) AS total_sales b
FROM sales AS 5
JOIN menu AS m
ON s.product_id = m.product_id
GROUP BY customerid;


--2. How many days has each customer visited the restaurant?

SELECT
customer_id,
COUNT(DISTINCT(order_date)) AS customer_visit_count
FROM sales
GROUP BY customer_id;


--3. What was the first item from the menu purchased by each customer?


WITH ordered_sales_cte AS
(
SELECT s.customer_id,
s.order_date,
m.product_name,
ROW_NUMBER() OVER(PARTITION BY s.customer_id
ORDER BY s.order_date) AS ranking
FROM sales AS s
JOIN menu AS m
ON s.product_id = m.product_id
SELECT customer_id, product_name, ranking
FROM ordered_sales_cte
WHERE ranking = 1
GROUP BY customer_id,
         product_name;


--4. What is the most purchased item on the menu and how many times was it purchased by all customers?


SELECT (COUNT(s.product_id)) AS most_purchased_item,
        product_name
FROM sales AS s
JOIN menu AS m
ON s.product_id = m.product_id
GROUP BY s.product_id,
         product_name
ORDER BY most_purchased_item DESC
LIMIT 1;


--5. Which item was the most popular for each customer?


WITH fav_item_cte AS
(

SELECT s.customer_id,
       m.product_name,
       COUNT(m.product_id) AS order_count,
DENSE_RANK() OVER(PARTITION BY s.customer_id
ORDER BY COUNT(m.product_id) DESC) AS ranking
FROM menu AS m
JOIN sales AS s
ON m.product_id = s.product_id
GROUP BY s.customer_id,
         m.product_name

)

SELECT customer_id,
       product_name,
       order_count,
       ranking
FROM fav_item_cte
WHERE ranking = 1;


--6. Which item was purchased first by the customer after they became a member?


WITH member_first_purchased_cte AS 
(
SELECT s.customer_id,
       m.join_date,
       s.order_date,
       s.product_id,
DENSE_RANK() OVER(PARTITION BY s.customer_id
ORDER BY s.order_date) AS ranking
FROM sales AS s
JOIN members AS m
ON s.customer_id = m.customer_id
WHERE s.order_date =  m.join_date
)
SELECT s.customer_id,
       s.order_date,
       m2.product_name,
       ranking
FROM member_first_purchased_cte AS s
JOIN menu AS m2
ON s.product_id = m2.product_id;


--7. Which item was purchased just before the customer became a member?


WITH prior_member_purchased_cte AS 
(
SELECT s.customer_id,
       m.join_date,
       s.order_date,
       s.product_id,
DENSE_RANK() OVER(PARTITION BY s.customer_id
ORDER BY order_date DESC) AS ranking
FROM sales AS s
JOIN members AS m
ON s.customer_id = m.customer_id
WHERE s.order_date < m.join_date
)
SELECT s.customer_id,
       s.order_date,
       m2.product_name
FROM prior_member_purchased_cte AS s
JOIN menu AS m2
ON s.product_id = m2.product_id
WHERE ranking = 1
ORDER BY customer_id;


--8. What is the total items and amount spent for each member before they became a member?


SELECT s.customer_id,
       COUNT(DISTINCT s.product_id) AS unique_menu_item,
	   SUM(m.price) AS total_sales
FROM sales AS s
JOIN members AS mm
ON s.customer_id = mm.customer_id
JOIN menu AS m
ON s.product_id = m.product_id
WHERE s.order_date < mm.join_date
GROUP BY s.customer_id;
    
    
--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?


WITH price_points_cte AS 
(
SELECT *,
CASE
    WHEN product_id = 1 THEN price * 20
    ELSE price * 10
    END AS points
FROM menu
)
SELECT s.customer_id,
       SUM(p.points) AS total_points
FROM price_points_cte AS p
JOIN sales AS s
ON p.product_id = s.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;


--10 In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?


WITH 
dates_cte AS 
(
SELECT *,
	   DATE_ADD(join_date, INTERVAL 6 DAY) AS valid_date, 
       DATE('2021-01-31') AS last_date
FROM members AS m
),
points_cte AS 
(
SELECT d.customer_id, 
       s.order_date, 
       d.join_date, 
       d.valid_date, 
       d.last_date,
       m.product_name,
       m.price,
 SUM(CASE
         WHEN m.product_name = 'sushi' THEN 2 * 10 * m.price
         WHEN s.order_date BETWEEN d.join_date AND d.valid_date THEN 2 * 10 * m.price
         ELSE 10 * m.price
         END) AS points
FROM dates_cte AS d
JOIN sales AS s
ON d.customer_id = s.customer_id
JOIN menu AS m
ON s.product_id = m.product_id
WHERE s.order_date < d.last_date
GROUP BY d.customer_id, 
         s.order_date, 
         d.join_date, 
         d.valid_date, 
         d.last_date, 
         m.product_name, 
         m.price
)
SELECT cuStomer_id,
       SUM(points) AS total_points
FROM points_cte
GROUP BY customer_id;
       
           
