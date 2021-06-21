CREATE DATABASE blogpost;
USE blogpost;

CREATE TABLE table1 (id int auto_increment primary key, table2_id int, created_at date);
CREATE TABLE table2 (id int auto_increment primary key);
CREATE TABLE table3 (id int auto_increment primary key, table1_id int, table4_id int);
CREATE TABLE table4 (id int auto_increment primary key, cond varchar(20));

INSERT INTO table1 values (1, 1, '2019-01-01 00:00:00'), (2, 2, '2019-01-01 00:00:00'), (3, 3, '2019-01-01 00:00:00'), (4, 4, '2020-01-01 00:00:00');
INSERT INTO table2 values (1), (2), (3), (4);
INSERT INTO table3 values (1, 1, 1), (2, 1, 1), (3, 1, 1), (4, 2, 2), (5, 3, 3);
INSERT INTO table4 values (1, "Value1"), (2, "Value2"), (3, "Value1");


