------------------------------------------------------
-- COMP9311 25T2 Project 1 
-- SQL and PL/pgSQL Template
-- Name:Yaxuan HU
-- zID:z5620596
------------------------------------------------------

DROP VIEW IF EXISTS Q1 CASCADE;

CREATE OR REPLACE VIEW Q1(name) AS
SELECT DISTINCT p.name
FROM subjects s
JOIN courses c ON c.subject = s.id
JOIN course_staff cs ON cs.course = c.id
JOIN staff_roles sr on cs.role = sr.id
JOIN staff_role_classes src ON sr.rclass = src.id
JOIN staff st ON st.id = cs.staff
JOIN people p ON p.id = st.id
WHERE s.code = 'COMP9311'
  AND src.description = 'Academic'
;


-- Q2
DROP VIEW IF EXISTS Q2 CASCADE;
CREATE or REPLACE VIEW Q2(code, room) AS
SELECT DISTINCT s.code, r.name
FROM subjects s
JOIN courses c ON c.subject = s.id
JOIN semesters sem ON sem.id = c.semester
JOIN classes cl ON cl.course = c.id
JOIN rooms r ON r.id = cl.room
WHERE cl.dayofwk = '1'
  AND cl.starttime >= '10'
  AND cl.endtime = '12'
  AND sem.year = 2002
  AND  sem.term = 'S2'
;


-- Q3
DROP VIEW IF EXISTS Q3 CASCADE;
CREATE or REPLACE VIEW Q3(count) AS
SELECT COUNT(DISTINCT s.id) AS count
FROM subjects s
JOIN courses c ON s.id = c.subject
JOIN semesters sem ON sem.id = c.semester
WHERE s.code LIKE 'COMP%'
  AND sem.term = 'S1'
  AND sem.year = 2012;
--... SQL statements, possibly using other views/functions defined by you ...
;


-- Q4
DROP VIEW IF EXISTS Q4 CASCADE;
CREATE or REPLACE VIEW Q4(name, mark) AS
SELECT p.name, ce.mark
FROM subjects s
JOIN courses c ON c.subject = s.id
JOIN semesters sem ON c.semester = sem.id
JOIN course_enrolments ce ON ce.course = c.id
JOIN students stu ON stu.id = ce.student
JOIN people p ON  stu.id = p.id 
WHERE s.code = 'COMP9020'
  AND sem.term = 'S2'
  AND sem.year = 2010
  AND ce.mark IS NOT NULL
  AND ce.mark = (
      SELECT MAX(ce1.mark)
      FROM subjects s1
      JOIN courses c1 ON c1.subject = s1.id
      JOIN semesters sem1 ON c1.semester = sem1.id
      JOIN course_enrolments ce1 ON ce1.course = c1.id
      WHERE s1.code = 'COMP9020'
        AND sem1.year = 2010
        AND sem1.term = 'S2'
        AND ce1.mark IS NOT NULL
  )
ORDER BY p.name;
--... SQL statements, possibly using other views/functions defined by you ...


-- Q5
DROP VIEW IF EXISTS Q5 CASCADE;
CREATE or REPLACE VIEW Q5(code, pass_rate) AS
SELECT s.code,
       ROUND(100.0 * SUM(CASE WHEN ce.mark >= 50 THEN 1 ELSE 0 END) / COUNT(ce.mark),
       2) AS pass_rate
FROM subjects s
JOIN courses c ON c.subject = s.id
JOIN semesters sem ON c.semester = sem.id 
JOIN course_enrolments ce ON c.id = ce.course 
WHERE s.code LIKE 'COMP%'
  AND sem.term = 'S1'
  AND sem.year = 2010
  AND ce.mark IS NOT NULL
GROUP BY s.code;
--... SQL statements, possibly using other views/functions defined by you ...


-- Q6
DROP VIEW IF EXISTS Q6 CASCADE;
CREATE or REPLACE VIEW Q6(name) AS
SELECT DISTINCT pd.name
FROM program_degrees pd
JOIN programs p ON p.id = pd.program
JOIN orgunits o ON o.id = p.offeredby
WHERE o.name LIKE '%Computer Science%';
--... SQL statements, possibly using other views/functions defined by you ...


--Q7
DROP VIEW IF EXISTS Q7a CASCADE;
CREATE OR REPLACE VIEW Q7a AS
SELECT pd.name , pd.dtype, dt.career from program_degrees pd
JOIN programs p ON p.id = pd.program
JOIN orgunits o ON o.id = p.offeredby
JOIN degree_types dt ON dt.id = pd.dtype
WHERE o.longname LIKE 'School of Computer Science and Engineering';

DROP VIEW IF EXISTS Q7b CASCADE;
CREATE OR REPLACE VIEW Q7b AS
SELECT count(career) AS total FROM Q7a;

DROP VIEW IF EXISTS Q7c CASCADE;
CREATE OR REPLACE VIEW Q7c AS 
SELECT career,count(career) FROM Q7a
GROUP BY  career
ORDER BY count DESC;

DROP VIEW IF EXISTS Q7 CASCADE;
CREATE OR REPLACE VIEW Q7 AS
SELECT q7c.career,q7c.count AS count,ROUND(100.0 * q7c.count::numeric / q7b.total, 2) AS percentage
FROM
    Q7c
    JOIN Q7b ON true
ORDER BY
    count DESC;

-- Q8
DROP VIEW IF EXISTS Q8 CASCADE;
CREATE or REPLACE VIEW Q8(unswid, name, avg_mark) AS
SELECT p.unswid, p.name, ROUND(AVG(ce.mark)::numeric, 2) AS avg_mark
FROM people p
    JOIN students stu ON p.id = stu.id
    JOIN course_enrolments ce ON ce.student = stu.id
WHERE
    stu.stype = 'local'
    AND ce.mark IS NOT NULL
    AND NOT EXISTS (
        SELECT 1
        FROM course_enrolments ce
        WHERE ce.student = stu.id
        AND ce.grade IS DISTINCT FROM 'HD'
    )
GROUP BY p.unswid, p.name;
--... SQL statements, possibly using other views/functions defined by you ...


-- Q9
DROP FUNCTION IF EXISTS Q9 CASCADE;
CREATE or REPLACE FUNCTION Q9(course_id integer)
returns text as $$
DECLARE
    hd_count integer := 0;
    dn_count integer := 0;
    cr_count integer := 0;
    ps_count integer := 0;
    fl_count integer := 0;
    total integer := 0;
    result text;
BEGIN
    SELECT
        COUNT(*) FILTER (WHERE grade = 'HD'),
        COUNT(*) FILTER (WHERE grade = 'DN'),
        COUNT(*) FILTER (WHERE grade = 'CR'),
        COUNT(*) FILTER (WHERE grade = 'PS'),
        COUNT(*) FILTER (WHERE grade = 'FL'),
        COUNT(*)
    INTO hd_count, dn_count, cr_count, ps_count, fl_count, total
    FROM course_enrolments
    WHERE course = course_id;

    IF total = 0 THEN
        RETURN FORMAT('Course %s has no enrolled students.', course_id);
    ELSE
        RETURN FORMAT(
            'Course %s grade distribution: HD: %s, DN: %s, CR: %s, PS: %s, FL: %s.',
            course_id, hd_count, dn_count, cr_count, ps_count, fl_count
        );
    END IF;
END;
--... SQL statements, possibly using other views/functions defined by you ...
$$ language plpgsql;


-- Q10
DROP FUNCTION IF EXISTS Q10 CASCADE;
CREATE OR REPLACE FUNCTION Q10(student_id integer)
RETURNS text AS $$ 
DECLARE
    r record;
    result TEXT := '';
BEGIN

    FOR r IN
        SELECT
            sem.year,
            sem.term,
            round(avg(ce.mark)::numeric, 2) AS avg_mark
        FROM
            course_enrolments ce
            JOIN courses c ON ce.course = c.id
            JOIN semesters sem ON c.semester = sem.id
        WHERE
            ce.student = student_id
            AND ce.mark IS NOT NULL
            AND sem.year BETWEEN 2000 AND 2015
            AND sem.term IN ('S1', 'S2')
        GROUP BY sem.year, sem.term
        ORDER BY sem.year, sem.term
    LOOP
        IF result <> '' THEN
            result := result || ' | ';
        END IF;
        result := result || r.year || ' ' || r.term || ' ' || r.avg_mark;
    END LOOP;

    IF result = '' THEN
        RETURN format('Student %s has no course marks.', student_id);
    ELSE
        RETURN format('Student %s average marks: %s', student_id, result);
    END IF;
END;
--... SQL statements, possibly using other views/functions defined by you ...
$$ language plpgsql;