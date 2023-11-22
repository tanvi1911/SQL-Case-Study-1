SELECT * 
FROM members; 

SELECT * 
FROM menu; 

SELECT * 
FROM sales; 

--Q1.What is the total amount each customer spent at the restaurant?
SELECT s.customer_id, SUM(m.price) AS total_amount 
FROM sales AS s
INNER JOIN menu AS m ON s.product_id = m.product_id
GROUP BY customer_id
ORDER BY customer_id;

--Q2.How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT(order_date)) AS total_days
FROM sales 
GROUP BY customer_id
ORDER BY customer_id;

--Q3.What was the first item from the menu purchased by each customer?
SELECT DISTINCT(s.customer_id), m.product_name, s.order_date
FROM sales AS s
INNER JOIN menu AS m ON s.product_id = m.product_id
WHERE s.order_date = (Select MIN(order_date) FROM sales)
ORDER BY s.customer_id;

--Q4.What is the most purchased item on the menu and how many times was it 
--purchased by all customers?
SELECT m.product_name, COUNT(*) AS purchase_count
FROM sales s
JOIN menu m ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY purchase_count DESC
LIMIT 1;

--Q5.Which item was the most popular for each customer?
WITH customer_most_popular_item AS (
  SELECT
    s.customer_id,
    m.product_name,
    COUNT(*) AS purchase_count,
    RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(*) DESC) AS item_rank
  FROM
    sales s
    JOIN menu m ON s.product_id = m.product_id
  GROUP BY
    s.customer_id, m.product_name
)

SELECT
  customer_id,
  product_name AS most_popular_item,
  purchase_count
FROM
  customer_most_popular_item
WHERE
  item_rank = 1;


--Q6.Which item was purchased first by the customer after they became a member?
WITH customer_first_purchase AS (
  SELECT
    s.customer_id,
    m.product_name,
    s.order_date,
    mem.join_date,
    ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS purchase_rank
  FROM
    sales s
    JOIN menu m ON s.product_id = m.product_id
    JOIN members mem ON s.customer_id = mem.customer_id
  WHERE
    s.order_date >= mem.join_date
)

SELECT
  customer_id,
  product_name AS first_purchase_item,
  order_date AS purchase_date
FROM
  customer_first_purchase
WHERE
  purchase_rank = 1;

--Q7.Which item was purchased just before the customer became a member?
WITH customer_last_purchase_before_membership AS (
  SELECT
    s.customer_id,
    m.product_name,
    s.order_date,
    LAG(mem.join_date) OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS previous_membership_date
  FROM
    sales s
    JOIN menu m ON s.product_id = m.product_id
    LEFT JOIN members mem ON s.customer_id = mem.customer_id
)

SELECT
  customer_id,
  product_name AS last_purchase_before_membership_item,
  order_date AS last_purchase_date
FROM
  customer_last_purchase_before_membership
WHERE
  order_date = previous_membership_date;

--Q8.What is the total items and amount spent for each member before they became a member?
WITH member_purchase_summary AS (
  SELECT
    s.customer_id,
    COUNT(*) AS total_items,
    SUM(m.price) AS total_amount_spent
  FROM
    sales s
    JOIN menu m ON s.product_id = m.product_id
    LEFT JOIN members mem ON s.customer_id = mem.customer_id
  WHERE
    s.order_date < mem.join_date OR mem.join_date IS NULL
  GROUP BY
    s.customer_id
)

SELECT
  customer_id,
  total_items,
  total_amount_spent
FROM
  member_purchase_summary;

--Q9.If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH customer_points AS (
  SELECT
    s.customer_id,
    SUM(CASE WHEN m.product_name = 'sushi' THEN 2 * m.price ELSE m.price END) AS total_amount_spent
  FROM
    sales s
    JOIN menu m ON s.product_id = m.product_id
  GROUP BY
    s.customer_id
)

SELECT
  customer_id,
  total_amount_spent * 10 AS total_points
FROM
  customer_points;
  
--Q10.In the first week after a customer joins the program (including their join date) they 
--earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH customer_points AS (
  SELECT
    s.customer_id,
    SUM(
      CASE
        WHEN s.order_date < mem.join_date + INTERVAL '7 days' THEN 2 * m.price
        ELSE m.price
      END
    ) AS total_amount_spent
  FROM
    sales s
    JOIN menu m ON s.product_id = m.product_id
    LEFT JOIN members mem ON s.customer_id = mem.customer_id
  WHERE
    s.order_date <= '2021-01-31' AND s.order_date >= mem.join_date
  GROUP BY
    s.customer_id
)
SELECT
  customer_id,
  total_amount_spent * 10 AS total_points
FROM
  customer_points
WHERE
  customer_id IN ('A', 'B');


