-- Фильтрация с использованием массива и json-формата
-- Без индексов

SET LOCAL enable_indexscan = off;
SET LOCAL enable_bitmapscan = off;
SET LOCAL enable_indexonlyscan = off;

EXPLAIN (ANALYZE, BUFFERS)
    SELECT 
        teacher_surname, 
        teacher_name,
        teacher_patronymic,
        subjects_taught, 
        teacher_metadata
    FROM dim_teacher
    WHERE subjects_taught @> ARRAY['Practice']
    AND teacher_metadata->'projects' @> '["Development of Computer Algebra Systems"]';