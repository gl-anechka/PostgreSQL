SELECT 
    s.group_num,
    s.study_status,
    COUNT(*) AS count_students,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percent
FROM dim_student s
GROUP BY s.group_num, s.study_status
ORDER BY percent DESC;
