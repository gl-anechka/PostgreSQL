-- Проверка работы триггера
-- Автоматически коректирует длительность пары

BEGIN;
INSERT INTO timetable (course, week_parity, day_of_week, time_begin, time_end, classroom, lesson_type, semester)
VALUES (1, NULL, 1, '08:00', '08:30', '101', 'лекция', 1);
COMMIT;
