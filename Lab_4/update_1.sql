-- Добавление новой должности, если такой нет
INSERT INTO job_desc (title)
SELECT 'Профессор'
	WHERE NOT EXISTS (SELECT * FROM job_desc WHERE title = 'Профессор');

-- Обновление должности
UPDATE teacher 
SET job = (
    SELECT id_job FROM job_desc WHERE title = 'Профессор'
)
WHERE id_teacher = 10 AND work_status = TRUE;

-- Проверка обновления
SELECT 
    t.id_teacher,
	t.teacher_surname,
    t.teacher_name,
	t.teacher_patronymic,
    jd.title AS new_job
FROM teacher t
JOIN job_desc jd ON t.job = jd.id_job
WHERE t.id_teacher = 10;