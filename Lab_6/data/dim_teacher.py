import csv
import json
import random

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
    course_list = [row['title'].strip() for row in reader if row['title'].strip()]

# научные интересы
with open('interest.csv', encoding='utf-8', newline='') as f:
    reader = csv.DictReader(f, delimiter=';')
    interests = [row['title'].strip() for row in reader if row['title'].strip()]

# проекты
with open('project.csv', encoding='utf-8', newline='') as f:
    reader = csv.DictReader(f, delimiter=';')
    projects = [row['title'].strip() for row in reader if row['title'].strip()]

num_teachers = 1_000_000
job_titles = ['Professor', 'Docent', 'Assistant', 'Teacher', 'Postgraduate']
degrees = ['Doctor of Science', 'Candidate of Science', 'None']

with open('temp_teacher.csv', 'w', newline='', encoding='utf-8') as f:
    writer = csv.writer(f)

    for i in range(1, num_teachers + 1):
        name = random.choice(names)
        teacher_surname = name['real_surname']
        teacher_name = name['real_name']
        teacher_patronymic = name['real_patronymic']

        job_title = job_titles[i % len(job_titles)]
        cafedra_name = random.choice(cafedras)
        academic_degree = degrees[i % len(degrees)]
        work_status = 'retired' if i % 100000 == 0 else 'active'

        publications = random.randint(0, 10)
        teacher_projects = random.sample(projects, k=publications)
        num_interests = random.randint(2, 6)
        teacher_interests = random.sample(interests, k=min(num_interests, len(interests)))

        teacher_metadata = json.dumps({
            'publications': publications,
            'projects': teacher_projects,
            'interests': teacher_interests
        })

        num_subjects = random.randint(1, 7)
        subjects = random.sample(course_list, k=min(num_subjects, len(course_list)))
        subjects_taught = '{' + ','.join('"' + s.replace('"','\\"') + '"' for s in subjects) + '}'

        writer.writerow([
            teacher_surname,
            teacher_name,
            teacher_patronymic,
            job_title,
            cafedra_name,
            academic_degree,
            teacher_metadata,
            subjects_taught,
            work_status
        ])