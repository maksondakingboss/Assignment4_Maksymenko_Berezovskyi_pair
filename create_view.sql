CREATE OR REPLACE VIEW schedules AS
SELECT
    course.course_display_short_name,
    course.course_display_full_name,
    course.course_description,
    instructor.first_name AS instructor_first_name,
    instructor.last_name AS instructor_last_name,
    instructor.email AS instructor_email,
    CONCAT(room.building, ', ', room.floor, ', ', room.number, ', ', room.display_name) AS address,
    schedule.week_day,
    lesson.id AS lesson_id,
    lesson.start_time AS lesson_start_time,
    lesson.end_time AS lesson_end_time
FROM schedule
JOIN courses course
    ON schedule.course_id = course.id
JOIN instructors instructor
    ON schedule.instructor_id = instructor.id
JOIN rooms room
    ON schedule.room_id = room.id
JOIN lessons_schedule lesson
    ON schedule.lesson_schedule_id = lesson.id;

-- To check performance, run separately, not inside CREATE VIEW:
-- EXPLAIN ANALYZE SELECT * FROM schedules;
