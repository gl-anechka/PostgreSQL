-- Секционирование таблицы фактов
\connect university_analytic

ALTER SYSTEM SET maintenance_work_mem = '1.9GB';
ALTER SYSTEM SET max_wal_size = '8GB';
ALTER SYSTEM SET checkpoint_timeout = '30min';
ALTER SYSTEM SET synchronous_commit = off;
SELECT pg_reload_conf();


CREATE TABLE fact_student_performance_prt (
    fact_id BIGSERIAL NOT NULL,

    date_id INTEGER NOT NULL,
    student_id INTEGER NOT NULL,
    teacher_id INTEGER NOT NULL, 
    course_id INTEGER NOT NULL,

    lesson_type VARCHAR(20),
    cancelled BOOLEAN,
    time_begin TIME,
    time_end TIME,
    classroom VARCHAR(5),
    attendance BOOLEAN,
    grade NUMERIC(4,2),

    duration_minutes INTEGER,
    academic_hours INTEGER,
    is_credited BOOLEAN,

    PRIMARY KEY (fact_id, date_id)
) PARTITION BY RANGE (date_id);


-- секции
CREATE TABLE fact_prt_1970_2000 PARTITION OF fact_student_performance_prt FOR VALUES FROM (1) TO (11081);  -- 1970 - 2000
CREATE TABLE fact_prt_2000_2010 PARTITION OF fact_student_performance_prt FOR VALUES FROM (11081) TO (14733);  -- 2000 - 2010
CREATE TABLE fact_prt_2010_2020 PARTITION OF fact_student_performance_prt FOR VALUES FROM (14733) TO (18386);  -- 2010 - 2020
CREATE TABLE fact_prt_2020_2022 PARTITION OF fact_student_performance_prt FOR VALUES FROM (18386) TO (19116);  -- 2020 - 2022
CREATE TABLE fact_prt_2023 PARTITION OF fact_student_performance_prt FOR VALUES FROM (19116) TO (19481);  -- 2023
CREATE TABLE fact_prt_2024 PARTITION OF fact_student_performance_prt FOR VALUES FROM (19481) TO (19847);  -- 2024
CREATE TABLE fact_prt_2025 PARTITION OF fact_student_performance_prt FOR VALUES FROM (19847) TO (20211);  -- 2025


ALTER TABLE fact_prt_1970_2000 SET UNLOGGED;
ALTER TABLE fact_prt_2000_2010 SET UNLOGGED;
ALTER TABLE fact_prt_2010_2020 SET UNLOGGED;
ALTER TABLE fact_prt_2020_2022 SET UNLOGGED;
ALTER TABLE fact_prt_2023 SET UNLOGGED;
ALTER TABLE fact_prt_2024 SET UNLOGGED;
ALTER TABLE fact_prt_2025 SET UNLOGGED;


-- вставка данных
INSERT INTO fact_student_performance_prt 
SELECT * FROM fact_student_performance 
WHERE date_id BETWEEN 1 AND 11080;

INSERT INTO fact_student_performance_prt 
SELECT * FROM fact_student_performance 
WHERE date_id BETWEEN 11081 AND 14732;

INSERT INTO fact_student_performance_prt 
SELECT * FROM fact_student_performance 
WHERE date_id BETWEEN 14733 AND 18385;

INSERT INTO fact_student_performance_prt 
SELECT * FROM fact_student_performance 
WHERE date_id BETWEEN 18386 AND 19115;

INSERT INTO fact_student_performance_prt 
SELECT * FROM fact_student_performance 
WHERE date_id BETWEEN 19116 AND 19480;

INSERT INTO fact_student_performance_prt 
SELECT * FROM fact_student_performance 
WHERE date_id BETWEEN 19481 AND 19846;

INSERT INTO fact_student_performance_prt 
SELECT * FROM fact_student_performance 
WHERE date_id BETWEEN 19847 AND 20210;


-- анализ
ANALYZE fact_prt_1970_2000;
ANALYZE fact_prt_2000_2010;
ANALYZE fact_prt_2010_2020;
ANALYZE fact_prt_2020_2022;
ANALYZE fact_prt_2023;
ANALYZE fact_prt_2024;
ANALYZE fact_prt_2025;


ALTER TABLE fact_prt_1970_2000 SET LOGGED;
ALTER TABLE fact_prt_2000_2010 SET LOGGED;
ALTER TABLE fact_prt_2010_2020 SET LOGGED;
ALTER TABLE fact_prt_2020_2022 SET LOGGED;
ALTER TABLE fact_prt_2023 SET LOGGED;
ALTER TABLE fact_prt_2024 SET LOGGED;
ALTER TABLE fact_prt_2025 SET LOGGED;


-- внешние ключи
ALTER TABLE fact_prt_1970_2000
    ADD FOREIGN KEY(date_id) REFERENCES dim_date(date_id),
    ADD FOREIGN KEY(student_id) REFERENCES dim_student(student_id),
    ADD FOREIGN KEY(teacher_id) REFERENCES dim_teacher(teacher_id),
    ADD FOREIGN KEY(course_id) REFERENCES dim_course(course_id);

ALTER TABLE fact_prt_2000_2010
    ADD FOREIGN KEY(date_id) REFERENCES dim_date(date_id),
    ADD FOREIGN KEY(student_id) REFERENCES dim_student(student_id),
    ADD FOREIGN KEY(teacher_id) REFERENCES dim_teacher(teacher_id),
    ADD FOREIGN KEY(course_id) REFERENCES dim_course(course_id);

ALTER TABLE fact_prt_2010_2020
    ADD FOREIGN KEY(date_id) REFERENCES dim_date(date_id),
    ADD FOREIGN KEY(student_id) REFERENCES dim_student(student_id),
    ADD FOREIGN KEY(teacher_id) REFERENCES dim_teacher(teacher_id),
    ADD FOREIGN KEY(course_id) REFERENCES dim_course(course_id);

ALTER TABLE fact_prt_2020_2022
    ADD FOREIGN KEY(date_id) REFERENCES dim_date(date_id),
    ADD FOREIGN KEY(student_id) REFERENCES dim_student(student_id),
    ADD FOREIGN KEY(teacher_id) REFERENCES dim_teacher(teacher_id),
    ADD FOREIGN KEY(course_id) REFERENCES dim_course(course_id);

ALTER TABLE fact_prt_2023
    ADD FOREIGN KEY(date_id) REFERENCES dim_date(date_id),
    ADD FOREIGN KEY(student_id) REFERENCES dim_student(student_id),
    ADD FOREIGN KEY(teacher_id) REFERENCES dim_teacher(teacher_id),
    ADD FOREIGN KEY(course_id) REFERENCES dim_course(course_id);

ALTER TABLE fact_prt_2024
    ADD FOREIGN KEY(date_id) REFERENCES dim_date(date_id),
    ADD FOREIGN KEY(student_id) REFERENCES dim_student(student_id),
    ADD FOREIGN KEY(teacher_id) REFERENCES dim_teacher(teacher_id),
    ADD FOREIGN KEY(course_id) REFERENCES dim_course(course_id);

ALTER TABLE fact_prt_2025
    ADD FOREIGN KEY(date_id) REFERENCES dim_date(date_id),
    ADD FOREIGN KEY(student_id) REFERENCES dim_student(student_id),
    ADD FOREIGN KEY(teacher_id) REFERENCES dim_teacher(teacher_id),
    ADD FOREIGN KEY(course_id) REFERENCES dim_course(course_id);


-- индексы
CREATE INDEX idx_fact_prt_1970_2000_student_att_date ON public.fact_prt_1970_2000 USING btree (student_id, date_id, attendance);
CREATE INDEX idx_fact_prt_2000_2010_student_att_date ON public.fact_prt_2000_2010 USING btree (student_id, date_id, attendance);
CREATE INDEX idx_fact_prt_2010_2020_student_att_date ON public.fact_prt_2010_2020 USING btree (student_id, date_id, attendance);
CREATE INDEX idx_fact_prt_2020_2022_student_att_date ON public.fact_prt_2020_2022 USING btree (student_id, date_id, attendance);
CREATE INDEX idx_fact_prt_2023_student_att_date ON public.fact_prt_2023 USING btree (student_id, date_id, attendance);
CREATE INDEX idx_fact_prt_2024_student_att_date ON public.fact_prt_2024 USING btree (student_id, date_id, attendance);
CREATE INDEX idx_fact_prt_2025_student_att_date ON public.fact_prt_2025 USING btree (student_id, date_id, attendance);

CREATE INDEX idx_fact_prt_1970_2000_performance_covering ON public.fact_prt_1970_2000 USING btree (date_id, student_id, cancelled)
    INCLUDE (course_id, teacher_id, attendance) WHERE (cancelled = false);
CREATE INDEX idx_fact_prt_2000_2010_performance_covering ON public.fact_prt_2000_2010 USING btree (date_id, student_id, cancelled)
    INCLUDE (course_id, teacher_id, attendance) WHERE (cancelled = false);
CREATE INDEX idx_fact_prt_2010_2020_performance_covering ON public.fact_prt_2010_2020 USING btree (date_id, student_id, cancelled)
    INCLUDE (course_id, teacher_id, attendance) WHERE (cancelled = false);
CREATE INDEX idx_fact_prt_2020_2022_performance_covering ON public.fact_prt_2020_2022 USING btree (date_id, student_id, cancelled)
    INCLUDE (course_id, teacher_id, attendance) WHERE (cancelled = false);
CREATE INDEX idx_fact_prt_2023_performance_covering ON public.fact_prt_2023 USING btree (date_id, student_id, cancelled)
    INCLUDE (course_id, teacher_id, attendance) WHERE (cancelled = false);
CREATE INDEX idx_fact_prt_2024_performance_covering ON public.fact_prt_2024 USING btree (date_id, student_id, cancelled)
    INCLUDE (course_id, teacher_id, attendance) WHERE (cancelled = false);
CREATE INDEX idx_fact_prt_2025_performance_covering ON public.fact_prt_2025 USING btree (date_id, student_id, cancelled)
    INCLUDE (course_id, teacher_id, attendance) WHERE (cancelled = false);


-- возврат настроек
ALTER SYSTEM RESET max_wal_size;
ALTER SYSTEM RESET synchronous_commit;
ALTER SYSTEM RESET maintenance_work_mem;
ALTER SYSTEM RESET checkpoint_timeout;
SELECT pg_reload_conf();


-- переименование таблиц
ALTER TABLE fact_student_performance RENAME TO fact_student_performance_old;
ALTER TABLE fact_student_performance_prt RENAME TO fact_student_performance;