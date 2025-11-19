-- Создание БД для аналитики
DROP DATABASE IF EXISTS university_analytic;
CREATE DATABASE university_analytic;
\connect university_analytic;


-- Оптимизации
ALTER SYSTEM SET maintenance_work_mem = '1.9GB';  -- максимальный объем памяти для операций обслуживания БД
ALTER SYSTEM SET max_wal_size = '8GB';  -- увеличивает максимальный размер журнала предзаписи (WAL)
ALTER SYSTEM SET checkpoint_timeout = '30min';  -- время между checkpoint
ALTER SYSTEM SET synchronous_commit = off;  -- отключает синхронную запись WAL на диск
SELECT pg_reload_conf();  -- применить изменения без перезапуска PostgreSQL


-- ==================================================
-- Таблицы измерений
-- ==================================================

-- Анализ времени
CREATE TABLE dim_date (
    date_id SERIAL PRIMARY KEY,
    lesson_date DATE NOT NULL,
    day_of_week INTEGER,
    week_number INTEGER,
    month_number INTEGER,
    semester INTEGER,
    academic_year VARCHAR(9),
    is_weekend BOOLEAN
);

-- Сведения о студенте
CREATE TABLE dim_student (
    student_id INTEGER PRIMARY KEY,  -- номер студенческого
    student_surname VARCHAR(100) NOT NULL,
    student_name VARCHAR(100) NOT NULL,
    student_patronymic VARCHAR(100),
    phone VARCHAR(20),

    group_num INTEGER,
    cafedra_name VARCHAR(200),
    head_of_group BOOLEAN,
    
    enrollment_date DATE,
    graduation_date DATE,
    study_status VARCHAR(50),  -- статус студента (учиться/в академе)
    previous_education JSONB,  -- json
    grades JSONB  -- оценки по предметам
);

-- Данные о преподавателе
CREATE TABLE dim_teacher (
    teacher_id SERIAL PRIMARY KEY,
    teacher_surname VARCHAR(100) NOT NULL,
    teacher_name VARCHAR(100) NOT NULL,
    teacher_patronymic VARCHAR(100),

    job_title VARCHAR(200),  -- должность
    cafedra_name VARCHAR(200),
    academic_degree VARCHAR(100),

    teacher_metadata JSONB,  -- json (доп данные, такие как публикации, проекты, научные интересы)
    subjects_taught TEXT[],  -- массив преподаваемых дисциплин
    work_status VARCHAR(50)
);

-- Характеристики курса
CREATE TABLE dim_course (
    course_id SERIAL PRIMARY KEY,
    course_title VARCHAR(300) NOT NULL,

    course_description TEXT,  -- текст (подробное описание курса)

    test_type VARCHAR(50),
    study_load INTEGER
);


-- ==================================================
-- Таблица фактов
-- ==================================================
CREATE TABLE fact_student_performance (
    fact_id BIGSERIAL PRIMARY KEY,

    date_id INTEGER NOT NULL,
    student_id INTEGER NOT NULL,
    teacher_id INTEGER NOT NULL, 
    course_id INTEGER NOT NULL,

    lesson_type VARCHAR(20),  -- тип занятия
    cancelled BOOLEAN,  -- признак отмены
    time_begin TIME,
    time_end TIME,
    classroom VARCHAR(5),  -- аудитория
    attendance BOOLEAN,  -- посещение
    grade NUMERIC(4,2),  -- оценка

    duration_minutes INTEGER,  -- длительность в минутах
    academic_hours INTEGER,  -- длительность в академических часах
    is_credited BOOLEAN,  -- является ли оценка зачетной

    CONSTRAINT check_time CHECK (time_end > time_begin),
    CONSTRAINT chk_duration CHECK (duration_minutes >= 0 AND academic_hours >= 0)
);


-- ==================================================
-- Таблицы данных (только для временного хранения)
-- ==================================================
-- Курсы
CREATE TEMPORARY TABLE real_course (
    title VARCHAR(300) NOT NULL,
    course_desc TEXT
);
COPY real_course(title, course_desc)
FROM 'C:/WORK_ANYA/SQL/Lab_6/data/course.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ';');


-- ==================================================
-- Генерация значений
-- ==================================================
ALTER TABLE dim_date SET UNLOGGED;
ALTER TABLE dim_course SET UNLOGGED;
ALTER TABLE dim_student SET UNLOGGED;
ALTER TABLE dim_teacher SET UNLOGGED;
ALTER TABLE fact_student_performance SET UNLOGGED;

-- Даты
INSERT INTO dim_date (lesson_date, day_of_week, week_number, month_number, semester, academic_year, is_weekend)
SELECT 
    d::DATE,
    EXTRACT(DOW FROM d)::INT,
    EXTRACT(WEEK FROM d)::INT,
    EXTRACT(MONTH FROM d)::INT,
    CASE
        WHEN EXTRACT(MONTH FROM d) <= 6 THEN 2
        ELSE 1
    END,
    CONCAT(EXTRACT(YEAR FROM d), '/', EXTRACT(YEAR FROM d)+1),
    (EXTRACT(DOW FROM d)::INT IN (6,0))
FROM generate_series('1970-09-01'::DATE, '2025-12-31'::DATE, '1 day'::INTERVAL) d;


-- Записи о курсах
COPY (
WITH prepared_course AS (
    SELECT
        ARRAY_AGG(title) AS real_c,
        ARRAY_AGG(course_desc) AS real_d,
        COUNT(*) AS c_count
    FROM real_course
)
SELECT 
    pc.real_c[1 + i % c_count],
    pc.real_d[1 + i % c_count],
    CASE i % 2
        WHEN 0 THEN 'exam'
        ELSE 'test'
    END,
    100 + (i % 90)
FROM generate_series(1, 1000000) i
CROSS JOIN prepared_course AS pc
) TO 'C:/WORK_ANYA/SQL/Lab_6/data/temp_course.csv' WITH CSV;

COPY dim_course (course_title, course_description, test_type, study_load)
FROM 'C:/WORK_ANYA/SQL/Lab_6/data/temp_course.csv' WITH (FORMAT csv, HEADER false, DELIMITER ',');


-- Записи о студентах
COPY dim_student(student_id, student_surname, student_name, student_patronymic, phone, group_num,
    cafedra_name, head_of_group, enrollment_date, graduation_date, study_status, previous_education, grades)
FROM 'C:/WORK_ANYA/SQL/Lab_6/data/temp_student.csv' WITH (FORMAT csv, HEADER false, DELIMITER ',');


-- Записи о преподавателях
COPY dim_teacher (teacher_surname, teacher_name, teacher_patronymic, job_title, cafedra_name, academic_degree,
    teacher_metadata, subjects_taught, work_status)
FROM 'C:/WORK_ANYA/SQL/Lab_6/data/temp_teacher.csv' WITH (FORMAT csv, HEADER false, DELIMITER ',');


-- Таблица фактов
COPY fact_student_performance(date_id, student_id, teacher_id, course_id, lesson_type, cancelled,
    time_begin, time_end, classroom, attendance, grade, duration_minutes, academic_hours, is_credited)
FROM 'C:/WORK_ANYA/SQL/Lab_6/data/temp_fact.csv' WITH (FORMAT csv, HEADER false, DELIMITER ',');


ALTER TABLE dim_date SET LOGGED;
ALTER TABLE dim_course SET LOGGED;
ALTER TABLE dim_student SET LOGGED;
ALTER TABLE dim_teacher SET LOGGED;
ALTER TABLE fact_student_performance SET LOGGED;

-- Внешние ключи
ALTER TABLE fact_student_performance
    ADD FOREIGN KEY(date_id) REFERENCES dim_date(date_id),
    ADD FOREIGN KEY(student_id) REFERENCES dim_student(student_id),
    ADD FOREIGN KEY(teacher_id) REFERENCES dim_teacher(teacher_id),
    ADD FOREIGN KEY(course_id) REFERENCES dim_course(course_id);


ANALYZE dim_student;
ANALYZE dim_teacher;
ANALYZE dim_course;
ANALYZE dim_date;
ANALYZE fact_student_performance;


-- Возврат настроек
ALTER SYSTEM RESET max_wal_size;
ALTER SYSTEM RESET synchronous_commit;
ALTER SYSTEM RESET maintenance_work_mem;
ALTER SYSTEM RESET checkpoint_timeout;
SELECT pg_reload_conf();