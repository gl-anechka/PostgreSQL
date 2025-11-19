-- Полнотекстовый поиск
-- Без индексов

SET LOCAL enable_indexscan = off;
SET LOCAL enable_bitmapscan = off;
SET LOCAL enable_indexonlyscan = off;

-- Поиск по столбцу course_description
EXPLAIN (ANALYZE, BUFFERS)
    SELECT course_id, course_title, course_description
    FROM dim_course
    WHERE to_tsvector('english', course_description) @@ to_tsquery('english', 'systems | computational');