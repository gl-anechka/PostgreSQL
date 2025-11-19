-- Актуальное расписание для конкретной группы на определенный день недели.
-- Учтены изменения, т.к. группе логичнее получать расписание именно на сегодня.

-- переменные
WITH params AS (
    SELECT 
        327 AS group_num,
        '90 minutes'::INTERVAL AS time_int,
		'24.09.2025'::DATE AS date_of_lesson
)
SELECT
	c.title,
	STRING_AGG(
		DISTINCT
		COALESCE(
            -- если есть замена, вывести нового преподавателя
            CASE 
                WHEN tc.id_teacher IS NOT NULL
					AND tc.lesson_date = params.date_of_lesson THEN 
                    rt.teacher_surname || ' ' || 
                    LEFT(rt.teacher_name, 1) || '.' || 
                    LEFT(rt.teacher_patronymic, 1) || '. (замена)'
                ELSE NULL
            END,
            -- иначе по раписанию
            teacher.teacher_surname || ' ' || 
            LEFT(teacher.teacher_name, 1) || '.' || 
            LEFT(teacher.teacher_patronymic, 1) || '.'
        ),
		', '
	) AS teachers,
	COALESCE (
		-- если это перенос пары, вывести новое время
		CASE 
            WHEN tc.new_date = params.date_of_lesson THEN 
                tc.new_time || ' - ' || tc.new_time + params.time_int
            ELSE NULL
        END,
        -- иначе по расписанию
        t.time_begin || ' - ' || t.time_end
	) AS l_time,
	t.classroom,
	t.lesson_type,
	CASE t.week_parity 
		WHEN FALSE THEN 'Четная'
        WHEN TRUE THEN 'Нечетная'
        ELSE 'Еженедельно'
	END AS parity
FROM timetable AS t
CROSS JOIN params
JOIN timetable_teacher AS tt ON tt.id_timetable = t.id_timetable
JOIN timetable_group AS tg ON tg.id_timetable = t.id_timetable
JOIN course AS c ON c.id_course = t.course
JOIN teacher ON teacher.id_teacher = tt.id_teacher
LEFT JOIN timetable_change AS tc ON tc.id_timetable = tt.id_timetable
LEFT JOIN teacher AS rt ON tc.id_teacher = rt.id_teacher
WHERE
	tg.id_group = params.group_num
	AND (
        -- пары по расписанию
        (t.day_of_week = EXTRACT(DOW FROM params.date_of_lesson)
         AND NOT EXISTS (
            SELECT 1 FROM timetable_change tc_cancel 
            WHERE tc_cancel.id_timetable = t.id_timetable 
            AND tc_cancel.lesson_date = params.date_of_lesson 
            AND (tc_cancel.cancel = 1 OR tc_cancel.cancel = 2)
        ))
        OR 
        -- или перенесенные
        EXISTS (
            SELECT 1 FROM timetable_change tc_reschedule 
            WHERE tc_reschedule.id_timetable = t.id_timetable 
            AND tc_reschedule.new_date = params.date_of_lesson 
            AND tc_reschedule.cancel = 2
        )
	)
GROUP BY c.title, l_time, t.classroom, t.lesson_type, t.week_parity, tc.info	
ORDER BY l_time;