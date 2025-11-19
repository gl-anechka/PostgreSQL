import csv
import random
from datetime import time, timedelta, datetime

num_rows = 100_000_000
dates = list(range(1, 20_211))              # date_id
with open('temp_student.csv') as f:
    reader = csv.reader(f)
    students = [row[0] for row in reader]   # student_id
teachers = list(range(1, 1_000_001))        # teacher_id
courses = list(range(1, 1_000_001))         # course_id

lesson_types = ['lecture', 'seminar', 'exam', 'test']

with open('temp_fact.csv', 'w', newline='') as f:
    writer = csv.writer(f)
    for _ in range(num_rows):
        date_id = random.choice(dates)
        student_id = random.choice(students)
        teacher_id = random.choice(teachers)
        course_id = random.choice(courses)
        lesson_type = random.choices(lesson_types, weights=[0.5,0.5,0.1,0.1])[0]
        cancelled = random.random() < 0.02
        start_hour = random.randint(8, 18)
        start_minute = random.choice([0,15,30,45])
        duration = random.choice([45, 90, 135, 180])
        t_begin = time(start_hour, start_minute)
        t_end = (datetime.combine(datetime.today(), t_begin) + timedelta(minutes=duration)).time()
        classroom = str(random.randint(1,800)).zfill(3)
        attendance = random.random() < 0.9
        grade = round(random.uniform(0,5),2)
        duration_minutes = duration
        academic_hours = (duration + 44)//45
        is_credited = random.random() < 0.95
        writer.writerow([date_id, student_id, teacher_id, course_id, lesson_type, cancelled,
                         t_begin, t_end, classroom, attendance, grade, duration_minutes,
                         academic_hours, is_credited])