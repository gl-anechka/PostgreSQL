-- Запрос к нескольким связанным таблицам, содержащий фильтрацию по нескольким полям
-- Получить план выполнения запроса без использования индексов.
-- Получить статистику (IO и Time) выполнения запроса без использования индексов.

CREATE INDEX IF NOT EXISTS idx_fact_performance_covering 
ON fact_student_performance (date_id, student_id, cancelled)
INCLUDE (course_id, teacher_id, attendance)
WHERE cancelled = false;

CREATE INDEX IF NOT EXISTS idx_dim_date_academic_year 
ON dim_date (academic_year, date_id);

CREATE INDEX IF NOT EXISTS idx_dim_student_status
ON dim_student (study_status, student_id)
WHERE study_status = 'active';

CREATE INDEX IF NOT EXISTS idx_dim_course_covering 
ON dim_course (course_id)
INCLUDE (course_title);

CREATE INDEX IF NOT EXISTS idx_dim_teacher_covering 
ON dim_teacher (teacher_id)
INCLUDE (teacher_surname, teacher_name, teacher_patronymic);


EXPLAIN (ANALYZE, BUFFERS)
    WITH filtered_dates AS (
        SELECT date_id
        FROM dim_date
        WHERE academic_year = '2024/2025'
    ),
    filtered_students AS (
        SELECT student_id
        FROM dim_student
        WHERE study_status = 'active'
    ),
    filtered_f AS (
        SELECT
            f.course_id,
            f.teacher_id,
            f.attendance,
            f.date_id
        FROM fact_student_performance f
        WHERE
            f.cancelled = FALSE
            AND f.date_id IN (SELECT date_id FROM filtered_dates)
            AND f.student_id IN (SELECT student_id FROM filtered_students)
    ),
    attendance_agg AS (
        SELECT
            course_id,
            teacher_id,
            SUM(CASE WHEN attendance THEN 1 ELSE 0 END)::NUMERIC AS attended_count,
            COUNT(*)::NUMERIC AS total_count,
            MIN(date_id) AS any_date_id
        FROM filtered_f
        GROUP BY course_id, teacher_id
    )
    SELECT 
        c.course_id,
        c.course_title,
        t.teacher_surname,
        t.teacher_name,
        t.teacher_patronymic,
        ROUND(a.attended_count / NULLIF(a.total_count, 0), 2) AS attendance_rate,
        d.academic_year
    FROM attendance_agg a
    JOIN dim_course c ON c.course_id = a.course_id
    JOIN dim_teacher t ON t.teacher_id = a.teacher_id
    JOIN dim_date d ON d.date_id = a.any_date_id
    ORDER BY attendance_rate DESC
    LIMIT 10;