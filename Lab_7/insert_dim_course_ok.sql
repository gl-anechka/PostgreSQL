INSERT INTO dim_course (course_title, course_description, test_type, study_load)
VALUES ('Modern Databases', 'Practical course on PostgreSQL and Analytics', 'exam', 120);

SELECT * FROM dim_course WHERE course_title = 'Modern Databases';