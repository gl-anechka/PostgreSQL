-- Запрос к нескольким связанным таблицам, содержащий фильтрацию по нескольким полям
-- Получить план выполнения запроса без использования индексов.
-- Получить статистику (IO и Time) выполнения запроса без использования индексов.

SET LOCAL enable_indexscan = off;
SET LOCAL enable_bitmapscan = off;
SET LOCAL enable_indexonlyscan = off;

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