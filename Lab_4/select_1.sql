-- Расписание на неделю (без учета замен и переносов),
-- т.е. расписание по плану.
-- Выводит название предмета, время, аудиторию и список групп и преподавателей.

SELECT 
    c.title AS title,
	STRING_AGG(
		DISTINCT
        t.teacher_surname || ' ' || 
        LEFT(t.teacher_name, 1) || '.' || 
        LEFT(t.teacher_patronymic, 1) || '.', 
        ', '
    ) AS teachers,
    STRING_AGG(DISTINCT tg.id_group::text, ', ') AS id_group,
	CASE tt.day_of_week
		WHEN 1 THEN 'ПН'
		WHEN 2 THEN 'ВТ'
		WHEN 3 THEN 'СР'
		WHEN 4 THEN 'ЧТ'
		WHEN 5 THEN 'ПТ'
		WHEN 6 THEN 'СБ'
		WHEN 0 THEN 'ВС'
	END AS day_of_week,
    tt.time_begin || ' - ' || tt.time_end AS l_time,
    tt.classroom,
    tt.lesson_type,
    CASE tt.week_parity 
        WHEN FALSE THEN 'Четная'
        WHEN TRUE THEN 'Нечетная'
        ELSE 'Еженедельно'
    END AS parity
FROM timetable AS tt
JOIN course AS c ON tt.course = c.id_course
JOIN timetable_teacher AS st ON tt.id_timetable = st.id_timetable
JOIN teacher AS t ON st.id_teacher = t.id_teacher
JOIN timetable_group AS tg ON tt.id_timetable = tg.id_timetable
GROUP BY 
    c.title, tt.day_of_week, l_time, tt.classroom, tt.lesson_type, tt.week_parity
ORDER BY tt.day_of_week, l_time;