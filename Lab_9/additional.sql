-- как устроен индекс, на что влияет порядок
-- пример индекса по выражению

CREATE INDEX IF NOT EXISTS student_name ON dim_student ((student_surname || ' ' || student_name));

EXPLAIN ANALYZE
	SELECT * FROM dim_student
	WHERE (student_surname || ' ' || student_name) = 'Petrov Ivan';
