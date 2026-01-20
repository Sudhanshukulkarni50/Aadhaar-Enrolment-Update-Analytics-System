-- Biometric Updates Table
create table aadhar_biometric(
date date,
state varchar(20),
district varchar(20),
pincode int,
bio_age_5_17 int,
bio_age_17_ int
);

-- Demographic Updates Table
create table aadhar_demographic(
date date,
state varchar(20),
district varchar(20),
pincode int,
demo_age_5_17 int,
demo_age_17_ int
);

-- Enrolment Table
create table aadhar_enrollment(
date date,
state varchar(20),
district varchar(20),
pincode int,
age_0_5 int,
age_5_17 int,
age_18_greater int
);

select * from aadhar_demographic;
select * from aadhar_demographic;
select * from aadhar_enrollment;

-- Removed Wrong Inputs of Data ----
select * from aadhar_enrollment
where state = 'Orissa';

select state from aadhar_biometric
where district = 'South 24 Parganas';

delete from aadhar_demographic
where state = '100000';
update aadhar_enrollment
set state = 'Odisha' where state = 'Orissa';

update aadhar_demographic
set state = 'Bihar' where state = 'Darbhanga';

update aadhar_demographic
set state = 'Maharashtra' where state = 'Nagpur';

update aadhar_demographic
set state = 'Tamil Nadu' where state = 'Raja Annamalai Puram';

select * from aadhar_enrollment
where state = 'Chhatisgarh';

update aadhar_biometric
set state = 'Chhattisgarh' where state = 'Chhatisgarh';

update aadhar_demographic
set state = 'Chhattisgarh' where state = 'Chhatisgarh';

update aadhar_biometric
set state = 'Tamil Nadu' where state = 'Tamilnadu';

select * from aadhar_enrollment
where state = 'Pondicherry';

update aadhar_enrollment
set state = 'Puducherry' where state = 'Pondicherry'



select * from aadhar_biometric
where state = 'Andaman And Nicobar Islands';



set district = 'Dadra and Nagar Haveli' where state = 'Dadra and Nagar Haveli';

-- Normalize Daman & Diu
update aadhar_biometric
set state = 'Daman and Diu' where district in ('Daman','Diu');

alter table aadhar_biometric aadhar_biometric
rename bio_age_5_17 to bio_age_5_to_17;

alter table aadhar_demographic
rename demo_age_5_17 to demo_age_5_to_17;

alter table aadhar_enrollment
rename age_0_5 to age_0_to_5;

alter table aadhar_enrollment
rename age_5_17 to age_5_to_17;

alter table aadhar_enrollment
rename age_18_greater to age_18_plus;

-- Identify inconsistent district names
select * from aadhar_enrollment
where district like '%Daman%';

-- Normalize Dadra & Nagar Haveli
update aadhar_enrollment
set state = 'Dadra and Nagar Haveli' where district = 'Dadra And Nagar Haveli';

update aadhar_enrollment
set state = 'Dadra and Nagar Haveli' where district = 'Dadra & Nagar Haveli';

update aadhar_enrollment
set district = 'Dadra and Nagar Haveli' where state = 'Dadra and Nagar Haveli';

-- Normalize Daman & Diu
update aadhar_enrollment
set state = 'Daman and Diu' where district in ('Daman','Diu');



-- INSIGHT (1):  Aadhaar enrolment evolution over time across different age groups --


SELECT
    trim(to_char(date,'Month')) AS month,
	extract(month from date) as month_num,
    SUM(age_0_to_5)     AS enroll_age_0_to_5,
    SUM(age_5_to_17)    AS enroll_age_5_to_17,
    SUM(age_18_plus)    AS enroll_age_18_plus,
    SUM(age_0_to_5 + age_5_to_17 + age_18_plus) 
        AS total_enrollments
FROM aadhar_enrollment
GROUP BY month,month_num
order by month_num asc;


-- INSIGHT (2): Demographic vs Biometric Update Load 

with biometric_updates as (
select trim(to_char(date,'Month')) as month_name,
extract(month from date) as month_no,
sum(bio_age_5_to_17) as bio_people_age_5_to_17,
sum(bio_age_17_) as bio_people_age_18_plus
from aadhar_biometric
group by month_name,month_no
),
demographic_updates as (
select trim(to_char(date,'Month')) as month_name,
extract(month from date) as month_no,
sum(demo_age_5_to_17) as demo_people_age_5_to_17,
sum(demo_age_17_) as demo_people_age_18_plus
from aadhar_demographic
group by month_name,month_no
)

select b.month_name,b.bio_people_age_5_to_17,
b.bio_people_age_18_plus,d.demo_people_age_5_to_17,
d.demo_people_age_18_plus from biometric_updates b
join demographic_updates d 
on b.month_no = d.month_no
order by b.month_no;


-- Insight (3): Update-to-Enrolment Ratio (18+ Stability Indicator)


with biometric_updates as (
select extract(month from date) as month_no,
trim(to_char(date,'Month')) as month_name,
sum(bio_age_17_) as bio_age_18_plus
from aadhar_biometric
group by month_no,month_name
),
demographic_updates as (
select extract(month from date) as month_no,
trim(to_char(date,'Month')) as month_name,
sum(demo_age_17_) as demo_age_18_plus
from aadhar_demographic
group by month_no,month_name
),
enrollment_updates as(
select extract(month from date) as month_no,
trim(to_char(date,'Month')) as month_name,
sum(age_18_plus) as enrolled_age_18_plus
from aadhar_enrollment
group by month_no, month_name
)
select b.month_name,e.enrolled_age_18_plus as enrolled_18_plus,(b.bio_age_18_plus+d.demo_age_18_plus) as updates_age_18_plus,
round(
(b.bio_age_18_plus+d.demo_age_18_plus)::numeric/nullif(e.enrolled_age_18_plus,0),2) as update_to_enroll_ratio from biometric_updates b
join demographic_updates d
on b.month_no = d.month_no
join enrollment_updates e
on d.month_no = e.month_no;

-- Insight (4): State-wise Adult Update Intensity

with biometric_updates as (
select state, sum(bio_age_17_) as bio_age_18_plus
from aadhar_biometric
group by state
),
demographic_updates as (
select state, sum(demo_age_17_) as demo_age_18_plus
from aadhar_demographic
group by state
),
enrollment_updates as (
select state, sum(age_18_plus) as enrolled_age_18_plus
from aadhar_enrollment
group by state
)

select e.state, e.enrolled_age_18_plus as total_adult_enrollments,
(b.bio_age_18_plus+d.demo_age_18_plus) as total_updates,
round(
((b.bio_age_18_plus+d.demo_age_18_plus::numeric/nullif(e.enrolled_age_18_plus,0))*1000),2
)  as updates_per_1000_enrollments from enrollment_updates e 
join biometric_updates b
on e.state = b.state
join demographic_updates d 
on e.state = d.state;

-- Insight (5): District-Level Hotspots & Data Governance Gaps

with biometric_updates as (
select state,district, sum(bio_age_17_) as bio_age_18_plus
from aadhar_biometric
group by state,district
),
demographic_updates as (
select state,district, sum(demo_age_17_) as demo_age_18_plus
from aadhar_demographic
group by state,district
),
enrollment_updates as (
select state,district, sum(age_18_plus) as enrolled_age_18_plus
from aadhar_enrollment
group by state,district
)
select  e.state, e.district, e.enrolled_age_18_plus as total_adult_enrollments,
(b.bio_age_18_plus+d.demo_age_18_plus) as total_adult_updates,
round(
((b.bio_age_18_plus+d.demo_age_18_plus::numeric/nullif(e.enrolled_age_18_plus,0))*1000),2
) as updates_per_1000_enrollments from enrollment_updates e
join biometric_updates b
on e.state = b.state and e.district = b.district
join demographic_updates  d
on e.state = d.state and e.district = d.district
where e.enrolled_age_18_plus>500
order by updates_per_1000_enrollments desc
limit 20;













