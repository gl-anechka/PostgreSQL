\connect university_analytic;


-- Создание пользователя
DROP OWNED BY test CASCADE;
DROP USER IF EXISTS test;
CREATE USER test WITH PASSWORD 'testpass';
GRANT CONNECT ON DATABASE university_analytic TO test;


-- Права доступа к таблицам
GRANT SELECT, UPDATE, INSERT ON TABLE dim_course TO test;
GRANT USAGE, SELECT, UPDATE ON SEQUENCE dim_course_course_id_seq TO test;

GRANT SELECT ON TABLE dim_student TO test;
GRANT UPDATE (phone, group_num, study_status) ON TABLE dim_student TO test;

GRANT SELECT ON TABLE dim_teacher TO test;
GRANT UPDATE (work_status) ON TABLE dim_teacher TO test;

GRANT SELECT ON TABLE dim_date TO test;
GRANT SELECT ON TABLE fact_student_performance TO test;


-- Представления (view)
-- данные об учащихся студентах
CREATE OR REPLACE VIEW active_student AS
SELECT
    student_id,
    student_surname,
    student_name,
    student_patronymic,
    phone,
    group_num,
    cafedra_name,
    study_status
FROM dim_student
WHERE study_status = 'active'
WITH CHECK OPTION;

-- посещаемость
DROP MATERIALIZED VIEW IF EXISTS group_attendance;
CREATE MATERIALIZED VIEW group_attendance AS
SELECT
    s.group_num,
    t.academic_year,
    t.month_number,
    COUNT(*) AS total_lessons,
    SUM(CASE WHEN f.attendance THEN 1 ELSE 0 END) AS attendance_count,
    ROUND(
        (SUM(CASE WHEN f.attendance THEN 1 ELSE 0 END) * 100.0 / COUNT(*))::NUMERIC, 
        2
    ) AS attendance_percent
FROM fact_student_performance AS f
JOIN dim_student AS s ON f.student_id = s.student_id
JOIN dim_date AS t ON f.date_id = t.date_id
WHERE f.cancelled = FALSE
GROUP BY s.group_num, t.academic_year, t.month_number
ORDER BY t.academic_year, t.month_number, s.group_num;

-- расписание
CREATE OR REPLACE VIEW cur_schedule AS
SELECT
	CASE d.day_of_week
		WHEN 1 THEN 'ПН'
		WHEN 2 THEN 'ВТ'
		WHEN 3 THEN 'СР'
		WHEN 4 THEN 'ЧТ'
		WHEN 5 THEN 'ПТ'
		WHEN 6 THEN 'СБ'
	END,
    f.time_begin,
    f.time_end,
    f.classroom,
    c.course_title,
    t.teacher_surname || ' ' || LEFT(t.teacher_name, 1) || '.' AS t_name,
    s.group_num,
    f.lesson_type
FROM fact_student_performance AS f
JOIN dim_course AS c ON f.course_id = c.course_id
JOIN dim_teacher AS t ON f.teacher_id = t.teacher_id
JOIN dim_student AS s ON f.student_id = s.student_id
JOIN dim_date AS d ON f.date_id = d.date_id
WHERE f.cancelled = FALSE AND d.day_of_week <> 0
ORDER BY d.day_of_week, f.time_begin;

GRANT SELECT ON group_attendance TO test;


-- Новая роль и права доступа
DROP OWNED BY new_role CASCADE;
DROP ROLE IF EXISTS new_role;
CREATE ROLE new_role;
GRANT SELECT ON active_student TO new_role;
GRANT UPDATE (phone, group_num, cafedra_name) ON active_student TO new_role;
GRANT new_role TO test;