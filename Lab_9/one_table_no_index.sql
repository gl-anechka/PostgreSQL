-- Запрос к одной таблице, содержащий фильтрацию по нескольким полям
-- Получить план выполнения запроса без использования индексов.
-- Получить статистику (IO и Time) выполнения запроса без использования индексов.

-- отключение всех сканирований по индексам
SET LOCAL enable_indexscan = off;
SET LOCAL enable_indexonlyscan = off;
SET LOCAL enable_bitmapscan = off;

EXPLAIN (ANALYZE, BUFFERS)
    SELECT
        fact_id,
        date_id,
        student_id,
        course_id,
        lesson_type,
        attendance
    FROM fact_student_performance
    WHERE
        student_id = 20556819
		AND date_id BETWEEN 19725 AND 19997  -- id за 2024/2025 учебный год
        AND attendance = true;