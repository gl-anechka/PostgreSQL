-- Скрипт для создания БД университета

DROP DATABASE IF EXISTS university;

CREATE DATABASE university;

\connect university;


-- Пользовательские типы данных
CREATE TYPE t_lesson AS ENUM ('лекция', 'семинар', 'экзамен', 'зачет');
CREATE TYPE t_test AS ENUM ('зачет', 'экзамен', 'зачет с оценкой');


--- ==================================================
-- Таблица: ученые степени
--- ==================================================
CREATE TABLE academic_degree (
    id_degree SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL UNIQUE
);

COMMENT ON TABLE academic_degree IS 'Ученая степень преподавателя';

--- ==================================================
-- Таблица: должности
--- ==================================================
CREATE TABLE job_desc (
    id_job SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL UNIQUE
);

COMMENT ON TABLE job_desc IS 'Должность преподавателя на кафедре';

--- ==================================================
-- Таблица: кафедра
--- ==================================================
CREATE TABLE cafedra (
    id_caf VARCHAR(5) PRIMARY KEY,
    title VARCHAR(255) NOT NULL UNIQUE
);

COMMENT ON TABLE cafedra IS 'Кафедра';

--- ==================================================
-- Таблица: преподаватель
--- ==================================================
CREATE TABLE teacher (
    id_teacher SERIAL PRIMARY KEY,
    teacher_surname VARCHAR(30) NOT NULL,
    teacher_name VARCHAR(30) NOT NULL,
    teacher_patronymic VARCHAR(30),
    job INT NOT NULL,
    cafedra VARCHAR(5) NOT NULL,
    academic_degree INT DEFAULT NULL,
    work_status BOOLEAN DEFAULT TRUE,
    UNIQUE NULLS NOT DISTINCT (teacher_surname, teacher_name, teacher_patronymic)
);

COMMENT ON TABLE teacher IS 'Преподаватель';
COMMENT ON COLUMN teacher.work_status IS 'Рабочий статус преподавателя. 0 - не работает в данный момент, 1 - работает.';

--- ==================================================
-- Таблица: группа
--- ==================================================
CREATE TABLE group_number (
    id_group INT PRIMARY KEY,
    cafedra VARCHAR(5) DEFAULT NULL
);

COMMENT ON TABLE group_number IS 'Группа';

--- ==================================================
-- Таблица: студент
--- ==================================================
CREATE TABLE student (
    id_student INT PRIMARY KEY,
    student_surname VARCHAR(30) NOT NULL,
    student_name VARCHAR(30) NOT NULL,
    student_patronymic VARCHAR(30),
    phone VARCHAR(20) CHECK (phone ~ '^(\+7|8)\d{10}$'),
    group_number INT NOT NULL,
    date_of_entry DATE NOT NULL,
    ending_date DATE NOT NULL,
    representative BOOLEAN DEFAULT FALSE
    CONSTRAINT check_dates CHECK (date_of_entry < ending_date),
    UNIQUE NULLS NOT DISTINCT (student_surname, student_name, student_patronymic)
); 

COMMENT ON TABLE student IS 'Студент';
COMMENT ON COLUMN student.date_of_entry IS 'Дата поступления.';
COMMENT ON COLUMN student.ending_date IS 'Дата окончания учебы.';
COMMENT ON COLUMN student.representative IS 'Является ли студент старостой группы. 0 - нет, 1 - да.';

--- ==================================================
-- Таблица: курс
--- ==================================================
CREATE TABLE course (
    id_course SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    test_course t_test NOT NULL,
    study_load INT NOT NULL CHECK (study_load > 0),
    UNIQUE (title, test_course)
);

COMMENT ON TABLE course IS 'Преподаваемая дисциплина';

--- ==================================================
-- Таблица: расписание
--- ==================================================
CREATE TABLE timetable (
    id_timetable SERIAL PRIMARY KEY,
    course INT NOT NULL,
    week_parity BOOLEAN DEFAULT NULL,
    day_of_week INT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
    time_begin TIME NOT NULL,
    time_end TIME NOT NULL,
    classroom VARCHAR(5) CHECK (classroom ~ '^(П-\d{1,2}|\d{2,3})$'),
    lesson_type t_lesson NOT NULL,
    semester INT NOT NULL CHECK (semester > 0)
    CONSTRAINT check_time CHECK (time_begin < time_end)
);

COMMENT ON TABLE timetable IS 'Расписание пар';
COMMENT ON COLUMN timetable.week_parity IS 'Четность недели. FALSE - четная, TRUE - нечетная, NULL - каждую неделю';

--- ==================================================
-- Таблица: изменения в расписании
--- ==================================================
CREATE TABLE timetable_change (
    id_timetable_change SERIAL PRIMARY KEY,
    id_timetable INT NOT NULL,
    lesson_date DATE NOT NULL,
    id_teacher INT DEFAULT NULL,
    cancel INT NOT NULL CHECK (cancel IN (0, 1, 2)),
    new_date DATE DEFAULT NULL,
    new_time TIME DEFAULT NULL,
    info TEXT
    CONSTRAINT check_timetable_change CHECK (
        (cancel = 0 AND id_teacher IS NOT NULL) OR
        (cancel = 1) OR
        (cancel = 2 AND new_date IS NOT NULL AND new_time IS NOT NULL)
    )
);

COMMENT ON TABLE timetable_change IS 'Фиксация изменений в расписании';
COMMENT ON COLUMN timetable_change.lesson_date IS 'Дата пары, которая была изменена.';
COMMENT ON COLUMN timetable_change.id_teacher IS 'Замена преподавателя.';
COMMENT ON COLUMN timetable_change.cancel IS 'Отменена/перенесена ли пара. 0 - отмены не было, 1 - отмена, 2 - перенос.';
COMMENT ON COLUMN timetable_change.new_date IS 'Новая дата пары в случае переноса.';
COMMENT ON COLUMN timetable_change.new_time IS 'Новое время пары в случае переноса.';
COMMENT ON COLUMN timetable_change.info IS 'Комментарий в произвольной форме.';

--- ==================================================
-- Таблица: связь таблиц расписание и преподаватель
--- ==================================================
CREATE TABLE timetable_teacher (
    id_timetable INT NOT NULL REFERENCES timetable(id_timetable) ON DELETE RESTRICT,
    id_teacher INT NOT NULL REFERENCES teacher(id_teacher) ON DELETE RESTRICT,
    PRIMARY KEY (id_timetable, id_teacher)
);

COMMENT ON TABLE timetable_teacher IS 'Связь многие-ко-многим между расписанием и преподавателем.';

--- ==================================================
-- Таблица: связь таблиц расписание и группа
--- ==================================================
CREATE TABLE timetable_group (
    id_timetable INT NOT NULL REFERENCES timetable(id_timetable) ON DELETE RESTRICT,
    id_group INT NOT NULL REFERENCES group_number(id_group) ON DELETE RESTRICT,
    PRIMARY KEY (id_timetable, id_group)
);

COMMENT ON TABLE timetable_group IS 'Связь многие-ко-многим между расписанием и группой.';


-- Добавление внешних ключей
ALTER TABLE teacher
    ADD CONSTRAINT fk_teacher_job FOREIGN KEY(job)
        REFERENCES job_desc(id_job)
        ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE teacher
    ADD CONSTRAINT fk_teacher_cafedra FOREIGN KEY(cafedra)
        REFERENCES cafedra(id_caf)
        ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE teacher
    ADD CONSTRAINT fk_teacher_academic_deg FOREIGN KEY(academic_degree)
        REFERENCES academic_degree(id_degree)
        ON DELETE SET DEFAULT ON UPDATE CASCADE;

ALTER TABLE group_number
    ADD CONSTRAINT fk_group_cafedra FOREIGN KEY(cafedra)
        REFERENCES cafedra(id_caf)
        ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE student
    ADD CONSTRAINT fk_student_group FOREIGN KEY(group_number)
        REFERENCES group_number(id_group)
        ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE timetable
    ADD CONSTRAINT fk_timetable_course FOREIGN KEY(course)
        REFERENCES course(id_course)
        ON DELETE RESTRICT ON UPDATE CASCADE;
 
ALTER TABLE timetable_change
    ADD CONSTRAINT fk_timetable_change FOREIGN KEY(id_timetable)
        REFERENCES timetable(id_timetable)
        ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE timetable_change
    ADD CONSTRAINT fk_timetable_change_teacher FOREIGN KEY(id_teacher)
        REFERENCES teacher(id_teacher)
        ON DELETE SET DEFAULT ON UPDATE CASCADE;


-- Вставка данных в БД
INSERT INTO academic_degree (title) VALUES
    ('канд. физ.-мат. наук'),
    ('чл.-корр. РАН');

INSERT INTO job_desc (title) VALUES
    ('Преподаватель'),
    ('Доцент'),
    ('Заведующий кафедрой'),
    ('Аспирант'),
    ('Ассистент');

INSERT INTO cafedra (id_caf, title) VALUES
    ('СП', 'Системного программирования'),
    ('АНИ', 'Автоматизации научных исследований'),
    ('ММП', 'Математических методов прогнозирования'),
    ('МФ', 'Математической физики'),
    ('АСВК', 'Автоматизации систем вычислительных комплексов'),
    ('ИИТ', 'Интеллектуальных информационных технологий');

INSERT INTO teacher (teacher_surname, teacher_name, teacher_patronymic, job, cafedra, academic_degree) VALUES
    ('Яцков', 'Александр', 'Константинович', 1, 'СП', NULL),
    ('Теймуразов', 'Кирилл', 'Борисович', 1, 'СП', NULL),
    ('Иновенков', 'Игорь', 'Николаевич', 2, 'АНИ', 1),
    ('Гуров', 'Сергей', 'Исаевич', 2, 'ММП', 1),
    ('Головина', 'Светлана', 'Георгиевна', 2, 'МФ', 1),
    ('Хорошилов', 'Алексей', 'Владимирович', 2, 'СП', 1),
    ('Чепцов', 'Виталий', 'Юрьевич', 1, 'СП', NULL),
    ('Басков', 'Евгений', 'Сергеевич', 4, 'СП', NULL),
    ('Смелянский', 'Руслан', 'Леонидович', 3, 'АСВК', 2),
    ('Бахтин', 'Владимир', 'Александрович', 2, 'СП', 1),
    ('Тарлапан', 'Олег', 'Анатольевич', 5, 'СП', 1),
    ('Петровский', 'Михаил', 'Игоревич', 2, 'ИИТ', 1),
    ('Бабернов', 'Василий', 'Вячеславович', 1, 'АСВК', NULL);

INSERT INTO group_number (id_group, cafedra) VALUES
    (327, 'СП'),
    (328, 'СП');

INSERT INTO student (id_student, student_surname, student_name, student_patronymic, phone, group_number, date_of_entry, ending_date, representative) VALUES
    (2230062, 'Беляев', 'Никита', 'Алексеевич', '89291234567', 327, '04.08.2023', '31.05.2027', FALSE),
    (2230095, 'Глущенко', 'Анна', 'Сергеевна', '89261234567', 327, '04.08.2023', '31.05.2027', TRUE),
    (2230190, 'Митрофанов', 'Андрей', 'Сергеевич', '89281234567', 327, '04.08.2023', '31.05.2027', FALSE),
    (2230011, 'Титов', 'Денис', 'Дмитриевич', '89161234567', 327, '04.08.2023', '31.05.2027', FALSE),
    (2230300, 'Шайхутдинова', 'Алина', 'Маратовна', '89281234578', 327, '04.08.2023', '31.05.2027', FALSE),
    (2230111, 'Есаулова', 'Диана', 'Сергеевна', '89291234556', 328, '04.08.2023', '31.05.2027', FALSE),
    (2230738, 'Кашкин', 'Роман', 'Алексеевич', '89261234589', 328, '04.08.2023', '31.05.2027', FALSE),
    (2220149, 'Курганский', 'Леонид', 'Олегович', '89291234576', 328, '04.08.2022', '31.05.2027', FALSE),
    (2230192, 'Моисейкин', 'Андрей', 'Денисович', '89161234533', 328, '04.08.2023', '31.05.2027', TRUE),
    (2230010, 'Терентьева', 'Мария', 'Александровна', '89381234578', 328, '04.08.2023', '31.05.2027', FALSE);

INSERT INTO course (title, test_course, study_load) VALUES
    ('Практикум на ЭВМ', 'зачет с оценкой', 72),
    ('Уравнения математической физики', 'экзамен', 144),
    ('Базы данных', 'экзамен', 108),
    ('Введение в сети ЭВМ', 'экзамен', 180),
    ('Методы машинного обучения', 'зачет', 72),
    ('Суперкомпьютеры и параллельная обработка данных', 'экзамен', 108),
    ('Прикладная алгебра', 'экзамен', 108),
    ('Констуирование ядра операционной системы', 'экзамен', 144);

INSERT INTO timetable (course, week_parity, day_of_week, time_begin, time_end, classroom, lesson_type, semester) VALUES
    (1, NULL, 1, '8:45:00', '10:20:00', '582', 'семинар', 5),
    (2, NULL, 1, '10:30:00', '12:05:00', 'П-13', 'лекция', 5),
    (7, NULL, 1, '12:50:00', '14:25:00', 'П-8', 'лекция', 5),
    (2, NULL, 2, '10:30:00', '12:05:00', '72', 'семинар', 5),
    (2, NULL, 2, '12:15:00', '13:45:00', '696', 'семинар', 5),
    (8, NULL, 2, '14:35:00', '16:10:00', '510', 'лекция', 5),
    (8, NULL, 2, '16:20:00', '17:55:00', '510', 'семинар', 5),
    (4, NULL, 3, '8:45:00', '10:20:00', 'П-14', 'лекция', 5),
    (4, NULL, 3, '10:30:00', '12:05:00', 'П-14', 'лекция', 5),
    (5, NULL, 3, '12:50:00', '14:25:00', 'П-12', 'лекция', 5),
    (6, FALSE, 4, '8:45:00', '10:20:00', 'П-8', 'лекция', 5),
    (6, NULL, 4, '10:30:00', '12:05:00', 'П-8', 'лекция', 5),
    (3, NULL, 4, '12:50:00', '14:25:00', 'П-6', 'лекция', 5),
    (3, NULL, 4, '14:35:00', '16:10:00', 'П-6', 'лекция', 5);

INSERT INTO timetable_teacher (id_timetable, id_teacher) VALUES
    (1, 1),
    (1, 2),
    (2, 3),
    (3, 4),
    (4, 3),
    (5, 5),
    (6, 6),
    (6, 7),
    (6, 8),
    (7, 6),
    (7, 7),
    (7, 8),
    (8, 9),
    (9, 9),
    (10, 12),
    (11, 10),
    (12, 10),
    (13, 11),
    (14, 11);

INSERT INTO timetable_group (id_timetable, id_group) VALUES
    (1, 327),
    (1, 328),
    (2, 327),
    (2, 328),
    (3, 327),
    (3, 328),
    (4, 328),
    (5, 327),
    (6, 327),
    (6, 328),
    (7, 327),
    (7, 328),
    (8, 327),
    (8, 328),
    (9, 327),
    (9, 328),
    (10, 327),
    (10, 328),
    (11, 327),
    (11, 328),
    (12, 327),
    (12, 328),
    (13, 327),
    (13, 328),
    (14, 327),
    (14, 328);

INSERT INTO timetable_change (id_timetable, lesson_date, id_teacher, cancel, new_date, new_time, info) VALUES
    (3, '06.10.2025', NULL, 1, NULL, NULL, ''),
    (5, '21.10.2025', NULL, 2, '29.10.2025', '14:35:00', 'Преподаватель уехал на неделю вести пары в филиал'),
    (8, '24.09.2025', 13, 0, NULL, NULL, 'Преподаватель на конференции'),
    (9, '24.09.2025', 13, 0, NULL, NULL, 'Преподаватель на конференции');