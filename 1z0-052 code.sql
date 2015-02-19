-- Chapter 2: Exploring the Database Architecture

/**** Exercise 2-1 Determine if the Database Is Single Instance or Part 
of a Distributed System */

-- Determine if the instance is part of an RAC database:
select parallel from v$instance;

-- Determine if the database is protected against data loss by a standby database:
select protection_level from v$database;

-- Determine if Streams has been configured in the database:
select * from dba_streams_administrator;

/**** Exercise 2-2 Investigate the Memory Structures of the Instance*/

/* Show the current, maximum, and minimum sizes of the SGA components
that can be dynamically resized: */
select COMPONENT,CURRENT_SIZE,MIN_SIZE,MAX_SIZE
from v$sga_dynamic_components;

/* Determine how much memory has been, and is currently, allocated to
program global areas: */
select name,value from v$pgastat
where name in ('maximum PGA allocated','total PGA allocated');

/**** Exercise 2-3 Investigate the Processes Running in Your Instance */

-- Determine what processes are running, and how many of each:
select program from v$session order by program;
select program from v$process order by program;

/**** Exercise 2-4 Investigate the Storage Structures in Your Database */

/* Create a table without nominating a tablespace—it will be created in your
default tablespace, with one extent: */
create table tab24 (c1 varchar2(10));

/* Identify the tablespace in which the table resides, the size of the extent, the
file number the extent is in, and which block of the file the extent starts at: */
select tablespace_name, extent_id, bytes, file_id, block_id
from dba_extents where owner='SYSTEM' and segment_name='TAB24';

/* Identify the file by name: substitute the file_id from the previous query when
prompted: */
select name from v$datafile where file#=&file_id;

/* Work out precisely where in the file the extent is, in terms of how many
bytes into the file it begins. This requires finding out the tablespace’s block
size. Enter the block_id and tablespace_name returned by the query in Step 3
when prompted.*/
select block_size * &block_id from dba_tablespaces
where tablespace_name='&tablespace_name';

/**** LAB QUESTION
Simulate the situation a DBA will find himself/herself in many times: he/she has been asked to take
on management of a database that he/she has not seen before, and for which the documentation is
woefully inadequate. Using either SQL Developer or SQL*Plus, write a series of queries that will
begin to document the system. Following are some of the views that will help: describe each view and
then query the relevant columns. To see the views, it will be necessary to connect as a user with high
privileges, such as user SYSTEM.
■ V$DATABASE On what operating system is the database is running?
■ V$CONTROLFILE Where is the controlfile? Is it multiplexed?
■ V$LOG, V$LOGFILE How many online log file groups are there? How many members are
in each group, and what are they called? How big are they?
■ V$TABLESPACE, V$DATAFILE What tablespaces exist in the database? What datafiles
are assigned to each tablespace? What are they called, and how big are they?
*/

-- return the operating system that database is running on
select platform_name from v$database;

-- return one row for each copy of the controlfile
select name from v$controlfile;

/* The first query will show how many groups exist, their size, and how many members each group
has. The second lists the name of each member and the group to which it belongs.*/
select group#,bytes,members from v$log;
select group#,member from v$logfile;

-- list the tablespaces, with their datafile(s).
select t.name tname,d.name fname,bytes
from v$tablespace t join v$datafile d on t.ts#=d.ts# order by t.ts#;

-- show the temporary tablespaces
select t.name tname,d.name fname,bytes
from v$tablespace t join v$tempfile d on t.ts#=d.ts# order by t.ts#;


-------------------------------------------------
---- Chapter 5: Managing the Oracle Instance ----
-------------------------------------------------

/**** Exercise 5-1 Conduct a Startup and a Shutdown */

/* Check the status of the database listener, and start it if necessary. From an
operating system prompt: */

lsnrctl status
lsnrctl start

/* Check the status of the Database Control console, and start it if necessary.
From an operating system prompt: */

emctl status dbconsole
emctl start dbconsole

-- Connect to sql Plus
sqlplus / as sysdba

-- Start the instance only:
startup nomount;

-- Mount the database: 
alter database mount;

-- Open the database:
alter database open;

-- Confirm that the database is open by querying a data dictionary view:
select count(*) from dba_data_files;

-- Log in to Oracle Enterprise Manager
-- On the database home page, click the Shutdown button.


/**** Exercise 5-2 Query and Set Initialization Parameters */

/*Display all the basic parameters, checking whether they have all been set or
are still on default:*/
select name,value,isdefault from v$parameter where isbasic=-'TRUE'
order by name;

-- Change the PROCESSES parameter to 200. This is a static parameter
alter system set processes = 200; -- error static param
alter system set processes = 200 scope = spfile;
startup force;

/*Rerun the first query. Note the new value for PROCESSES, and
also for SESSIONS. PROCESSES limits the number of operating system
processes that are allowed to connect to the instance, and SESSIONS limits
the number of sessions. These figures are related, because each session will
require a process. The default value for SESSIONS is derived from PROCESSES,
so if SESSIONS was on default, it will now have a new value.*/
select name,value,isdefault from v$parameter where isbasic=-'TRUE'
order by name;

-- Change the value for the NLS_LANGUAGE parameter for your session.
alter session set nls_language=German;

-- Confirm that the change has worked by querying the system date:
select to_char(sysdate,'day') from dual;

/* Change the OPTIMIZER_MODE parameter, but restrict the scope to the
running instance only; do not update the parameter file. */
alter system set optimizer_mode=rule scope=memory;

/* Confirm that the change has been effected, but not written to the parameter file */
select value from v$parameter where name='optimizer_mode'
union
select value from v$spparameter where name='optimizer_mode';

/* Return the OPTIMIZER_MODE to its standard value, in both the running
instance and the parameter file: */
alter system set optimizer_mode=all_rows scope=both;


/**** Exercise 5-3 Use the Alert Log */

/* Connect to your database with either SQL*Plus or SQL Developer, and find
the value of the BACKGROUND_DUMP_DEST parameter: */
select value from v$parameter where name='background_dump_dest';

/* Open the alert log. It will be a file called alert_SID.log, where SID is the
name of the instance 
Go to the bottom of the file. You will see the ALTER SYSTEM commands of
Exercise 5-2 and the results of the startup and shutdowns.
*/

/**** Exercise 5-3 Query Data Dictionary and Dynamic Performance Views */

/* Use dynamic performance views to determine what datafile and tablespaces
make up the database: */
select t.name,d.name,d.bytes from v$tablespace t join
v$datafile d on t.ts#=d.ts# order by t.name;

-- Obtain the same information from data dictionary views:
select t.tablespace_name,d.file_name,d.bytes from
dba_tablespaces t
join dba_data_files d on t.tablespace_name=d.tablespace_name
order by tablespace_name;

-- Determine the location of all the controlfile copies. Use two techniques
select * from v$controlfile;
select value from v$parameter where name='control_files';

/* Determine the location of the online redo log file members, and their size. As
the size is an attribute of the group, not the members, you will have to join
two views: */

select m.group#,m.member,g.bytes from v$log g join v$logfile m
on m.group#=g.group# order by m.group#,m.member;