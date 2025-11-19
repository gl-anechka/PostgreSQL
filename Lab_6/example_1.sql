SELECT 
    t.teacher_surname,
    t.teacher_name,
    AVG(f.grade) AS avg_grade
FROM fact_student_performance f
JOIN dim_teacher t ON f.teacher_id = t.teacher_id
GROUP BY t.teacher_surname, t.teacher_name
ORDER BY avg_grade DESC;
