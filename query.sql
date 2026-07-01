-- єдина школа
--teachers
create table teachers
(
    id         serial primary key,
    first_name varchar(200) not null,
    last_name  varchar(200) not null,
    email      varchar(200) not null unique,
    phone      varchar(20),
    active     boolean      not null default true
);
--заняття
create table school_classes
(
    id                  serial primary key,
    class_name          varchar(20) not null unique,
    grade_level         int         not null check (grade_level between 1 and 12),
    homeroom_teacher_id int unique  references teachers (id) on delete set null -- 1 вчитель - 1 клас
);
--учні
create table students
(
    id         serial primary key,
    first_name varchar(200) not null,
    last_name  varchar(200) not null,
    birth_date date         not null,
    class_id   int          references school_classes (id) on delete set null, -- 1:many 1 клас багато учнів
    active     boolean      not null default true
);
-- тут інфа про учнів
create table student_profiles --1:1 студент до студент профілю
(
    student_id              int primary key references students (id) on delete cascade,
    medical_notes           varchar(500),
    emergency_contact_name  varchar(200),
    emergency_contact_phone varchar(20)
);
--батьки
create table parents
(
    id         serial primary key,
    first_name varchar(200) not null,
    last_name  varchar(200) not null,
    email      varchar(200) unique,
    phone      varchar(20)  not null
);
-- показує хто з батьків належить якому учню, типу у 1 учня може бути 2 батьків але у 2 батьків може бути більше 1 дитини
create table student_parents -- М:М учень може мати декілька батьків
(
    student_id   int         not null references students (id) on delete cascade,
    parent_id    int         not null references parents (id) on delete cascade,
    relationship varchar(20) not null default 'parent' check (relationship in ('parent', 'guardian')),
    primary key (student_id, parent_id)
);
--предмети
create table subjects
(
    id           serial primary key,
    subject_name varchar(200) not null unique,
    description  varchar(500)
);

--звязок вчитель-предмет
create table teachers_subjects
( -- М:М вчитель може викладати багато предметів
    teacher_id int not null references teachers (id) on delete cascade,
    subject_id int not null references subjects (id) on delete cascade,
    primary key (teacher_id, subject_id)
);

--розклад
create table lessons_schedule
(
    id         serial primary key,
    class_id   int         not null references school_classes (id) on delete cascade,
    subject_id int         not null references subjects (id) on delete cascade,
    teacher_id int         not null references teachers (id) on delete cascade,
    week_day   varchar(20) not null check (week_day in
                                           ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday')),
    start_time time        not null,
    end_time   time        not null,
    check (end_time > start_time),
    constraint lessons_schedule_unique unique (class_id, week_day, start_time) -- перевірка щоб уроки не накладались
);

--оцінки
create table grades
(
    id          serial primary key,
    student_id  int         not null references students (id) on delete cascade,
    subject_id  int         not null references subjects (id) on delete cascade,
    teacher_id  int         not null references teachers (id) on delete cascade,
    grade_value int         not null check (grade_value between 1 and 12),
    grade_date  date        not null,
    grade_type  varchar(20) not null default 'current' check (grade_type in ('current', 'thematic', 'exam'))
);

create table attendance
(
    id                 serial primary key, -- унікальний номер запису відвідування (uuid)
    student_id         int         not null references students (id) on delete cascade,
    lesson_schedule_id int         not null references lessons_schedule (id) on delete cascade,
    lesson_date        date        not null,
    status             varchar(20) not null check (status in ('present', 'absent', 'late', 'excused')),
    constraint attendance_unique unique (student_id, lesson_schedule_id, lesson_date)
);

create table homework
(
    id          serial primary key,
    subject_id  int           not null references subjects (id) on delete cascade,
    class_id    int           not null references school_classes (id) on delete cascade,
    teacher_id  int           not null references teachers (id) on delete cascade,
    description varchar(1000) not null,
    due_date    date          not null
);


SELECT COUNT(*)
FROM grades;
SELECT COUNT(*)
FROM attendance;

create index idx_grades_student_id on grades (student_id);
create index idx_grades_subject_id on grades (subject_id);
create index idx_grades_date on grades (grade_date);
create index idx_attendance_date on attendance (lesson_date);
create index idx_students_class_id on students (class_id);
create index idx_students_last_name on students (last_name);
explain
analyze
SELECT *
FROM grades
WHERE student_id = 123;
--Gather  (cost=1000.00..7504.37 rows=502 width=31) (actual time=10.852..141.432 rows=528 loops=1)
-- Workers Planned: 2
--   Workers Launched: 2
--   ->  Parallel Seq Scan on grades  (cost=0.00..6454.17 rows=209 width=31) (actual time=0.052..23.599 rows=176 loops=3)
--         Filter: (student_id = 123)
--         Rows Removed by Filter: 166491
-- Planning Time: 0.222 ms
-- Execution Time: 141.581 ms

-- ств індекси
explain
analyze
SELECT *
FROM grades
WHERE student_id = 123;
--Bitmap Heap Scan on grades  (cost=8.31..1406.79 rows=502 width=31) (actual time=0.321..1.226 rows=528 loops=1)
-- Recheck Cond: (student_id = 123)
--   Heap Blocks: exact=486
--   ->  Bitmap Index Scan on idx_grades_student_id  (cost=0.00..8.19 rows=502 width=0) (actual time=0.219..0.219 rows=528 loops=1)
--         Index Cond: (student_id = 123)
-- Planning Time: 14.362 ms
-- Execution Time: 1.300 ms
-- швидше у 100 разів мінімум

EXPLAIN
ANALYZE
SELECT *
FROM attendance
WHERE student_id = 123;
--
-- Bitmap Heap Scan on attendance  (cost=5.84..539.05 rows=200 width=23) (actual time=0.108..0.493 rows=188 loops=1)
--   Recheck Cond: (student_id = 123)
--   Heap Blocks: exact=176
--   ->  Bitmap Index Scan on idx_attendance_student_id  (cost=0.00..5.79 rows=200 width=0) (actual time=0.055..0.055 rows=188 loops=1)
--         Index Cond: (student_id = 123)
-- Planning Time: 0.236 ms
-- Execution Time: 0.552 ms