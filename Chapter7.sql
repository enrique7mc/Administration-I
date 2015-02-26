----------------------------------------------------
-- CHAPTER 7 Managing Database Storage Structures --
----------------------------------------------------

--*** Understand Tablespaces and Dataf iles

-- Segments, Extents, Blocks, and Rows

/*Data is stored in segments. The data dictionary view DBA_SEGMENTS describes
every segment in the database. This query shows the segment types in a simple
database—the counts are low because there is no real application installed: */
select segment_type,count(1) from dba_segments group by
segment_type
order by segment_type;

/* In the figure, the first command creates the table HR.NEWTAB, relying
completely on defaults for the storage. Then a query against DBA_EXTENTS shows
that the segment consists of just one extent, extent number zero. This extent is in
file number 4 and is 8 blocks long. The first of the 8 blocks is block number 1401.
The size of the extent is 64 KB, which shows that the block size is 8 KB. 
The next command forces Oracle to allocate another extent to the segment, even though the
first extent will not be full. The next query shows that this new extent, number 1,
is also in file number 4 and starts immediately after extent zero.*/
create table hr.newtab(c1 date);

select tablespace_name, file_id, extent_id, block_id, blocks, bytes
from dba_extents where owner='HR' and segment_name='NEWTAB';

alter table hr.newtab allocate extent;

select tablespace_name, file_id, extent_id, block_id, blocks, bytes
from dba_extents where owner='HR' and segment_name='NEWTAB';

select tablespace_name, file_name from dba_data_files where file_id = 4;

-------------------------------------------------------------------------------------------------
-- EXERCISE 7-1 Investigate the Database’s Data Storage Structures

-- 1. Connect to the database as user SYSTEM.

-- 2. Determine the name and size of the controlfile(s):
select name,block_size*file_size_blks bytes from
v$controlfile;

-- 3. Determine the name and size of the online redo log file members:
select member,bytes from v$log join v$logfile using (group#);

-- 4. Determine the name and size of the datafiles and the tempfiles:
select name,bytes from v$datafile
union all
select name,bytes from v$tempfile;

-------------------------------------------------------------------------------------------------
--*** Create and Manage Tablespaces

/* To create a tablespace with Enterprise Manager Database Control, from the database
home page take the Server tab and then the Tablespaces link in the Storage section. */

/* This information could be also be gleaned by querying the data dictionary
views DBA_TABLESPACES, DBA_DATA_FILES, DBA_SEGMENTS, and DB_FREE_SPACE as in this example: */

select t.tablespace_name name, d.allocated, u.used, f.free,
t.status, d.cnt, contents, t.extent_management extman,
t.segment_space_management segman
from dba_tablespaces t,
(select sum(bytes) allocated, count(file_id) cnt from dba_data_files
where tablespace_name='EXAMPLE') d,
(select sum(bytes) free from dba_free_space
where tablespace_name='EXAMPLE') f,
(select sum(bytes) used from dba_segments
where tablespace_name='EXAMPLE') u
where t.tablespace_name='EXAMPLE';

/* Creating a tablespace*/
CREATE SMALLFILE TABLESPACE "NEWTS"
DATAFILE 'D:\APP\ORACLE\ORADATA\ORCL11G\newts01.dbf'
SIZE 100M AUTOEXTEND ON NEXT 10M MAXSIZE 200M
LOGGING
EXTENT MANAGEMENT LOCAL
SEGMENT SPACE MANAGEMENT AUTO
DEFAULT NOCOMPRESS;

create tablespace gltabs datafile
'C:\app\oradata\gltabs_01.dbf' size 10m,
'C:\app\oradata\gltabs_02.dbf' size 10m
extent managment local uniform size 5120k;

select t.name, t.bigfile, d.name, d.bytes
from v$tablespace t join v$datafile d using (ts#)
where t.name='GLTABS';

select t.name tname, d.name dname, d.bytes, d.create_bytes
from v$tablespace t join v$tempfile d using(ts#)
where t.name='TEMP';

--*** Altering Tablespaces

-- Rename a Tablespace and Its Datafiles, the syntax is
ALTER TABLESPACE tablespaceoldname RENAME TO tablespacenewname;

alter tablespace gltabs rename to gl_large_tabs;
alter tablespace gl_large_tabs offline;
host rename C:\app\oradata\gltabs_01.dbf gl_large_tabs_01.dbf
host rename C:\app\oradata\gltabs_02.dbf gl_large_tabs_02.dbf

alter database rename file 'C:\app\oradata\gltabs_01.dbf' to 
'C:\app\oradata\gl_large_tabs_01.dbf';

alter database rename file 'C:\app\oradata\gltabs_02.dbf' to 
'C:\app\oradata\gl_large_tabs_02.dbf';

alter tablespace gl_large_tabs online;

/* A tablespace can be renamed while it is in use, but to rename a datafile, 
the datafiles must be offline. */

-- Taking a Tablespace Online or Offline
/* An online tablespace or datafile is available for use; an offline tablespace or datafile
exists as a definition in the data dictionary and the controlfile but cannot be used. It
is possible for a tablespace to be online but one or more of its datafiles to be offline. */ 

-- The syntax for taking a tablespace offline is
ALTER TABLESPACE tablespacename OFFLINE [NORMAL* | IMMEDIATE | TEMPORARY];

-- Mark a Tablespace as Read Only
-- The syntax is completely self-explanatory:
ALTER TABLESPACE tablespacename [READ ONLY | READ WRITE];

create table testtab(c1 date) tablespace gl_large_tabs;
alter tablespace gl_large_tabs read only;
insert into testtab values(sysdate);
drop table testtab;

-- Resizing a Tablespace

/* A tablespace can be resized either by adding datafiles to it or by adjusting the size of
the existing datafiles. The datafiles can be resized upward automatically as necessary
if the AUTOEXTEND syntax was used at file creation time. */

ALTER DATABASE DATAFILE filename RESIZE n[M|G|T];

/* The M, G, or T refer to the units of size for the file: megabytes, gigabytes, or
terabytes. For example, */ 
alter database datafile '/oradata/users02.dbf' resize 10m;

-- To add another datafile of size two gigabytes to a tablespace:
alter tablespace gl_large_tabs
add datafile 'C:\app\oradata\gl_large_tabs_03.dbf' size 10m;
/*Clauses for automatic extension can be included, or to enable automatic
extension later use a command such as this: */
alter database datafile 'C:\app\ORADATA\gl_large_tabs_03.dbf'
autoextend on next 100m maxsize 4g;
-- This will allow the file to double in size, increasing 100 MB at a time.

--*** Dropping Tablespaces
DROP TABLESPACE tablespacename
[INCLUDING CONTENTS [AND DATAFILES] ] ;

-------------------------------------------------------------------------------------------------
-- EXERCISE 7-2 Create, Alter, and Drop Tablespaces

-- 1. Connect to the database as user SYSTEM.

/* 2. Create a tablespace in a suitable directory—any directory on which the
Oracle owner has write permission will do: */
create tablespace newtbs
datafile 'C:\app\oradata\newtbs_01.dbf' size 10m
extent management local autoallocate
segment space management auto;
/* This command specifies the options that are the default. Nonetheless, it
may be considered good practice to do this, to make the statement selfdocumenting. */

-- 3. Create a table in the new tablespace, and determine the size of the first extent:
create table newtab(c1 date) tablespace newtbs;
select extent_id,bytes from dba_extents
where owner='SYSTEM' and segment_na me='NEWTAB';

/* 4. Add extents manually, and observe the size of each new extent by repeatedly
executing this command, */ 
alter table newtabs allocate extent;
/* followed by the query from Step 3. Note the point at which the extent size
increases. */

-- 5. Take the tablespace offline, observe the effect, and bring it back online. 
alter tablespace newtabs offline;
insert into newtab values(sysdate); -- error
alter tablespace newtabs online;
insert into newtab values(sysdate); -- correct

-- 6. Make the tablespace read only, observe the effect, and make it read-write again.
alter tablespace newtabs read only;
insert into newtab values(sysdate); -- error
drop table newtab; -- correct
alter tablespace newtabs read write;

-- 7. Enable OMF for datafile creation:
alter system set db_create_file_dest='C:\app\oradata';

-- 8. Create a tablespace, using the minimum syntax now possible:
create tablespace omftbs;

-- 9. Determine the characteristics of the OMF file:
select file_name,bytes,autoextensible,maxbytes,increment_by
from dba_data_files where tablespace_name='OMFTBS';
-- Note the file is initially 100MB, autoextensible, with no upper limit.

/*11. Drop the tablespace, and use an operating system command to confirm that
the file has indeed gone: */
drop tablespace omftbs including contents and datafiles;

-------------------------------------------------------------------------------------------------
--*** Manage Space in Tablespaces

-- Extent Management

/* The extent management method is set per tablespace and applies to all segments
in the tablespace. There are two techniques for managing extent usage: dictionary
management or local management. The difference is clear: local management should
always be used; dictionary management should never be used. Dictionary-managed
extent management is still supported, but only just. */

-- Consider this statement:
create tablespace large_tabs datafile 'large_tabs_01.dbf' size 100m
extent management local uniform size 16m;

/* Every extent allocated in this tablespace will be 160 MB, so there will be about
64 of them. The bitmap needs only 64 bits, and 160 MB of space can be allocated by
updating just one bit. This is going to be very efficient—provided that the segments
in the tablespace are large. If a segment were created that only needed space for a
few rows (such as the HR.REGIONS table), it would still get an extent of 160 MB.
Small objects need their own tablespace: */

create tablespace small_tabs datafile 'small_tabs_01.dbf' size 1g
extent management local uniform size 160k;

-- The alternative (and default) syntax would be
create tablespace any_tabs datafile 'any_tabs_01.dbf' size 10g
extent management local autoallocate;
/* When segments are created in this tablespace, Oracle will allocate a 64 KB extent.
As a segment grows and requires more extents, Oracle will allocate extents of 64 KB
up to 16 extents, from which it will allocate progressively larger extents. Thus fastgrowing
segments will tend to be given space in ever-increasing chunks */ 

/* It is possible that if a database has been upgraded from previous versions, it will
include dictionary-managed tablespaces. Check this with this query: */
select tablespace_name, extent_management from dba_tablespaces;
/* Any dictionary-managed tablespaces should be converted to local management
with this PL/SQL procedure call: */ 
execute dbms_space_admin.tablespace_migragte_to_local('tablespacename');

-- Segment Space Management

/* The segment space management method is set per tablespace and applies to all
segments in the tablespace. There are two techniques for managing segment space
usage: manual or automatic. The difference is clear: automatic management should
always be used; manual management should never be used. Manual segment space
management is still supported but never recommended. */

-- To see if any tablespaces are using manual management, run this query:
select tablespace_name,segment_space_management from dba_tablespaces;

-- It is not possible to convert tablespace from manual to automatic segment space management.

-------------------------------------------------------------------------------------------------
-- EXERCISE 7-3 Change Tablespace Characteristics

-- 1. Connect to your database as user SYSTEM

/* 2. Create a tablespace using manual segment space management. As OMF was
enabled in Exercise 7-2, there is no need for any datafile clause: */
create tablespace manualsegs segment space management manual; 

-- 3. Confirm that the new tablespace is indeed using the manual technique:
select segment_space_management from dba_tablespaces
where tablespace_name='MANUALSEGS';

-- 4. Create a table and an index in the tablespace:
create table mantab (c1 number) tablespace manualsegs;
create index mantabi on mantab(c1) tablespace manualsegs;
-- These segments will be created with freelists, not bitmaps.

-- 5. Create a new tablespace that will (by default) use automatic segment space management:
create tablespace autosegs;

-- 6. Move the objects into the new tablespace:
alter table mantab move tablespace autosegs;
alter index mantabi rebuild online tablespace autosegs;

-- 7. Confirm that the objects are in the correct tablespace:
select tablespace_name from dba_segments
where segment_name like 'MANTAB%';

-- 8. Drop the original tablespace:
drop tablespace manualsegs including contents and datafiles;

/* 9. Rename the new tablespace to the original name. This is often necessary,
because some application software checks tablespaces names: */ 
alter tablespace autosegs rename to manualsegs;

-- 10. Tidy up by dropping the tablespace, first with this command:
drop tablespace manualsegs;
-- Note the error caused by the tablespace not being empty, and fix it:
drop tablespace manualsegs including contents and datafiles;