-- TITLE PAGE
-- Author: Joseph Pepe
-- TITLE: DBMS HW3
-- Date: 10/21/2025

set SQL_SAFE_UPDATES=0; 
set FOREIGN_KEY_CHECKS=0; 

use homework_three; 

-- set contrains
-- contrains the primary key
alter table merchants
add constraint mer_pk primary key(mid);

alter table contain
add constraint con_fk foreign key(oid) references orders(oid)
on delete cascade
on update cascade,
add constraint con_fk2 foreign key (pid) references products(pid)
on delete cascade
on update cascade;

alter table customers
add constraint cust_pk primary key(cid);

alter table place
add constraint place_fk foreign key(cid) references customers(cid)
on delete cascade
on update cascade,
add constraint place_fk2 foreign key(oid) references orders(oid)
on delete cascade
on update cascade;


-- contrains the name of products to only certain works, as well as
-- contrains category and primary key
alter table products
add constraint produ_pk primary key(pid),
add constraint prod_name_const check
(name in ("Printer" , "Ethernet Adapter", "Desktop", "Hard Drive", "Laptop", "Network Card", "Router", "Monitor", "Super Drive")),
add constraint prod_cat check (category in ("Networking", "Computer", "Peripheral"));

-- contrains foreign key and sets reference, contrains other fk
-- adds contraint on sell_price and quantity that can be available
alter table sell
	add constraint sell_fk_mid foreign key(mid) references merchants(mid)
    on delete cascade
    on update cascade,
add constraint sell_fk foreign key(pid) references products(pid)
on delete cascade
on update cascade,
add constraint sell_price check (price between 0 and 100000),
add constraint quant_available check (quantity_available between 0 and 1000);

-- constrains shipping method and shipping cost
alter table orders
add constraint ord_pk primary key(oid),
add constraint ship_meth2 check (shipping_method in ("UPS", "FedEX", "USPS")),
add constraint ship_cost2 check (shipping_cost between 0 and 500);





/*
**********************************************************************************************************************************
**********************************************************************************************************************************
**********************************************************************************************************************************
*/


SELECT 
    products.name, merchants.name
FROM
    products
        JOIN
    sell ON products.pid = sell.pid
        JOIN
    merchants ON merchants.mid = sell.mid
WHERE
    sell.quantity_available = 0;
    


-- Query 2: List names and descriptions of products that are not sold.
/*
We will select the names and descriptions of products, and we need to join sell
to see if anything is sold, and we include a where clause because we want products
that aren"t sold, or null.
*/

SELECT 
    products.name, products.description
FROM
    products
        JOIN
    sell ON sell.pid = products.pid
WHERE
    sell.pid IS NULL;

-- Query 3:How many customers bought SATA drives but not any routers?
/*
We want to select customers and the number of orders that we will filter later. We join 
place -> orders -> contain -> products in order to be able to filter by the name where the name has Sata.
We will make a subquery in the and clause because we also want people who did not by routers, so we will
do a join from customers all the way over to products again and select people who bought routers. In the main
query, they won't be selected though because of the NOT.
*/
SELECT 
    customers.fullname, COUNT(orders.oid)
FROM
    customers
        INNER JOIN
    place ON customers.cid = place.cid
        INNER JOIN
    orders ON place.oid = orders.oid
        INNER JOIN
    contain ON orders.oid = contain.oid
        INNER JOIN
    products ON contain.pid = products.pid
WHERE
    products.name LIKE '%SATA%'
        AND customers.cid NOT IN (SELECT 
            customers.cid
        FROM
            customers
                INNER JOIN
            place ON customers.cid = place.cid
                JOIN
            orders ON place.oid = orders.oid
                JOIN
            contain ON orders.oid = contain.oid
                JOIN
            products ON contain.pid = products.pid
        WHERE
            products.name LIKE '%Router%')
GROUP BY customers.fullname;


-- Query 4: HP has a 20% sale on all its Networking products.
/*
This question was left up to interpretation. I chose to select product name and sell price, and display the items
at a 20% discount. In order to do this, I needed to go from products -> sell -> merchants, so I could filter
by 'HP' and 'Networking' to make sure I am only selecting what the problem wants. 
*/
SELECT 
    products.name, ROUND(sell.price * 0.8, 2)
FROM
    products
        JOIN
    sell ON products.pid = sell.pid
        JOIN
    merchants ON sell.mid = merchants.mid
WHERE
    merchants.name = 'HP'
        AND products.category = 'Networking';

-- Query 5:  What did Uriel Whitney order (make sure to at least retrieve product names and prices).
/*
First, I select the product name, and the min price. There is some tricky stuff going on in the sell table - multiple
merchants sell the same product. This can lead to redundancy in the results if you are not careful. So, I will assume
that Uriel bought the cheapest of each item. Next, I must join place -> contain -> products -> sell then group by product
name and fulter out all customers but Uriel Whitney.
*/

SELECT 
    products.name, MIN(sell.price) AS price
FROM
    customers
        JOIN
    place ON place.cid = customers.cid
        JOIN
    contain ON contain.oid = place.oid
        JOIN
    products ON products.pid = contain.pid
        JOIN
    sell ON sell.pid = products.pid
WHERE
    customers.fullname = 'Uriel Whitney'
GROUP BY products.name;



-- Query 6: List the annual total sales for each company (sort the results along the company and the year attributes).
/*
I select merchant name, the date (you can use the function year to have SQL order the datetimes into years), and summation of sell price.
I need to join customers to place to contain to products to sell to merchants. to get over to merchant names. Now this problem
is a little tricky because of the way the schema is - the answer may not be 100% accurate. Becuase of the way contains is, it 
is not possible to recall which merchant fulfilled which order - therefore it is not possible to recall exact prices because
different merchants sell the same items at different prices. So in this table, when I am joining sell, I do so with a subquery
that bases it on a consistent price. Finally, I group by name and year. 
*/
SELECT 
    m.name,
    YEAR(pl.order_date) AS eachYear,
    ROUND(SUM(s.price), 2) AS revenue
FROM
    customers c
        JOIN
    place pl ON c.cid = pl.cid
        JOIN
    contain ct ON pl.oid = ct.oid
        JOIN
    products p ON ct.pid = p.pid
        JOIN
    (SELECT 
        sell.price, sell.mid, sell.pid
    FROM
        sell
    JOIN (SELECT 
        pid, MIN(price) AS minPrice
    FROM
        sell
    GROUP BY pid) table2 ON sell.pid = table2.pid
        AND sell.price = table2.minPrice) s ON p.pid = s.pid
        JOIN
    merchants m ON m.mid = s.mid
GROUP BY m.name , eachYear
ORDER BY eachYear , m.name;

 
    
-- Query 7: Which company had the highest annual revenue and in what year?
/*
This query is almost exactly the same as the previous one. Again, we select the name of the merchant, year, and the revenue.
We need to go from customer to merchants so we do customers -> place -> contain -> products -> sell -> merchants. Similar to the
last problem, we have this weird issue with the schema where we cannot tell who fulfilled what, so I will make the same assumption. 
When I am joining sell, I wil do so with a subquery selecting only the min price so that we do not have loads of redundant values
when joining the tables. The main difference is that we are ordering by revenue instead of company and year and then limiting it to 1. 
*/
SELECT 
    m.name,
    YEAR(pl.order_date) AS eachYear,
    ROUND(SUM(s.price), 2) AS revenue
FROM
    customers c
        JOIN
    place pl ON c.cid = pl.cid
        JOIN
    contain ct ON pl.oid = ct.oid
        JOIN
    products p ON ct.pid = p.pid
        JOIN
    (SELECT 
        sell.price, sell.mid, sell.pid
    FROM
        sell
    JOIN (SELECT 
        pid, MIN(price) AS minPrice
    FROM
        sell
    GROUP BY pid) table2 ON sell.pid = table2.pid
        AND sell.price = table2.minPrice) s ON p.pid = s.pid
        JOIN
    merchants m ON m.mid = s.mid
GROUP BY m.name , eachYear
ORDER BY revenue DESC
LIMIT 1;




-- Query8: On average, what was the cheapest shipping method used ever?
/*
This query is relatively simple. We can select the shipping methods and get the average of the shipping cost, 
then group by method and order it in ascending order so the cheapest is displayed. 
*/
SELECT 
    orders.shipping_method,
    ROUND(AVG(shipping_cost), 2) AS shipcost
FROM
    orders
GROUP BY orders.shipping_method
ORDER BY shipcost ASC
LIMIT 1;

-- Query 9: What is the best sold ($) category for each company?
/*
First I will select merchant name, product category, and the revenue. I need to go from sell -> products -> merchants in order
to include the merchant name. While joining I am able to get the product category and I can calculate price from the sell table. 
Finally, I just group my merchant name and category and order it by sales.
*/
SELECT 
    m.name AS merchant_name,
    p.category,
    ROUND(SUM(s.price), 2) AS total_sales
FROM
    sell s
        JOIN
    products p ON s.pid = p.pid
        JOIN
    merchants m ON s.mid = m.mid
GROUP BY m.name , p.category
ORDER BY total_sales DESC;



-- Query 9: For each company find out which customers have spent the most and the least amounts.
/*
I start by selecting the name, customer, the amount the customer spent, and their rank. Next, we open a subquery. It was a little difficult 
to figure out how to rank by how much they spent - it was hard to get the number to display for both highest and lowest at once. Therefore,
I did some researching and we are able to use a subquery and this RANK() function. Here is what I used to learn about it:
https://www.geeksforgeeks.org/sql/rank-function-in-sql-server/
The inner subquery is basically just getting the total spending per customer per merchant, and that is done by selecting
the customer names, getting the total amount that they spent, and assigning a rank to them. We need to just join all of the
tables to be able to connect customer to merchants. The outer query is quite simple, it just filters to make sure that only
the highest and lowest are displayed, and since we are displaying the merchants, the query will return the highest and lowest 
customer per merchant. 

*/
select merchant_name, customer_name, total_spent, spend_rank
from (
    select
        m.name AS merchant_name,
        c.fullname AS customer_name,
        round(SUM(s.price),2) AS total_spent,
        RANK() OVER (PARTITION BY m.name ORDER BY SUM(s.price) DESC) AS spend_rank,
        RANK() OVER (PARTITION BY m.name ORDER BY SUM(s.price) ASC) AS low_rank
    from customers c
    join place pl ON c.cid = pl.cid
    join contain co ON pl.oid = co.oid
    join sell s ON co.pid = s.pid
    join merchants m ON s.mid = m.mid
    group by m.name, c.fullname
) ranked
where spend_rank = 1 OR low_rank = 1;
