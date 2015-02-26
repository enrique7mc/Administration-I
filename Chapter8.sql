-------------------------------------------
-- CHAPTER 8 ADMINISTERING USER SECURITY --
-------------------------------------------

--**** Create and Manage Database User Accounts

/* In the first example in the figure, a username JOHN is created. This was entered
in lowercase, but will have been converted to uppercase, as can be seen in the first
query. The second example uses double quotes to create the user with a name in
lowercase. The third and fourth examples use double quotes to bypass the rules on
characters and reserved words; both of these would fail without the double quotes. If
a username includes lowercase letters or illegal characters or is a reserved word, then
double quotes must always be used to connect to the account subsequently*/
CREATE USER JOHN IDENTIFIED BY password;
CREATE USER "john" IDENTIFIED BY password;
CREATE USER "john%#" IDENTIFIED BY password;
CREATE USER "table" IDENTIFIED BY password;

SELECT username, created
FROM dba_users 
WHERE LOWER(username) LIKE 'john%';

SELECT username, created
FROM dba_users 
WHERE username = 'table';
-------------------------------------------------------------------------------------------------
--****** Default Tablespace and Quotas

-- Change the default tablespace
ALTER DATABASE DEFAULT TABLESPACE tablespace_name;


/* The first query in the figure is against DBA_USERS and determines the default
and temporary tablespaces for the user JOHN. DBA_USERS
has one row for every user account in the database. User JOHN has picked up the
database defaults for the default and temporary tablespaces, which are shown in the
last query against DATABASE_PROPERTIES.*/
SELECT username, default_tablespace, temporary_tablespace
FROM dba_users
WHERE username = 'JOHN';

ALTER USER john quota 10m on users;
ALTER USER john quota unlimited on example;

SELECT tablespace_name, bytes, max_bytes
FROM dba_ts_quotas
WHERE username = 'JOHN';

SELECT property_name, property_value
FROM database_properties
WHERE promerty_name LIKE '%TABLESPACE';

-- Users do not need a quota on their temporary tablespaces.

/* To change a user’s temporary tablespace (which will affect all future sessions that
connect to the account), use an ALTER USER command: */
ALTER USER username TEMPORARY TABLESPACE tablespace_name;

-------------------------------------------------------------------------------------------------
--** Account Status

-- To lock and unlock an account, use these commands:
ALTER USER username ACCOUNT LOCK ;
ALTER USER username ACCOUNT UNLOCK ;
-- To force a user to change his password, use this command:
ALTER USER username PASSWORD EXPIRE;

-------------------------------------------------------------------------------------------------
--******* Authentication Methods

--- Operating System and Password File Authentication

/* To enable operating system and password file authentication (the two go together)
for an account, you must grant the user either the SYSDBA or the SYSOPER
privilege:*/
GRANT [sysdba | sysoper ] TO username ;

-- To use password file authentication, the user can connect with this syntax with SQL*Plus:
CONNECT username / password [@db_alias] AS [ SYSOPER | SYSDBA ] ;

-- To use operating system authentication, the user can connect with this syntax with SQL*Plus:
CONNECT / AS [ SYSOPER | SYSDBA ] ;

/* To determine to whom the SYSDBA and SYSOPER privileges
have been granted, query the view V$PWFILE_USERS. */

--- Password Authentication
-- The syntax for a connection with password authentication using SQL*Plus is
CONNECT username / password [@db_alias];

/* Any user can change his/her user account password at any time, or a highly
privileged user (such as SYSTEM) can change any user account password. */ 
ALTER USER username IDENTIFIED BY password ;

-------------------------------------------------------------------------------------------------
--***** Creating Accounts

/* The CREATE USER command has only two required arguments: a user name and
a method of authentication. */

create user scott identified by tiger -- Provide the username, and a password for password authentication.
default tablespace users temporary tablespace temp -- Provide the default and temporary tablespaces.
quota 100m on users, quota unlimited on example -- Set up quotas on the default and another tablespace.
profile developer_profile -- Nominate a profile for password and resource management.
password expire -- Force the user to change his password immediately.
account unlock; -- Make the account available for use (which would have been the default).

/* Every attribute of an account can be adjusted later with ALTER USER
commands, with the exception of the name. To change the password, */
alter user scott identified by lion;
-- To change the default and temporary tablespaces,
alter user scott default tablespace hr_data temporary tablespace hr_temp;
-- To change quotas,
alter user scott quota unlimited on hr_data, quota 0 on users;
-- To change the profile,
alter user scott profile prod_profile;
-- To force a password change,
alter user scott password expire;
-- To lock the account,
alter user scott account lock;
-- Having created a user account, it may be necessary to drop it:
drop user scott;

/* This command will only succeed if the user does not own any objects: if the
schema is empty. If you do not want to identify all the objects owned and drop them
first, they can be dropped with the user by specifying CASCADE: */
drop user scott cascade;

-------------------------------------------------------------------------------------------------
-- EXERCISE 8-1 Create Users

-- 2. Create three users:
create user alois identified by alois
default tablespace example password expire;
create user afra identified by oracle;
default tablespace example quota unlimited on example;
create user anja identified by oracle;

/* 3. Confirm that the users have been created with Database Control. From the
database home page, the navigation path is the Server tab and the Users link 
in the Security section. */

-- 4. From SQL*Plus, attempt to connect as user ALOIS:
connect alois/alois 

/* 5. When prompted, select a new password (such as “oracle”). But it won’t
get you anywhere, because ALOIS does not have the CREATE SESSION
privilege. */

/* 6. Refresh the Database Control window, and note that the status of the ALOIS
account is no longer EXPIRED but OPEN, because his password has been
changed. */

-------------------------------------------------------------------------------------------------
--**** Grant and Revoke Privileges

/* Privileges come in two groups: system privileges that (generally speaking) let users
perform actions that affect the data dictionary and object privileges that let users
perform actions that affect data. */

--- System Privileges 

--The syntax for granting system privileges is
GRANT privilege [, privilege...] TO username;

grant create session, alter session,
create table, create view, create synonym, create cluster,
create database link, create sequence,
create trigger, create type, create procedure, create operator
to username ;

/*A variation in the syntax lets the grantee pass his/her privilege on to a third party.
For example: */

connect system/oracle;
grant create table to scott with admin option;
connect scott/tiger;
grant create table to jon;

-- Revocation of a system privilege will not cascade (unlike revocation of an object privilege).

/* The ANY privileges give permissions against all relevant objects in the database. 
This, will let SCOTT query every table in every schema in the database. */
grant select any table to scott;

--- Object Privileges
/* Object privileges give the ability to perform SELECT, INSERT, UPDATE, and
DELETE commands against tables and related objects, and to execute PL/SQL
objects. */

-- The syntax is
GRANT privilege ON schema.object TO username [WITH GRANT OPTION] ;
-- For example,
grant select on hr.regions to scott;

/* Variations include the use of ALL, which will apply all the permissions relevant
to the type of object, and nominating particular columns of view or tables: */
grant select on hr.employees to scott;
grant update (salary) on hr.employees to scott;
grant all on hr.regions to scott; 

/* Oracle retains a record of who granted object privileges to whom; this
allows a REVOKE of an object to cascade to all those in the chain. Consider this
sequence of commands: */
connect hr/hr;
grant select on employees to scott with grant option;
connect scott/tiger;
grant select on hr.employees to jon with grant option;
conn jon/jon;
grant select on hr.employees to sue;
connect hr/hr;
revoke select on employees from scott;

-------------------------------------------------------------------------------------------------
-- EXERCISE 8-2 Grant Direct Privileges

-- 1. Connect to your database as user SYSTEM with SQL*Plus.

-- 2. Grant CREATE SESSION to user ALOIS:
grant create sessions to alois;

/* 3. Open another SQL*Plus session, and connect as ALOIS. This time, the login
will succeed: */ 
connect alois/oracle

-- 4. As ALOIS, attempt to create a table:
create table t1 (c1 date);
-- This will fail with the message “ORA-01031: insufficient privileges.”

-- 5. In the SYSTEM session, grant ALOIS the CREATE TABLE privilege:
grant create table to alois;

-- 6. In the ALOIS session, try again:
create table t1 (c1 date);
-- This will fail with the message “ORA-01950: no privileges on tablespace 'EXAMPLE'.”

-- 7. In the SYSTEM session, give ALOIS a quota on the EXAMPLE tablespace:
alter user alois quota 1m on example;

-- 8. In the ALOIS session, try again. This time, the creation will succeed.

-- 9. As ALOIS, grant object privileges on the new table:
grant all on t1 to afra;
grant select on t1 to anja;

-- 10. Connect to Database Control as user SYSTEM.

/* 11. Confirm that the object privileges have been granted. The navigation path
from the database home page is: on the Schema tab click the Tables link in
the Database Objects section. Enter ALOIS as the Schema and T1 as the
Table and click the Go button. In the Actions drop-down box, select Object
Privileges. As shown in the next illustration, ANJA has only SELECT,
but AFRA has everything. Note that the window also shows by whom the
privileges were granted, and that none of them were granted WITH GRANT
OPTION. */

/* 12. With Database Control, confirm which privileges have granted to ALOIS.
The navigation path from the database home page is: on the Server tab click
the Users link in the Security section. Select the radio button for ALOIS,
and click the View button. You will see that he has two system privileges
(CREATE SESSION and CREATE TABLE) without the ADMIN OPTION,
a 1MB quota and EXAMPLE, and nothing else. */

/* 13. Retrieve the same information shown in Steps 11 and 12 with SQL*Plus. As
SYSTEM, run these queries: */
select grantee,privilege,grantor,grantable from dba_tab_privs
where owner='ALOIS' and table_name='T1';
select * from dba_sys_privs where grantee='ALOIS';

-- 14. Revoke the privileges granted to AFRA and ANJA:
revoke all on alois.t1 from afra;
revoke all on alois.t1 from anja;
-- Confirm the revocations by rerunning the first query from Step 13.

-------------------------------------------------------------------------------------------------
--*** Create and Manage Roles

-- Creating and Granting Roles

/* A role is a bundle
of system and/or object privileges that can be granted and revoked as a unit, and
having been granted can be temporarily activated or deactivated within a session. */

/* Roles are not schema objects: they aren’t owned by anyone and so cannot be prefixed
with a username. However, they do share the same namespace as users: it is not
possible to create a role with the same name as an already-existing user, or a user with
the same name as an already-existing role. */

-- Create a role with the CREATE ROLE command:
CREATE ROLE rolename ;

/* For example, assume that the HR schema is being used as a repository for data to
be used by three groups of staff: managerial staff have full access, senior clerical staff
have limited access, junior clerical staff have very restricted access. First create a
role that might be suitable for the junior clerk; all they can do is answer questions by
running queries: */

create role hr_junior;
grant create session to hr_junior;
grant select on hr.regions to hr_junior;
grant select on hr.locations to hr_junior;
grant select on hr.countries to hr_junior;
grant select on hr.departments to hr_junior;
grant select on hr.job_history to hr_junior;
grant select on hr.jobs to hr_junior;
grant select on hr.employees to hr_junior;

/* Then create a role for the senior clerks, who can
also write data to the EMPLOYEES and JOB_HISTORY tables: */

create role hr_senior;
grant hr_junior to hr_senior with admin option;
grant insert, update, delete on hr.employees to hr_senior;
grant insert, update, delete on hr.job_history to hr_senior;

-- Then create the manager’s role, which can update all the other tables:
create role hr_manager;
grant hr_senior to hr_manager with admin option;
grant all on hr.regions to hr_manager;
grant all on hr.locations to hr_manager;
grant all on hr.countries to hr_manager;
grant all on hr.departments to hr_manager;
grant all on hr.job_history to hr_manager;
grant all on hr.jobs to hr_manager;
grant all on hr.employees to hr_manager;

connect / as sysdba
grant hr_manager to scott;
connect scott/tiger
grant hr_senior to sue;
connect sue/sue;
grant hr_junior to jon;
grant hr_junior to roop;

/*There is also a predefined role PUBLIC, which is always granted to every database
user account. It follows that if a privilege is granted to PUBLIC, it will be available
to all users. So following this command all users will be able to query the HR.REGIONS table: */
grant select on hr.regions to public;

--*** Enabling Roles
/* Following the example given in the preceding section, this query shows what 
roles have been granted to JON: */
select * from dba_role_privs where grantee='JON';

-- To change the default behavior:
alter user jon default role none;

grant connect to jon;
alter user jon default role connect;
select * from dba_role_privs where grantee='JON';

/* Then the role can only be enabled by running the PL/SQL procedure nominated by
procedure_name. */
CREATE ROLE rolename IDENTIFIED USING procedure_name ;

-------------------------------------------------------------------------------------------------
-- EXERCISE 8-3 Create and Grant Roles

-- 1. Connect to your database with SQL*Plus as user SYSTEM.

-- 2. Create two roles as follows:
create role usr_role;
create role mgr_role;

-- 3. Grant some privileges to the roles, and grant USR_ROLE to MGR_ROLE:
grant create session to usr_role;
grant select on alois.t1 to usr_role;
grant usr_role to mgr_role with admin option;
grant all on alois.t1 to mgr_role;

-- 4. As user SYSTEM, grant the roles to AFRA and ANJA:
grant mgr_role to AFRA;

-- 5. Connect to the database as user AFRA:
connect afra/oracle;

-- 6. Grant the USR_ROLE to ANJA, and insert a row into ALOIS.T1:
grant usr_role to anja;
insert into alois.t1 values(sysdate);
commit;

-- 7. Confirm the ANJA can connect and query ALOIS.t1 but do nothing else:
connect anja/oracle
select * from alois.t1;
insert into alois.t1 values(sysdate);

-- 8. As user SYSTEM, adjust ANJA so that by default she can log on but do nothing else:
connect system/oracle
grant connect to anja;
alter user anja default role connect;

-- 9. Demonstrate the enabling and disabling of roles: connect anja/oracle
select * from alois.t1;
set role usr_role;
select * from alois.t1;

/* 10. Use Database Control to inspect the roles. The navigation path from the
database home page is: on the Server tab click the Roles link in the Security
section. Click the links for the two new roles to see their privileges. */

/* 11. To see to whom a role has been granted, in the Actions drop-down box
shown in the preceding illustration, select Show Grantees and click the Go
button. */

-- 12. Obtain the same information retrieved in Steps 10 and 11 with these queries:
select * from dba_role_privs
where granted_role in ('USR_ROLE','MGR_ROLE');
select grantee,owner,table_name,privilege,grantable
from dba_tab_privs where grantee in ('USR_ROLE','MGR_ROLE')
union all
select grantee,to_char(null),to_char(null),privilege,admin_
option
from dba_sys_privs where grantee in ('USR_ROLE','MGR_ROLE')
order by grantee;

-------------------------------------------------------------------------------------------------
--*** Create and Manage Profiles

/* A profile has a dual function: to enforce a password policy and to restrict the resources a
session can take up. Password controls are always enforced; resource limits are only enforced if the
instance parameter RESOURCE_LIMIT is on TRUE—by default, it is FALSE. */

-- Resource limits will not be applied unless an instance parameter has been set:
alter system set resource_limit=true;

--** Creating and Assigning Profiles 

-- To see which profile is currently assigned to ach user, run this query:
select username,profile from dba_users;

-- Then the view that will display the profiles themselves is DBA_PROFILES:
select * from dba_profiles where profile='DEFAULT';

/* For example, it could be that the rules
of the organization state that no users should be able to log on more than once,
except for administration staff, who can log on as many concurrent sessions as they
want and must change their passwords every week with one-day grace, and the
programmers, who can log on twice. */

-- To do this, first adjust the DEFAULT profile:
alter profile default limit sessions_per_user 1;

-- Create a new profile for the DBAs, and assign it:
create profile dba_profile limit sessions_per_user unlimited
password_life_time 7 password_grace_time 1;
alter user sys profile dba_profile;
alter user system profile dba_profile;

-- Create a profile for the programmers, and assign it:
create profile programmers_profile limit sessions_per_user 2;
alter user jon profile programmers_profile;
alter user sue profile programmers_profile;
-- To let the resource limit take effect, adjust the instance parameter:
alter system set resource_limit=true;

/* A profile cannot be dropped if it has been assigned to users. They must be altered
to a different profile first. Once done, drop the profile with */ 
DROP PROFILE profile_name ;
-- Alternatively, use this syntax:
DROP PROFILE profile_name CASCADE ;
/* which will automatically reassign all users with profile_name back to the DEFAULT
profile. */ 

-------------------------------------------------------------------------------------------------
--*** EXERCISE 8-4 Create and Use Profiles

-- 1. Connect to your database with SQL*Plus as user system.

-- 2. Create a profile that will lock accounts after two wrong passwords:
create profile two_wrong limit failed_login_attempts 2;

-- 3. Assign this new profile to ALOIS:
alter user alois profile two_wrong;

-- 4. Deliberately enter the wrong password for ALOIS a few times:
connect alois/wrongpassword

-- 5. As user SYSTEM, unlock the ALOIS account:
alter user alois account unlock;

-- 6. Check that ALOIS can now connect:
connect alois/oracle

/* 7. Tidy up by dropping the profile, the roles, and the users. Note the use of
CASCADE when dropping the profile to remove it from ALOIS, and on
the DROP USER command to drop his table as well. Roles can be dropped
even if they are assigned to users. The privileges granted on the table will be
revoked as the table is dropped. */
connect system/oracle
drop profile two_wrong cascade;
drop role usr_role;
drop role mgr_role;
drop user alois cascade;
drop user anja;
drop user afra;