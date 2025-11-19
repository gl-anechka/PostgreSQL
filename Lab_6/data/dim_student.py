import csv
import random
import json
from datetime import date

# фио
with open('data.csv', encoding='utf-8', newline='') as f:
    names = list(csv.DictReader(f))

# кафедры
with open('cafedra.csv', encoding='utf-8', newline='') as f:
    reader = csv.DictReader(f, delimiter=';')
    cafedras = [row['title'].strip() for row in reader if row['title'].strip()]

# курсы
with open('course.csv', encoding='utf-8', newline='') as f:
    reader = csv.DictReader(f, delimiter=';')
    courses = [row['title'].strip() for row in reader if row['title'].strip()]

num_students = 1_000_000

with open('temp_student.csv', 'w', newline='', encoding='utf-8') as f:
    writer = csv.writer(f)

    for num in range(1, num_students + 1):
        year_enrolled = random.randint(1970, 2020)
        student_id = (year_enrolled % 100) * 1000000 + num

        name = random.choice(names)
        student_surname = name['real_surname']
        student_name = name['real_name']
        student_patronymic = name['real_patronymic']

        phone = f"+7{str(random.randint(0,9999999999)).zfill(10)}"
        group_num = random.randint(101, 601)
        cafedra_name = random.choice(cafedras)
        head_of_group = (num % 100 == 0)
        enrollment_date = date(year_enrolled, 8, 9)
        graduation_date = None if head_of_group else date(year_enrolled + 4, 6, 30)
        study_status = 'academic_leave' if num % 1000 == 0 else 'active'

        grades_list = []
        for _ in range(7):
            subject = random.choice(courses)
            if random.random() < 0.8:
                grade = random.randint(3, 5)
            else:
                grade = 2
            grades_list.append({"subject": subject, "grade": grade})
        grades = json.dumps({"grades": grades_list})

        previous_education = json.dumps({
            "school": {
                "number": f"School {random.randint(1,10000)}",
                "year_finished": year_enrolled - random.randint(1,3),
                "certificate_num": str(random.randint(10**13, 10**14-1)).zfill(14)
            }
        })

        writer.writerow([
            student_id,
            student_surname,
            student_name,
            student_patronymic,
            phone,
            group_num,
            cafedra_name,
            head_of_group,
            enrollment_date,
            graduation_date,
            study_status,
            previous_education,
            grades
        ])