#!/bin/bash

# Created by Carlos Tutte 16th June, 2021 as a proof of concept for Percona blogpost

# local db credentials
USER=root
PASS=sekret
MYSQL_BIN=/usr/bin/mysql

# Variables for pt-archiver
PT_ARCHIVER=/usr/bin/pt-archiver
SOURCE_DSN='h=localhost,P=3306,u=root,p=sekret,D=blogpost'


$MYSQL_BIN -u $USER -p$PASS -e "CREATE DATABASE IF NOT EXISTS percona;"

STATUS=`echo $?`
if [ $STATUS -ne 0 ]
then
  echo "Percona DB could not be created, exiting"
  exit 1
fi

echo "Created Percona DB"

$MYSQL_BIN -u $USER -p$PASS -e "CREATE TABLE IF NOT EXISTS percona.tmp_ids_to_remove (table1_id int, table2_id int, table3_id int, table4_id int, KEY ix1 (table1_id), KEY ix2 (table2_id), KEY ix3 (table3_id), KEY ix4 (table4_id) );"

STATUS=`echo $?`
if [ $STATUS -ne 0 ]
then
  echo "Table tmp_ids_to_remove could not be created, exiting"
  exit 1
fi

echo "Created temporary table"


# Check if table is empty
# Otherwise it might be still full from a previous run. 
# You should manually check if the rows were already archived. If not, use pt-archiver to archive them
# then truncate the table to start from scratch
$MYSQL_BIN -u $USER -p$PASS -e "SELECT COUNT(*) FROM percona.tmp_ids_to_remove LIMIT 1;" > /tmp/check.out

STATUS=`echo $?`
if [ $STATUS -ne 0 ]
then
  echo "Could not check if tmp_ids_to_remove table was empty, exiting"
  exit 1
fi

RESULT=`cat /tmp/check.out | tail -n 1`
if [ $RESULT -ne 0 ]
then
  echo "Table tmp_ids_to_remove is NOT empty. You should manually check if the rows were archived and manually truncate table afterwards, exiting"
  exit 1
fi

echo "Temporary table is empty which is correct, continuing execution"

##########################################################################################################################
###################################################### SCRIPT START ######################################################
##########################################################################################################################

# Fetching the ids for archiving:
$MYSQL_BIN -u $USER -p$PASS blogpost -e " INSERT INTO percona.tmp_ids_to_remove ( SELECT table1.id, table2.id, table3.id, table4.id FROM table1 INNER JOIN table3 ON table1.id = table3.table1_id INNER JOIN table2 ON table1.table2_id = table2.id INNER JOIN table4 ON (table3.table4_id = table4.id AND table4.cond = 'Value1') WHERE table1.created_at < '2020-01-01 00:00:00');" 

STATUS=`echo $?`
if [ $STATUS -ne 0 ]
then
  echo "Could not fetch rows for archiving, exiting"
  exit 1
fi


##########################################################################
# Now that the percona.tmp_ids_to_remove table was populated, it's time to archive the ID's for each of the tables. Let's go in this order:
# 1st archive table1 -> table2 -> table3 -> table4
##########################################################################


# table1
$PT_ARCHIVER --source $SOURCE_DSN,t=table1 \
--file /tmp/table1.out \
--no-check-charset \
--purge \
--progress 10000 \
--statistics \
--why-quit \
--limit 1 \
--commit-each \
--where 'EXISTS(SELECT table1_id FROM percona.tmp_ids_to_remove purge_t WHERE id=purge_t.table1_id)'

STATUS=`echo $?`
if [ $STATUS -ne 0 ]
then
  echo "Something went wrong archiving table table1, exiting"
  exit 1
fi

echo "Archive of table table1 finished"

##########################################################################

# table2
$PT_ARCHIVER --source $SOURCE_DSN,t=table2 \
--file /tmp/table2.out \
--no-check-charset \
--purge \
--progress 10000 \
--statistics \
--why-quit \
--limit 1 \
--commit-each \
--where 'EXISTS(SELECT table2_id FROM percona.tmp_ids_to_remove purge_t WHERE id=purge_t.table2_id)'

STATUS=`echo $?`
if [ $STATUS -ne 0 ]
then
  echo "Something went wrong archiving table table2, exiting"
  exit 1
fi

echo "Archive of table table2 finished"

##########################################################################

# table3
$PT_ARCHIVER --source $SOURCE_DSN,t=table3 \
--file /tmp/table3.out \
--no-check-charset \
--purge \
--progress 10000 \
--statistics \
--why-quit \
--limit 1 \
--commit-each \
--where 'EXISTS(SELECT table3_id FROM percona.tmp_ids_to_remove purge_t WHERE id=purge_t.table3_id)'

STATUS=`echo $?`
if [ $STATUS -ne 0 ]
then
  echo "Something went wrong archiving table table3, exiting"
  exit 1
fi

echo "Archive of table table3 finished"

##########################################################################

# table4
$PT_ARCHIVER --source $SOURCE_DSN,t=table4 \
--file /tmp/table4.out \
--no-check-charset \
--purge \
--progress 10000 \
--statistics \
--why-quit \
--limit 1 \
--commit-each \
--where 'EXISTS(SELECT table4_id FROM percona.tmp_ids_to_remove purge_t WHERE id=purge_t.table4_id)'

STATUS=`echo $?`
if [ $STATUS -ne 0 ]
then
  echo "Something went wrong archiving table table4, exiting"
  exit 1
fi

echo "Archive of table table4 finished"

##########################################################################

echo "Script executed succesfully complete!"
exit 0

