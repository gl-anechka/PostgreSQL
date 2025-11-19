-- Расписание для конкретной группы на определенный день недели
-- (без учета замен и переносов)

SELECT
	c.title,
	STRING_AGG(
		teacher.teacher_surname || ' ' || 
		LEFT(teacher.teacher_name, 1) || '.' || 
		LEFT(teacher.teacher_patronymic, 1) || '.',
		', '
	) AS teachers,
	t.time_begin || ' - ' || t.time_end AS l_time,
	t.classroom,
	t.lesson_type,
	CASE t.week_parity
		WHEN FALSE THEN 'Четная'
        WHEN TRUE THEN 'Нечетная'
        ELSE 'Еженедельно'
	END AS parity
FROM timetable AS t
JOIN timetable_teacher AS tt ON tt.id_timetable = t.id_timetable
JOIN teacher ON teacher.id_teacher = tt.id_teacher
JOIN timetable_group AS tg ON tg.id_timetable = t.id_timetable
JOIN course AS c ON c.id_course = t.course
WHERE tg.id_group = 327 AND t.day_of_week = '1'
GROUP BY c.title, l_time, t.classroom, t.lesson_type, t.week_parity
ORDER BY l_time;