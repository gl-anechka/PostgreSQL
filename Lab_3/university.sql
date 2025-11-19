-- Ñêðèïò äëÿ ñîçäàíèÿ ÁÄ óíèâåðñèòåòà

DROP DATABASE IF EXISTS university;

CREATE DATABASE university;

\connect university;


-- Ïîëüçîâàòåëüñêèå òèïû äàííûõ
CREATE TYPE t_lesson AS ENUM ('ëåêöèÿ', 'ñåìèíàð', 'ýêçàìåí', 'çà÷åò');
CREATE TYPE t_test AS ENUM ('çà÷åò', 'ýêçàìåí', 'çà÷åò ñ îöåíêîé');


--- ==================================================
-- Òàáëèöà: ó÷åíûå ñòåïåíè
--- ==================================================
CREATE TABLE academic_degree (
    id_degree SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL UNIQUE
);

COMMENT ON TABLE academic_degree IS 'Ó÷åíàÿ ñòåïåíü ïðåïîäàâàòåëÿ';

--- ==================================================
-- Òàáëèöà: äîëæíîñòè
--- ==================================================
CREATE TABLE job_desc (
    id_job SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL UNIQUE
);

COMMENT ON TABLE job_desc IS 'Äîëæíîñòü ïðåïîäàâàòåëÿ íà êàôåäðå';

--- ==================================================
-- Òàáëèöà: êàôåäðà
--- ==================================================
CREATE TABLE cafedra (
    id_caf VARCHAR(5) PRIMARY KEY,
    title VARCHAR(255) NOT NULL UNIQUE
);

COMMENT ON TABLE cafedra IS 'Êàôåäðà';

--- ==================================================
-- Òàáëèöà: ïðåïîäàâàòåëü
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

COMMENT ON TABLE teacher IS 'Ïðåïîäàâàòåëü';
COMMENT ON COLUMN teacher.work_status IS 'Ðàáî÷èé ñòàòóñ ïðåïîäàâàòåëÿ. 0 - íå ðàáîòàåò â äàííûé ìîìåíò, 1 - ðàáîòàåò.';

--- ==================================================
-- Òàáëèöà: ãðóïïà
--- ==================================================
CREATE TABLE group_number (
    id_group INT PRIMARY KEY,
    cafedra VARCHAR(5) DEFAULT NULL
);

COMMENT ON TABLE group_number IS 'Ãðóïïà';

--- ==================================================
-- Òàáëèöà: ñòóäåíò
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

COMMENT ON TABLE student IS 'Ñòóäåíò';
COMMENT ON COLUMN student.date_of_entry IS 'Äàòà ïîñòóïëåíèÿ.';
COMMENT ON COLUMN student.ending_date IS 'Äàòà îêîí÷àíèÿ ó÷åáû.';
COMMENT ON COLUMN student.representative IS 'ßâëÿåòñÿ ëè ñòóäåíò ñòàðîñòîé ãðóïïû. 0 - íåò, 1 - äà.';

--- ==================================================
-- Òàáëèöà: êóðñ
--- ==================================================
CREATE TABLE course (
    id_course SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    test_course t_test NOT NULL,
    study_load INT NOT NULL CHECK (study_load > 0),
    UNIQUE (title, test_course)
);

COMMENT ON TABLE course IS 'Ïðåïîäàâàåìàÿ äèñöèïëèíà';

--- ==================================================
-- Òàáëèöà: ðàñïèñàíèå
--- ==================================================
CREATE TABLE timetable (
    id_timetable SERIAL PRIMARY KEY,
    course INT NOT NULL,
    week_parity BOOLEAN DEFAULT NULL,
    day_of_week INT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
    time_begin TIME NOT NULL,
    time_end TIME NOT NULL,
    classroom VARCHAR(5) CHECK (classroom ~ '^(Ï-\d{1,2}|\d{2,3})$'),
    lesson_type t_lesson NOT NULL,
    semester INT NOT NULL CHECK (semester > 0)
    CONSTRAINT check_time CHECK (time_begin < time_end)
);

COMMENT ON TABLE timetable IS 'Ðàñïèñàíèå ïàð';
COMMENT ON COLUMN timetable.week_parity IS '×åòíîñòü íåäåëè. FALSE - ÷åòíàÿ, TRUE - íå÷åòíàÿ, NULL - êàæäóþ íåäåëþ';

--- ==================================================
-- Òàáëèöà: èçìåíåíèÿ â ðàñïèñàíèè
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

COMMENT ON TABLE timetable_change IS 'Ôèêñàöèÿ èçìåíåíèé â ðàñïèñàíèè';
COMMENT ON COLUMN timetable_change.lesson_date IS 'Äàòà ïàðû, êîòîðàÿ áûëà èçìåíåíà.';
COMMENT ON COLUMN timetable_change.id_teacher IS 'Çàìåíà ïðåïîäàâàòåëÿ.';
COMMENT ON COLUMN timetable_change.cancel IS 'Îòìåíåíà/ïåðåíåñåíà ëè ïàðà. 0 - îòìåíû íå áûëî, 1 - îòìåíà, 2 - ïåðåíîñ.';
COMMENT ON COLUMN timetable_change.new_date IS 'Íîâàÿ äàòà ïàðû â ñëó÷àå ïåðåíîñà.';
COMMENT ON COLUMN timetable_change.new_time IS 'Íîâîå âðåìÿ ïàðû â ñëó÷àå ïåðåíîñà.';
COMMENT ON COLUMN timetable_change.info IS 'Êîììåíòàðèé â ïðîèçâîëüíîé ôîðìå.';

--- ==================================================
-- Òàáëèöà: ñâÿçü òàáëèö ðàñïèñàíèå è ïðåïîäàâàòåëü
--- ==================================================
CREATE TABLE timetable_teacher (
    id_timetable INT NOT NULL REFERENCES timetable(id_timetable) ON DELETE RESTRICT,
    id_teacher INT NOT NULL REFERENCES teacher(id_teacher) ON DELETE RESTRICT,
    PRIMARY KEY (id_timetable, id_teacher)
);

COMMENT ON TABLE timetable_teacher IS 'Ñâÿçü ìíîãèå-êî-ìíîãèì ìåæäó ðàñïèñàíèåì è ïðåïîäàâàòåëåì.';

--- ==================================================
-- Òàáëèöà: ñâÿçü òàáëèö ðàñïèñàíèå è ãðóïïà
--- ==================================================
CREATE TABLE timetable_group (
    id_timetable INT NOT NULL REFERENCES timetable(id_timetable) ON DELETE RESTRICT,
    id_group INT NOT NULL REFERENCES group_number(id_group) ON DELETE RESTRICT,
    PRIMARY KEY (id_timetable, id_group)
);

COMMENT ON TABLE timetable_group IS 'Ñâÿçü ìíîãèå-êî-ìíîãèì ìåæäó ðàñïèñàíèåì è ãðóïïîé.';


-- Äîáàâëåíèå âíåøíèõ êëþ÷åé
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


-- Âñòàâêà äàííûõ â ÁÄ
INSERT INTO academic_degree (title) VALUES
    ('êàíä. ôèç.-ìàò. íàóê'),
    ('÷ë.-êîðð. ÐÀÍ');

INSERT INTO job_desc (title) VALUES
    ('Ïðåïîäàâàòåëü'),
    ('Äîöåíò'),
    ('Çàâåäóþùèé êàôåäðîé'),
    ('Àñïèðàíò'),
    ('Àññèñòåíò');

INSERT INTO cafedra (id_caf, title) VALUES
    ('ÑÏ', 'Ñèñòåìíîãî ïðîãðàììèðîâàíèÿ'),
    ('ÀÍÈ', 'Àâòîìàòèçàöèè íàó÷íûõ èññëåäîâàíèé'),
    ('ÌÌÏ', 'Ìàòåìàòè÷åñêèõ ìåòîäîâ ïðîãíîçèðîâàíèÿ'),
    ('ÌÔ', 'Ìàòåìàòè÷åñêîé ôèçèêè'),
    ('ÀÑÂÊ', 'Àâòîìàòèçàöèè ñèñòåì âû÷èñëèòåëüíûõ êîìïëåêñîâ'),
    ('ÈÈÒ', 'Èíòåëëåêòóàëüíûõ èíôîðìàöèîííûõ òåõíîëîãèé');

INSERT INTO teacher (teacher_surname, teacher_name, teacher_patronymic, job, cafedra, academic_degree) VALUES
    ('ßöêîâ', 'Àëåêñàíäð', 'Êîíñòàíòèíîâè÷', 1, 'ÑÏ', NULL),
    ('Òåéìóðàçîâ', 'Êèðèëë', 'Áîðèñîâè÷', 1, 'ÑÏ', NULL),
    ('Èíîâåíêîâ', 'Èãîðü', 'Íèêîëàåâè÷', 2, 'ÀÍÈ', 1),
    ('Ãóðîâ', 'Ñåðãåé', 'Èñàåâè÷', 2, 'ÌÌÏ', 1),
    ('Ãîëîâèíà', 'Ñâåòëàíà', 'Ãåîðãèåâíà', 2, 'ÌÔ', 1),
    ('Õîðîøèëîâ', 'Àëåêñåé', 'Âëàäèìèðîâè÷', 2, 'ÑÏ', 1),
    ('×åïöîâ', 'Âèòàëèé', 'Þðüåâè÷', 1, 'ÑÏ', NULL),
    ('Áàñêîâ', 'Åâãåíèé', 'Ñåðãååâè÷', 4, 'ÑÏ', NULL),
    ('Ñìåëÿíñêèé', 'Ðóñëàí', 'Ëåîíèäîâè÷', 3, 'ÀÑÂÊ', 2),
    ('Áàõòèí', 'Âëàäèìèð', 'Àëåêñàíäðîâè÷', 2, 'ÑÏ', 1),
    ('Òàðëàïàí', 'Îëåã', 'Àíàòîëüåâè÷', 5, 'ÑÏ', 1),
    ('Ïåòðîâñêèé', 'Ìèõàèë', 'Èãîðåâè÷', 2, 'ÈÈÒ', 1),
    ('Áàáåðíîâ', 'Âàñèëèé', 'Âÿ÷åñëàâîâè÷', 1, 'ÀÑÂÊ', NULL);

INSERT INTO group_number (id_group, cafedra) VALUES
    (327, 'ÑÏ'),
    (328, 'ÑÏ');

INSERT INTO student (id_student, student_surname, student_name, student_patronymic, phone, group_number, date_of_entry, ending_date, representative) VALUES
    (2230062, 'Áåëÿåâ', 'Íèêèòà', 'Àëåêñååâè÷', '89291234567', 327, '04.08.2023', '31.05.2027', FALSE),
    (2230095, 'Ãëóùåíêî', 'Àííà', 'Ñåðãååâíà', '89261234567', 327, '04.08.2023', '31.05.2027', TRUE),
    (2230190, 'Ìèòðîôàíîâ', 'Àíäðåé', 'Ñåðãååâè÷', '89281234567', 327, '04.08.2023', '31.05.2027', FALSE),
    (2230011, 'Òèòîâ', 'Äåíèñ', 'Äìèòðèåâè÷', '89161234567', 327, '04.08.2023', '31.05.2027', FALSE),
    (2230300, 'Øàéõóòäèíîâà', 'Àëèíà', 'Ìàðàòîâíà', '89281234578', 327, '04.08.2023', '31.05.2027', FALSE),
    (2230111, 'Åñàóëîâà', 'Äèàíà', 'Ñåðãååâíà', '89291234556', 328, '04.08.2023', '31.05.2027', FALSE),
    (2230738, 'Êàøêèí', 'Ðîìàí', 'Àëåêñååâè÷', '89261234589', 328, '04.08.2023', '31.05.2027', FALSE),
    (2220149, 'Êóðãàíñêèé', 'Ëåîíèä', 'Îëåãîâè÷', '89291234576', 328, '04.08.2022', '31.05.2027', FALSE),
    (2230192, 'Ìîèñåéêèí', 'Àíäðåé', 'Äåíèñîâè÷', '89161234533', 328, '04.08.2023', '31.05.2027', TRUE),
    (2230010, 'Òåðåíòüåâà', 'Ìàðèÿ', 'Àëåêñàíäðîâíà', '89381234578', 328, '04.08.2023', '31.05.2027', FALSE);

INSERT INTO course (title, test_course, study_load) VALUES
    ('Ïðàêòèêóì íà ÝÂÌ', 'çà÷åò ñ îöåíêîé', 72),
    ('Óðàâíåíèÿ ìàòåìàòè÷åñêîé ôèçèêè', 'ýêçàìåí', 144),
    ('Áàçû äàííûõ', 'ýêçàìåí', 108),
    ('Ââåäåíèå â ñåòè ÝÂÌ', 'ýêçàìåí', 180),
    ('Ìåòîäû ìàøèííîãî îáó÷åíèÿ', 'çà÷åò', 72),
    ('Ñóïåðêîìïüþòåðû è ïàðàëëåëüíàÿ îáðàáîòêà äàííûõ', 'ýêçàìåí', 108),
    ('Ïðèêëàäíàÿ àëãåáðà', 'ýêçàìåí', 108),
    ('Êîíñòóèðîâàíèå ÿäðà îïåðàöèîííîé ñèñòåìû', 'ýêçàìåí', 144);

INSERT INTO timetable (course, week_parity, day_of_week, time_begin, time_end, classroom, lesson_type, semester) VALUES
    (1, NULL, 1, '8:45:00', '10:20:00', '582', 'ñåìèíàð', 5),
    (2, NULL, 1, '10:30:00', '12:05:00', 'Ï-13', 'ëåêöèÿ', 5),
    (7, NULL, 1, '12:50:00', '14:25:00', 'Ï-8', 'ëåêöèÿ', 5),
    (2, NULL, 2, '10:30:00', '12:05:00', '72', 'ñåìèíàð', 5),
    (2, NULL, 2, '12:15:00', '13:45:00', '696', 'ñåìèíàð', 5),
    (8, NULL, 2, '14:35:00', '16:10:00', '510', 'ëåêöèÿ', 5),
    (8, NULL, 2, '16:20:00', '17:55:00', '510', 'ñåìèíàð', 5),
    (4, NULL, 3, '8:45:00', '10:20:00', 'Ï-14', 'ëåêöèÿ', 5),
    (4, NULL, 3, '10:30:00', '12:05:00', 'Ï-14', 'ëåêöèÿ', 5),
    (5, NULL, 3, '12:50:00', '14:25:00', 'Ï-12', 'ëåêöèÿ', 5),
    (6, FALSE, 4, '8:45:00', '10:20:00', 'Ï-8', 'ëåêöèÿ', 5),
    (6, NULL, 4, '10:30:00', '12:05:00', 'Ï-8', 'ëåêöèÿ', 5),
    (3, NULL, 4, '12:50:00', '14:25:00', 'Ï-6', 'ëåêöèÿ', 5),
    (3, NULL, 4, '14:35:00', '16:10:00', 'Ï-6', 'ëåêöèÿ', 5);

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
    (5, '21.10.2025', NULL, 2, '29.10.2025', '14:35:00', 'Ïðåïîäàâàòåëü óåõàë íà íåäåëþ âåñòè ïàðû â ôèëèàë'),
    (8, '24.09.2025', 13, 0, NULL, NULL, 'Ïðåïîäàâàòåëü íà êîíôåðåíöèè'),
    (9, '24.09.2025', 13, 0, NULL, NULL, 'Ïðåïîäàâàòåëü íà êîíôåðåíöèè');
