-- ==========
-- ВОПРОС 1
-- ==========
-- Как огранизовать право доступа только в определенным строкам?
-- Есть два способа реализации: с помощью view и политика защиты строк (row level security)
\connect university_analytic;

-- пример для политики
ALTER TABLE dim_date ENABLE ROW LEVEL SECURITY;
CREATE POLICY date_test ON dim_date TO test
    USING (academic_year = '2024/2025');

-- ==========
-- ВОПРОС 2
-- ==========
-- Ограничить доступ пользователя к таблице и сейчас и потом до определенного распоряжения
REVOKE ALL PRIVILEGES ON TABLE dim_course FROM test;

ALTER TABLE dim_course ENABLE ROW LEVEL SECURITY;
CREATE POLICY revoke_all ON dim_course FOR ALL
    TO test USING (false) WITH CHECK (false);
ALTER ROLE test NOINHERIT;

CREATE POLICY allow_others ON dim_course FOR ALL 
    TO PUBLIC USING (true) WITH CHECK (true);

-- проверка
DROP OWNED BY other CASCADE;
DROP ROLE IF EXISTS other;
CREATE ROLE other;
GRANT SELECT ON dim_course TO other;
GRANT other TO test;

DROP OWNED BY one_more CASCADE;
DROP USER IF EXISTS one_more;
CREATE USER one_more WITH PASSWORD '123';
GRANT other TO one_more;
