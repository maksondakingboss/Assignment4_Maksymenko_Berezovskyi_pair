-- PostgreSQL version
-- Run once outside the database if needed:
-- CREATE DATABASE uni_db;
-- Then connect to uni_db and run the rest of this file.


CREATE TABLE IF NOT EXISTS students (
    id VARCHAR(36) PRIMARY KEY,
    first_name VARCHAR(200) NOT NULL,
    last_name VARCHAR(200) NOT NULL,
    email VARCHAR(200) NOT NULL UNIQUE,
    phone VARCHAR(20) NOT NULL,
    course INT,
    educational_degree VARCHAR(20),
    speciality VARCHAR(20),
    active BOOLEAN
);

COMMENT ON TABLE students IS 'Table to store student information';
COMMENT ON COLUMN students.id IS 'Unique identifier for each student';
COMMENT ON COLUMN students.first_name IS 'First name of the student';
COMMENT ON COLUMN students.last_name IS 'Last name of the student';
COMMENT ON COLUMN students.email IS 'Email address of the student';
COMMENT ON COLUMN students.phone IS 'Phone number of the student';
COMMENT ON COLUMN students.course IS 'Course number the student is enrolled in';
COMMENT ON COLUMN students.educational_degree IS 'Educational degree of the student';
COMMENT ON COLUMN students.speciality IS 'Speciality of the student';
COMMENT ON COLUMN students.active IS 'Indicates whether the student is active or not';

CREATE TABLE IF NOT EXISTS rooms (
    id VARCHAR(36) PRIMARY KEY,
    building VARCHAR(200),
    floor INT,
    number INT,
    display_name VARCHAR(200),
    seats_number INT CHECK (seats_number > 0)
);

COMMENT ON TABLE rooms IS 'Table to store room information';
COMMENT ON COLUMN rooms.id IS 'Unique identifier for each room';
COMMENT ON COLUMN rooms.building IS 'Building where the room is located';
COMMENT ON COLUMN rooms.floor IS 'Floor number where the room is located';
COMMENT ON COLUMN rooms.number IS 'Room number';
COMMENT ON COLUMN rooms.display_name IS 'Display name of the room';
COMMENT ON COLUMN rooms.seats_number IS 'Number of seats available in the room';

CREATE TABLE IF NOT EXISTS courses (
    id VARCHAR(36) PRIMARY KEY,
    course_display_short_name VARCHAR(36),
    course_display_full_name VARCHAR(200),
    course_description VARCHAR(500),
    lectures_num INT CHECK (lectures_num >= 0),
    practices_num INT CHECK (practices_num >= 0)
);

COMMENT ON TABLE courses IS 'Table to store course information';
COMMENT ON COLUMN courses.id IS 'Unique identifier for each course';
COMMENT ON COLUMN courses.course_display_short_name IS 'Short name of the course';
COMMENT ON COLUMN courses.course_display_full_name IS 'Full name of the course';
COMMENT ON COLUMN courses.course_description IS 'Description of the course';
COMMENT ON COLUMN courses.lectures_num IS 'Number of lectures in the course';
COMMENT ON COLUMN courses.practices_num IS 'Number of practice sessions in the course';

CREATE TABLE IF NOT EXISTS instructors (
    id VARCHAR(36) PRIMARY KEY,
    first_name VARCHAR(200),
    last_name VARCHAR(200),
    email VARCHAR(200) UNIQUE,
    phone VARCHAR(20),
    active BOOLEAN
);

COMMENT ON TABLE instructors IS 'Table to store instructor information';
COMMENT ON COLUMN instructors.id IS 'Unique identifier for each instructor';
COMMENT ON COLUMN instructors.first_name IS 'First name of the instructor';
COMMENT ON COLUMN instructors.last_name IS 'Last name of the instructor';
COMMENT ON COLUMN instructors.email IS 'Email address of the instructor';
COMMENT ON COLUMN instructors.phone IS 'Phone number of the instructor';
COMMENT ON COLUMN instructors.active IS 'Indicates whether the instructor is active or not';

CREATE TABLE IF NOT EXISTS lessons_schedule (
    id INT PRIMARY KEY,
    start_time TIME,
    end_time TIME,
    CHECK (end_time > start_time)
);

COMMENT ON TABLE lessons_schedule IS 'Table to store lessons schedule';
COMMENT ON COLUMN lessons_schedule.id IS 'Unique identifier for each lesson schedule';
COMMENT ON COLUMN lessons_schedule.start_time IS 'Start time of the lesson';
COMMENT ON COLUMN lessons_schedule.end_time IS 'End time of the lesson';

CREATE TABLE IF NOT EXISTS instructors_courses (
    instructor_id VARCHAR(36) NOT NULL REFERENCES instructors(id) ON DELETE CASCADE,
    course_id VARCHAR(36) NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    PRIMARY KEY (instructor_id, course_id)
);

COMMENT ON TABLE instructors_courses IS 'Table to store relationship between instructors and courses';
COMMENT ON COLUMN instructors_courses.instructor_id IS 'Identifier for the instructor';
COMMENT ON COLUMN instructors_courses.course_id IS 'Identifier for the course';

CREATE TABLE IF NOT EXISTS students_course_groups (
    id VARCHAR(36) PRIMARY KEY,
    course_id VARCHAR(36) NOT NULL REFERENCES courses(id) ON DELETE CASCADE
);

COMMENT ON TABLE students_course_groups IS 'Table to store student course groups';
COMMENT ON COLUMN students_course_groups.id IS 'Unique identifier for each student course group';
COMMENT ON COLUMN students_course_groups.course_id IS 'Identifier for the course';

CREATE TABLE IF NOT EXISTS students_course_group_students (
    student_id VARCHAR(36) NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    group_id VARCHAR(36) NOT NULL REFERENCES students_course_groups(id) ON DELETE CASCADE,
    PRIMARY KEY (student_id, group_id)
);

COMMENT ON TABLE students_course_group_students IS 'Table to store relationship between students and course groups';
COMMENT ON COLUMN students_course_group_students.student_id IS 'Identifier for the student';
COMMENT ON COLUMN students_course_group_students.group_id IS 'Identifier for the student course group';

CREATE TABLE IF NOT EXISTS schedule (
    id INT PRIMARY KEY,
    course_id VARCHAR(36) REFERENCES courses(id),
    instructor_id VARCHAR(36) REFERENCES instructors(id),
    students_course_group_id VARCHAR(36) REFERENCES students_course_groups(id),
    week_day VARCHAR(20),
    lesson_schedule_id INT REFERENCES lessons_schedule(id),
    room_id VARCHAR(36) REFERENCES rooms(id),
    CONSTRAINT schedule_unique_key UNIQUE (course_id, instructor_id, students_course_group_id, room_id)
);

COMMENT ON TABLE schedule IS 'Table to store schedule information';
COMMENT ON COLUMN schedule.id IS 'Unique identifier for each schedule entry';
COMMENT ON COLUMN schedule.course_id IS 'Identifier for the course';
COMMENT ON COLUMN schedule.instructor_id IS 'Identifier for the instructor';
COMMENT ON COLUMN schedule.students_course_group_id IS 'Identifier for the student course group';
COMMENT ON COLUMN schedule.week_day IS 'Day of the week for the schedule';
COMMENT ON COLUMN schedule.lesson_schedule_id IS 'Identifier for the lesson schedule';
COMMENT ON COLUMN schedule.room_id IS 'Identifier for the room';

CREATE INDEX IF NOT EXISTS idx_schedule_course_id ON schedule(course_id);
CREATE INDEX IF NOT EXISTS idx_schedule_instructor_id ON schedule(instructor_id);
CREATE INDEX IF NOT EXISTS idx_schedule_room_id ON schedule(room_id);
CREATE INDEX IF NOT EXISTS idx_students_email ON students(email);
