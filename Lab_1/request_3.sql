-- Минимальная, средняя (округлена до 2 знаков после запятой)
-- и максимальная стоимость билета для каждого рейса

SELECT DISTINCT	flight_id,
		MIN(amount) OVER (PARTITION BY flight_id),
		ROUND(AVG(amount) OVER (PARTITION BY flight_id), 2),
		MAX(amount) OVER (PARTITION BY flight_id)
FROM ticket_flights
ORDER BY flight_id;