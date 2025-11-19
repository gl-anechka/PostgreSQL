-- Удалить записи о студентах, закончивших учебу
DELETE FROM student
WHERE EXTRACT(YEAR FROM ending_date) < EXTRACT(YEAR FROM CURRENT_DATE);

-- Проверка обновления
SELECT
	id_student,
	date_of_entry,
	ending_date
FROM student;