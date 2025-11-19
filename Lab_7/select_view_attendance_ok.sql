SELECT *
FROM group_attendance
WHERE academic_year = '2024/2025' AND month_number = 9
ORDER BY attendance_percent, group_num DESC;