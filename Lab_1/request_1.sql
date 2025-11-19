-- Доход авиакомпании по сезонам

SELECT
	CASE
		WHEN EXTRACT(MONTH FROM book_date) IN (12, 1, 2) THEN 'Зима'
		WHEN EXTRACT(MONTH FROM book_date) IN (3, 4, 5) THEN 'Весна'
		WHEN EXTRACT(MONTH FROM book_date) IN (6, 7, 8) THEN 'Лето'
		WHEN EXTRACT(MONTH FROM book_date) IN (9, 10, 11) THEN 'Осень'
		ELSE 'Ошибка'
	END
	AS season,
	SUM(total_amount) AS total
FROM bookings
GROUP BY season;