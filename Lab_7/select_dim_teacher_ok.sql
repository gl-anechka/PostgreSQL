SELECT teacher_id,
       teacher_surname || ' ' || teacher_name AS full_name,
       cafedra_name,
       work_status
FROM dim_teacher
WHERE work_status = 'active'
ORDER BY teacher_id
LIMIT 10;