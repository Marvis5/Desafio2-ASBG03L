#1

CREATE OR REPLACE VIEW vista_peliculas_info AS
SELECT
    f.film_id,
    f.title AS nombre_pelicula,
    GROUP_CONCAT(DISTINCT CONCAT(ac.first_name, ' ', ac.last_name) SEPARATOR ', ') AS actores,
    GROUP_CONCAT(DISTINCT c.name SEPARATOR ', ') AS categorias,
    CONCAT(ci.city, ', ', co.country) AS tienda_ubicacion
FROM film f
JOIN film_actor fa ON f.film_id = fa.film_id
JOIN actor ac ON fa.actor_id = ac.actor_id
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
JOIN inventory i ON i.film_id = f.film_id
JOIN store s ON i.store_id = s.store_id
JOIN address a ON s.address_id = a.address_id
JOIN city ci ON a.city_id = ci.city_id
JOIN country co ON ci.country_id = co.country_id
GROUP BY f.film_id, f.title, ci.city, co.country;

SELECT * FROM `vista_peliculas_info`

#2

CREATE OR REPLACE VIEW vista_ganancias_pelicula_tienda AS
SELECT
    s.store_id,
    f.film_id,
    f.title AS nombre_pelicula,
    CONCAT(ci.city, ', ', co.country) AS tienda_ubicacion,
    SUM(p.amount) AS total_ganancias
FROM payment p
JOIN rental r ON p.rental_id = r.rental_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
JOIN store s ON i.store_id = s.store_id
JOIN address a ON s.address_id = a.address_id
JOIN city ci ON a.city_id = ci.city_id
JOIN country co ON ci.country_id = co.country_id
GROUP BY s.store_id, f.film_id, f.title, ci.city, co.country;

SELECT * FROM `vista_ganancias_pelicula_tienda`

#3 

DELIMITER $$

CREATE PROCEDURE sp_generar_compra (
    IN p_film_id INT,
    IN p_customer_id INT,
    IN p_staff_id INT,
    OUT p_total_out DECIMAL(5,2)
)
BEGIN
    DECLARE v_inventory_id INT;
    DECLARE v_rental_id INT;
    DECLARE v_amount DECIMAL(5,2);
    DECLARE v_payment_date DATETIME;

    SELECT inventory_id
    INTO v_inventory_id
    FROM inventory
    WHERE film_id = p_film_id
    LIMIT 1;

    
    IF v_inventory_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No hay inventario disponible para esta película.';
    END IF;

   
    INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id)
    VALUES (NOW(), v_inventory_id, p_customer_id, NULL, p_staff_id);

    SET v_rental_id = LAST_INSERT_ID();

  
    SELECT rental_rate INTO v_amount
    FROM film
    WHERE film_id = p_film_id;

    SET v_payment_date = NOW();

    
    INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
    VALUES (p_customer_id, p_staff_id, v_rental_id, v_amount, v_payment_date);

  
    SET p_total_out = v_amount;
END$$

DELIMITER ;


SET @total_pago = 0;


CALL sp_generar_compra(7, 3, 1, @total_pago);

SELECT @total_pago AS total_pagado;
SELECT @id_compra AS id_compra;