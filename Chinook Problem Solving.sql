use chinook;
-- select * from album;
-- select * from artist;
-- select * from customer;
-- select * from employee;
-- select * from genre;
-- select * from invoice;
-- select * from invoice_line;
-- select * from media_type;
-- select * from playlist;
-- select * from playlist_track;
-- select * from track;

-- Joins for reference
-- Select * from employee e
-- Join customer c on e.employee_id = c.support_rep_id
-- Join invoice i on c.customer_id = i.customer_id
-- Join invoice_line il on i.invoice_id = il.invoice_id
-- Join track t on il.track_id = t.track_id
-- Join playlist_track pt on t.track_id = pt.track_id
-- Join playlist p on pt.playlist_id = p.playlist_id
-- Join album a on t.album_id = a.album_id
-- Join artist art on a.artist_id = art.artist_id
-- Join media_type mt on t.media_type_id = mt.media_type_id
-- Join genre g on t.genre_id = g.genre_id; 
-- --------------------------------------------------------------------------------------------------------------------------------------------
-- ---------------------------------------------------------- OBJECTIVE QUESTIONS--------------------------------------------------------------
-- Q1. Does any table have missing values or duplicates? If yes how would you handle it?
-- Ans.
update customer
set company='Unknown'
where company is NULL;

update customer
set state='Not Mentioned'
where state is NULL;

update customer
set postal_code='Unknown'
where postal_code is NULL;

update customer
set phone='Not Mentioned'
where phone is NULL;

update customer
set fax='Not Mentioned'
where fax is NULL;

UPDATE track 
SET composer = 'Not Mentioned'
WHERE composer IS NULL;
-- --------------------------------------------------------------------------------------------------------------------------------------------

-- Q2. Find the top-selling tracks and top artist in the USA and identify their most famous genres.
-- Ans. Top selling track in USA
SELECT t.name as track_name, SUM(il.quantity) AS quantity
FROM customer c 
JOIN invoice i ON c.customer_id = i.customer_id 
JOIN invoice_line il ON i.invoice_id = il.invoice_id 
JOIN track t ON il.track_id = t.track_id
WHERE c.country = 'USA'
GROUP BY t.name
ORDER BY quantity DESC;

-- Top Artist in USA
SELECT art.name as artist_name, SUM(il.quantity) AS quantity
FROM customer c 
JOIN invoice i ON c.customer_id = i.customer_id 
JOIN invoice_line il ON i.invoice_id = il.invoice_id 
JOIN track t ON il.track_id = t.track_id
JOIN album a on t.album_id = a.album_id 
JOIN artist art ON a.artist_id = art.artist_id
WHERE c.country = 'USA'
GROUP BY art.name
ORDER BY quantity DESC;

-- Most famous genre in USA
SELECT g.name AS genre_name, SUM(il.quantity) AS quantity
FROM customer c 
JOIN invoice i ON c.customer_id = i.customer_id 
JOIN invoice_line il ON i.invoice_id = il.invoice_id 
JOIN track t ON il.track_id = t.track_id
JOIN genre g ON t.genre_id = g.genre_id
WHERE c.country = 'USA'
GROUP BY g.name
ORDER BY quantity DESC;
-- --------------------------------------------------------------------------------------------------------------------------------------------

-- Q3. What is the customer demographic breakdown (age, gender, location) of Chinook's customer base?
-- Ans. Customer demographic breakdown on the basis of Country 
SELECT country, count(customer_id) as number_of_customers
FROM customer
GROUP BY country
ORDER BY number_of_customers;

-- Customer demographic breakdown on the basis of State 
SELECT state, count(customer_id) as number_of_customers
FROM customer
WHERE state != 'Not Mentioned'
GROUP BY state
ORDER BY number_of_customers;

-- Customer demographic breakdown on the basis of City 
SELECT city, count(customer_id) as number_of_customers
FROM customer
GROUP BY city
ORDER BY number_of_customers;
-- --------------------------------------------------------------------------------------------------------------------------------------------

-- Q4. Calculate the total revenue and number of invoices for each country, state, and city.
-- Ans. Total revenue and number of invoices for each country
SELECT billing_country as country, count(invoice_id) invoice_count, sum(total) as total_revenue 
FROM invoice
GROUP BY billing_country
ORDER BY total_revenue desc, invoice_count desc;

-- Total revenue and number of invoices for each state
SELECT billing_state as state, count(invoice_id) invoice_count, sum(total) as total_revenue
FROM invoice
WHERE billing_state != 'None'
GROUP BY billing_state
ORDER BY total_revenue desc, invoice_count desc;

-- Total revenue and number of invoices for each city
SELECT billing_city as city, count(invoice_id) invoice_count, sum(total) as total_revenue
FROM invoice
GROUP BY billing_city
ORDER BY total_revenue desc, invoice_count desc;
-- --------------------------------------------------------------------------------------------------------------------------------------------

-- Q5. Find the top 5 customers by total revenue in each country
-- Ans. Top 5 customers by total revenue in each country
with cte as
(SELECT customer_id, billing_country, sum(total) as revenue, rank() over(PARTITION BY billing_country ORDER BY sum(total) desc) as `rank`
FROM invoice
GROUP BY customer_id, billing_country)

SELECT billing_country as country, c.customer_id, first_name, last_name, revenue, `rank`
FROM cte c
JOIN customer cc on c.customer_id = cc.customer_id
WHERE `rank` <=5
-- --------------------------------------------------------------------------------------------------------------------------------------------

-- Q6. Identify the top-selling track for each customer
-- Ans. Top-selling track for each customer
WITH CustomerTrackSales AS (
SELECT c.customer_id, c.first_name, c.last_name, t.track_id, t.name AS track_name,
SUM(il.quantity) AS total_quantity
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
JOIN track t ON il.track_id = t.track_id
GROUP BY c.customer_id, c.first_name, c.last_name, t.track_id, t.name),
TopTracks AS (
SELECT customer_id, first_name, last_name, track_id, track_name, total_quantity,
ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY total_quantity DESC) AS `rank`
FROM CustomerTrackSales)
SELECT customer_id, first_name, last_name, track_name, total_quantity
FROM TopTracks
WHERE `rank` = 1
ORDER BY customer_id;

-- --------------------------------------------------------------------------------------------------------------------------------------------

-- Q7. Are there any patterns or trends in customer purchasing behavior (e.g., frequency of purchases, preferred payment methods, average order value)?
-- Ans.
SELECT c.customer_id, c.first_name, c.last_name, YEAR(i.invoice_date) AS year, 
COUNT(i.invoice_id) AS purchase_count, round(avg(i.total),2) as Avg_order_value
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, YEAR(i.invoice_date)
ORDER BY c.customer_id, c.first_name, c.last_name, YEAR(i.invoice_date);
-- --------------------------------------------------------------------------------------------------------------------------------------------

-- Q8. What is the customer churn rate?
-- Ans.
With CutoffDate AS (
SELECT DATE_SUB((SELECT MAX(invoice_date) AS most_recent_invoice_date
FROM invoice), INTERVAL 1 YEAR) AS cutoff_date),
ChurnCustomers AS (
SELECT c.customer_id, c.first_name, c.last_name, MAX(i.invoice_date) AS latest_purchase_date
FROM customer c
LEFT JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING latest_purchase_date IS NULL OR latest_purchase_date < (SELECT cutoff_date FROM CutoffDate))

SELECT round((SELECT COUNT(*) FROM ChurnCustomers) / COUNT(*) * 100, 2) AS churn_rate
FROM customer;
-- --------------------------------------------------------------------------------------------------------------------------------------------

-- Q9. Calculate the percentage of total sales contributed by each genre in the USA and identify the best-selling genres and artists.
-- Ans. Best-selling genres and percentage of total sales contributed by each genre in the USA
WITH genre_counts AS (
SELECT g.name AS genre_name, COUNT(g.genre_id) AS genre_count
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
JOIN track t ON il.track_id = t.track_id
JOIN genre g ON t.genre_id = g.genre_id
WHERE c.country = 'USA'
GROUP BY g.name),
total_count AS (
SELECT COUNT(g.genre_id) AS total_count
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
JOIN track t ON il.track_id = t.track_id
JOIN genre g ON t.genre_id = g.genre_id
WHERE c.country = 'USA')

SELECT gc.genre_name, gc.genre_count, round((gc.genre_count  / tc.total_count) * 100,2) AS percentage
FROM genre_counts gc
CROSS JOIN total_count tc
ORDER BY gc.genre_count DESC;

-- Best selling Artist in USA
SELECT art.name as artist_name, SUM(il.quantity) AS quantity
FROM customer c 
JOIN invoice i ON c.customer_id = i.customer_id 
JOIN invoice_line il ON i.invoice_id = il.invoice_id 
JOIN track t ON il.track_id = t.track_id
JOIN album a on t.album_id = a.album_id 
JOIN artist art ON a.artist_id = art.artist_id
WHERE c.country = 'USA'
GROUP BY art.name
ORDER BY quantity DESC;
-- --------------------------------------------------------------------------------------------------------------------------------------------

-- Q10. Find customers who have purchased tracks from at least 3 different genres
-- Ans. 
SELECT c.customer_id, c.first_name, c.last_name, count(distinct g.genre_id) AS genre_count
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
JOIN track t ON il.track_id = t.track_id
JOIN genre g ON t.genre_id = g.genre_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING count(distinct g.genre_id) >=3
ORDER BY genre_count DESC
-- --------------------------------------------------------------------------------------------------------------------------------------------

-- 11. Rank genres based on their sales performance in the USA
-- Ans.
SELECT g.name, sum(i.total) as genre_sum, RANK() OVER(ORDER BY sum(i.total) DESC) as `rank`
FROM customer c 
JOIN invoice i on c.customer_id = i.customer_id 
JOIN invoice_line il on i.invoice_id = il.invoice_id 
JOIN track t on il.track_id = t.track_id
JOIN genre g on t.genre_id = g.genre_id
WHERE c.country = "USA"
GROUP BY g.name
-- --------------------------------------------------------------------------------------------------------------------------------------------

-- 12. Identify customers who have not made a purchase in the last 3 months
-- Ans.
WITH last_3_month as
(SELECT customer_id
FROM invoice
WHERE DATE(invoice_date) BETWEEN '2020-10-01' AND '2020-12-30')

SELECT c.customer_id, c.first_name, c.last_name, max(DATE(invoice_date)) as last_purchase_date 
FROM customer c 
JOIN invoice i on c.customer_id = i.customer_id
WHERE c.customer_id not in (select * from last_3_month)
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY c.customer_id;
-- ---------------------------------------------------------------------------------------------------------------------------------
-- -------------------------------------------------------SUBJECTIVE QUESTIONS------------------------------------------------------

-- Q1. Recommend the three albums from the new record label that should be prioritised for advertising and promotion in the USA based on genre sales analysis.
-- Ans.
SELECT g.genre_id, g.name AS genre_name, al.album_id, al.title as album_title,
SUM(i.total) AS total_genre_sales,
DENSE_RANK() OVER (ORDER BY SUM(i.total) DESC) AS `rank`
FROM customer c 
JOIN invoice i ON i.customer_id = c.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id 
JOIN genre g ON g.genre_id = t.genre_id
JOIN album al on t.album_id = al.album_id
WHERE c.country = 'USA'
GROUP BY g.genre_id, g.name, al.album_id, al.title
ORDER BY total_genre_sales DESC;
-- ---------------------------------------------------------------------------------------------------------------------------------

-- Q2. Determine the top-selling genres in countries other than the USA and identify any commonalities or differences.
-- Ans. 
SELECT i.billing_country, g.name AS genre_name, 
SUM(i.total) AS total_genre_sales,
RANK() OVER (ORDER BY SUM(i.total) DESC) AS `rank`
FROM invoice i 
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id 
JOIN genre g ON g.genre_id = t.genre_id
JOIN album al on t.album_id = al.album_id
GROUP BY i.billing_country, g.name
ORDER BY total_genre_sales DESC;
-- ---------------------------------------------------------------------------------------------------------------------------------

-- Q3. Customer Purchasing Behaviour Analysis: How do the purchasing habits (frequency, basket size, spending amount) of long-term customers 
-- differ from those of new customers? What insights can these patterns provide about customer loyalty and retention strategies?
WITH Customerinsights AS (
SELECT c.customer_id, COUNT(i.invoice_id) AS purchase_frequency, SUM(il.quantity) AS total_items_purchased,
SUM(i.total) AS total_spent, AVG(i.total) AS avg_order_value,
DATEDIFF(MAX(i.invoice_date), MIN(i.invoice_date)) AS customer_tenure_days
FROM customer c 
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
GROUP BY c.customer_id),

Customersegment AS (
SELECT customer_id, purchase_frequency, total_items_purchased, total_spent, avg_order_value, customer_tenure_days,
CASE WHEN customer_tenure_days >= 365 THEN 'Long-Term' ELSE 'New'
END AS customer_segment
FROM Customerinsights)

SELECT customer_segment, ROUND(AVG(purchase_frequency),2) AS avg_purchase_frequency,
ROUND(AVG(total_items_purchased),2) AS avg_basket_size, ROUND(AVG(total_spent),2) AS avg_spending_amount,
ROUND(AVG(avg_order_value),2) AS avg_order_value
FROM Customersegment
GROUP BY customer_segment;
-- ---------------------------------------------------------------------------------------------------------------------------------

-- Q4. Product Affinity Analysis: Which music genres, artists, or albums are frequently purchased together by customers? 
-- How can this information guide product recommendations and cross-selling initiatives?
-- Ans. Analyze Genre Affinities
SELECT g1.name AS genre_1, g2.name AS genre_2, COUNT(*) AS purchase_count
FROM invoice i
JOIN invoice_line il ON i.invoice_id = il.invoice_id
JOIN track t ON il.track_id = t.track_id
JOIN genre g1 ON t.genre_id = g1.genre_id
JOIN invoice_line il2 ON i.invoice_id = il2.invoice_id
JOIN track t2 ON il2.track_id = t2.track_id
JOIN genre g2 ON t2.genre_id = g2.genre_id
WHERE g1.genre_id != g2.genre_id
GROUP BY g1.name, g2.name
ORDER BY purchase_count DESC
LIMIT 5;

-- Analyze Artist
SELECT a.name AS artist_1, a2.name AS artist_2, COUNT(*) AS purchase_count
FROM invoice_line il
JOIN track t ON il.track_id = t.track_id
JOIN album al ON t.album_id = al.album_id
JOIN artist a ON al.artist_id = a.artist_id
JOIN invoice_line il2 ON il.invoice_id = il2.invoice_id
JOIN track t2 ON il2.track_id = t2.track_id
JOIN album al2 ON t2.album_id = al2.album_id
JOIN artist a2 ON al2.artist_id = a2.artist_id
WHERE a.artist_id != a2.artist_id  
GROUP BY a.name, a2.name
ORDER BY purchase_count DESC
LIMIT 5;

-- Analyze Album Affinities
SELECT al.title AS album_1, al2.title AS album_2, COUNT(*) AS purchase_count
FROM invoice_line il
JOIN track t ON il.track_id = t.track_id
JOIN album al ON t.album_id = al.album_id
JOIN invoice_line il2 ON il.invoice_id = il2.invoice_id
JOIN track t2 ON il2.track_id = t2.track_id
JOIN album al2 ON t2.album_id = al2.album_id
WHERE al.album_id != al2.album_id 
GROUP BY al.title, al2.title
ORDER BY purchase_count DESC
LIMIT 5;
-- ---------------------------------------------------------------------------------------------------------------------------------

-- Q5. Regional Market Analysis: Do customer purchasing behaviours and churn rates vary across different geographic regions or store locations? 
-- How might these correlate with local demographic or economic factors?
-- Ans.
WITH frequency AS (
SELECT billing_country, AVG(purchase_frequency) as avg_days_bw_purchase 
FROM (SELECT customer_id, billing_country, invoice_date, next_date, DATEDIFF(next_date,invoice_date) AS purchase_frequency 
FROM (SELECT *, LEAD(invoice_date) OVER(PARTITION BY customer_id) AS next_date FROM invoice
ORDER BY customer_id) a) b
GROUP BY billing_country),
basket_size AS ( 
SELECT billing_country, ROUND(AVG(basket_size),2) AS avg_basket_size 
FROM (SELECT customer_id, billing_country, i.invoice_id, COUNT(invoice_line_id) AS basket_size FROM invoice i 
JOIN invoice_line i1 ON i.invoice_id=i1.invoice_id
GROUP BY customer_id, billing_country, invoice_id) a
GROUP BY billing_country),
spending AS(
SELECT billing_country, SUM(total) AS total_spent FROM invoice
GROUP BY billing_country),
last_purchase as ( 
SELECT customer_id, billing_country, MAX(DATE(invoice_date)) AS last_purchase_date FROM invoice
GROUP BY customer_id,billing_country
ORDER BY customer_id),
active_or_inactive as (
SELECT customer_id, last_purchase_date, billing_country, CASE WHEN last_purchase_date > DATE_SUB('2020-12-31',INTERVAL 6 MONTH) THEN 'Active Customer'
WHEN last_purchase_date < DATE_SUB('2020-12-31',INTERVAL 6 MONTH) THEN 'Churned Customer' END AS customer_status FROM last_purchase),
churned_count AS (
SELECT billing_country, customer_status, COUNT(customer_id) number_of_customers FROM active_or_inactive
GROUP BY billing_country, customer_status),
churn_rate  as (
SELECT billing_country, ROUND((SUM(CASE WHEN customer_status='Churned Customer' THEN number_of_customers ELSE 0 END)/SUM(number_of_customers))*100,2) AS churn_rate FROM churned_count
GROUP BY billing_country
ORDER BY billing_country)

SELECT s.billing_country, ROUND(avg_days_bw_purchase,0) AS purchase_frequency, total_spent, avg_basket_size, churn_rate FROM spending s 
JOIN basket_size b ON s.billing_country=b.billing_country
JOIN frequency f ON s.billing_country=f.billing_country
JOIN churn_rate c ON s.billing_country=c.billing_country
ORDER BY billing_country;
-- ---------------------------------------------------------------------------------------------------------------------------------

-- Q6. Customer Risk Profiling: Based on customer profiles (age, gender, location, purchase history), which customer 
-- segments are more likely to churn or pose a higher risk of reduced spending? What factors contribute to this risk?
-- Ans. 
WITH Customer_Segments AS (
SELECT c.customer_id, c.city, c.state, c.country, COUNT(i.invoice_id) AS purchase_count, SUM(i.total) AS total_spending,
DATEDIFF(CURDATE(), MAX(i.invoice_date)) AS days_since_last_purchase
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
WHERE c.state != 'Not Mentioned'
GROUP BY c.customer_id, c.city, c.state, c.country),
Risk_Profiles AS (
SELECT cs.customer_id, cs.city, cs.country, cs.purchase_count, cs.total_spending, cs.days_since_last_purchase,
CASE WHEN cs.days_since_last_purchase > 365 THEN 'High Risk' WHEN cs.days_since_last_purchase BETWEEN 180 AND 365 THEN 'Moderate Risk'
ELSE 'Low Risk' END AS churn_risk
FROM Customer_Segments cs)
SELECT churn_risk, COUNT(customer_id) AS customer_count, ROUND(AVG(total_spending),2) AS avg_spending, ROUND(AVG(purchase_count),2) AS avg_purchase_count
FROM Risk_Profiles
GROUP BY churn_risk
ORDER BY FIELD(churn_risk, 'High Risk', 'Moderate Risk', 'Low Risk');
-- ---------------------------------------------------------------------------------------------------------------------------------

-- Q7. Customer Lifetime Value Modelling: How can you leverage customer data (tenure, purchase history, engagement) to predict the 
-- lifetime value of different customer segments? This could inform targeted marketing and loyalty program strategies. 
-- Can you observe any common characteristics or purchase patterns among customers who have stopped purchasing?
-- Ans. 
WITH last_purchase AS (
SELECT customer_id, billing_country, max(DATE(invoice_date)) AS last_purchase_date FROM invoice
GROUP BY customer_id,billing_country
ORDER BY customer_id),
active_or_inactive AS (
SELECT customer_id, last_purchase_date, billing_country, CASE WHEN last_purchase_date > DATE_SUB('2020-12-31', INTERVAL 6 MONTH) THEN 'Active Customer'
WHEN last_purchase_date < DATE_SUB('2020-12-31', INTERVAL 6 MONTH) THEN 'Churned Customer' END AS status FROM last_purchase),
churned_cust AS (
SELECT customer_id FROM active_or_inactive
WHERE STATUS = 'Churned Customer'),
active_cust AS (
SELECT customer_id FROM active_or_inactive
WHERE status = 'Active Customer'),
frequency AS (
SELECT customer_id, AVG(purchase_frequency) AS avg_days_bw_purchase 
FROM (SELECT customer_id, invoice_date, next_date, DATEDIFF(next_date, invoice_date) AS purchase_frequency 
FROM (SELECT *, LEAD(invoice_date) OVER(PARTITION BY customer_id) AS next_date FROM invoice
ORDER BY customer_id) a) b
GROUP BY customer_id),
avg_days AS (
SELECT 'Active Customer' AS status, ROUND(AVG(avg_days_bw_purchase),2) AS average_frequency FROM frequency
WHERE customer_id IN (SELECT * FROM active_cust)
UNION
SELECT 'Inactive Customer' as status, ROUND(AVG(avg_days_bw_purchase),2) AS average_frequency FROM frequency
WHERE customer_id IN (SELECT * FROM churned_cust)),
inactive_purchase AS (
SELECT * FROM invoice_line 
WHERE invoice_id IN (SELECT invoice_id FROM invoice
WHERE customer_id IN (SELECT customer_id FROM churned_cust))),
inactivity AS (
SELECT ip.track_id, invoice_line_id, genre_id, album_id FROM inactive_purchase ip 
JOIN track t on ip.track_id=t.track_id),
genrestat AS (
SELECT genre_id, COUNT(invoice_line_id) genre_sale FROM inactivity
GROUP BY genre_id
ORDER BY genre_sale DESC)

SELECT gg.name AS Genre, genre_sale FROM genrestat g 
JOIN genre gg ON g.genre_id=gg.genre_id
ORDER BY genre_sale DESC;

-- frequency of inactive customers

WITH last_purchase AS (
SELECT customer_id, billing_country, MAX(DATE(invoice_date)) AS last_purchase_date FROM invoice
GROUP BY customer_id, billing_country
ORDER BY customer_id),
active_or_inactive AS (
SELECT customer_id, last_purchase_date, billing_country, CASE WHEN last_purchase_date > DATE_SUB('2020-12-31', INTERVAL 6 MONTH) THEN 'Active Customer'
WHEN last_purchase_date < DATE_SUB('2020-12-31', INTERVAL 6 MONTH) THEN 'Churned Customer' END AS status FROM last_purchase),
churned_cust AS (
SELECT customer_id FROM active_or_inactive
where status='Churned Customer'),
active_cust AS ( 
SELECT customer_id FROM active_or_inactive
WHERE STATUS='Active Customer'),
frequency  AS (
SELECT customer_id, AVG(purchase_frequency) AS avg_days_bw_purchase 
FROM (SELECT customer_id, invoice_date, next_date, DATEDIFF(next_date, invoice_date) AS purchase_frequency 
FROM (SELECT *,LEAD(invoice_date) OVER(PARTITION BY customer_id) AS next_date FROM invoice
ORDER BY customer_id) a) b
GROUP BY customer_id),
avg_days AS (
SELECT 'Active Customer' AS status, ROUND(AVG(avg_days_bw_purchase),2) AS average_frequency FROM frequency
WHERE customer_id IN (SELECT * FROM active_cust)
UNION
SELECT 'Inactive Customer' AS status, ROUND(AVG(avg_days_bw_purchase),2) AS average_frequency FROM frequency
WHERE customer_id IN (SELECT * FROM churned_cust))

SELECT * FROM avg_days;
-- ---------------------------------------------------------------------------------------------------------------------------------

-- Q11. Chinook is interested in understanding the purchasing behaviour of customers based on their geographical location. 
-- They want to know the average total amount spent by customers from each country, along with the number of customers and 
-- the average number of tracks purchased per customer. Write an SQL query to provide this information.
-- Ans.
WITH Customer_Purchases AS (
SELECT country, c.customer_id, SUM(i.total) AS total_spent, COUNT(il.track_id) AS total_tracks
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
GROUP BY country, c.customer_id)

SELECT country, COUNT(customer_id) AS number_of_customers, ROUND(AVG(total_spent),2) AS avg_total_spent,
ROUND(AVG(total_tracks),2) AS avg_tracks_purchased_per_customer
FROM Customer_Purchases
GROUP BY country
ORDER BY avg_total_spent DESC;

-- -----------------------------------------------------THAK YOU--------------------------------------------------------------------













