SELECT 
    d.academic_year,
    d.semester,
    ROUND(AVG(CASE WHEN f.attendance THEN 1 ELSE 0 END) * 100, 2) AS attendance_rate
FROM fact_student_performance f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.academic_year, d.semester
ORDER BY d.academic_year, d.semester;
