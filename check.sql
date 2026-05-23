----------------------------------------------------------
--		COMP9311 25T2 Project 1
-- 		Project AutoTest File
-- 		MyMyUNSW Check
----------------------------------------------------------

SET client_min_messages TO WARNING;

-- check if a table exists, return true or false
create or replace function
	proj1_table_exists(tname text) returns boolean
as $$
declare
	_check integer := 0;
begin
	select count(*) into _check from pg_class
	where relname=tname and relkind='r';
	return (_check = 1);
end;
$$ language plpgsql;

-- check if a view exists, return true or false
create or replace function
	proj1_view_exists(tname text) returns boolean
as $$
declare
	_check integer := 0;
begin
	select count(*) into _check from pg_class
	where relname=tname and relkind='v';
	return (_check = 1);
end;
$$ language plpgsql;

-- check if a function exists, return true or false
create or replace function
	proj1_function_exists(tname text) returns boolean
as $$
declare
	_check integer := 0;
begin
	select count(*) into _check from pg_proc
	where proname=tname;
	return (_check > 0);
end;
$$ language plpgsql;

--------------------------------------------------------------
-- show warning if the tests are not run on the course server
---------------------------------------------------------------
DROP FUNCTION IF EXISTS version_warning_msg;
CREATE OR REPLACE FUNCTION version_warning_msg() RETURNS text AS $$
DECLARE
    version_info TEXT;
	warn_msg text;
BEGIN
    SELECT version() INTO version_info;
	warn_msg := '';
    IF position('PostgreSQL 13.14' IN version_info) = 0 THEN
        warn_msg := ' (Warning: Your PostgreSQL version may not be compatible with that of course server, please run this check on vxdb before submission.)';
		warn_msg := '';
	END IF;
	RETURN warn_msg;
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------
-- proj1_check_result:
-- determines appropriate message, based on count of
-- excess and missing tuples in user output vs expected output
--------------------------------------------------------------

create or replace function
	proj1_check_result(_res text,nexcess integer, nmissing integer) returns text
as $$
begin
	if (nexcess = 0 and nmissing = 0) then
		return _res || ': correct.';
	elsif (nexcess > 0 and nmissing = 0) then
		return _res || ': too many tuples.';
	elsif (nexcess = 0 and nmissing > 0) then
		return _res || ': missing tuples.';
	elsif (nexcess > 0 and nmissing > 0) then
		return _res || ': incorrect.';
	end if;
end;
$$ language plpgsql;

--------------------------------------------------------------
-- proj1_check:
-- * compares output of user view/function against expected output
-- * returns string (text message) containing analysis of results
--  _type: 'view' or 'function'
--  _name: view or function name defined by student
--	_res: table name containing expected results, e.g. 'q1_expected'
--	_query: query string to be executed on student solution, e.g. $$select * from q1$$
-- Example: select proj1_check('view','q1','q1_expected',$$select * from q1$$)
--------------------------------------------------------------

create or replace function
	proj1_check(_type text, _name text, _res text, _query text) returns text
as $$
declare
	nexcess integer;
	nmissing integer;
	excessQ text;
	missingQ text;
	return_msg text;
begin
	return_msg := '';
	if (_type = 'view' and not proj1_view_exists(_name)) then
		return_msg := 'No '||_name||' view; did it load correctly?';
	elsif (_type = 'function' and not proj1_function_exists(_name)) then
		return_msg := 'No '||_name||' function; did it load correctly?';
	elsif (not proj1_table_exists(_res)) then
		return_msg := _res||': No expected results!';
	else
		excessQ := 'select count(*) '||
				 'from (('||_query||') except '||
				 '(select * from '||_res||')) as X';
		-- raise notice 'Q: %',excessQ;
		execute excessQ into nexcess;
		missingQ := 'select count(*) '||
					'from ((select * from '||_res||') '||
					'except ('||_query||')) as X';
		-- raise notice 'Q: %',missingQ;
		execute missingQ into nmissing;
		return_msg := proj1_check_result(regexp_replace(_res, '_expected$', ''),nexcess,nmissing);
	end if;
	return return_msg || version_warning_msg();
end;
$$ language plpgsql;



--------------------------------------------------------------
-- proj1_rescheck:
-- * compares output of user function against expected result
-- * returns string (text message) containing analysis of results
--------------------------------------------------------------

create or replace function
	proj1_rescheck(_type text, _name text, _res text, _query text) returns text
as $$
declare
	_sql text;
	_chk boolean;
begin
	if (_type = 'function' and not proj1_function_exists(_name)) then
		return 'No '||_name||' function; did it load correctly?';
	elsif (_res is null) then
		_sql := 'select ('||_query||') is null';
		-- raise notice 'SQL: %',_sql;
		execute _sql into _chk;
		-- raise notice 'CHK: %',_chk;
	else
		_sql := 'select ('||_query||') = '||quote_literal(_res);
		-- raise notice 'SQL: %',_sql;
		execute _sql into _chk;
		-- raise notice 'CHK: %',_chk;
	end if;
	if (_chk) then
		return 'correct';
	else
		return 'incorrect result';
	end if;
end;
$$ language plpgsql;

--------------------------------------------------------------
-- check_all:
-- * run all of the checks and return a table of results
--------------------------------------------------------------

drop type if exists TestingResult cascade;
create type TestingResult as (test text, result text);

create or replace function
	check_all() returns setof TestingResult
as $$
declare
	i int;
	testQ text;
	result text;
	out TestingResult;
	tests text[] := array['q1', 'q2', 'q3', 'q4', 'q5', 'q6', 'q7', 'q8', 'q9a', 'q9b', 'q9c', 'q9d', 'q9e', 'q9f', 'q10a', 'q10b', 'q10c', 'q10d', 'q10e', 'q10f', 'q10g'];
begin
	for i in array_lower(tests,1) .. array_upper(tests,1)
	loop
		testQ := 'select check_'||tests[i]||'()';
		execute testQ into result;
		out := (tests[i],result);
		return next out;
	end loop;
	return;
end;
$$ language plpgsql;


-----------------------Q1----------------

create or replace function check_q1() returns text as $chk$
select proj1_check('view','q1','q1_expected', $$select * from q1$$)
$chk$ language sql;

drop table if exists q1_expected;
create table q1_expected (
	name VARCHAR(128)
);

COPY q1_expected (name) FROM stdin;
Jessica Wong
John Shepherd
Muhammad Cheema
Wei Wang
Wenjie Zhang
Xuemin Lin
Ying Zhang
\.
;

-- SELECT check_q1();

-----------------------Q2----------------

create or replace function check_q2() returns text as $chk$
select proj1_check('view','q2','q2_expected', $$select * from q2$$)
$chk$ language sql;

drop table if exists q2_expected;
create table q2_expected (
	code VARCHAR(128),
	room VARCHAR(128)
);

COPY q2_expected (code, room) FROM stdin;
ACTL3003	MAT-312
BENV2304	OMB-144
BIOS3111	BIOM-C
BIOS3301	BIOM-C
CHEM1021	NSG
CHEM1041	ASB-229
CHEM1817	ASB-229
CHIN2312	MB-215
ECON1203	WEB-290
ECON2292	WEB-290
ELEC1011	D23-201
ENGL2101	D23-304
FINS1612	BIOM-B
GENS2005	RC-2062
GMAT1150	EE-222
HIST2021	MAT-310
HIST2033	MB-G4
HIST3900	CE-102
IDES2171	RC-1003
IROB1701	CLB-7
IROB2704	CLB-3
LEGT7741	CLB-6
MATH1041	RC-G12B
MATH1059	RC-G12A
MATH1081	CLB-102
MATH1251	EE-LG1
MATH3560	RC-2062
MATS3064	E8-219
MICR3051	BIOM-E
SAHT2103	B-104
SAHT2103	C-201
SART1602	E-G02
SDES1107	F-121
SLSP1001	OMB-19
SLSP4000	OMB-115
SOCA2205	CLB-1
\.
;

-- SELECT check_q2();




-----------------------q3----------------

create or replace function check_q3() returns text as $chk$
select proj1_check('view','q3','q3_expected', $$select * from q3$$)
$chk$ language sql;

drop table if exists q3_expected;
create table q3_expected (
	count INTEGER
);

COPY q3_expected (count) FROM stdin;
65 
\.
;

-- SELECT check_q3();


-----------------------q4----------------

create or replace function check_q4() returns text as $chk$
select proj1_check('view','q4','q4_expected', $$select * from q4$$)
$chk$ language sql;

drop table if exists q4_expected;
create table q4_expected (
	name VARCHAR(128),
	mark INTEGER
);

COPY q4_expected (name, mark) FROM stdin;
Amanda Hollis	98
Seoh Ho	98
\.
;

-- SELECT check_q4();



-----------------------q5----------------

create or replace function check_q5() returns text as $chk$
select proj1_check('view','q5','q5_expected', $$select * from q5$$)
$chk$ language sql;

drop table if exists q5_expected;
create table q5_expected (
	code VARCHAR(128),
	pass_rate NUMERIC(5,2)
);

COPY q5_expected (code, pass_rate) FROM stdin;
COMP1911	90.43
COMP1917	82.19
COMP1921	88.24
COMP1927	60.87
COMP2041	80.00
COMP2111	96.15
COMP2121	93.88
COMP2911	92.45
COMP3121	100.00
COMP3131	83.33
COMP3141	100.00
COMP3211	100.00
COMP3231	100.00
COMP3311	96.30
COMP3331	92.31
COMP3411	94.12
COMP3441	100.00
COMP3711	100.00
COMP3821	100.00
COMP3891	100.00
COMP3901	100.00
COMP4317	87.50
COMP4411	100.00
COMP4415	100.00
COMP4511	100.00
COMP4601	100.00
COMP6721	100.00
COMP9018	100.00
COMP9020	100.00
COMP9021	100.00
COMP9024	100.00
COMP9041	100.00
COMP9101	92.31
COMP9102	100.00
COMP9152	100.00
COMP9201	100.00
COMP9211	100.00
COMP9243	66.67
COMP9283	100.00
COMP9311	91.30
COMP9317	100.00
COMP9318	94.12
COMP9321	91.49
COMP9322	95.65
COMP9323	100.00
COMP9331	79.17
COMP9332	100.00
COMP9333	100.00
COMP9414	90.00
COMP9417	100.00
COMP9441	100.00
COMP9447	100.00
COMP9814	100.00
\.
;

-- SELECT * from q5;
-- SELECT check_q5();


-----------------------q6----------------

create or replace function check_q6() returns text as $chk$
select proj1_check('view','q6','q6_expected', $$select * from q6$$)
$chk$ language sql;

drop table if exists q6_expected;
create table q6_expected (
	name VARCHAR(128)
);

COPY q6_expected (name) FROM stdin;
Bachelor of Arts
Bachelor of Commerce
Bachelor of Digital Media
Bachelor of Engineering
Bachelor of Science
Doctor of Philosophy
Graduate Certificate
Graduate Diploma
Graduate Diploma in Information Science
Master of Biomedical Engineering
Master of Computer Science
Master of Computing and Information Technology
Master of Engineering
Master of Engineering Science
Master of Information Science
Master of Information Technology
Master of Science
\.
;

-- SELECT check_q6();


-----------------------q7----------------

create or replace function check_q7() returns text as $chk$
select proj1_check('view','q7','q7_expected', $$select * from q7$$)
$chk$ language sql;

drop table if exists q7_expected;
create table q7_expected (
	career VARCHAR(128),
	degree_count INTEGER,
	percentage NUMERIC(5,2)
);

COPY q7_expected (career,degree_count,percentage) FROM stdin;
UG	24	55.81
PG	16	37.21
RS	3	6.98
\.
;


-- SELECT check_q7();


-----------------------q8----------------

create or replace function check_q8() returns text as $chk$
select proj1_check('view','q8','q8_expected', $$select * from q8$$)
$chk$ language sql;

drop table if exists q8_expected;
create table q8_expected (
	unswid INTEGER,
	name VARCHAR(128),
	avg_mark NUMERIC(5,2)
);

COPY q8_expected (unswid, name, avg_mark) FROM stdin;
2202270	Scott Karmakar	89.00
2230438	William McGinniss	94.50
3013927	Lachlan Paoloni	90.50
3082954	Bryan Joye	90.00
3103161	Avinash Mohd Miran	90.00
3109454	Joel Raveendran	90.50
3119674	Anna Basford	90.50
3191036	Cheaseth Heng	98.00
3193144	Megan Mendelsohn	90.00
3224767	Nigel Smallbone	90.00
3266368	Bandarage Das	94.50
3305385	Shu Kwong	94.67
3307879	Jason Tong	87.00
3307887	Jana Sikorski	93.00
3312005	Po Chim	93.50
3312751	Sydney McClintock	88.33
3326984	Kylie Sui	95.50
3342602	Adrian Hynes	89.00
3345752	Daniel Black	95.67
3360868	Campbell Munday	89.00
3368663	Jemille Ambler	89.50
3376647	Yanmin Qian	91.67
3378291	Elijah Burns-Woods	89.00
3385991	Michelle Croker	92.50
3387921	Barry Cane	89.50
3392463	Lisa Bullivant	93.00
3397891	Katie Cai	90.00
3398209	Matthew Stephens	92.33
3417244	Kingsley Siu	93.00
3417457	Russell Kalinowski	91.60
3421409	Larissa Tofts	93.33
3429557	Kimberly Black	92.88
3437727	Vincy Thorpe	92.00
3444213	Meredith Fagundez	90.50
3456650	Belinda Browitt	93.33
3461061	Hamad Osmani	90.33
3461389	Ros Mccrindle	91.00
3464715	Juita Abdullah Jalani	89.50
3476003	Joseph Leblond	89.50
3483850	Imad Schuman	91.67
3485061	Valerie Cheng	91.00
3498534	Mui Kok	93.88
\.
;

-- SELECT * from q8;
-- SELECT check_q8();



-----------------------q9a----------------

create or replace function check_q9a() returns text as $chk$
select proj1_check('function','q9','q9a_expected', $$select Q9(1572)$$)
$chk$ language sql;

drop table if exists q9a_expected;
create table q9a_expected (
	q9 text
);

COPY q9a_expected (q9) FROM stdin;
Course 1572 has no enrolled students.
\.
;

-- SELECT check_q9a();


-----------------------q9b----------------

create or replace function check_q9b() returns text as $chk$
select proj1_check('function','q9','q9b_expected', $$select Q9(5727)$$)
$chk$ language sql;

drop table if exists q9b_expected;
create table q9b_expected (
	q9 text
);

COPY q9b_expected (q9) FROM stdin;
Course 5727 grade distribution: HD: 4, DN: 2, CR: 2, PS: 1, FL: 0.
\.
;

-- SELECT check_q9b();

-----------------------q9c----------------

create or replace function check_q9c() returns text as $chk$
select proj1_check('function','q9','q9c_expected', $$select q9(7927)$$)
$chk$ language sql;

drop table if exists q9c_expected;
create table q9c_expected (
	q9 text
);

COPY q9c_expected (q9) FROM stdin;
Course 7927 grade distribution: HD: 3, DN: 1, CR: 0, PS: 4, FL: 0.
\.
;

-- SELECT * from q9;
-- SELECT check_q9c();

-----------------------q9d----------------

create or replace function check_q9d() returns text as $chk$
select proj1_check('function','q9','q9d_expected', $$select q9(10029)$$)
$chk$ language sql;

drop table if exists q9d_expected;
create table q9d_expected (
	q9 text
);

COPY q9d_expected (q9) FROM stdin;
Course 10029 grade distribution: HD: 4, DN: 7, CR: 1, PS: 0, FL: 0.
\.
;

-- SELECT check_q9d();



-----------------------q9e----------------

create or replace function check_q9e() returns text as $chk$
select proj1_check('function','q9','q9e_expected', $$select q9(12174)$$)
$chk$ language sql;

drop table if exists q9e_expected;
create table q9e_expected (
	q9 text
);

COPY q9e_expected (q9) FROM stdin;
Course 12174 grade distribution: HD: 1, DN: 3, CR: 3, PS: 1, FL: 1.
\.
;

-- SELECT check_q9e();




-----------------------q9f----------------

create or replace function check_q9f() returns text as $chk$
select proj1_check('function','q9','q9f_expected', $$select q9(16527)$$)
$chk$ language sql;

drop table if exists q9f_expected;
create table q9f_expected (
	q9 text
);

COPY q9f_expected (q9) FROM stdin;
Course 16527 grade distribution: HD: 0, DN: 2, CR: 1, PS: 1, FL: 0.
\.
;

-- SELECT check_q9f();


-----------------------q10a----------------

create or replace function check_q10a() returns text as $chk$
select proj1_check('function','q10','q10a_expected', $$select q10(1150306)$$)
$chk$ language sql;

drop table if exists q10a_expected;
create table q10a_expected (
	q10 text
);

COPY q10a_expected (q10) FROM stdin;
Student 1150306 average marks: 2009 S1 56.75 | 2009 S2 56.25 | 2010 S1 32.50 | 2010 S2 59.25 | 2011 S1 50.00 | 2011 S2 38.50 | 2012 S1 61.75 | 2012 S2 55.00
\.
;

-- SELECT * from q10;
-- SELECT check_q10a();


-----------------------q10b----------------

create or replace function check_q10b() returns text as $chk$
select proj1_check('function','q10','q10b_expected', $$select q10(1143435)$$)
$chk$ language sql;

drop table if exists q10b_expected;
create table q10b_expected (
	q10 text
);

COPY q10b_expected (q10) FROM stdin;
Student 1143435 average marks: 2008 S1 74.75 | 2008 S2 67.00 | 2010 S1 66.00 | 2010 S2 74.75 | 2011 S1 71.75 | 2011 S2 63.75
\.
;


-- SELECT check_q10b();

-----------------------q10c----------------

create or replace function check_q10c() returns text as $chk$
select proj1_check('function','q10','q10c_expected', $$select q10(1177304)$$)
$chk$ language sql;

drop table if exists q10c_expected;
create table q10c_expected (
	q10 text
);

COPY q10c_expected (q10) FROM stdin;
Student 1177304 average marks: 2010 S1 70.25 | 2010 S2 63.00 | 2011 S1 72.00 | 2011 S2 71.00 | 2012 S1 76.25 | 2012 S2 74.00
\.
;

-- SELECT * from q10;
-- SELECT check_q10c();

-----------------------q10d----------------

create or replace function check_q10d() returns text as $chk$
select proj1_check('function','q10','q10d_expected', $$select q10(1124532)$$)
$chk$ language sql;

drop table if exists q10d_expected;
create table q10d_expected (
	q10 text
);

COPY q10d_expected (q10) FROM stdin;
Student 1124532 average marks: 2007 S1 82.75 | 2007 S2 84.50 | 2008 S1 95.25 | 2008 S2 78.25 | 2009 S1 90.75 | 2009 S2 85.75 | 2010 S1 87.00 | 2010 S2 85.75 | 2011 S1 86.33 | 2011 S2 88.25
\.
;


-- SELECT check_q10d();

-----------------------q10e----------------

create or replace function check_q10e() returns text as $chk$
select proj1_check('function','q10','q10e_expected', $$select q10(1172811)$$)
$chk$ language sql;

drop table if exists q10e_expected;
create table q10e_expected (
	q10 text
);

COPY q10e_expected (q10) FROM stdin;
Student 1172811 average marks: 2011 S1 75.25 | 2011 S2 71.75 | 2012 S1 82.75 | 2012 S2 69.25
\.
;

-- SELECT check_q10e();


-----------------------q10f----------------

create or replace function check_q10f() returns text as $chk$
select proj1_check('function','q10','q10f_expected', $$select q10(1159983)$$)
$chk$ language sql;

drop table if exists q10f_expected;
create table q10f_expected (
	q10 text
);

COPY q10f_expected (q10) FROM stdin;
Student 1159983 average marks: 2009 S1 55.50 | 2009 S2 53.25 | 2010 S1 68.75 | 2010 S2 71.00 | 2011 S1 67.50 | 2011 S2 66.67 | 2012 S1 77.33
\.
;

-- SELECT * from q10;
-- SELECT check_q10f();

-----------------------q10g----------------

create or replace function check_q10g() returns text as $chk$
select proj1_check('function','q10','q10g_expected', $$select q10(1173010)$$)
$chk$ language sql;

drop table if exists q10g_expected;
create table q10g_expected (
	q10 text
);

COPY q10g_expected (q10) FROM stdin;
Student 1173010 average marks: 2010 S1 71.75 | 2010 S2 66.00 | 2011 S1 77.00 | 2011 S2 79.25 | 2012 S1 82.75 | 2012 S2 91.25
\.
;

-- select CHECK_ALL();
