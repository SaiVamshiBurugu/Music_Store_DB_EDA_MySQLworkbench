-- 01. Who is the senior most employee based on job title? 

SELECT last_name,first_name,e.title FROM employee as e
JOIN (select title,MIN(hire_date) as min_hire_date FROM employee
	  GROUP BY title) as ge
ON e.title = ge.title
WHERE e.hire_date = ge.min_hire_date;


-- Using Window Function (Rank or we can use Row_number as well)
SELECT last_name, first_name, title, hire_date
FROM (
    SELECT 
        last_name,
        first_name,
        title,
        hire_date,
        RANK() OVER (PARTITION BY title ORDER BY hire_date ASC) AS r
    FROM employee
) AS ranked_employees
WHERE r = 1;


-- 02. Which countries have the most Invoices?

SELECT billing_country,COUNT(invoice_id) AS invoice_count FROM INVOICE
GROUP BY billing_country
ORDER BY invoice_count DESC
LIMIT 3;

-- 03. What are the top 3 values of total invoice?

SELECT total FROM INVOICE
ORDER BY total DESC
LIMIT 3;

-- 04. Which city has the best customers? - We would like to throw a promotional Music Festival in the city we made the most money. 
	-- Write a query that returns one city that has the highest sum of invoice totals. 
	-- Return both the city name & sum of all invoice totals
    
SELECT billing_country,SUM(total) AS total_sale FROM invoice
GROUP BY billing_country
LIMIT 1;

-- 05. Who is the best customer? - The customer who has spent the most money will be declared the best customer. 
	-- Write a query that returns the person who has spent the most money
    
    
SELECT c.first_name,c.last_name,i.customer_id,i.total_sale FROM (SELECT customer_id,SUM(total) AS total_sale FROM invoice
									GROUP BY customer_id) as i
JOIN customer as c
ON i.customer_id = c.customer_id
ORDER BY i.total_sale DESC
LIMIT 1;

-- 06. Write a query to return the email, first name, last name, & Genre of all Rock Music listeners. 
	-- Return your list ordered alphabetically by email starting with A
    
SELECT c.first_name,c.last_name,c.email,g.name FROM customer AS c
JOIN invoice AS i
ON c.customer_id = i.customer_id
JOIN invoiceline AS il
ON i.invoice_id = il.invoice_id
JOIN track AS t
ON il.track_id = t.track_id
JOIN genre AS g
ON t.genre_id = g.genre_id
WHERE g.name = "rock" and c.email LIKE 'a%'
GROUP BY c.email, c.first_name, c.last_name, g.name
ORDER BY email;
    
-- 07. Let's invite the artists who have written the most rock music in our dataset. 
	-- Write a query that returns the Artist name and total track count of the top 10 rock bands 
    
SELECT  a.name,COUNT(t.track_id) AS total_no_of_tracks FROM artist AS a
JOIN album AS al
ON a.artist_id = al.artist_id
JOIN track AS t
ON al.album_id = t.album_id
JOIN genre AS g
ON t.genre_id = g.genre_id
WHERE g.name = 'rock'
GROUP BY a.artist_id
ORDER BY total_no_of_tracks DESC
LIMIT 10;

-- 08. Return all the track names that have a song length longer than the average song length.- 
	-- Return the Name and Milliseconds for each track. Order by the song length, with the longest songs listed first
    

SELECT name,milliseconds FROM track
WHERE milliseconds >  (SELECT AVG(milliseconds) FROM track)
ORDER BY milliseconds DESC
LIMIT 10;
  
  
-- 09. Find how much amount is spent by each customer on artists? 
	-- Write a query to return customer name, artist name and total spent 
    
SELECT c.first_name,c.last_name,ar.name,SUM(il.unit_price*il.quantity) amount_spent FROM customer AS c
JOIN invoice AS i
ON c.customer_id = i.customer_id
JOIN invoiceline AS il
ON i.invoice_id = il.invoice_id
JOIN track AS t
ON il.track_id = t.track_id
JOIN album AS al
ON t.album_id = al.album_id
JOIN artist as ar
ON al.artist_id = ar.artist_id
GROUP BY ar.name,c.first_name,c.last_name
ORDER BY c.first_name,amount_spent DESC;


-- Advance Filtering of Only top 3 spends of each customer using window function

SELECT first_name,last_name,name,amount_spent from (
SELECT first_name,last_name,name,amount_spent, ROW_NUMBER() OVER (
																PARTITION BY first_name,last_name
                                                                ORDER BY amount_spent DESC	) AS rn
FROM (
SELECT c.first_name,c.last_name,ar.name,SUM(il.unit_price*il.quantity) amount_spent FROM customer AS c
JOIN invoice AS i
ON c.customer_id = i.customer_id
JOIN invoiceline AS il
ON i.invoice_id = il.invoice_id
JOIN track AS t
ON il.track_id = t.track_id
JOIN album AS al
ON t.album_id = al.album_id
JOIN artist as ar
ON al.artist_id = ar.artist_id
GROUP BY ar.name,c.first_name,c.last_name
ORDER BY c.first_name,amount_spent DESC ) AS table_after_window ) AS ranked
WHERE rn <= 3
ORDER BY first_name,last_name,amount_spent DESC;


-- 10. We want to find out the most popular music Genre for each country. 
	-- We determine the most popular genre as the genre with the highest amount of purchases. 
	-- Write a query that returns each country along with the top Genre. For countries where the maximum number of purchases is shared, return all Genres
    
SELECT i.billing_country , g.name, SUM(il.unit_price*il.quantity) AS total_sale FROM invoice as i
JOIN invoiceline AS il
ON i.invoice_id = il.invoice_id
JOIN track AS t
ON il.track_id = t.track_id
JOIN genre AS g
ON t.genre_id = g.genre_id
GROUP BY i.billing_country,g.name
ORDER BY total_sale DESC,i.billing_country;


-- Finding which country has highest total sale

SELECT billing_country from invoice
GROUP BY billing_country
ORDER BY SUM(total) DESC
LIMIT 1;

-- Returning Only USA genres with total_sale.
SELECT i.billing_country , g.name, SUM(il.unit_price*il.quantity) AS total_sale FROM invoice as i
JOIN invoiceline AS il
ON i.invoice_id = il.invoice_id
JOIN track AS t
ON il.track_id = t.track_id
JOIN genre AS g
ON t.genre_id = g.genre_id
WHERE i.billing_country = (SELECT billing_country from invoice
							GROUP BY billing_country
							ORDER BY SUM(total) DESC
							LIMIT 1)
GROUP BY i.billing_country,g.name
ORDER BY i.billing_country,total_sale DESC;


-- 11. Write a query that determines the customer that has spent the most on music for each country. 
	-- Write a query that returns the country along with the top customer and how much they spent. 
	-- For countries where the top amount spent is shared, provide all customers who spent this amount.

SELECT billing_country ,first_name,last_name,total_sale FROM (
SELECT billing_country ,first_name,last_name,total_sale,ROW_NUMBER() OVER (PARTITION BY billing_country ORDER BY total_sale) as rn FROM (
SELECT i.billing_country ,c.first_name,c.last_name, SUM(i.total) AS total_sale FROM customer AS c
JOIN invoice as i
ON c.customer_id = i.customer_id
GROUP BY i.billing_country, c.first_name,c.last_name
ORDER BY i.billing_country,total_sale DESC ) as sale_with_rownumber) as final_table
WHERE rn = 1
ORDER BY total_sale DESC ;

-- Returnng all the customers from Czech Republic as it is the top country for highest sale

SELECT i.billing_country ,c.first_name,c.last_name, SUM(i.total) AS total_sale FROM customer AS c
JOIN invoice as i
ON c.customer_id = i.customer_id
GROUP BY i.billing_country, c.first_name,c.last_name
ORDER BY total_sale DESC,i.billing_country
LIMIT 2;
    