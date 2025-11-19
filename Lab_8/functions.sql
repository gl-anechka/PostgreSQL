\connect university_analytic;

-- Средний балл студента по всем предметам
-- Если не задан id, то выводит ср. балл для всех студентов
CREATE OR REPLACE FUNCTION get_avg_grade(g_student_id INT DEFAULT NULL)
RETURNS TABLE (
    student_id INT,
    avg_grade  NUMERIC
) AS $$
DECLARE
    rec RECORD;
    grade_rec JSONB;
    json_elem JSONB;
    grade_val NUMERIC;
    total NUMERIC := 0;
    cnt INT := 0;
BEGIN
    -- если задан конкретный студент
    IF g_student_id IS NOT NULL THEN
        SELECT grades INTO grade_rec
        FROM dim_student
        WHERE dim_student.student_id = g_student_id;

        -- проверка id студента
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Student with ID % not found', g_student_id;
        END IF;

        -- оценки
        FOR json_elem IN
            SELECT * FROM jsonb_array_elements(grade_rec->'grades')
        LOOP
            grade_val := (json_elem->>'grade')::NUMERIC;
            total := total + grade_val;
            cnt := cnt + 1;
        END LOOP;

        -- проверка на пустой массив оценок
        IF cnt = 0 THEN
            RAISE NOTICE 'Student % has no grades', g_student_id;
            RETURN QUERY SELECT g_student_id, NULL::NUMERIC;
        ELSE
            RETURN QUERY SELECT g_student_id, ROUND(total / cnt, 2);
        END IF;
        RETURN;
    END IF;

    -- иначе считаем средние оценки для всех студентов
    FOR rec IN SELECT dim_student.student_id, grades FROM dim_student
    LOOP
        FOR json_elem IN
            SELECT * FROM jsonb_array_elements(rec.grades->'grades')
        LOOP
            grade_val := (json_elem->>'grade')::NUMERIC;
            total := total + grade_val;
            cnt := cnt + 1;
        END LOOP;

        IF cnt > 0 THEN
            RETURN QUERY SELECT rec.student_id, ROUND(total / cnt, 2);
        ELSE
            RETURN QUERY SELECT rec.student_id, NULL::NUMERIC;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;



-- Отчислить студентов (статус студента поменять на "под отчисление")
-- со средним баллом ниже порогового или посещаемостью за год ниже пороговой
-- По умолчанию:
--      порог посещаемости - 75 %,
--      порог оценки - 2.5
CREATE OR REPLACE FUNCTION low_stud_perf(
    threshold_val NUMERIC DEFAULT 2.5,
    attend_threshold NUMERIC DEFAULT 0.75,
    ac_year VARCHAR(9) DEFAULT '2024/2025'
)
RETURNS TABLE (
    student_id INT,
    student_surname VARCHAR(100),
    student_name VARCHAR(100),
    student_patronymic VARCHAR(100),
    avg_grade NUMERIC,
    attendance_rate NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    WITH avg_data AS (
        SELECT 
            s.student_id,
            s.student_surname,
            s.student_name,
            s.student_patronymic,
            g.avg_grade,
            ROUND(
                COALESCE(
                    SUM(CASE WHEN f.attendance THEN 1 ELSE 0 END)::NUMERIC 
                    / NULLIF(COUNT(f.*), 0), 
                    0
                ),
                2
            ) AS attendance_rate
        FROM dim_student AS s
        LEFT JOIN get_avg_grade() AS g ON g.student_id = s.student_id
        LEFT JOIN fact_student_performance AS f ON f.student_id = s.student_id
        LEFT JOIN dim_date AS d ON d.date_id = f.date_id AND d.academic_year = ac_year
        WHERE s.study_status = 'active'
        GROUP BY 
            s.student_id, s.student_surname, 
            s.student_name, s.student_patronymic, g.avg_grade
    ),
    to_update AS (
        SELECT 
            a.student_id
        FROM avg_data AS a
        WHERE 
            (a.avg_grade IS NOT NULL AND a.avg_grade < threshold_val)
            OR a.attendance_rate < attend_threshold
    ),
    updated AS (
        UPDATE dim_student AS s
        SET study_status = 'at risk of expulsion'
        FROM to_update AS t
        WHERE s.student_id = t.student_id
        RETURNING s.student_id
    )
    SELECT 
        a.student_id,
        a.student_surname,
        a.student_name,
        a.student_patronymic,
        a.avg_grade,
        a.attendance_rate
    FROM avg_data AS a
    JOIN updated AS u ON u.student_id = a.student_id;
END;
$$ LANGUAGE plpgsql;



-- Анализ преподавательской деятельности: сколько проведено занятий и средняя оценка студентов за семинар
-- Оценивается за указанный период
CREATE OR REPLACE FUNCTION teacher_activity(duration INTERVAL DEFAULT '3 month')
RETURNS TABLE (
    teacher_id INT,
    teacher_fullname VARCHAR(100),
    lesson_count INT,
    avg_grade NUMERIC(4,2),
    quality_category TEXT,
    report_period INTERVAL
) AS $$
DECLARE
    cur CURSOR FOR
        SELECT
            t.teacher_id,
            t.teacher_surname,
            t.teacher_name,
            t.teacher_patronymic,
            COUNT(*) AS lesson_count,
            AVG(f.grade) AS avg_grade
        FROM dim_teacher AS t
        LEFT JOIN fact_student_performance AS f ON f.teacher_id = t.teacher_id
        LEFT JOIN dim_date AS d ON f.date_id = d.date_id
        WHERE f.cancelled = FALSE AND f.grade IS NOT NULL AND d.lesson_date >= (CURRENT_DATE - duration)
        GROUP BY t.teacher_id, t.teacher_surname, t.teacher_name, t.teacher_patronymic;
    rec RECORD;
    quality TEXT;
BEGIN
    -- работа с курсором по таблице преподавателей
    OPEN cur;
    LOOP
        FETCH cur INTO rec;
        EXIT WHEN NOT FOUND;

        teacher_id := rec.teacher_id;
        teacher_fullname := rec.teacher_surname || ' ' || rec.teacher_name || ' ' || COALESCE(rec.teacher_patronymic, '');
        lesson_count := COALESCE(rec.lesson_count, 0);
        avg_grade := ROUND(COALESCE(rec.avg_grade, 0), 2);
        report_period := duration;

        IF rec.lesson_count IS NULL OR rec.lesson_count = 0 THEN
            quality_category := 'No activity';
        ELSIF rec.avg_grade >= 4.5 THEN
            quality_category := 'High teaching quality';
        ELSIF rec.avg_grade >= 3.5 THEN
            quality_category := 'Good teaching quality';
        ELSE
            quality_category := 'Average teaching quality';
        END IF;

        -- без параметров, поэтому присвоение значений выше
        RETURN NEXT;
    END LOOP;

    CLOSE cur;
END;
$$ LANGUAGE plpgsql;



-- Средняя оценка по курсу среди всех студентов
CREATE OR REPLACE FUNCTION get_avg_grade_by_course(c_title TEXT DEFAULT NULL)
RETURNS NUMERIC AS $$
DECLARE
    cur CURSOR FOR
        SELECT student_id, grades
        FROM dim_student
        WHERE grades IS NOT NULL;
    rec RECORD;
    grade_val NUMERIC;
    total NUMERIC := 0;
    cnt INT := 0;
BEGIN
    IF c_title IS NULL THEN
        RAISE EXCEPTION 'Course is not specified';
    END IF;

    OPEN cur;
    LOOP
        FETCH cur INTO rec;
        EXIT WHEN NOT FOUND;

        BEGIN
            -- проверка, что есть такой ключ
            IF rec.grades ? 'grades' THEN
                FOR grade_val IN
                    SELECT (g->>'grade')::NUMERIC
                    FROM jsonb_array_elements(rec.grades->'grades') AS g
                    WHERE g->>'subject' = c_title
                LOOP
                    total := total + grade_val;
                    cnt := cnt + 1;
                END LOOP;
            END IF;

        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING 'Error when processing student %', rec.student_id;
        END;
    END LOOP;

    CLOSE cur;

    IF cnt = 0 THEN
        RAISE NOTICE 'No grades for the course %', c_title;
        RETURN NULL;
    ELSE
        RETURN ROUND(total / cnt, 2);
    END IF;
END;
$$ LANGUAGE plpgsql;