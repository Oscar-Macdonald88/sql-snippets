--Run this on Master database.
 
Use Master
Go
 
SET NOCOUNT ON;
 
 
Declare @EXEC_SQL Nvarchar(512)
,@Orphaned_Users Nvarchar(100)
,@DB_Name nvarchar(512)
 
 
If exists (select * from tempdb..sysobjects where name like '#OrphanedUsers%')
BEGIN
Drop table #OrphanedUsers
END
Create Table #OrphanedUsers
(
DB_Name nvarchar(512),
UserName Nvarchar(100),
UserId Nvarchar(256),
User_Fixed nvarchar(2),
Error_msg nvarchar(512)
);
 
Create Table #DBName
(
DB_Name nvarchar(512),
);
 
Insert Into #DBName (DB_Name) SELECT name FROM MASTER.SYS.DM_HADR_DATABASE_REPLICA_STATES A
	INNER JOIN MASTER.SYS.DATABASES B ON A.DATABASE_ID = B.DATABASE_ID
	WHERE	
	A.IS_LOCAL = 1
	AND		A.DATABASE_STATE = 0
	AND		A.SYNCHRONIZATION_HEALTH = 2
	AND		A.IS_PRIMARY_REPLICA = 1;
 
 
IF (SELECT SERVERPROPERTY('IsHadrEnabled')) = 1
BEGIN
DECLARE DB_NAME CURSOR
FOR
SELECT DB_Name from #DBName;
END
 
ELSE
 
BEGIN
DECLARE DB_NAME CURSOR
FOR
Select name from sys.databases where database_id> 4 and state_desc = 'ONLINE';
END
 
OPEN DB_NAME
FETCH NEXT FROM DB_NAME INTO @DB_Name
 
WHILE @@FETCH_STATUS = 0
BEGIN
 
Set @EXEC_SQL = '
Use [' + @DB_Name + '];' + 
'Insert Into #OrphanedUsers (UserName, UserID)
EXEC sp_change_users_login ''Report'';'
 
Exec (@EXEC_SQL);
Print '<--Checked ' + @DB_Name + ' for Orphaned Users.-->'
 
Update #OrphanedUsers Set DB_Name = @DB_Name Where DB_Name IS NULL;
 
FETCH NEXT FROM DB_NAME INTO @DB_Name
END
CLOSE DB_NAME
DEALLOCATE DB_NAME
 
If (Select Top 1 1 from #OrphanedUsers) = 1
BEGIN
Print '<--Orphaned Users Found-->'
 
DECLARE Orphaned_Users CURSOR
FOR
SELECT DISTINCT db_name,UserName
From #OrphanedUsers
 
OPEN Orphaned_Users
FETCH NEXT FROM Orphaned_Users INTO @DB_Name,@Orphaned_Users
 
WHILE @@FETCH_STATUS = 0
BEGIN
 
BEGIN TRY
 
Set @EXEC_SQL = '
Use [' + @DB_Name + '];' + 
'EXEC sp_change_users_login ''Auto_Fix''' + ',' + '''' + @Orphaned_Users + '''' + ';'
 
EXEC (@EXEC_SQL);
 
 
END TRY
BEGIN CATCH
Update #OrphanedUsers  Set User_Fixed = 'N' where UserName = @Orphaned_Users;
Update #OrphanedUsers Set Error_msg = 'User: ' + @Orphaned_users + ' is not part of SQL Server security.' where UserName = @Orphaned_Users;
Print '<--User: ' + @Orphaned_users + ' is not part of SQL Server security.-->'
END CATCH
 
IF EXISTS (Select name from sys.server_principals where name = @Orphaned_Users)
BEGIN
Update #OrphanedUsers Set User_Fixed = 'Y' where UserName = @Orphaned_Users;
Update #OrphanedUsers Set Error_msg = 'No Error found, user ' + @Orphaned_Users + ' was successfully fixed.' where UserName = @Orphaned_Users;
Print '<--User: ' + @Orphaned_users + ' Fixed.-->'
END
 
FETCH NEXT FROM Orphaned_Users INTO @DB_Name,@Orphaned_Users
END
CLOSE Orphaned_Users
DEALLOCATE Orphaned_Users
END
 
IF (Select DISTINCT User_Fixed from #OrphanedUsers WHERE User_Fixed = 'Y') = 'Y'
BEGIN
IF (Select DISTINCT User_Fixed from #OrphanedUsers WHERE User_Fixed = 'N') = 'N'
BEGIN
Print '<--Not All Orphaned Users are Fixed, check the Output -->'
END
ELSE
Print '<--All Orphaned Users Fixed -->'
END
 
IF (Select count(*) from #OrphanedUsers) = 0
BEGIN
Print '<--No Orphaned Users Found-->'
END
 
 
Select DB_Name as Database_Name, UserName as Orphaned_User,User_Fixed,Error_msg as Error from #OrphanedUsers;
 
Drop Table #OrphanedUsers;
Drop Table #DBName;