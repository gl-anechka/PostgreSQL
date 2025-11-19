-- Доход авиакомпании по месяцам,
-- отсортирован по возрастанию номера месяца

SELECT	EXTRACT(MONTH from book_date) as month_of_year,
		SUM(total_amount) as total
FROM bookings 
GROUP BY month_of_year 
ORDER BY month_of_year ASC;