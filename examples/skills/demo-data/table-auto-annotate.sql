-- Demo data for the `table-auto-annotate` example skill
-- (examples/skills/table-auto-annotate/).
--
-- Purpose: create four obscurely named objects (XE01 employee master,
-- XT02 training records, XR03 recognition awards, XV_ET01 rollup view)
-- populated with realistic-looking data so the skill has something to
-- infer meaning from. All object and column names are intentionally
-- meaningless; there are no COMMENTs or annotations here by design.
--
-- WARNING: this script DROPS and recreates XV_ET01, XR03, XT02 and XE01.
-- Run it as the schema owner (e.g. HR) with:
--   @examples/skills/demo-data/table-auto-annotate.sql

DROP VIEW XV_ET01;
DROP TABLE XR03;
DROP TABLE XT02;
DROP TABLE XE01;

CREATE TABLE XE01 (
  c1 NUMBER        CONSTRAINT XE01_PK PRIMARY KEY,
  c2 VARCHAR2(100),
  c3 VARCHAR2(60),
  c4 VARCHAR2(20),
  c5 DATE,
  c6 VARCHAR2(120),
  c7 NUMBER(10,2),
  c8 VARCHAR2(2),
  c9 NUMBER        CONSTRAINT XE01_MGR_FK REFERENCES XE01(c1)
);

CREATE TABLE XT02 (
  c1 NUMBER        CONSTRAINT XT02_PK PRIMARY KEY,
  c2 NUMBER        NOT NULL CONSTRAINT XT02_EMP_FK REFERENCES XE01(c1),
  c3 VARCHAR2(100),
  c4 VARCHAR2(20),
  c5 DATE,
  c6 NUMBER(5,1),
  c7 NUMBER(3)
);

CREATE TABLE XR03 (
  z1 NUMBER        CONSTRAINT XR03_PK PRIMARY KEY,
  z2 NUMBER        NOT NULL CONSTRAINT XR03_EMP_FK REFERENCES XE01(c1),
  z3 VARCHAR2(30),
  z4 DATE,
  z5 NUMBER        CONSTRAINT XR03_NOM_FK REFERENCES XE01(c1),
  z6 NUMBER(4)
);
-- XE01: 60 rows
INSERT INTO XE01 VALUES (1, 'William Wilson', 'Engineering', 'ACTIVE', DATE '2015-12-09', 'william.wilson@example.com', 5561.15, 'GB', NULL);
INSERT INTO XE01 VALUES (2, 'Sarah Wright', 'Finance', 'ACTIVE', DATE '2016-11-24', 'sarah.wright@example.com', 13652.24, 'DE', NULL);
INSERT INTO XE01 VALUES (3, 'Yuki Hernandez', 'Marketing', 'ACTIVE', DATE '2024-07-02', 'yuki.hernandez@example.com', 2872.47, 'IN', NULL);
INSERT INTO XE01 VALUES (4, 'Mateo Sharma', 'Operations', 'ACTIVE', DATE '2018-09-20', 'mateo.sharma@example.com', 2831.7, 'BR', NULL);
INSERT INTO XE01 VALUES (5, 'Leila Silva', 'Support', 'ACTIVE', DATE '2025-12-18', 'leila.silva@example.com', 7744.0, 'JP', NULL);
INSERT INTO XE01 VALUES (6, 'Pieter Kovacs', 'Sales', 'PROMOTED', DATE '2024-05-26', 'pieter.kovacs@example.com', 13366.25, 'US', 2);
INSERT INTO XE01 VALUES (7, 'Robert Petrov', 'Engineering', 'ON_LEAVE', DATE '2020-05-05', 'robert.petrov@example.com', 5191.42, 'GB', 3);
INSERT INTO XE01 VALUES (8, 'Elizabeth Wang', 'Finance', 'ACTIVE', DATE '2016-07-04', 'elizabeth.wang@example.com', 6987.24, 'DE', 3);
INSERT INTO XE01 VALUES (9, 'Thomas Kumar', 'Marketing', 'TERMINATED', DATE '2019-01-24', 'thomas.kumar@example.com', 8242.81, 'IN', 1);
INSERT INTO XE01 VALUES (10, 'Ana Johnson', 'Operations', 'ON_LEAVE', DATE '2016-09-10', 'ana.johnson@example.com', 12867.56, 'BR', 5);
INSERT INTO XE01 VALUES (11, 'Sofia Wilson', 'Support', 'ACTIVE', DATE '2024-04-23', 'sofia.wilson@example.com', 3369.44, 'JP', 2);
INSERT INTO XE01 VALUES (12, 'Omar Wright', 'Sales', 'ACTIVE', DATE '2016-04-28', 'omar.wright@example.com', 3762.52, 'US', 3);
INSERT INTO XE01 VALUES (13, 'Zanele Hernandez', 'Engineering', 'PROMOTED', DATE '2025-06-06', 'zanele.hernandez@example.com', 7127.26, 'GB', 2);
INSERT INTO XE01 VALUES (14, 'Mary Sharma', 'Finance', 'ACTIVE', DATE '2025-11-03', 'mary.sharma@example.com', 10114.14, 'DE', 2);
INSERT INTO XE01 VALUES (15, 'David Silva', 'Marketing', 'ONBOARDING', DATE '2018-03-15', 'david.silva@example.com', 7243.19, 'IN', 5);
INSERT INTO XE01 VALUES (16, 'Jessica Kovacs', 'Operations', 'ACTIVE', DATE '2025-06-27', 'jessica.kovacs@example.com', 12103.92, 'BR', 1);
INSERT INTO XE01 VALUES (17, 'Carlos Petrov', 'Support', 'ACTIVE', DATE '2015-06-13', 'carlos.petrov@example.com', 5846.76, 'JP', 2);
INSERT INTO XE01 VALUES (18, 'Lars Wang', 'Sales', 'TERMINATED', DATE '2020-04-21', 'lars.wang@example.com', 8740.39, 'US', 4);
INSERT INTO XE01 VALUES (19, 'Nadia Kumar', 'Engineering', 'ACTIVE', DATE '2019-03-08', 'nadia.kumar@example.com', 11812.36, 'GB', 5);
INSERT INTO XE01 VALUES (20, 'Kwame Johnson', 'Finance', 'ACTIVE', DATE '2024-07-19', 'kwame.johnson@example.com', 7492.51, 'DE', 2);
INSERT INTO XE01 VALUES (21, 'James Wilson', 'Marketing', 'ACTIVE', DATE '2023-08-03', 'james.wilson@example.com', 11947.28, 'IN', 1);
INSERT INTO XE01 VALUES (22, 'Linda Wright', 'Operations', 'ACTIVE', DATE '2025-03-26', 'linda.wright@example.com', 11006.02, 'BR', 5);
INSERT INTO XE01 VALUES (23, 'Joseph Hernandez', 'Support', 'ACTIVE', DATE '2021-07-20', 'joseph.hernandez@example.com', 14951.52, 'JP', 5);
INSERT INTO XE01 VALUES (24, 'Fatima Sharma', 'Sales', 'ACTIVE', DATE '2023-01-22', 'fatima.sharma@example.com', 11509.02, 'US', 5);
INSERT INTO XE01 VALUES (25, 'Ingrid Silva', 'Engineering', 'ACTIVE', DATE '2025-06-04', 'ingrid.silva@example.com', 6168.75, 'GB', 2);
INSERT INTO XE01 VALUES (26, 'Dmitri Kovacs', 'Finance', 'PROMOTED', DATE '2015-12-24', 'dmitri.kovacs@example.com', 5792.36, 'DE', 5);
INSERT INTO XE01 VALUES (27, 'Aisha Petrov', 'Marketing', 'ACTIVE', DATE '2023-02-28', 'aisha.petrov@example.com', 10316.25, 'IN', 5);
INSERT INTO XE01 VALUES (28, 'Jorge Wang', 'Operations', 'TERMINATED', DATE '2018-03-12', 'jorge.wang@example.com', 12031.39, 'BR', 5);
INSERT INTO XE01 VALUES (29, 'Michael Kumar', 'Support', 'ONBOARDING', DATE '2015-10-11', 'michael.kumar@example.com', 8607.57, 'JP', 1);
INSERT INTO XE01 VALUES (30, 'Susan Johnson', 'Sales', 'ACTIVE', DATE '2019-04-02', 'susan.johnson@example.com', 5510.89, 'US', 5);
INSERT INTO XE01 VALUES (31, 'Ahmed Wilson', 'Engineering', 'ACTIVE', DATE '2016-12-16', 'ahmed.wilson@example.com', 12700.29, 'GB', 5);
INSERT INTO XE01 VALUES (32, 'Rahul Wright', 'Finance', 'ACTIVE', DATE '2017-11-16', 'rahul.wright@example.com', 14335.61, 'DE', 2);
INSERT INTO XE01 VALUES (33, 'Elena Hernandez', 'Marketing', 'ACTIVE', DATE '2023-10-14', 'elena.hernandez@example.com', 14554.54, 'IN', 5);
INSERT INTO XE01 VALUES (34, 'Wei Sharma', 'Operations', 'ACTIVE', DATE '2019-07-22', 'wei.sharma@example.com', 10623.48, 'BR', 4);
INSERT INTO XE01 VALUES (35, 'Sunita Silva', 'Support', 'ONBOARDING', DATE '2022-02-08', 'sunita.silva@example.com', 5308.72, 'JP', 3);
INSERT INTO XE01 VALUES (36, 'Jennifer Kovacs', 'Sales', 'ACTIVE', DATE '2024-09-08', 'jennifer.kovacs@example.com', 9855.5, 'US', 1);
INSERT INTO XE01 VALUES (37, 'Richard Petrov', 'Engineering', 'ACTIVE', DATE '2025-01-08', 'richard.petrov@example.com', 3342.5, 'GB', 1);
INSERT INTO XE01 VALUES (38, 'Karen Wang', 'Finance', 'ACTIVE', DATE '2016-09-08', 'karen.wang@example.com', 5980.97, 'DE', 4);
INSERT INTO XE01 VALUES (39, 'Priya Kumar', 'Marketing', 'ACTIVE', DATE '2023-03-24', 'priya.kumar@example.com', 14193.93, 'IN', 5);
INSERT INTO XE01 VALUES (40, 'Lucas Johnson', 'Operations', 'TERMINATED', DATE '2022-04-26', 'lucas.johnson@example.com', 8412.16, 'BR', 4);
INSERT INTO XE01 VALUES (41, 'Mei Wilson', 'Support', 'ACTIVE', DATE '2016-02-22', 'mei.wilson@example.com', 7888.14, 'JP', 4);
INSERT INTO XE01 VALUES (42, 'Ravi Wright', 'Sales', 'ON_LEAVE', DATE '2022-12-02', 'ravi.wright@example.com', 10917.06, 'US', 1);
INSERT INTO XE01 VALUES (43, 'John Hernandez', 'Engineering', 'ACTIVE', DATE '2021-12-11', 'john.hernandez@example.com', 12507.41, 'GB', 1);
INSERT INTO XE01 VALUES (44, 'Barbara Sharma', 'Finance', 'ACTIVE', DATE '2018-04-18', 'barbara.sharma@example.com', 8107.67, 'DE', 4);
INSERT INTO XE01 VALUES (45, 'Charles Silva', 'Marketing', 'ACTIVE', DATE '2019-08-08', 'charles.silva@example.com', 13431.07, 'IN', 1);
INSERT INTO XE01 VALUES (46, 'Kenji Kovacs', 'Operations', 'PROMOTED', DATE '2023-02-02', 'kenji.kovacs@example.com', 10651.81, 'BR', 5);
INSERT INTO XE01 VALUES (47, 'Chloe Petrov', 'Support', 'ACTIVE', DATE '2016-04-06', 'chloe.petrov@example.com', 7580.18, 'JP', 4);
INSERT INTO XE01 VALUES (48, 'Hiroshi Wang', 'Sales', 'ACTIVE', DATE '2021-01-06', 'hiroshi.wang@example.com', 7237.16, 'US', 4);
INSERT INTO XE01 VALUES (49, 'Anouk Kumar', 'Engineering', 'ACTIVE', DATE '2022-05-14', 'anouk.kumar@example.com', 11207.39, 'GB', 5);
INSERT INTO XE01 VALUES (50, 'Patricia Johnson', 'Finance', 'PROMOTED', DATE '2017-04-10', 'patricia.johnson@example.com', 5221.26, 'DE', 1);
INSERT INTO XE01 VALUES (51, 'William Wilson', 'Marketing', 'TERMINATED', DATE '2023-01-24', 'william.wilson@example.com', 6420.06, 'IN', 1);
INSERT INTO XE01 VALUES (52, 'Sarah Wright', 'Operations', 'TERMINATED', DATE '2022-09-28', 'sarah.wright@example.com', 9139.08, 'BR', 1);
INSERT INTO XE01 VALUES (53, 'Yuki Hernandez', 'Support', 'ONBOARDING', DATE '2016-03-03', 'yuki.hernandez@example.com', 9937.94, 'JP', 2);
INSERT INTO XE01 VALUES (54, 'Mateo Sharma', 'Sales', 'ON_LEAVE', DATE '2016-10-08', 'mateo.sharma@example.com', 9736.49, 'US', 1);
INSERT INTO XE01 VALUES (55, 'Leila Silva', 'Engineering', 'TERMINATED', DATE '2016-07-22', 'leila.silva@example.com', 9795.9, 'GB', 5);
INSERT INTO XE01 VALUES (56, 'Pieter Kovacs', 'Finance', 'ACTIVE', DATE '2019-04-22', 'pieter.kovacs@example.com', 11452.4, 'DE', 2);
INSERT INTO XE01 VALUES (57, 'Robert Petrov', 'Marketing', 'ACTIVE', DATE '2021-03-22', 'robert.petrov@example.com', 10568.76, 'IN', 4);
INSERT INTO XE01 VALUES (58, 'Elizabeth Wang', 'Operations', 'ACTIVE', DATE '2016-01-15', 'elizabeth.wang@example.com', 10264.49, 'BR', 5);
INSERT INTO XE01 VALUES (59, 'Thomas Kumar', 'Support', 'ACTIVE', DATE '2016-09-07', 'thomas.kumar@example.com', 8823.56, 'JP', 2);
INSERT INTO XE01 VALUES (60, 'Ana Johnson', 'Sales', 'ACTIVE', DATE '2016-04-12', 'ana.johnson@example.com', 6062.34, 'US', 4);

-- XT02: 110 rows
INSERT INTO XT02 VALUES (1, 54, 'Advanced SQL Tuning', 'CANCELLED', DATE '2023-10-26', 26.5, NULL);
INSERT INTO XT02 VALUES (2, 1, 'Cloud Architecture Basics', 'CANCELLED', DATE '2023-11-04', 37.6, NULL);
INSERT INTO XT02 VALUES (3, 9, 'Data Ethics', 'COMPLETED', DATE '2021-02-24', 22.6, 67);
INSERT INTO XT02 VALUES (4, 19, 'Project Management Fundamentals', 'COMPLETED', DATE '2023-04-22', 25.7, 66);
INSERT INTO XT02 VALUES (5, 33, 'Effective Communication', 'PLANNED', DATE '2023-01-03', 25.7, NULL);
INSERT INTO XT02 VALUES (6, 54, 'Python for Data Analysis', 'COMPLETED', DATE '2021-01-11', 31.1, 90);
INSERT INTO XT02 VALUES (7, 17, 'Negotiation Skills', 'COMPLETED', DATE '2024-09-23', 17.7, 50);
INSERT INTO XT02 VALUES (8, 8, 'Oracle Database Security', 'COMPLETED', DATE '2022-09-02', 33.5, 87);
INSERT INTO XT02 VALUES (9, 36, 'Agile Delivery', 'COMPLETED', DATE '2024-03-02', 13.0, 100);
INSERT INTO XT02 VALUES (10, 56, 'Financial Acumen', 'COMPLETED', DATE '2023-04-22', 10.7, 56);
INSERT INTO XT02 VALUES (11, 23, 'Leadership Essentials', 'CANCELLED', DATE '2024-10-24', 7.0, NULL);
INSERT INTO XT02 VALUES (12, 60, 'Advanced SQL Tuning', 'COMPLETED', DATE '2022-03-14', 2.0, 97);
INSERT INTO XT02 VALUES (13, 60, 'Cloud Architecture Basics', 'COMPLETED', DATE '2024-11-28', 29.7, 65);
INSERT INTO XT02 VALUES (14, 18, 'Data Ethics', 'COMPLETED', DATE '2021-07-28', 2.5, 80);
INSERT INTO XT02 VALUES (15, 15, 'Project Management Fundamentals', 'COMPLETED', DATE '2024-06-10', 33.0, 64);
INSERT INTO XT02 VALUES (16, 15, 'Effective Communication', 'COMPLETED', DATE '2022-07-11', 11.9, 54);
INSERT INTO XT02 VALUES (17, 50, 'Python for Data Analysis', 'COMPLETED', DATE '2023-11-17', 16.6, 84);
INSERT INTO XT02 VALUES (18, 22, 'Negotiation Skills', 'COMPLETED', DATE '2021-05-06', 23.6, 66);
INSERT INTO XT02 VALUES (19, 3, 'Oracle Database Security', 'COMPLETED', DATE '2025-07-12', 29.4, 70);
INSERT INTO XT02 VALUES (20, 28, 'Agile Delivery', 'CANCELLED', DATE '2021-07-19', 8.4, NULL);
INSERT INTO XT02 VALUES (21, 3, 'Financial Acumen', 'IN_PROGRESS', DATE '2021-09-26', 22.0, NULL);
INSERT INTO XT02 VALUES (22, 47, 'Leadership Essentials', 'COMPLETED', DATE '2023-07-03', 38.0, 71);
INSERT INTO XT02 VALUES (23, 40, 'Advanced SQL Tuning', 'COMPLETED', DATE '2021-12-10', 20.8, 92);
INSERT INTO XT02 VALUES (24, 27, 'Cloud Architecture Basics', 'COMPLETED', DATE '2024-12-10', 22.6, 62);
INSERT INTO XT02 VALUES (25, 27, 'Data Ethics', 'IN_PROGRESS', DATE '2022-10-19', 12.7, NULL);
INSERT INTO XT02 VALUES (26, 36, 'Project Management Fundamentals', 'COMPLETED', DATE '2023-05-07', 17.8, 87);
INSERT INTO XT02 VALUES (27, 39, 'Effective Communication', 'COMPLETED', DATE '2024-08-15', 27.3, 82);
INSERT INTO XT02 VALUES (28, 31, 'Python for Data Analysis', 'COMPLETED', DATE '2021-05-17', 26.9, 89);
INSERT INTO XT02 VALUES (29, 22, 'Negotiation Skills', 'COMPLETED', DATE '2022-11-10', 9.8, 62);
INSERT INTO XT02 VALUES (30, 10, 'Oracle Database Security', 'COMPLETED', DATE '2021-04-16', 24.8, 99);
INSERT INTO XT02 VALUES (31, 5, 'Agile Delivery', 'PLANNED', DATE '2024-11-19', 8.6, NULL);
INSERT INTO XT02 VALUES (32, 45, 'Financial Acumen', 'IN_PROGRESS', DATE '2024-07-08', 6.8, NULL);
INSERT INTO XT02 VALUES (33, 45, 'Leadership Essentials', 'COMPLETED', DATE '2021-07-08', 7.9, 94);
INSERT INTO XT02 VALUES (34, 34, 'Advanced SQL Tuning', 'PLANNED', DATE '2021-09-08', 36.8, NULL);
INSERT INTO XT02 VALUES (35, 8, 'Cloud Architecture Basics', 'PLANNED', DATE '2022-08-22', 21.7, NULL);
INSERT INTO XT02 VALUES (36, 36, 'Data Ethics', 'COMPLETED', DATE '2024-10-27', 29.1, 82);
INSERT INTO XT02 VALUES (37, 28, 'Project Management Fundamentals', 'CANCELLED', DATE '2024-03-24', 34.6, NULL);
INSERT INTO XT02 VALUES (38, 29, 'Effective Communication', 'COMPLETED', DATE '2022-11-09', 30.9, 83);
INSERT INTO XT02 VALUES (39, 32, 'Python for Data Analysis', 'COMPLETED', DATE '2023-08-03', 28.8, 65);
INSERT INTO XT02 VALUES (40, 18, 'Negotiation Skills', 'COMPLETED', DATE '2023-09-03', 6.4, 64);
INSERT INTO XT02 VALUES (41, 25, 'Oracle Database Security', 'COMPLETED', DATE '2022-02-14', 16.9, 84);
INSERT INTO XT02 VALUES (42, 30, 'Agile Delivery', 'IN_PROGRESS', DATE '2021-04-27', 17.4, NULL);
INSERT INTO XT02 VALUES (43, 58, 'Financial Acumen', 'COMPLETED', DATE '2025-07-16', 1.2, 72);
INSERT INTO XT02 VALUES (44, 20, 'Leadership Essentials', 'IN_PROGRESS', DATE '2024-09-24', 29.7, NULL);
INSERT INTO XT02 VALUES (45, 52, 'Advanced SQL Tuning', 'COMPLETED', DATE '2024-04-09', 18.0, 51);
INSERT INTO XT02 VALUES (46, 25, 'Cloud Architecture Basics', 'COMPLETED', DATE '2024-12-06', 33.8, 58);
INSERT INTO XT02 VALUES (47, 40, 'Data Ethics', 'CANCELLED', DATE '2021-07-19', 23.0, NULL);
INSERT INTO XT02 VALUES (48, 2, 'Project Management Fundamentals', 'COMPLETED', DATE '2024-03-28', 19.0, 53);
INSERT INTO XT02 VALUES (49, 17, 'Effective Communication', 'IN_PROGRESS', DATE '2023-04-15', 13.7, NULL);
INSERT INTO XT02 VALUES (50, 49, 'Python for Data Analysis', 'IN_PROGRESS', DATE '2023-07-09', 33.6, NULL);
INSERT INTO XT02 VALUES (51, 31, 'Negotiation Skills', 'COMPLETED', DATE '2025-01-12', 9.7, 54);
INSERT INTO XT02 VALUES (52, 50, 'Oracle Database Security', 'COMPLETED', DATE '2021-04-07', 33.7, 89);
INSERT INTO XT02 VALUES (53, 10, 'Agile Delivery', 'COMPLETED', DATE '2022-08-22', 5.5, 63);
INSERT INTO XT02 VALUES (54, 30, 'Financial Acumen', 'COMPLETED', DATE '2023-03-20', 24.7, 97);
INSERT INTO XT02 VALUES (55, 46, 'Leadership Essentials', 'COMPLETED', DATE '2022-05-04', 23.6, 69);
INSERT INTO XT02 VALUES (56, 37, 'Advanced SQL Tuning', 'IN_PROGRESS', DATE '2024-12-07', 4.0, NULL);
INSERT INTO XT02 VALUES (57, 45, 'Cloud Architecture Basics', 'COMPLETED', DATE '2021-12-25', 12.8, 93);
INSERT INTO XT02 VALUES (58, 39, 'Data Ethics', 'COMPLETED', DATE '2025-01-12', 21.8, 92);
INSERT INTO XT02 VALUES (59, 24, 'Project Management Fundamentals', 'COMPLETED', DATE '2025-11-11', 1.5, 76);
INSERT INTO XT02 VALUES (60, 53, 'Effective Communication', 'PLANNED', DATE '2021-07-12', 25.8, NULL);
INSERT INTO XT02 VALUES (61, 54, 'Python for Data Analysis', 'PLANNED', DATE '2022-07-06', 29.6, NULL);
INSERT INTO XT02 VALUES (62, 42, 'Negotiation Skills', 'COMPLETED', DATE '2025-09-25', 19.9, 77);
INSERT INTO XT02 VALUES (63, 53, 'Oracle Database Security', 'COMPLETED', DATE '2023-04-27', 37.5, 67);
INSERT INTO XT02 VALUES (64, 57, 'Agile Delivery', 'PLANNED', DATE '2022-08-19', 24.8, NULL);
INSERT INTO XT02 VALUES (65, 25, 'Financial Acumen', 'COMPLETED', DATE '2021-08-28', 13.7, 81);
INSERT INTO XT02 VALUES (66, 14, 'Leadership Essentials', 'COMPLETED', DATE '2023-06-09', 35.3, 94);
INSERT INTO XT02 VALUES (67, 57, 'Advanced SQL Tuning', 'COMPLETED', DATE '2025-01-17', 38.0, 55);
INSERT INTO XT02 VALUES (68, 16, 'Cloud Architecture Basics', 'IN_PROGRESS', DATE '2024-09-25', 10.4, NULL);
INSERT INTO XT02 VALUES (69, 31, 'Data Ethics', 'PLANNED', DATE '2024-01-03', 12.5, NULL);
INSERT INTO XT02 VALUES (70, 26, 'Project Management Fundamentals', 'COMPLETED', DATE '2023-11-19', 15.4, 85);
INSERT INTO XT02 VALUES (71, 34, 'Effective Communication', 'COMPLETED', DATE '2024-12-18', 13.9, 94);
INSERT INTO XT02 VALUES (72, 30, 'Python for Data Analysis', 'COMPLETED', DATE '2023-05-08', 5.7, 62);
INSERT INTO XT02 VALUES (73, 21, 'Negotiation Skills', 'COMPLETED', DATE '2025-12-06', 8.5, 97);
INSERT INTO XT02 VALUES (74, 31, 'Oracle Database Security', 'COMPLETED', DATE '2025-09-20', 12.0, 56);
INSERT INTO XT02 VALUES (75, 54, 'Agile Delivery', 'COMPLETED', DATE '2023-04-12', 8.0, 50);
INSERT INTO XT02 VALUES (76, 46, 'Financial Acumen', 'CANCELLED', DATE '2022-05-02', 39.0, NULL);
INSERT INTO XT02 VALUES (77, 36, 'Leadership Essentials', 'COMPLETED', DATE '2022-11-28', 30.4, 56);
INSERT INTO XT02 VALUES (78, 56, 'Advanced SQL Tuning', 'COMPLETED', DATE '2025-05-16', 19.7, 71);
INSERT INTO XT02 VALUES (79, 12, 'Cloud Architecture Basics', 'COMPLETED', DATE '2023-08-04', 33.1, 75);
INSERT INTO XT02 VALUES (80, 32, 'Data Ethics', 'COMPLETED', DATE '2025-11-22', 3.1, 59);
INSERT INTO XT02 VALUES (81, 52, 'Project Management Fundamentals', 'COMPLETED', DATE '2021-04-04', 22.8, 76);
INSERT INTO XT02 VALUES (82, 39, 'Effective Communication', 'COMPLETED', DATE '2025-07-15', 36.4, 69);
INSERT INTO XT02 VALUES (83, 56, 'Python for Data Analysis', 'IN_PROGRESS', DATE '2023-10-20', 3.3, NULL);
INSERT INTO XT02 VALUES (84, 48, 'Negotiation Skills', 'COMPLETED', DATE '2022-11-07', 11.3, 55);
INSERT INTO XT02 VALUES (85, 11, 'Oracle Database Security', 'COMPLETED', DATE '2022-09-03', 7.1, 76);
INSERT INTO XT02 VALUES (86, 29, 'Agile Delivery', 'PLANNED', DATE '2023-01-08', 12.2, NULL);
INSERT INTO XT02 VALUES (87, 19, 'Financial Acumen', 'PLANNED', DATE '2021-11-08', 37.0, NULL);
INSERT INTO XT02 VALUES (88, 51, 'Leadership Essentials', 'COMPLETED', DATE '2024-02-18', 9.8, 59);
INSERT INTO XT02 VALUES (89, 59, 'Advanced SQL Tuning', 'COMPLETED', DATE '2022-02-02', 7.5, 69);
INSERT INTO XT02 VALUES (90, 39, 'Cloud Architecture Basics', 'COMPLETED', DATE '2024-02-15', 27.9, 94);
INSERT INTO XT02 VALUES (91, 26, 'Data Ethics', 'COMPLETED', DATE '2025-09-16', 18.1, 88);
INSERT INTO XT02 VALUES (92, 3, 'Project Management Fundamentals', 'IN_PROGRESS', DATE '2023-10-09', 2.0, NULL);
INSERT INTO XT02 VALUES (93, 15, 'Effective Communication', 'COMPLETED', DATE '2023-10-02', 30.8, 61);
INSERT INTO XT02 VALUES (94, 31, 'Python for Data Analysis', 'CANCELLED', DATE '2024-05-06', 39.9, NULL);
INSERT INTO XT02 VALUES (95, 28, 'Negotiation Skills', 'PLANNED', DATE '2021-08-12', 16.9, NULL);
INSERT INTO XT02 VALUES (96, 21, 'Oracle Database Security', 'COMPLETED', DATE '2022-06-14', 28.1, 68);
INSERT INTO XT02 VALUES (97, 43, 'Agile Delivery', 'IN_PROGRESS', DATE '2025-01-15', 4.4, NULL);
INSERT INTO XT02 VALUES (98, 17, 'Financial Acumen', 'COMPLETED', DATE '2021-07-28', 21.1, 50);
INSERT INTO XT02 VALUES (99, 43, 'Leadership Essentials', 'CANCELLED', DATE '2024-07-02', 8.3, NULL);
INSERT INTO XT02 VALUES (100, 24, 'Advanced SQL Tuning', 'PLANNED', DATE '2024-01-07', 11.4, NULL);
INSERT INTO XT02 VALUES (101, 9, 'Cloud Architecture Basics', 'COMPLETED', DATE '2024-12-16', 5.7, 90);
INSERT INTO XT02 VALUES (102, 39, 'Data Ethics', 'COMPLETED', DATE '2022-05-18', 1.5, 76);
INSERT INTO XT02 VALUES (103, 6, 'Project Management Fundamentals', 'COMPLETED', DATE '2021-08-04', 26.3, 59);
INSERT INTO XT02 VALUES (104, 32, 'Effective Communication', 'COMPLETED', DATE '2025-12-09', 17.2, 80);
INSERT INTO XT02 VALUES (105, 31, 'Python for Data Analysis', 'COMPLETED', DATE '2024-09-05', 16.0, 88);
INSERT INTO XT02 VALUES (106, 33, 'Negotiation Skills', 'COMPLETED', DATE '2021-05-25', 31.8, 76);
INSERT INTO XT02 VALUES (107, 22, 'Oracle Database Security', 'CANCELLED', DATE '2023-01-10', 29.3, NULL);
INSERT INTO XT02 VALUES (108, 54, 'Agile Delivery', 'PLANNED', DATE '2022-08-18', 19.9, NULL);
INSERT INTO XT02 VALUES (109, 22, 'Financial Acumen', 'CANCELLED', DATE '2025-07-15', 37.4, NULL);
INSERT INTO XT02 VALUES (110, 56, 'Leadership Essentials', 'COMPLETED', DATE '2022-10-13', 10.1, 99);

-- XR03: 45 rows
INSERT INTO XR03 VALUES (1, 32, 'Leadership', DATE '2022-06-24', 31, 772);
INSERT INTO XR03 VALUES (2, 57, 'Innovation', DATE '2025-07-22', 51, 890);
INSERT INTO XR03 VALUES (3, 47, 'Customer Focus', DATE '2023-08-02', 9, 564);
INSERT INTO XR03 VALUES (4, 43, 'Mentoring', DATE '2024-02-28', 55, 500);
INSERT INTO XR03 VALUES (5, 12, 'Teamwork', DATE '2025-01-24', 10, 469);
INSERT INTO XR03 VALUES (6, 47, 'Leadership', DATE '2023-02-16', 51, 321);
INSERT INTO XR03 VALUES (7, 27, 'Innovation', DATE '2025-11-03', 55, 386);
INSERT INTO XR03 VALUES (8, 60, 'Customer Focus', DATE '2025-06-21', 46, 958);
INSERT INTO XR03 VALUES (9, 54, 'Mentoring', DATE '2025-09-02', 40, 120);
INSERT INTO XR03 VALUES (10, 21, 'Teamwork', DATE '2024-04-24', 6, 494);
INSERT INTO XR03 VALUES (11, 12, 'Leadership', DATE '2022-08-06', 45, 356);
INSERT INTO XR03 VALUES (12, 7, 'Innovation', DATE '2022-06-26', 4, 350);
INSERT INTO XR03 VALUES (13, 28, 'Customer Focus', DATE '2024-07-05', 16, 593);
INSERT INTO XR03 VALUES (14, 32, 'Mentoring', DATE '2023-03-06', 6, 674);
INSERT INTO XR03 VALUES (15, 30, 'Teamwork', DATE '2023-08-19', 10, 287);
INSERT INTO XR03 VALUES (16, 35, 'Leadership', DATE '2024-08-09', 43, 59);
INSERT INTO XR03 VALUES (17, 57, 'Innovation', DATE '2025-05-22', 35, 211);
INSERT INTO XR03 VALUES (18, 10, 'Customer Focus', DATE '2025-06-19', 20, 704);
INSERT INTO XR03 VALUES (19, 33, 'Mentoring', DATE '2024-08-28', 20, 253);
INSERT INTO XR03 VALUES (20, 30, 'Teamwork', DATE '2025-02-08', 25, 635);
INSERT INTO XR03 VALUES (21, 28, 'Leadership', DATE '2024-12-10', 2, 899);
INSERT INTO XR03 VALUES (22, 48, 'Innovation', DATE '2025-05-01', 37, 935);
INSERT INTO XR03 VALUES (23, 49, 'Customer Focus', DATE '2022-10-24', 32, 902);
INSERT INTO XR03 VALUES (24, 24, 'Mentoring', DATE '2023-10-26', 23, 274);
INSERT INTO XR03 VALUES (25, 46, 'Teamwork', DATE '2023-10-09', 44, 823);
INSERT INTO XR03 VALUES (26, 52, 'Leadership', DATE '2023-11-04', 58, 692);
INSERT INTO XR03 VALUES (27, 47, 'Innovation', DATE '2022-05-26', 29, 84);
INSERT INTO XR03 VALUES (28, 43, 'Customer Focus', DATE '2024-12-05', 6, 981);
INSERT INTO XR03 VALUES (29, 24, 'Mentoring', DATE '2024-12-14', 12, 255);
INSERT INTO XR03 VALUES (30, 14, 'Teamwork', DATE '2024-09-17', 59, 329);
INSERT INTO XR03 VALUES (31, 59, 'Leadership', DATE '2023-05-27', 31, 875);
INSERT INTO XR03 VALUES (32, 24, 'Innovation', DATE '2024-02-15', 5, 194);
INSERT INTO XR03 VALUES (33, 54, 'Customer Focus', DATE '2023-11-24', 44, 456);
INSERT INTO XR03 VALUES (34, 60, 'Mentoring', DATE '2024-02-26', 26, 64);
INSERT INTO XR03 VALUES (35, 22, 'Teamwork', DATE '2022-08-12', 44, 816);
INSERT INTO XR03 VALUES (36, 49, 'Leadership', DATE '2024-10-13', 53, 703);
INSERT INTO XR03 VALUES (37, 29, 'Innovation', DATE '2022-11-08', 31, 75);
INSERT INTO XR03 VALUES (38, 45, 'Customer Focus', DATE '2024-10-08', 42, 114);
INSERT INTO XR03 VALUES (39, 46, 'Mentoring', DATE '2025-12-10', 42, 468);
INSERT INTO XR03 VALUES (40, 13, 'Teamwork', DATE '2023-01-02', 20, 554);
INSERT INTO XR03 VALUES (41, 13, 'Leadership', DATE '2022-04-18', 9, 447);
INSERT INTO XR03 VALUES (42, 35, 'Innovation', DATE '2024-11-24', 45, 603);
INSERT INTO XR03 VALUES (43, 32, 'Customer Focus', DATE '2023-07-21', 7, 903);
INSERT INTO XR03 VALUES (44, 37, 'Mentoring', DATE '2025-05-02', 45, 429);
INSERT INTO XR03 VALUES (45, 19, 'Teamwork', DATE '2025-08-08', 55, 421);

CREATE VIEW XV_ET01 AS
SELECT e.c2                       AS k1,
       e.c3                       AS k2,
       (SELECT COUNT(*) FROM XT02 t
         WHERE t.c2 = e.c1 AND t.c4 = 'COMPLETED') AS k3,
       (SELECT NVL(SUM(t.c6), 0) FROM XT02 t
         WHERE t.c2 = e.c1 AND t.c4 = 'COMPLETED') AS k4,
       (SELECT NVL(SUM(r.z6), 0) FROM XR03 r
         WHERE r.z2 = e.c1)                        AS k5
FROM   XE01 e;

COMMIT;
