-- Список аэропортов (с сокращениями) вылета по городам

SELECT DISTINCT airports.city, airports.airport_name || ' (' || airport_code || ')' AS new_name
FROM airports
JOIN flights ON airports.airport_code = flights.departure_airport
ORDER BY airports.city, new_name;