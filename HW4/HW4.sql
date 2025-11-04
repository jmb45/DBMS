-- TITLE PAGE

-- TITLE: DBMS HW4
-- Date: 10/4/2025
set SQL_SAFE_UPDATES=0; 
set FOREIGN_KEY_CHECKS=0; 

use homework_four; 
/*
###########################################################################
###########################################################################
First we need to declare all the primary keys. The code was being weird
so I declared all primary keys first, seperately.
*/
ALTER TABLE actor
ADD CONSTRAINT pk_actor PRIMARY KEY (actor_id);

ALTER TABLE address
ADD CONSTRAINT pk_address PRIMARY KEY (address_id);

ALTER TABLE category
ADD CONSTRAINT pk_category PRIMARY KEY (category_id);

ALTER TABLE city
ADD CONSTRAINT pk_city PRIMARY KEY (city_id);

ALTER TABLE country
ADD CONSTRAINT pk_country PRIMARY KEY (country_id);

ALTER TABLE customer
ADD CONSTRAINT pk_customer PRIMARY KEY (customer_id);

ALTER TABLE film
ADD CONSTRAINT pk_film PRIMARY KEY (film_id);

ALTER TABLE film_actor
ADD CONSTRAINT pk_film_actor PRIMARY KEY (actor_id, film_id);

ALTER TABLE film_category
ADD CONSTRAINT pk_film_category PRIMARY KEY (film_id, category_id);

ALTER TABLE inventory
ADD CONSTRAINT pk_inventory PRIMARY KEY (inventory_id);

ALTER TABLE language
ADD CONSTRAINT pk_language PRIMARY KEY (language_id);

ALTER TABLE payment
ADD CONSTRAINT pk_payment PRIMARY KEY (payment_id);

ALTER TABLE rental
ADD CONSTRAINT pk_rental PRIMARY KEY (rental_id);

ALTER TABLE staff
ADD CONSTRAINT pk_staff PRIMARY KEY (staff_id);

ALTER TABLE store
ADD CONSTRAINT pk_store PRIMARY KEY (store_id);


-- ######################################################################
-- ######################################################################

-- ######################################################################
-- Now we need to add all the other contraints now that the PK's are set.
-- We add foreign keys where necessary as well as restrict values.

ALTER TABLE address
ADD CONSTRAINT fk_address_city FOREIGN KEY (city_id) REFERENCES city(city_id);

ALTER TABLE category
modify column name varchar(50);
alter table category
ADD CONSTRAINT uq_category_name UNIQUE (name),
ADD CONSTRAINT chk_category_name CHECK (name IN (
    'Animation', 'Comedy', 'Family', 'Foreign', 'Sci-Fi', 'Travel', 
    'Children', 'Drama', 'Horror', 'Action', 'Classics', 'Games', 
    'New', 'Documentary', 'Sports', 'Music'
));

ALTER TABLE city
ADD CONSTRAINT fk_city_country FOREIGN KEY (country_id) REFERENCES country(country_id);

ALTER TABLE customer
ADD CONSTRAINT fk_customer_store FOREIGN KEY (store_id) REFERENCES store(store_id),
ADD CONSTRAINT fk_customer_address FOREIGN KEY (address_id) REFERENCES address(address_id),
ADD CONSTRAINT chk_customer_active CHECK (active IN (0,1));

ALTER TABLE film
ADD CONSTRAINT fk_film_language FOREIGN KEY (language_id) REFERENCES language(language_id),
ADD CONSTRAINT chk_film_rental_duration CHECK (rental_duration BETWEEN 2 AND 8),
ADD CONSTRAINT chk_film_rental_rate CHECK (rental_rate BETWEEN 0.99 AND 6.99),
ADD CONSTRAINT chk_film_length CHECK (length BETWEEN 30 AND 200),
ADD CONSTRAINT chk_film_replacement_cost CHECK (replacement_cost BETWEEN 5.00 AND 100.00),
ADD CONSTRAINT chk_film_special_features CHECK (
    special_features LIKE '%Behind the Scenes%' OR
    special_features LIKE '%Commentaries%' OR
    special_features LIKE '%Deleted Scenes%' OR
    special_features LIKE '%Trailers%'
),
ADD CONSTRAINT chk_film_rating CHECK (rating IN ('PG', 'G', 'NC-17', 'PG-13', 'R'));

ALTER TABLE film_actor
ADD CONSTRAINT fk_film_actor_actor FOREIGN KEY (actor_id) REFERENCES actor(actor_id),
ADD CONSTRAINT fk_film_actor_film FOREIGN KEY (film_id) REFERENCES film(film_id);

ALTER TABLE film_category
ADD CONSTRAINT fk_film_category_film FOREIGN KEY (film_id) REFERENCES film(film_id),
ADD CONSTRAINT fk_film_category_category FOREIGN KEY (category_id) REFERENCES category(category_id);

ALTER TABLE inventory
ADD CONSTRAINT fk_inventory_film FOREIGN KEY (film_id) REFERENCES film(film_id),
ADD CONSTRAINT fk_inventory_store FOREIGN KEY (store_id) REFERENCES store(store_id);

ALTER TABLE payment
ADD CONSTRAINT fk_payment_customer FOREIGN KEY (customer_id) REFERENCES customer(customer_id),
ADD CONSTRAINT fk_payment_staff FOREIGN KEY (staff_id) REFERENCES staff(staff_id),
ADD CONSTRAINT fk_payment_rental FOREIGN KEY (rental_id) REFERENCES rental(rental_id),
ADD CONSTRAINT chk_payment_amount CHECK (amount >= 0);

ALTER TABLE rental
ADD CONSTRAINT fk_rental_inventory FOREIGN KEY (inventory_id) REFERENCES inventory(inventory_id),
ADD CONSTRAINT fk_rental_customer FOREIGN KEY (customer_id) REFERENCES customer(customer_id),
ADD CONSTRAINT fk_rental_staff FOREIGN KEY (staff_id) REFERENCES staff(staff_id),
ADD CONSTRAINT uq_rental UNIQUE (rental_date, inventory_id, customer_id),
ADD CONSTRAINT chk_rental_dates CHECK (rental_date <= return_date);

ALTER TABLE staff
modify email VARCHAR (100);
ALTER TABLE staff
ADD CONSTRAINT fk_staff_address FOREIGN KEY (address_id) REFERENCES address(address_id),
ADD CONSTRAINT fk_staff_store FOREIGN KEY (store_id) REFERENCES store(store_id),
ADD CONSTRAINT uq_staff_email UNIQUE (email),
ADD CONSTRAINT chk_staff_active CHECK (active IN (0,1));

ALTER TABLE store
ADD CONSTRAINT fk_store_address FOREIGN KEY (address_id) REFERENCES address(address_id);
-- Query 1: List avg film length by category
/*
We start by selecting name and the average film length. From there,
We need to join from film -> category, then we simply group by category
and ordering by category will get us the categories in alphabetical order.
*/
select category.name, avg(film.length) as avg_length
from film
join film_category on film.film_id = film_category.film_id
join category on film_category.category_id = category.category_id
group by category.name
order by category.name;



/*
Query 2: Begin by selecting category name and use the function avg to
get the average length of films. We will start in the film table
then need to move from film -> film_category -> category. 
Finally, we will group by category since that is what the problem
says and we can order by the name without including anything else since 
it auto orders by ascending. Now this query is a little different - we need
the highest and lowest average length. One of the ways to do this is 
to make two seperate queries and make a union of them so that they display 
together, which is what I do. 
*/
(select category.name, avg(film.length) as avg_length
from film
join film_category on film.film_id = film_category.film_id
join category on film_category.category_id = category.category_id
group by category.name
order by avg_length
limit 1)

union all

(select category.name, avg(film.length) as avg_length
from film
join film_category on film.film_id = film_category.film_id
join category on film_category.category_id = category.category_id
group by category.name
order by avg_length desc
limit 1);

/*
Query 3: Which customers have rented action but not comedy or classic movies?
This query has a lot going on. First we want to select the customer's name,
since that is what the problem wants this to return. Next, we have to join
from customer -> rental -> inventory -> film -> film_category -> category
and we want to make sure the category is action, so we include that in the 
where clause. Next, we want to make sure that we are disallowing the comedy 
and classics, so we say 'not' then open a subquery and basically put
in the exact same query but we select classics and comedy, which will
disallow those categories from the main query.
*/

select distinct customer.first_name, customer.last_name
from customer
join rental on customer.customer_id = rental.customer_id
join inventory on rental.inventory_id = inventory.inventory_id
join film on inventory.film_id = film.film_id
join film_category on film.film_id = film_category.film_id
join category on film_category.category_id = category.category_id
where category.name like "%Action%"
and customer.customer_id not in (
select customer.customer_id 
from customer 
join rental on customer.customer_id = rental.customer_id
join inventory on rental.inventory_id = inventory.inventory_id
join film on inventory.film_id = film.film_id
join film_category on film.film_id = film_category.film_id
join category on film_category.category_id = category.category_id
where category.name like "%Comedy%" or category.name like "%Classic%"
);


/*
Query 4: Which actor has appeared in the most amount of English lang. films
First, we select the actor name, and we also want to select the count
of the language id, because when we are done culling out things
this will tell us the total number of english language films
the actor was in. Next, we have to join from actor -> film_actor 
-> film ->language, and include a where to make sure the language is 
english. Since we only want one actor we can just order by desc
and limit it to one.
*/
select actor.first_name, actor.last_name, count(language.language_id) as num
from actor
join film_actor on actor.actor_id = film_actor.actor_id
join film on film.film_id = film_actor.film_id
join language on film.language_id = language.language_id
where language.name = ("English") 
group by actor.actor_id, actor.first_name, actor.last_name
order by num desc
limit 1;

/*
Query 5: How many distinct movies were rented for 
exactly 10 days from the store where Mike works?
We solve this by only selecting the count of distinct film IDs, since
we want the movies to be unique. Next we join from inventory -> 
rental to staff and add a where to make sure that the staff is Mike.
We don't want this to be the only parameter though, so we add an and 
and make sure the difference between the retal and return is exactly 10 days.
*/
select count(distinct film.film_id) as distinct_movies
from film
join inventory on film.film_id = inventory.film_id
join rental on rental.inventory_id = inventory.inventory_id
join staff on staff.staff_id = rental.staff_id
where staff.first_name = ("Mike") AND
datediff(rental.return_date, rental.rental_date) = 10;

/*
Alphabetically list actors from the movie with the largest amount of actors
Query 6: First we select the actor first and last name. Next we join
to go from actor -> film_actor. Next we need to open a subquery to 
get the film with the largest amount of actors, and in the main query
we can list all the actors by name since we are only looking at actors 
from the largest film.
*/
select actor.first_name, actor.last_name
from actor 
join film_actor on actor.actor_id = film_actor.actor_id
where film_actor.film_id = (
    select film_actor.film_id
    from film_actor 
    group by film_actor.film_id
    order by count(film_actor.actor_id) desc
    limit 1
)
order by actor.last_name, actor.first_name;



