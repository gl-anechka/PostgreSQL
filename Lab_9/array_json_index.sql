-- Фильтрация с использованием массива и json-формата
-- С индексами

CREATE INDEX IF NOT EXISTS idx_dim_teacher_sub_proj
ON dim_teacher USING GIN (subjects_taught, (teacher_metadata -> 'projects'));

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