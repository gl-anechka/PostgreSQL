-- Посчитать самый длинный маршрут (по времени полета) с пересадками, вывести ФИО пассажира, время полета

WITH flight_times AS (
	SELECT flight_id, actual_departure, actual_arrival, actual_arrival - actual_departure
		AS f_time
	FROM flights
	WHERE actual_departure IS NOT NULL AND actual_arrival IS NOT NULL
), ticket_total_times AS (
    SELECT tf.ticket_no, SUM(ft.f_time) AS total_flight_time
    FROM ticket_flights AS tf
    JOIN flight_times AS ft ON tf.flight_id = ft.flight_id
    GROUP BY tf.ticket_no
), max_time AS (
    SELECT MAX(total_flight_time) AS max_flight_time FROM ticket_total_times
)
SELECT t.passenger_name, ttt.total_flight_time
FROM tickets AS t
JOIN ticket_total_times AS ttt ON t.ticket_no = ttt.ticket_no
JOIN max_time AS mt ON ttt.total_flight_time = mt.max_flight_time
ORDER BY t.passenger_name;