-- Проверка работы триггера
-- Неправильные данные, откат транзакции

BEGIN;
INSERT INTO timetable (course, week_parity, day_of_week, time_begin, time_end, classroom, lesson_type, semester)
VALUES (1, NULL, 1, '21:00', '22:30', '101', 'лекция', 1);
ROLLBACK;