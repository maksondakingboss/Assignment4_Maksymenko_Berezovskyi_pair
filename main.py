import random
from datetime import date, timedelta
import psycopg2
from psycopg2 import Error
from psycopg2.extras import execute_values
from faker import Faker
import time
from dotenv import load_dotenv
import os

load_dotenv()

HOST = os.getenv('DB_HOST')
USER = os.getenv('DB_USER')
PASSWORD = os.getenv('DB_PASSWORD')
DATABASE = os.getenv('DB_NAME')
PORT = os.getenv('DB_PORT')
# Кількість рядків для масової генерації
TARGET_GRADES = 500_000
TARGET_ATTENDANCE = 200_000
BATCH_SIZE = 10_000

fake = Faker("uk_UA")

def create_connection():
    try:
        connection = psycopg2.connect(
            host=HOST, port=PORT, user=USER, password=PASSWORD, dbname=DATABASE
        )
        print("✅ Підключення до БД успішне.")
        return connection
    except Error as e:
        print(f"❌ Помилка підключення: {e}")
        return None

def clear_database(connection):
    print("🧹 Очищення старих даних...")
    tables = [
        "homework", "attendance", "grades", "student_parents", "student_profiles",
        "lessons_schedule", "students", "school_classes", "teachers_subjects",
        "subjects", "parents", "teachers"
    ]
    query = f"TRUNCATE TABLE {', '.join(tables)} RESTART IDENTITY CASCADE;"
    with connection.cursor() as cursor:
        cursor.execute(query)
    connection.commit()

def bulk_insert_get_ids(connection, query, data):
    with connection.cursor() as cursor:
        result = execute_values(cursor, query, data, fetch=True)
        ids = [row[0] for row in result]
    connection.commit()
    return ids

def bulk_insert(connection, query, data):
    with connection.cursor() as cursor:
        execute_values(cursor, query, data)
    connection.commit()

def seed_data(connection):
    clear_database(connection)
    start_time = time.time()

    # 1. ВЧИТЕЛІ (teachers)
    print("👨‍🏫 Генерація вчителів (50)...")
    teachers_data = [(fake.first_name(), fake.last_name(), fake.unique.email(), fake.phone_number()[:20], True) for _ in range(50)]
    t_ids = bulk_insert_get_ids(connection, "INSERT INTO teachers (first_name, last_name, email, phone, active) VALUES %s RETURNING id", teachers_data)

    # 2. ПРЕДМЕТИ (subjects)
    print("📚 Генерация предметів (15)...")
    subject_names = ["Українська мова", "Математика", "Історія України", "Всесвітня історія", "Фізика", "Хімія", "Біологія", "Англійська мова", "Географія", "Інформатика", "Мистецтво", "Фізична культура", "Захист України", "Правознавство", "Література"]
    subjects_data = [(name, f"Опис для {name}") for name in subject_names]
    sub_ids = bulk_insert_get_ids(connection, "INSERT INTO subjects (subject_name, description) VALUES %s RETURNING id", subjects_data)

    # 3. ВЧИТЕЛІ-ПРЕДМЕТИ (teachers_subjects) - Зв'язок M:M
    print("🔗 Прив'язка вчителів до предметів (M:M)...")
    ts_data = set()
    for t_id in t_ids:
        for sub_id in random.sample(sub_ids, k=random.randint(1, 3)): # Кожен вчитель веде 1-3 предмети
            ts_data.add((t_id, sub_id))
    bulk_insert(connection, "INSERT INTO teachers_subjects (teacher_id, subject_id) VALUES %s ON CONFLICT DO NOTHING", list(ts_data))

    # 4. БАТЬКИ (parents)
    print("👪 Генерация батьків (800)...")
    parents_data = [(fake.first_name(), fake.last_name(), fake.unique.email(), fake.phone_number()[:20]) for _ in range(800)]
    p_ids = bulk_insert_get_ids(connection, "INSERT INTO parents (first_name, last_name, email, phone) VALUES %s RETURNING id", parents_data)

    # 5. КЛАСИ (school_classes)
    print("🏫 Генерация класів (33)...")
    classes_data = []
    letters = ["А", "Б", "В"]
    t_pool = t_ids.copy()
    random.shuffle(t_pool)
    for grade in range(1, 12):
        for letter in letters:
            classes_data.append((f"{grade}-{letter}", grade, t_pool.pop()))
    class_ids = bulk_insert_get_ids(connection, "INSERT INTO school_classes (class_name, grade_level, homeroom_teacher_id) VALUES %s RETURNING id", classes_data)

    # 6. УЧНІ (students) та ПРОФІЛІ (student_profiles - 1:1)
    print("🎓 Генерация учнів та їх профілів (~1000)...")
    students_data = []
    for cid in class_ids:
        for _ in range(30):
            birth_date = fake.date_of_birth(minimum_age=6, maximum_age=17)
            students_data.append((fake.first_name(), fake.last_name(), birth_date, cid, True))

    s_ids = bulk_insert_get_ids(connection, "INSERT INTO students (first_name, last_name, birth_date, class_id, active) VALUES %s RETURNING id", students_data)

    profiles_data = [(sid, "Алергія на пилок" if random.random() < 0.1 else None, fake.name(), fake.phone_number()[:20]) for sid in s_ids]
    bulk_insert(connection, "INSERT INTO student_profiles (student_id, medical_notes, emergency_contact_name, emergency_contact_phone) VALUES %s", profiles_data)

    # 7. ЗВ'ЯЗОК БАТЬКИ-УЧНІ (student_parents - M:M)
    print("👨‍👩‍👦 Прив'язка батьків до учнів...")
    sp_data = []
    for sid in s_ids:
        assigned_parents = random.sample(p_ids, k=random.choice([1, 2])) # 1 або 2 батьків у дитини
        for pid in assigned_parents:
            sp_data.append((sid, pid, 'parent'))
    bulk_insert(connection, "INSERT INTO student_parents (student_id, parent_id, relationship) VALUES %s ON CONFLICT DO NOTHING", sp_data)

    # 8. РОЗКЛАД (lessons_schedule)
    print("📅 Генерація розкладу...")
    schedule_data = []
    week_days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']
    for cid in class_ids:
        for day in week_days:
            start_hour = 8
            for _ in range(random.randint(4, 6)): # 4-6 уроків на день
                schedule_data.append((cid, random.choice(sub_ids), random.choice(t_ids), day, f"{start_hour:02d}:00:00", f"{start_hour}:45:00"))
                start_hour += 1
    ls_ids = bulk_insert_get_ids(connection, "INSERT INTO lessons_schedule (class_id, subject_id, teacher_id, week_day, start_time, end_time) VALUES %s RETURNING id", schedule_data)

    # 9. ДОМАШНІ ЗАВДАННЯ (homework)
    print("📝 Генерація домашніх завдань...")
    hw_data = [(random.choice(sub_ids), random.choice(class_ids), random.choice(t_ids), fake.sentence(), fake.date_between(start_date='today', end_date='+14d')) for _ in range(500)]
    bulk_insert(connection, "INSERT INTO homework (subject_id, class_id, teacher_id, description, due_date) VALUES %s", hw_data)

    # 10. ВЕЛИКІ ДАНІ: ВІДВІДУВАНІСТЬ (attendance) ~200 000
    print(f"📊 Генерація {TARGET_ATTENDANCE} записів відвідуваності...")
    attendance_data = []
    inserted_att = 0
    statuses = ['present', 'present', 'present', 'absent', 'late', 'excused']
    today = date.today()
    start_date = today - timedelta(days=90)

    while inserted_att < TARGET_ATTENDANCE:
        attendance_data.append((random.choice(s_ids), random.choice(ls_ids), fake.date_between(start_date=start_date, end_date=today), random.choice(statuses)))
        if len(attendance_data) == BATCH_SIZE:
            bulk_insert(connection, "INSERT INTO attendance (student_id, lesson_schedule_id, lesson_date, status) VALUES %s ON CONFLICT DO NOTHING", attendance_data)
            inserted_att += BATCH_SIZE
            attendance_data = []

    # 11. ВЕЛИКІ ДАНІ: ОЦІНКИ (grades) ~500 000
    print(f"📈 Генерація {TARGET_GRADES} оцінок (це займе пару хвилин)...")
    grades_data = []
    inserted_grd = 0
    grade_types = ['current', 'thematic', 'exam']

    with connection.cursor() as cursor:
        while inserted_grd < TARGET_GRADES:
            grades_data.append((random.choice(s_ids), random.choice(sub_ids), random.choice(t_ids), random.randint(1, 12), fake.date_between(start_date=start_date, end_date=today), random.choice(grade_types)))
            if len(grades_data) == BATCH_SIZE:
                execute_values(cursor, "INSERT INTO grades (student_id, subject_id, teacher_id, grade_value, grade_date, grade_type) VALUES %s", grades_data)
                connection.commit()
                inserted_grd += BATCH_SIZE
                grades_data = []
                if inserted_grd % 100_000 == 0:
                    print(f"   ...вставлено {inserted_grd} / {TARGET_GRADES}")

    elapsed = time.time() - start_time
    print(f"✅ База даних успішно заповнена за {elapsed:.2f} секунд!")

if __name__ == "__main__":
    conn = create_connection()
    if conn:
        seed_data(conn)
        conn.close()