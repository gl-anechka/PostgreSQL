-- Список преподавательского состава, утчен флаг "рабочий статус"

SELECT
	t.teacher_surname || ' ' || t.teacher_name || ' ' || t.teacher_patronymic AS full_name,
	COALESCE(a.title, '-') AS academic_deg,
	CASE j.title
		WHEN 'Заведующий кафедрой' THEN j.title || ' ' || LOWER(c.title)
		ELSE j.title || ' кафедры ' || LOWER(c.title)
	END AS job
FROM teacher AS t
JOIN job_desc AS j ON t.job = j.id_job
JOIN cafedra AS c ON c.id_caf = t.cafedra
LEFT JOIN academic_degree AS a ON a.id_degree = t.academic_degree
WHERE t.work_status = TRUE;


-- COALESCE(list) вернет первый не NULL аргумент списка