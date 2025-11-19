-- Студенты, поступившие в определенном году

SELECT
	s.student_surname || ' ' || s.student_name || ' ' || s.student_patronymic AS full_name,
	s.group_number,
	s.date_of_entry
FROM student AS s
WHERE EXTRACT(YEAR FROM s.date_of_entry) = '2023';