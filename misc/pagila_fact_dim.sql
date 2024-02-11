select  f.film_id, f.title, sum(p.amount) as gross
from film f
         join inventory i on f.film_id = i.film_id
         join rental r on i.inventory_id = r.inventory_id
         join payment p on r.rental_id = p.rental_id
group by f.film_id
order by gross desc;

select c.city_id, c.city, sum(p.amount) as revenue
from city c
         join address a on c.city_id = a.city_id
         join customer cu on a.address_id = cu.address_id
         join payment p on cu.customer_id = p.customer_id
group by c.city, c.city_id
order by revenue desc;

select f.title, p.amount, cu.customer_id, ci.city, extract(month from p.payment_date) as month
from payment p
    join rental r on r.rental_id = p.rental_id
    join inventory i on i.inventory_id = r.inventory_id
    join film f on f.film_id = i.film_id
    join customer cu on p.customer_id = cu.customer_id
    join address a on cu.address_id = a.address_id
    join city ci on a.city_id = ci.city_id
order by p.payment_date;


select f.title, ci.city, extract(month from p.payment_date) as month, sum(p.amount) as revenue
from payment p
    join rental r on r.rental_id = p.rental_id
    join inventory i on i.inventory_id = r.inventory_id
    join film f on f.film_id = i.film_id
    join customer cu on p.customer_id = cu.customer_id
    join address a on cu.address_id = a.address_id
    join city ci on a.city_id = ci.city_id
group by (f.title, ci.city, month)
order by month, revenue desc;

CREATE TABLE dimDate
(
    date_key SERIAL PRIMARY KEY,
    date DATE NOT NULL,
    year SMALLINT NOT NULL ,
    quarter SMALLINT NOT NULL ,
    month SMALLINT NOT NULL ,
    day SMALLINT NOT NULL ,
    week SMALLINT NOT NULL ,
    is_weekend BOOLEAN
);

CREATE TABLE dimCustomer
(
    customer_key SERIAL PRIMARY KEY,
    customer_id SMALLINT NOT NULL,
    first_name VARCHAR(45) NOT NULL,
    last_name VARCHAR(45) NOT NULL,
    email VARCHAR(50),
    address VARCHAR(50) NOT NULL,
    address2 VARCHAR(50),
    district VARCHAR(20) NOT NULL,
    city VARCHAR(50) NOT NULL,
    country VARCHAR(50) NOT NULL,
    postal_code VARCHAR(10),
    phone VARCHAR(20) NOT NULL,
    active BOOLEAN NOT NULL,
    create_date TIMESTAMP NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL
);

CREATE TABLE dimMovie (
                          movie_key SERIAL PRIMARY KEY,
                          film_id SMALLINT NOT NULL,
                          title VARCHAR(255) NOT NULL,
                          description TEXT,
                          release_year YEAR,
                          language VARCHAR(20) NOT NULL,
                          original_language VARCHAR(20),
                          rental_duration SMALLINT NOT NULL,
                          length SMALLINT NOT NULL,
                          rating VARCHAR(5) NOT NULL,
                          special_features TEXT,
                          create_date TIMESTAMP NOT NULL,
                          start_date DATE NOT NULL,
                          end_date DATE NOT NULL
);

CREATE TABLE dimStore
(
    store_key SERIAL PRIMARY KEY,
    store_id SMALLINT NOT NULL,
    manager_staff_id SMALLINT NOT NULL,
    address VARCHAR(50) NOT NULL,
    address2 VARCHAR(50),
    district VARCHAR(20) NOT NULL,
    city VARCHAR(50) NOT NULL,
    country VARCHAR(50) NOT NULL,
    postal_code VARCHAR(10),
    manager_first_name VARCHAR(45) NOT NULL,
    manager_last_name VARCHAR(45) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    create_date TIMESTAMP NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL
);

CREATE TABLE factSales
(
    sales_key SERIAL PRIMARY KEY,
    date_key INTEGER NOT NULL,
    customer_key INTEGER NOT NULL,
    movie_key INTEGER NOT NULL,
    store_key INTEGER NOT NULL,
    sales_amount NUMERIC NOT NULL
);

------ Insert data into the dimension and fact tables
INSERT INTO dimDate (date_key, date, year, quarter, month, day, week, is_weekend)
SELECT DISTINCT(TO_CHAR(payment_date :: DATE, 'YYYYMMDD')::INTEGER) AS date_key,
               payment_date :: DATE as date,
                EXTRACT(YEAR FROM payment_date) AS year,
                EXTRACT(QUARTER FROM payment_date) AS quarter,
                EXTRACT(MONTH FROM payment_date) AS month,
                EXTRACT(DAY FROM payment_date) AS day,
                EXTRACT(WEEK FROM payment_date) AS week,
                CASE WHEN EXTRACT(ISODOW FROM payment_date) IN (6, 7) THEN TRUE ELSE FALSE END AS is_weekend
FROM payment;

INSERT INTO dimCustomer (customer_key, customer_id, first_name, last_name, email, address,
                         address2, district, city,
                         country, postal_code, phone, active, create_date, start_date, end_date)
SELECT c.customer_id AS customer_key,
       c.customer_id,
       c.first_name,
       c.last_name,
       c.email,
       a.address,
       a.address2,
       a.district,
       ci.city,
       co.country,
       a.postal_code,
       a.phone,
       CAST(c.active AS BOOLEAN) as active,
       c.create_date,
       now() AS start_date,
       now() AS end_date
FROM customer c
         JOIN address a ON c.address_id = a.address_id
         JOIN city ci ON a.city_id = ci.city_id
         JOIN country co ON ci.country_id = co.country_id;

INSERT INTO dimMovie (movie_key, film_id, title, description, release_year, language, original_language,
                      rental_duration, length, rating, special_features, create_date, start_date, end_date)
SELECT f.film_id AS movie_key, f.film_id, f.title, f.description, f.release_year, l.name AS language,
       ol.name AS original_language, f.rental_duration, f.length, f.rating, f.special_features, f.last_update AS create_date,
       now() AS start_date, now() AS end_date
FROM film f
    JOIN language l ON f.language_id = l.language_id
    LEFT JOIN language ol ON f.original_language_id = ol.language_id;

INSERT INTO dimStore (store_key, store_id, manager_staff_id, address, address2,
                      district, city, country, postal_code,
                      manager_first_name, manager_last_name, phone, create_date, start_date, end_date)
SELECT s.store_id AS store_key, s.store_id, s.manager_staff_id, a.address, a.address2,
       a.district, ci.city, co.country,
       a.postal_code, st.first_name AS manager_first_name,
       st.last_name AS manager_last_name, a.phone, s.last_update AS create_date,
       now() AS start_date, now() AS end_date
FROM store s
         JOIN staff st ON s.manager_staff_id = st.staff_id
         JOIN address a ON s.address_id = a.address_id
         JOIN city ci ON a.city_id = ci.city_id
         JOIN country co ON ci.country_id = co.country_id;

INSERT INTO factSales (date_key, customer_key, movie_key, store_key, sales_amount)
SELECT
    TO_CHAR(payment_date :: DATE, 'YYYYMMDD')::INTEGER AS date_key,
        p.customer_id as customer_key, i.film_id AS movie_key, i.store_id AS store_key,
    p.amount AS sales_amount
FROM payment p
         JOIN rental r ON p.rental_id = r.rental_id
         JOIN inventory i ON r.inventory_id = i.inventory_id;

select factSales.movie_key, factSales.date_key, factSales.customer_key, factSales.sales_amount
from factSales;


select dimMovie.title, dimDate.month, dimCustomer.city, sum(factSales.sales_amount) as revenue
from factSales
         join dimMovie on factSales.movie_key = dimMovie.movie_key
         join dimDate on factSales.date_key = dimDate.date_key
         join dimCustomer on factSales.customer_key = dimCustomer.customer_key
group by (dimMovie.title, dimDate.month, dimCustomer.city)
order by dimDate.month, revenue desc;