SELECT 
    c.title as course_name,
    t.teacher_surname || ' ' || LEFT(t.teacher_name, 1) || '.' || LEFT(t.teacher_patronymic, 1) || '.' as teacher_name,
    g.id_group as group_id,
    s.day_of_week,
    s.time_begin,
    s.time_end,
    s.classroom,
    s.lesson_type,
    CASE s.week_parity 
        WHEN FALSE THEN 'Четная'
        WHEN TRUE THEN 'Нечетная'
        ELSE 'Еженедельно'
    END as week_type
FROM timetable s
JOIN course c ON s.course = c.id_course
JOIN timetable_teacher st ON s.id_timetable = st.id_timetable
JOIN teacher t ON st.id_teacher = t.id_teacher
JOIN timetable_group sg ON s.id_timetable = sg.id_timetable
JOIN group_number g ON sg.id_group = g.id_group;
