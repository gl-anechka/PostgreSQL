-- Полнотекстовый поиск
-- С индексами

CREATE INDEX IF NOT EXISTS idx_dim_course_desc
ON dim_course
USING GIN(to_tsvector('english', course_description));

EXPLAIN (ANALYZE, BUFFERS)
    SELECT course_id, course_title, course_description
    FROM dim_course
    WHERE to_tsvector('english', course_description) @@ to_tsquery('english', 'systems | computational');