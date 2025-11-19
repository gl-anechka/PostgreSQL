-- Кол-во пассажиров эконом-класса, с самым дорогим билетом

WITH max_economy AS (
	SELECT MAX(tf.amount) AS max_amount
	FROM ticket_flights AS tf
	WHERE tf.fare_conditions = 'Economy'
)
SELECT COUNT(DISTINCT t.passenger_id)
FROM tickets AS t
JOIN ticket_flights AS tf ON tf.ticket_no = t.ticket_no
JOIN max_economy ON tf.amount = max_amount
WHERE tf.fare_conditions = 'Economy'