--Практическая работа №5
--Создать схему БД для фиксации успеваемости студентов.
--Есть таблицы:
--	Специальности (просто справочник);
--Учебный план (специальность, семестр, предмет, вид отчетности);
--Студенты (фио, специальность, год поступления);
--Оценки (студент, дата, оценка – предусмотреть неявку).
--(Понятно, что указаны не все необходимые поля, а только список того, 
--что должно быть обязательно).
--В таблицах должны быть предусмотрены все ограничения целостности.
--Создать триггеры для автоинкрементности первичных ключей.
--Заполнить таблицы тестовыми данными.
--Написать запрос, выводящий список должников на текущий момент времени 
--(сколько семестров проучился студент вычислять из года поступления и текущей 
--даты – написать для этого функцию). Должны выводиться поля: код студента, 
--ФИО студента, курс, код предмета, название предмета, семестр, 
--оценка (2 – если сдавал экзамен, нулл – если не сдавал).
--Сделать из этого запроса представление.
--Выбрать из представления студентов с 4-мя и более хвостами (на отчисление).



--tables
create table specialities (
  specialty_id number(10),
  specialty_name varchar2(50) not null,
  constraint pc_specialty_id 
    primary key (specialty_id),
  constraint un_specialty_name 
    unique (specialty_name)
);

create table subjects ( 
  subject_id number(10),
  subject_name varchar2(50) not null,
  constraint pk_subject_id
    primary key (subject_id),
  constraint un_subject_name
    unique (subject_name)
);

create table students ( 
  student_id number(10),
  first_name varchar2(50) not null,
  last_name varchar2(50) not null,
  specialty_id number(10) not null,
  receipt_year number(5) not null,
  constraint pk_student 
    primary key (student_id),
  constraint fk_specialities_students
    foreign key (specialty_id)
    references specialities(specialty_id)
);

create table syllabuses ( 
  syllabus_id number(10),
  specialty_id number(10) not null,
  semester number(10) not null,
  constraint pk_syllabus_id 
    primary key (syllabus_id),
  constraint fk_specialities_syllabuses
    foreign key (specialty_id)
    references specialities(specialty_id)
);

create table syllabus_subjects ( 
  syllabus_id number(10),
  subject_id number(10),
  reporting_type varchar2(50) not null,
  constraint pk_syll_subj_id
    primary key (syllabus_id, subject_id),
  constraint fk_syll_syll_subj
    foreign key (syllabus_id)
    references syllabuses(syllabus_id),
  constraint fk_subj_syll_subj
    foreign key (subject_id)
    references subjects(subject_id),
  constraint check_reporting_type
    check (reporting_type in ('Экзамен', 'Зачет', 'Зачет с оценкой'))
);

create table marks (
  mark_id number(10),
  mark number(1),
  student_id number(10) not null,
  receiving_date Date not null,
  syllabus_id number(10) not null,
  subject_id number(10) not null,
  constraint pk_mark_id 
    primary key (mark_id),
  constraint fk_syll_subj_mark
    foreign key (syllabus_id, subject_id)
    references syllabuses(syllabus_id)
);


-- sequences and triggers specialities
create sequence specialty_seq
  minvalue 1
  maxvalue 9999999999999999999999999999
  increment by 1
  nocache noorder nocycle
;
/
create trigger tr_specialities_set_id
  before insert on specialities
  for each row
begin
  if :new.specialty_id is null then
    select specialty_seq.nextval
      into :new.specialty_id 
      from dual;
  end if;
end;
/
alter trigger tr_specialities_set_id enable;
/

-- sequences and triggers syllabuses
create sequence syllabus_seq
  minvalue 1
  maxvalue 9999999999999999999999999999
  increment by 1
  nocache noorder nocycle
;
/
create trigger tr_syllabus_set_id
  before insert on syllabuses
  for each row
begin
  if :new.syllabus_id is null then
    select syllabus_seq.nextval
      into :new.syllabus_id
      from dual;
  end if;
end;
/
alter trigger tr_syllabus_set_id enable;
/


-- sequences and triggers students
create sequence student_seq
  minvalue 1
  maxvalue 9999999999999999999999999999
  increment by 1
  nocache noorder nocycle
;
/
create trigger tr_students_set_id
  before insert on students
  for each row
begin
  if :new.student_id is null then
    select student_seq.nextval
      into :new.student_id
      from dual;
  end if;
end;
/
alter trigger tr_students_set_id enable;
/

-- sequences and triggers subjects
create sequence subject_seq
  minvalue 1
  maxvalue 9999999999999999999999999999
  increment by 1
  nocache noorder nocycle
;
/
create trigger tr_subjects_set_id
  before insert on subjects
  for each row
begin
  if :new.subject_id is null then
    select subject_seq.nextval
      into :new.subject_id
      from dual;
  end if;
end;
/
alter trigger tr_subjects_set_id enable;
/


-- sequences and triggers subjects
create sequence mark_seq
  minvalue 1
  maxvalue 9999999999999999999999999999
  increment by 1
  nocache noorder nocycle
;
/
create trigger tr_marks_set_id
  before insert on marks
  for each row
begin
  if :new.mark_id is null then
    select mark_seq.nextval
      into :new.mark_id
      from dual;
  end if;
end;
/
alter trigger tr_marks_set_id enable;
/


--inserts

-- specialties
insert all
  into specialities (specialty_name) values ('ФКН')
  into specialities (specialty_name) values ('ФизФак')
select * from dual
;

-- subjects
insert all
  into subjects (subject_name) values ('математика')
  into subjects (subject_name) values ('философия')
  into subjects (subject_name) values ('программирование')
  into subjects (subject_name) values ('экономика')
  into subjects (subject_name) values ('английский')
select * from dual;

-- students
insert all
  into students (first_name, last_name, specialty_id, receipt_year) values ('Александр', 'Турищев', 1, 2019)
  into students (first_name, last_name, specialty_id, receipt_year) values ('Алексей', 'Белых', 2, 2019)
  into students (first_name, last_name, specialty_id, receipt_year) values ('Алексей', 'Николаевич', 1, 2019)
  into students (first_name, last_name, specialty_id, receipt_year) values ('Анастасия', 'Теремщук', 2, 2019)
select * from dual;


-- syllabuses
insert all
  into syllabuses (specialty_id, semester) values (1, 1)
  into syllabuses (specialty_id, semester) values (1, 2)
  into syllabuses (specialty_id, semester) values (1, 3)
  into syllabuses (specialty_id, semester) values (1, 4)
  into syllabuses (specialty_id, semester) values (1, 5)
  into syllabuses (specialty_id, semester) values (1, 6)
  into syllabuses (specialty_id, semester) values (1, 7)
  into syllabuses (specialty_id, semester) values (1, 8)
  into syllabuses (specialty_id, semester) values (2, 1)
  into syllabuses (specialty_id, semester) values (2, 2)
  into syllabuses (specialty_id, semester) values (2, 3)
  into syllabuses (specialty_id, semester) values (2, 4)
  into syllabuses (specialty_id, semester) values (2, 5)
  into syllabuses (specialty_id, semester) values (2, 6)
  into syllabuses (specialty_id, semester) values (2, 7)
  into syllabuses (specialty_id, semester) values (2, 8)
select * from dual;

-- syllabus_subjects
insert all
  into syllabus_subjects (syllabus_id, subject_id, reporting_type) values (1, 1, 'Экзамен')
  into syllabus_subjects (syllabus_id, subject_id, reporting_type) values (1, 2, 'Зачет')
  into syllabus_subjects (syllabus_id, subject_id, reporting_type) values (2, 3, 'Экзамен')
  into syllabus_subjects (syllabus_id, subject_id, reporting_type) values (2, 4, 'Зачет с оценкой')
  into syllabus_subjects (syllabus_id, subject_id, reporting_type) values (3, 5, 'Экзамен')
  into syllabus_subjects (syllabus_id, subject_id, reporting_type) values (3, 2, 'Зачет')
  into syllabus_subjects (syllabus_id, subject_id, reporting_type) values (4, 4, 'Экзамен')
  into syllabus_subjects (syllabus_id, subject_id, reporting_type) values (4, 3, 'Зачет с оценкой')
  into syllabus_subjects (syllabus_id, subject_id, reporting_type) values (5, 2, 'Зачет')
  into syllabus_subjects (syllabus_id, subject_id, reporting_type) values (5, 1, 'Экзамен')
  into syllabus_subjects (syllabus_id, subject_id, reporting_type) values (6, 2, 'Зачет с оценкой')
  into syllabus_subjects (syllabus_id, subject_id, reporting_type) values (6, 3, 'Зачет')
  into syllabus_subjects (syllabus_id, subject_id, reporting_type) values (7, 4, 'Экзамен')
  into syllabus_subjects (syllabus_id, subject_id, reporting_type) values (7, 5, 'Зачет')
  into syllabus_subjects (syllabus_id, subject_id, reporting_type) values (8, 4, 'Зачет с оценкой')
  into syllabus_subjects (syllabus_id, subject_id, reporting_type) values (8, 3, 'Зачет')
  into syllabus_subjects (syllabus_id, subject_id, reporting_type) values (9, 4, 'Зачет с оценкой')
  into syllabus_subjects (syllabus_id, subject_id, reporting_type) values (9, 3, 'Экзамен')
  into syllabus_subjects (syllabus_id, subject_id, reporting_type) values (10, 2, 'Зачет с оценкой')
  into syllabus_subjects (syllabus_id, subject_id, reporting_type) values (10, 3, 'Экзамен')
  into syllabus_subjects (syllabus_id, subject_id, reporting_type) values (11, 3, 'Зачет с оценкой')
  into syllabus_subjects (syllabus_id, subject_id, reporting_type) values (11, 4, 'Зачет с оценкой')
  into syllabus_subjects (syllabus_id, subject_id, reporting_type) values (12, 4, 'Зачет с оценкой')
  into syllabus_subjects (syllabus_id, subject_id, reporting_type) values (12, 5, 'Зачет с оценкой')
  into syllabus_subjects (syllabus_id, subject_id, reporting_type) values (13, 5, 'Зачет с оценкой')
  into syllabus_subjects (syllabus_id, subject_id, reporting_type) values (13, 1, 'Зачет')
  into syllabus_subjects (syllabus_id, subject_id, reporting_type) values (14, 2, 'Зачет с оценкой')
  into syllabus_subjects (syllabus_id, subject_id, reporting_type) values (14, 3, 'Зачет с оценкой')
  into syllabus_subjects (syllabus_id, subject_id, reporting_type) values (15, 4, 'Зачет')
  into syllabus_subjects (syllabus_id, subject_id, reporting_type) values (15, 5, 'Экзамен')
  into syllabus_subjects (syllabus_id, subject_id, reporting_type) values (16, 1, 'Зачет с оценкой')
  into syllabus_subjects (syllabus_id, subject_id, reporting_type) values (16, 2, 'Экзамен')
select * from dual;

--marks
insert all
  into marks (mark, student_id, receiving_date, syllabus_id, subject_id) values (null, 1, date'2020-01-20', 1, 1)
  into marks (mark, student_id, receiving_date, syllabus_id, subject_id) values (5, 1, date'2020-01-21', 1, 2)
  into marks (mark, student_id, receiving_date, syllabus_id, subject_id) values (4, 2, date'2020-01-20', 9, 3)
  into marks (mark, student_id, receiving_date, syllabus_id, subject_id) values (null, 2, date'2020-01-21', 9, 4)
  into marks (mark, student_id, receiving_date, syllabus_id, subject_id) values (2, 3, date'2020-01-20', 1, 1)
  into marks (mark, student_id, receiving_date, syllabus_id, subject_id) values (3, 3, date'2020-01-21', 1, 2)
  into marks (mark, student_id, receiving_date, syllabus_id, subject_id) values (2, 4, date'2020-01-20', 9, 4)
  into marks (mark, student_id, receiving_date, syllabus_id, subject_id) values (3, 4, date'2020-01-21', 9, 3)
select * from dual;

--сколько семестров проучился студент вычислять из года поступления и текущей даты – написать для этого функцию
/
create or replace
function fn_count_semesters (
  p_student_id in students.student_id%type
  ) return number
is
  v_receipt_year students.receipt_year%type;
  v_years number;
  v_months number;
  v_semesters number;
begin
  select s.receipt_year into v_receipt_year
    from students s
    where s.student_id = p_student_id;
  v_years := extract(year from sysdate) - v_receipt_year;
  v_months := extract(month from sysdate);
  v_semesters := v_years * 2;
  if (v_months < 2) then
    v_semesters := v_semesters - 1;
  end if;
  if (v_months >= 9) then
    v_semesters := v_semesters + 1;
  end if;
  return v_semesters - 1;
end;
/

--Написать запрос, выводящий список должников на текущий момент времени. 
--Должны выводиться поля: код студента, ФИО студента, курс, код предмета, 
--название предмета, семестр, оценка (2 – если сдавал экзамен, 
--нулл – если не сдавал).Сделать из этого запроса представление.
create or replace 
view count_tails_view as
select  s.student_id,
          s.first_name || ' ' || s.last_name as name,
          trunc(fn_count_semesters(s.student_id)/2) +1 as course,
          sub.subject_id,
          sub.subject_name,
          syll.semester as semester,
          m.mark
    from  students s
          inner join marks m on
            m.student_id = s.student_id
          inner join syllabus_subjects syl_sub on
            syl_sub.syllabus_id = m.syllabus_id and
            syl_sub.subject_id = m.subject_id
          inner join syllabuses syll on
            syll.syllabus_id = syl_sub.syllabus_id
          inner join subjects sub on
            syl_sub.subject_id = sub.subject_id
    where nvl(m.mark, 2) = 2;
/

--Выбрать из представления студентов с 4-мя и более хвостами (на отчисление).
select  stv.student_id,
        stv.name, 
        count(stv.student_id) as tails_count
  from  count_tails_view stv
  group by  stv.student_id,
            stv.name
  having count(stv.student_id) > 3
;