/*
Changes made by Rob 13/2/2019
- Removed step 4 reference to PMF as this is not included in this version of the express install.
- Set default for @COPYEXEFILES to 'N'
- Add comment to explain the purpose of @ClientOperatorEmail

DBA Template Express Install


It can be adapted to other environments by updating the configuration Options Below.
Step 1.  Insert latest template install script below the line that says "INSTALL DBA TEMPLATE - PASTE TEMPLATE INSTALL SCRIPT BELOW HERE".  
		
Step 2.   As per a regular template install:
					Do a find on %1 and replace with the servername
					--select @@servername
					Do a find on %2 and replace with the Contract Expiry date - format YYYYMMDD
Step 3.   Update all variables in section 1.0
Step 4.   Run the script
*/
set nocount on
go
sp_configure 'show advanced options',1
reconfigure with override
go
sp_configure 'xp_Cmdshell',1
reconfigure with override
go
sp_configure 'Database Mail XPs',1
reconfigure with override 
go
sp_configure 'Remote Admin Connections',1
reconfigure with override 
go
sp_configure 'backup compression default',1
reconfigure with override 
go
sp_configure 'optimize for ad hoc workloads',1
reconfigure with override 

go
/*
#############################################################################
1.0 (begin) Update all variables
#############################################################################
*/

declare @ClientName				varchar(250)	= 'Set the client name'
declare @CustomerCode			varchar(10)		= 'XXX'
declare @ServerName				sysname			= '%1' -- don't change this except for when you do the replace on % 1
declare @SLALevel				varchar(20)		= 'Guardian'
declare @SSLTeam				varchar(20)		= 'DBATEAM3'
declare @InstallerEmail			varchar(150)	= '! CHANGEME @sqlservices.com !'
declare @ClientOperatorEmail	varchar(500)	= '! CHANGEME @sqlservices.com !'  --Who receives the emails for the client.  This address is set as the 'in-house operator' within tbl_Operator


declare @Extension24x7					char(1)		= 'N'
declare @ExtensionIsCluster 			char(1)		= 'N'
declare @ExtensionIsLogShipPrimary		char(1)		= 'N'
declare @ExtensionIsLogShipSecondary	char(1)		= 'N'	
declare @ExtensionPMFInstalled			char(1)		= 'N'
declare @ExtensionReplication			char(1)		= 'N'

declare @ContractExpiry			datetime		
declare @MailServer				varchar(100)	= '192.168.100.100'
declare @DropFolderDir			varchar(512)	= ''
declare @KaseyaServiceAccount	varchar(512)	= ''
declare @DBBackupStartTime		int				= 190500
declare @WeeklyJobStartDay		tinyint			= 1
declare @WeeklyJobStartTime		int				= 10500 -- (10500 = 1:05 am)
declare @MonthlyJobStartDay		int				= 28
declare @SQLDATA_Location		varchar(1000)	= 'C:\SQLData'		-- Location for SQL Data files e.g. E:\SQLData
declare @SQLLOGS_Location		varchar(1000)	= 'C:\SQLLogs'		-- Location for SQL Log files e.g.  F:\SQLLogs
declare @SQLDATADUMPS_Location	varchar(1000)	= 'C:\SQLDataDumps' -- Location for Backups e.g. D:\SQLDataDumps
declare @SQLLOGDUMPS_Location	varchar(1000)	= 'C:\SQLLogDumps'	-- location for Log Backups e.g. L:\SQLLogDumps
declare @SQLREPORTS_Location	varchar(1000)	= 'C:\SQLReports'	-- Note: The default location for this should be the same as the drive the backups are housed on.  
declare @SQLPMF_Location		varchar(1000)	= 'C:\SQLPMF'		-- Location for PMF, e.g. C:\SQLPMF

declare @CopyBackupsTo			char(1)			= '' -- location for CopyBackupsTo in tbl_Databases, e.g. \\SSLDFS01\Backups
declare @CopyLogBackupsTo		char(1)			= '' -- location for CopyLogBackupsTo in tbl_Databases, e.g. \\SSLDFS01\logs

declare @BestPracticeChanges	char(1)			= 'Y'
declare @ConfigureDBMail		char(1)			= 'Y'  --'Y' will configure database mail.  Set to anything else if database mail is already configured.
declare @EyesOnlyInstall		char(1)			= 'N'
declare @PowershellEnabled		char(1)			= 'N'
declare @CopyEXEfiles			char(1)			= 'N'
declare @CopyEXEPath			varchar(1000)	= '\\SSLDFS01\SSLDocs\Templates\SLAInstalls\V5\V5.4\FilesToGoOnServer'  --Source folder to copy pkzip.exe and elogdmp.exe FROM
declare @ReportsPerYear			tinyint			= 12  -- Valid values are:  0, 1, 2, 4, 6, 12

declare @ReplyToAddress			varchar(150)	= 'dba@sqlservices.com'
declare @Domain					varchar(500)	= 'changeme.com'
declare @TempString				varchar(4000) 

--Options
declare @InstallDBATemplate		char(1)	= 'Y'	-- Pretty self-explanatory ;)
declare @CONFIGURE_SQL_Agent	char(1)	= 'Y'	--'Y' will configure SQL Agent Properties as history = 100000 rows, Max per job = 5000 rows.

declare @RunWeeklyJob			int		= 2		--1=full job, 2 = from HC script, 3=Don't run
declare @RunBackupReportOnly	int		= 1		--0=backup all databases , 1 = only run backup report.

declare @Servermake				varchar(100) = 'VMWare'				-- Adjust as required
declare @Servermodel			varchar(100) = 'Virtualmachine'		-- We'll add an autocheck for this later

declare @TemplateBackups		char(1) = 'Y'	-- Set to N if we don't take backups
declare @TemplateLogBackups		char(1) = 'Y'	-- Set to N if we don't take log backups.


/*
#############################################################################
1.0 (end) Update all variables
#############################################################################
*/



if object_id('tempdb..#Install_Table') is not null 
	drop table #Install_Table

create table #Install_Table
(
	[Param_Name] [varchar](300) not null,
	[Param_String] [varchar](2000) null,
	[Param_Int] [int] null
) 

if object_id('tempdb..#OutMessages') is not null
	drop table #OutMessages

create table #OutMessages 
(
	MessageType	varchar(20)
	,TheMessage	varchar(2000)
)


-- Validate parameters:  These must pass before we proceed

-- Reports Per Yer - must be one of 0,1,2,4,6,12:
declare @OutputMessage	varchar(1000)
declare @Cmd			varchar(1000)
declare @Exists			int		= 0

-- Firstly:  Check that there is no SSLDBA.  If there is, what the hell are you doing running the install????
if exists (select * from sys.databases where name = 'SSLDBA')
begin
	set @OutputMessage = 'SSLDBA already exists on this instance, so it''s not possible to run the install script.  Stopping Script.'
	raiserror(@OutputMessage, 11,1) with nowait
	insert into #OutMessages select 'Error', @OutputMessage
end


if @ReportsPerYear not in (0,1,2,4,6,12)
begin
	set @OutputMessage = 'Invalid Setting has been entered for the @ReportsPerYear variable!  Valid vaues are :  0,1,2,4,6,12'
	raiserror(@OutputMessage, 11,1) with nowait
	insert into #OutMessages select 'Error', @OutputMessage
end


--	ServerName is set correctly  
if @ServerName = convert(nvarchar,serverproperty('ServerName'))
	print 'Servername (' + @ServerName + ') confirmed as correct for this server.'
else
begin
	set @OutputMessage = 'This server is ' + convert(nvarchar, serverproperty('ServerName')) +' - You are on the wrong server.  Stopping Script.'
	insert into #OutMessages select 'Error', @OutputMessage
	raiserror (@OutputMessage, 11, 1) with nowait
end

--  Template Expiry has been updated from % 2
begin try
	set @ContractExpiry = '%2'
end try
begin catch
	set @OutputMessage = 'The Contract Expiry has not been set to a valid date!'
	insert into #OutMessages select 'Error', @OutputMessage
	raiserror(@OutputMessage, 11,1) with nowait
end catch

if isdate(@ContractExpiry) = 1
begin
	-- a date has been entered, is it at least 7 days in the future?
	if datediff(day, getdate(), @ContractExpiry) < 7
	begin
		Set @OutputMessage = 'The Contract expiry date must be at least 7 days in the future.  You have entered ' + convert(varchar, @ContractExpiry, 112) + ' (' + convert(varchar, @ContractExpiry, 106) + ') as the Contract Expiry.  Stopping Script.'
		insert into #OutMessages select 'Error', @OutputMessage
		raiserror(@OutputMessage, 11,1) with nowait
	end
end
else
begin
	set @OutputMessage = 'The Contract Expiry has not been set to a valid date!  Stopping Script.'
	insert into #OutMessages select 'Error', @OutputMessage
	raiserror(@OutputMessage, 11,1) with nowait
end


-- SLA Level
if lower(@SLALevel) not in ('guardian','bronze','silver','gold','essentials','advanced','premier')
begin
	set @OutputMessage = 'The SLA Level has not been set to one of:  Guardian, Bronze, Silver, Gold, Essentials, Advanced, Premier.  Stopping Script.'
	insert into #OutMessages select 'Error', @OutputMessage
	raiserror(@OutputMessage, 11,1) with nowait
end

-- Drop Folder or Mail need to be set
if isnull(@DropFolderDir, '') = '' and isnull(@MailServer,'') = ''
begin
	set @OutputMessage = 'You need to either set the DropFolderDir or the MailServer.  Stopping Script.'
	insert into #OutMessages select 'Error', @OutputMessage
	raiserror(@OutputMessage, 11,1) with nowait
end

-- Monthly job start day
if @MonthlyJobStartDay not between 1 and 28
begin
	set @OutputMessage = 'The Monthly Job Start Day must be between 1 and 28.  Stopping Script.'
	insert into #OutMessages select 'Error', @OutputMessage
	raiserror(@OutputMessage, 11,1) with nowait
end

-- Locations

if @SQLDATA_Location = ''
begin
	set @OutputMessage = 'The SQL DATA Location has not been set.  Stopping Script.'
	insert into #OutMessages select 'Error', @OutputMessage
	raiserror(@OutputMessage, 11,1) with nowait
end

if @SQLLOGS_Location = ''
begin
	set @OutputMessage = 'The SQL LOGS Location has not been set.  Stopping Script.'
	insert into #OutMessages select 'Error', @OutputMessage
	raiserror(@OutputMessage, 11,1) with nowait
end

if @SQLDATADUMPS_Location = ''
begin
	set @OutputMessage = 'The SQL DATA DUMPS Location has not been set.  Stopping Script.'
	insert into #OutMessages select 'Error', @OutputMessage
	raiserror(@OutputMessage, 11,1) with nowait
end

if @SQLLOGDUMPS_Location = ''
begin
	set @OutputMessage = 'The SQL LOG DUMPS Location has not been set.  Stopping Script.'
	insert into #OutMessages select 'Error', @OutputMessage
	raiserror(@OutputMessage, 11,1) with nowait
end

if @SQLREPORTS_Location	= ''
begin
	set @OutputMessage = 'The SQL REPORTS Location has not been set.  Stopping Script.'
	insert into #OutMessages select 'Error', @OutputMessage
	raiserror(@OutputMessage, 11,1) with nowait
end


--Attempt to create the folders 
set @OutputMessage = 'Attempting to create ' + @SQLDATA_Location
raiserror(@OutputMessage, 10,1) with nowait
execute master.dbo.xp_create_subdir @SQLDATA_Location

set @OutputMessage = 'Attempting to create ' + @SQLLOGS_Location
raiserror(@OutputMessage, 10,1) with nowait
execute master.dbo.xp_create_subdir @SQLLOGS_Location

set @OutputMessage = 'Attempting to create ' + @SQLDATADUMPS_Location
raiserror(@OutputMessage, 10,1) with nowait
execute master.dbo.xp_create_subdir @SQLDATADUMPS_Location

set @OutputMessage = 'Attempting to create ' + @SQLLOGDUMPS_Location
raiserror(@OutputMessage, 10,1) with nowait
execute master.dbo.xp_create_subdir @SQLLOGDUMPS_Location

set @OutputMessage = 'Attempting to create ' + @SQLREPORTS_Location
raiserror(@OutputMessage, 10,1) with nowait
execute master.dbo.xp_create_subdir @SQLREPORTS_Location

if @SQLPMF_Location <> ''
begin	
	set @OutputMessage = 'Attempting to create ' + @SQLPMF_Location
	raiserror(@OutputMessage, 10,1) with nowait
	execute master.dbo.xp_create_subdir @SQLPMF_Location
end



-- Check pkzipc.exe and elogdmp.exe are in c:\Windows\
exec master.dbo.xp_fileexist 'c:\windows\pkzipc.exe', @Exists output

if @Exists=0
begin
	set @OutputMessage = 'pkzipc.exe not found in C:\Windows\'
	raiserror (@OutputMessage, 11, 1) with nowait
	insert into #OutMessages select 'Error', @OutputMessage
end
else
begin
	set @OutputMessage = 'pkzipc.exe has been found in C:\Windows\'
	raiserror (@OutputMessage, 10, 1) with nowait
end

exec master.dbo.xp_fileexist 'c:\windows\elogdmp.exe', @Exists output

if @Exists=0
begin
	set @OutputMessage = 'elogdmp.exe not found in C:\Windows\ '
	raiserror (@OutputMessage, 11, 1) with nowait
	insert into #OutMessages select 'Error', @OutputMessage
end
else
begin
	set @OutputMessage = 'elogdmp.exe has been found in C:\Windows\'
	raiserror (@OutputMessage, 10, 1) with nowait
end


if exists (select * from #OutMessages where MessageType = 'Error')
begin
	select * from #OutMessages
	truncate table #OutMessages
	raiserror('Stopping Install of SSLDBA, please review the errors', 20,1) with log
end




-- Verify folders are created:  if they are not, halt execution
if object_id('tempdb..#DirectoryCheck') is not null
	drop table #DirectoryCheck


if @InstallDBATemplate = 'Y'
begin

	--SQL Data
	create table #DirectoryCheck ([File Exists] int, [File is a Directory] int, [Parent Directory Exists] int) 
	insert into #DirectoryCheck exec master.dbo.xp_fileexist @SQLDATA_Location

	if (select [File is a Directory] from #DirectoryCheck) = 1 
	begin
		set @OutputMessage = 'The SQLDATA Directory ' + @SQLDATA_Location + ' has been created.'
		raiserror(@OutputMessage, 10,1) with nowait
	end
	else
	begin
		set @OutputMessage = 'The SQLDATA directory ' + @SQLDATA_Location + ' is not found!  Stopping Script.'
		raiserror(@OutputMessage, 11,1) with nowait
		insert into #OutMessages select 'Error', @OutputMessage
	end

	--SQL Logs
	truncate table #DirectoryCheck
	insert INTO #DirectoryCheck exec master.dbo.xp_fileexist @SQLLOGS_Location

	if (select [File is a Directory] from #DirectoryCheck) = 1 
	begin
		set @OutputMessage = 'The SQLLOGS Directory ' + @SQLLOGS_Location + ' has been created.'
		raiserror(@OutputMessage, 10,1) with nowait
	end
	else
	begin
		set @OutputMessage = 'The SQLLOGS Directory ' + @SQLLOGS_Location + ' is not found!  Stopping Script.'
		insert into #OutMessages select 'Error', @OutputMessage
		raiserror(@OutputMessage, 11,1) with nowait
	end

	--SQL Data Dumps
	truncate table #DirectoryCheck
	insert into #DirectoryCheck exec master.dbo.xp_fileexist @SQLDATADUMPS_Location

	if (select [File is a Directory] from #DirectoryCheck) = 1 
	begin
		set @OutputMessage = 'The SQLDATADUMPS Directory ' + @SQLDATADUMPS_Location + ' has been created.'
		raiserror(@OutputMessage, 10,1) with nowait
	end
	else
	begin
		set @OutputMessage = 'The SQLDATADUMPS directory ' + @SQLDATADUMPS_Location + ' is not found! Stopping Script.'
		raiserror(@OutputMessage, 11,1) with nowait
		insert into #OutMessages select 'Error', @OutputMessage
	end

	--SQL Log Dumps
	truncate table #DirectoryCheck
	insert into #DirectoryCheck exec master.dbo.xp_fileexist @SQLDATADUMPS_Location

	if (select [File is a Directory] from #DirectoryCheck) = 1 
	begin
		set @OutputMessage = 'The SQLLOGDUMPS Directory ' + @SQLLOGDUMPS_Location + ' has been created.'
		raiserror(@OutputMessage, 10,1) with nowait
	end
	else
	begin
		set @OutputMessage = 'The SQLLOGDUMPS directory ' + @SQLLOGDUMPS_Location + ' is not found! Stopping Script.'
		raiserror(@OutputMessage, 11,1) with nowait
		insert into #OutMessages select 'Error', @OutputMessage
	end

	--SQL Reports
	truncate table #DirectoryCheck
	insert into #DirectoryCheck exec master.dbo.xp_fileexist @SQLREPORTS_Location

	if (select [File is a Directory] from #DirectoryCheck) = 1 
	begin
		
		set @OutputMessage = 'The SQLREPORTS Directory ' + @SQLREPORTS_Location + ' has been created.'
		raiserror(@OutputMessage, 10,1) with nowait

		--Create SecLog_Search, AppLog_Search, SysLog_Search,DBCC_Search and DBCC_Search_Exclude in SQLREPORTS folder																			TO DO
		select @TempString = 'echo ' + char(34) + 'INFO' + char(34) + ' >> ' + @SQLREPORTS_Location + '\Applog_Search.txt'
		exec master..xp_cmdshell @TempString, no_output
		select @TempString = 'echo ' + char(34) + 'INFO' + char(34) + ' >> ' + @SQLREPORTS_Location + '\SysLog_Search.txt'
		exec master..xp_cmdshell @TempString, no_output
		select @TempString = 'echo Msg  >> ' + @SQLREPORTS_Location + '\DBCC_Search.txt'
		exec master..xp_cmdshell @TempString, no_output
		select @TempString = 'echo  failed  >> ' + @SQLREPORTS_Location + '\DBCC_Search.txt'
		exec master..xp_cmdshell @TempString, no_output
		select @TempString = 'echo Service Broker Msg 9675, State 1: Message Types analyzed: >> ' + @SQLREPORTS_Location + '\DBCC_SearchExclude.txt'
		exec master..xp_cmdshell @TempString, no_output
		select @TempString = 'echo Service Broker Msg 9676, State 1: Service Contracts analyzed: >> ' + @SQLREPORTS_Location + '\DBCC_SearchExclude.txt'
		exec master..xp_cmdshell @TempString, no_output
		select @TempString = 'echo Service Broker Msg 9667, State 1: Services analyzed: >> ' + @SQLREPORTS_Location + '\DBCC_SearchExclude.txt'
		exec master..xp_cmdshell @TempString, no_output
		select @TempString = 'echo Service Broker Msg 9668, State 1: Service Queues analyzed: >> ' + @SQLREPORTS_Location + '\DBCC_SearchExclude.txt'
		exec master..xp_cmdshell @TempString, no_output
		select @TempString = 'echo Service Broker Msg 9669, State 1: Conversation Endpoints analyzed: >> ' + @SQLREPORTS_Location + '\DBCC_SearchExclude.txt'
		exec master..xp_cmdshell @TempString, no_output
		select @TempString = 'echo Service Broker Msg 9674, State 1: Conversation Groups analyzed: >> ' + @SQLREPORTS_Location + '\DBCC_SearchExclude.txt'
		exec master..xp_cmdshell @TempString, no_output
		select @TempString = 'echo Service Broker Msg 9670, State 1: Remote Service Bindings analyzed: >> ' + @SQLREPORTS_Location + '\DBCC_SearchExclude.txt'
		exec master..xp_cmdshell @TempString, no_output
		select @TempString = 'echo ' + char(34) + 'AUDITSUCCESS' + char(34) + ' >> ' + @SQLREPORTS_Location + '\SecLog_Search.txt'
		exec master..xp_cmdshell @TempString, no_output
		select @TempString = 'echo ' + char(34) + 'SUCCESS AUDIT' + char(34) + ' >> ' + @SQLREPORTS_Location + '\SecLog_Search.txt'
		exec master..xp_cmdshell @TempString, no_output
	end
	else
	begin
		set @OutputMessage = 'The SQLREPORTS directory ' + @SQLREPORTS_Location + ' is not found!  Stopping Script.'
		raiserror(@OutputMessage, 11,1) with nowait
		insert into #OutMessages select 'Error', @OutputMessage
	end

	declare @sa_user sysname

	if (select count(*) from master.sys.databases where name = 'SSLDBA') = 0
	begin

		declare @Sql nvarchar(max) 

		--if right(@SQLDATA_Location, 1) <> '\' set @SQLDATA_Location = @SQLDATA_Location + '\'
		--if right(@SQLLOGS_Location, 1) <> '\' set @SQLLOGS_Location = @SQLLOGS_Location + '\'

		set @Sql = 'CREATE DATABASE SSLDBA ON PRIMARY (NAME=''SSLDBA'', FILENAME = ''' + @SQLDATA_Location + '\SSLDBA.mdf'', SIZE=51200KB, FILEGROWTH=10%)'
		set @Sql = @Sql + ' LOG ON (NAME=''SSLDBA_log'', FILENAME = ''' + @SQLLOGS_Location + '\SSLDBA_Log.ldf'', SIZE=5120KB, FILEGROWTH=10%)'
		
		exec sp_executesql @Sql

		-- Check:  If the DB now exists, carry on, else stop

		if not exists (select * from sys.databases where name = 'SSLDBA')
		begin
			set @OutputMessage ='SSLDBA was not able to be created, Stopping Script'
			raiserror(@OutputMessage, 11,1) with nowait
			insert into #OutMessages select 'Error', @OutputMessage
		end
		else
		begin
			set @OutputMessage ='SSLDBA was created:'
			raiserror(@OutputMessage, 10,1) with nowait
		end


		alter database SSLDBA set recovery simple
		alter database SSLDBA set read_write
		alter database SSLDBA set restricted_user 
		alter database SSLDBA set auto_shrink off
		alter database SSLDBA set ansi_null_default off
		alter database SSLDBA set recursive_triggers off
		alter database SSLDBA set ansi_nulls off
		alter database SSLDBA set quoted_identifier off
		alter database SSLDBA set auto_create_statistics on
		alter database SSLDBA set auto_update_statistics on

	
		set @sa_user = SUSER_SNAME(0x01)
		exec SSLDBA..sp_changedbowner @sa_user 

		set @OutputMessage = '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
		raiserror (@OutputMessage, 10, 1) with nowait
		set @OutputMessage = '!!!!!																				!!!!!'                  
		raiserror (@OutputMessage, 10, 1) with nowait															
		set @OutputMessage = '!!!!! SSLDBA has been automatically created, you may need to alter its location.	!!!!!'
		raiserror (@OutputMessage, 10, 1) with nowait
		set @OutputMessage = '!!!!!																				!!!!!'
		raiserror (@OutputMessage, 10, 1) with nowait
		set @OutputMessage = '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
		raiserror (@OutputMessage, 10, 1) with nowait

		print 'SSLDBA already exists'
	end
	else
	begin
		-- SSLDBA already exists - confirm 
		alter database SSLDBA set recovery simple
		alter database SSLDBA set read_write
		alter database SSLDBA set restricted_user 
		alter database SSLDBA set auto_shrink off
		alter database SSLDBA set ansi_null_default off
		alter database SSLDBA set recursive_triggers off
		alter database SSLDBA set ansi_nulls off
		alter database SSLDBA set quoted_identifier off
		alter database SSLDBA set auto_create_statistics on
		alter database SSLDBA set auto_update_statistics on


		set @sa_user = SUSER_SNAME(0x01)
		exec SSLDBA..sp_changedbowner @sa_user 

	end

end

-- set the sql agent job history
if @CONFIGURE_SQL_Agent = 'Y'
begin
	exec msdb.dbo.sp_set_sqlagent_properties @jobhistory_max_rows=100000, @jobhistory_max_rows_per_job=5000
end


-- Executables
-- Is a copy source location specified?
if @CopyEXEPath = ''
begin 
	set @OutputMessage = 'The @CopyEXEPath variable has not been set.  This must be set to provide the location to copy the elogdmp.exe and pkzipc.exe files from.  Stopping Script.'
	raiserror(@OutputMessage, 11,1) with nowait
	insert into #OutMessages select 'Error', @OutputMessage
end


--Check if we are copying executable files
if (@CopyEXEfiles='Y')
begin
	select @TempString = 'copy ' + @CopyEXEPath + '\pkzipc.exe C:\Windows\'
	raiserror(@TempString, 10,1) with nowait
	exec master..xp_cmdshell @TempString
	select @TempString = 'copy ' + @CopyEXEPath + '\elogdmp.exe C:\Windows\'
	raiserror(@TempString, 10,1) with nowait
	exec master..xp_cmdshell @TempString
end



--Now we need to put variables away in a table so we can use them later

-- Extensions
if @Extension24x7				= 'Y' insert into #Install_Table select 'Extension24x7', 'Y', null
if @ExtensionIsCluster			= 'Y' insert into #Install_Table select 'ExtensionIsCluster','Y', null
If @ExtensionIsLogShipPrimary	= 'Y' insert into #Install_Table select 'ExtensionIsLogShipPrimary','Y', null
if @ExtensionIsLogShipSecondary = 'Y' insert into #Install_Table select 'ExtensionIsLogShipSecondary', 'Y', null
if @ExtensionPMFInstalled 		= 'Y' insert into #Install_Table select 'ExtensionPMFInstalled', 'Y', null
If @ExtensionReplication		= 'Y' insert into #Install_Table select 'ExtensionReplication', 'Y', null

insert into #Install_Table(Param_Name,Param_String,Param_Int) values ('InstallerName', @InstallerEmail, NULL)
insert into #Install_Table(Param_Name,Param_String,Param_Int) values ('ClientName', @ClientName,NULL)
insert into #Install_Table(Param_Name,Param_String,Param_Int) values ('CustomerCode',@CustomerCode,NULL)
insert into #Install_Table(Param_Name,Param_String,Param_Int) values ('ServerName',@ServerName,NULL)
insert into #Install_Table(Param_Name,Param_String,Param_Int) values ('SLALevel',@SLALevel,NULL)
insert into #Install_Table(Param_Name,Param_String,Param_Int) values ('SQLDATA_Location',@SQLDATA_Location,NULL)
insert into #Install_Table(Param_Name,Param_String,Param_Int) values ('SQLLOGS_Location',@SQLLOGS_Location,NULL)
insert into #Install_Table(Param_Name,Param_String,Param_Int) values ('SQLDATADUMPS_Location',@SQLDATADUMPS_Location,NULL)
insert into #Install_Table(Param_Name,Param_String,Param_Int) values ('SQLLOGDUMPS_Location',@SQLLOGDUMPS_Location,NULL)
insert into #Install_Table(Param_Name,Param_String,Param_Int) values ('SQLREPORTS_Location',@SQLREPORTS_Location,NULL)
insert into #Install_Table(Param_Name,Param_String,Param_Int) values ('SSLTeam',@SSLTeam,NULL)
insert into #Install_Table(Param_Name,Param_String,Param_Int) values ('InstallDBATemplate',@InstallDBATemplate,NULL)
insert into #Install_Table(Param_Name,Param_String,Param_Int) values ('RunWeeklyJob',@RunWeeklyJob,NULL)
insert into #Install_Table(Param_Name,Param_String,Param_Int) values ('SQLPMF_Location',@SQLPMF_Location,NULL)
insert into #Install_Table(Param_Name,Param_String,Param_Int) values ('InstallDBATemplate',@InstallDBATemplate,NULL)
insert into #Install_Table(Param_Name,Param_String,Param_Int) values ('RunBackupReportOnly',NULL,@RunBackupReportOnly)
insert into #Install_Table(Param_Name,Param_String,Param_Int) values ('Servermake',@Servermake,NULL)
insert into #Install_Table(Param_Name,Param_String,Param_Int) values ('Servermodel',@Servermodel,NULL)
insert into #Install_Table(Param_Name,Param_String,Param_Int) values ('ClientOperatorEmail',@ClientOperatorEmail,NULL)
insert into #Install_Table(Param_Name,Param_String,Param_Int) values ('MonthlyJobStartDay',NULL,@MonthlyJobStartDay)
insert into #Install_Table(Param_Name,Param_String,Param_Int) values ('WeeklyJobStartTime',NULL, @WeeklyJobStartTime)
insert into #Install_Table(Param_Name,Param_String,Param_Int) values ('TemplateBackups', @TemplateBackups,NULL)
insert into #Install_Table(Param_Name,Param_String,Param_Int) values ('TemplateLogBackups',@TemplateLogBackups,NULL)
insert into #Install_Table(Param_Name,Param_String,Param_Int) values ('Domain',@Domain,NULL)
insert into #Install_Table(Param_Name,Param_String,Param_Int) values ('EyesOnlyInstall',@EyesOnlyInstall,NULL)
insert into #Install_Table(Param_Name,Param_String,Param_Int) values ('PowershellEnabled',@PowershellEnabled,NULL)
insert into #Install_Table(Param_Name,Param_String,Param_Int) values ('KaseyaServiceAccount',@KaseyaServiceAccount,NULL)
insert into #Install_Table(Param_Name,Param_String,Param_Int) values ('CopyBackupsTo',@CopyBackupsTo,NULL)
insert into #Install_Table(Param_Name,Param_String,Param_Int) values ('CopyLogBackupsTo',@CopyLogBackupsTo,NULL)
if ltrim(rtrim(@DropFolderDir)) <> ''
	insert into #Install_Table(Param_Name,Param_String,Param_Int) values ('DropFolderDir',@DropFolderDir,NULL)
insert into #Install_Table(Param_Name,Param_String,Param_Int) values ('DailyBackupStartTime',NULL, @DBBackupStartTime)


--Set model database data file to 10% autogrowth																																		TO DO
begin try
	use [master] 
	alter database [model] modify file ( NAME = N'modeldev', FILEGROWTH = 10%)
end try
begin catch
	set @OutputMessage = 'Unable to modify model database to 10 percent growth on the file model.mdf'
	raiserror(@OutputMessage, 10,1) with nowait
	insert into #OutMessages select 'Error', @OutputMessage
end catch


--Set Up Database Mail
if (@ConfigureDBMail='Y')
begin
	--Add a check that ManagedSQL doesn't already exist
	if (select count(*) from msdb..sysmail_profile where name = 'ManagedSQL') = 0
	begin

		set @OutputMessage = 'Setting Up Database Mail'
		raiserror(@OutputMessage, 10,1) with nowait

		declare @ServerEmail as varchar(150)
		declare @DisplayName as Varchar(150)

		set @ServerEmail = REPLACE(@@SERVERNAME,'\','_') + '@' + @Domain
		set @DisplayName = @CustomerCode + ' ' + REPLACE(@@SERVERNAME,'\','_') + '(' + @SLALevel + ')'
		
		execute msdb.dbo.sysmail_add_profile_sp
		
		@profile_name = 'ManagedSQL',
		@description = 'This Profile is used by SQL Services to manage this SQL Server.'
		
		execute msdb.dbo.sysmail_add_account_sp
		
		@account_name = 'ManagedSQL',
		@description = 'This account is used by SQL Services to monitor this SQL Server.',
		@email_address = @ServerEmail,
		@display_name = @DisplayName,
		@mailserver_name = @MailServer,
		@replyto_address = @ReplyToAddress,
		@port = 25
		
		execute msdb.dbo.sysmail_add_profileaccount_sp
		
		@profile_name = 'ManagedSQL',
		@account_name = 'ManagedSQL',
		@sequence_number = 1
	end
	else
	begin
		set @OutputMessage = 'Skipping create of ManagedSQL Database Mail profile - profile already exists'
		raiserror(@OutputMessage, 10,1) with nowait
	end
end





--Final Pre-run checks	
print 'Running Final Pre-install checks.....'	
print ''																										

--1.  Database Mail profile exists
if (select count(*) from msdb..sysmail_profile where name = 'ManagedSQL')=0
begin
	print 'No Mail Profile'
	raiserror ('Stopping Script - Database Mail profile not present', 20, 1) with log
end
else
	print 'Mail Profile Check detected.'


if exists (select * from #OutMessages where MessageType = 'Error')
begin
	select * from #OutMessages
	truncate table #OutMessages
	raiserror('Stopping Install of Template, please review the errors', 20,1) with log
end

/*
###################################################################################################################################
###################################################################################################################################
INSTALL DBA TEMPLATE - PASTE TEMPLATE INSTALL SCRIPT BELOW HERE
###################################################################################################################################
###################################################################################################################################
*/





/*
###################################################################################################################################
###################################################################################################################################
END DBA TEMPLATE INSTALL SCRIPT HERE
###################################################################################################################################
###################################################################################################################################
*/

/*
###################################################################################################################################
###################################################################################################################################
POST-DEPLOYMENT CODE BELOW HERE
###################################################################################################################################
###################################################################################################################################
*/
go
-- OK, if there were errors then we will not proceed

declare @JobStatus			int=0
declare @SQLJobName			varchar(300)

print 'Redeclare and Populate Parameters'

set nocount on

declare @ClientName					varchar(150)
declare @CustomerCode				varchar(10)
declare @ServerName					varchar(150)
declare @SLALevel					varchar(20) 
declare @SSLTeam					varchar(20)
declare @InstallerEmail				varchar(150)
declare @ClientOperatorEmail		varchar(500)
declare @Extension24x7				char(1)
declare @ExtensionIsCluster			char(1)
declare @ExtensionIsLogShipPrimary	char(1)
declare @ExtensionIsLogShipSecondary	char(1)
declare @ExtensionPMFInstalled			char(1)
declare @ExtensionReplication		char(1)
declare @ContractExpiry				datetime
declare @MailServer					varchar(100)
declare @DropFolderDir				varchar(512)
declare @KaseyaServiceAccount		varchar(512)
declare @DBBackupStartTime			int	
declare @WeeklyJobStartDay			tinyint
declare @SQLDATA_Location			varchar(1000) 
declare @SQLLOGS_Location			varchar(1000) 
declare @SQLDATADUMPS_Location		varchar(1000)
declare @SQLLOGDUMPS_Location		varchar(1000)
declare @SQLREPORTS_Location		varchar(1000) 
declare @SQLPMF_Location			varchar(1000)
declare @CopyBackupsTo				varchar(1000)
declare @CopyLogBackupsTo			varchar(1000)
declare @BestPracticeChanges		char(1)
declare @ConfigureDBMail			char(1)
declare @EyesOnlyInstall			char(1)
declare @PowershellEnabled			char(1)
declare @CopyEXEfiles				char(1)
declare @CopyEXEPath				varchar(1000)
declare @ReportsPerYear				tinyint
declare @ReplyToAddress				varchar(150)
declare @Domain						varchar(500)
declare @InstallDBATemplate			char(1)
declare @CONFIGURE_SQL_Agent		char(1)
declare @RunWeeklyJob				char(1)
declare @MonthlyJobStartDay			int 
declare @WeeklyJobStartTime			int 
declare @RunBackupReportOnly		int
declare @stepname					varchar(100)
declare @SQL						varchar(4000)
declare @Servermake					varchar(100)
declare @Servermodel				varchar(100)
declare @TemplateBackups			char(1)
declare @TemplateLogBackups			char(1)

declare @OutputMessage				varchar(max)


print 'Populating Variables from #Install_Table'
--select @InstallerEmail=Param_String from #Install_Table where Param_Name='InstallerName' 

select @ClientName = Param_String from #Install_Table where Param_Name = 'ClientName'					
select @CustomerCode = Param_String from #Install_Table where Param_Name = 'CustomerCode'									
select @ServerName = Param_String from #Install_Table where Param_Name = 'ServerName'									
select @SLALevel = Param_String from #Install_Table where Param_Name = 'SLALevel'														
select @SSLTeam	= Param_String from #Install_Table where Param_Name = 'SSLTeam'				
select @InstallerEmail = Param_String from #Install_Table where Param_Name = 'InstallerEmail'								
select @ClientOperatorEmail	= Param_String from #Install_Table where Param_Name = 'ClientOperatorEmail'									
select @Extension24x7 = Param_String from #Install_Table where Param_Name = 'Extension24x7'					
select @ExtensionIsCluster  = Param_String from #Install_Table where Param_Name = 'ExtensionIsCluster'					
select @ExtensionIsLogShipPrimary = Param_String from #Install_Table where Param_Name = 'ExtensionIsLogShipPrimary'				
select @ExtensionIsLogShipSecondary = Param_String from #Install_Table where Param_Name = 'ExtensionIsLogShipSecondary'			
select @ExtensionPMFInstalled = Param_String from #Install_Table where Param_Name = 'ExtensionPMFInstalled'			
select @ExtensionReplication = Param_String from #Install_Table where Param_Name = 'ExtensionReplication'		
select @ContractExpiry = Param_String from #Install_Table where Param_Name = 'ContractExpiry'			
select @MailServer = Param_String from #Install_Table where Param_Name = 'MailServer'					
select @DropFolderDir = Param_String from #Install_Table where Param_Name = 'DropFolderDir'				
select @KaseyaServiceAccount = Param_String from #Install_Table where Param_Name = 'KaseyaServiceAccount'		
select @DBBackupStartTime = Param_Int from #Install_Table where Param_Name = 'DailyBackupStartTime'	
select @WeeklyJobStartDay = Param_Int from #Install_Table where Param_Name = 'WeeklyJobStartDay'			
select @SQLDATA_Location = Param_String from #Install_Table where Param_Name = 'SQLDATA_Location'					
select @SQLLOGS_Location = Param_String from #Install_Table where Param_Name = 'SQLLOGS_Location'				
select @SQLDATADUMPS_Location = Param_String from #Install_Table where Param_Name = 'SQLDATADUMPS_Location'		
select @SQLLOGDUMPS_Location = Param_String from #Install_Table where Param_Name = 'SQLLOGDUMPS_Location'				
select @SQLREPORTS_Location = Param_String from #Install_Table where Param_Name = 'SQLREPORTS_Location'			
select @SQLPMF_Location = Param_String from #Install_Table where Param_Name = 'SQLPMF_Location'						
select @CopyBackupsTo = Param_String from #Install_Table where Param_Name = 'CopyBackupsTo'					
select @CopyLogBackupsTo = Param_String from #Install_Table where Param_Name = 'CopyLogBackupsTo'					
select @BestPracticeChanges	= Param_String from #Install_Table where Param_Name = 'BestPracticeChanges'			
select @ConfigureDBMail	= Param_String from #Install_Table where Param_Name = 'ConfigureDBMail'				
select @EyesOnlyInstall	= Param_String from #Install_Table where Param_Name = 'EyesOnlyInstall'		
select @PowershellEnabled = Param_String from #Install_Table where Param_Name = 'PowershellEnabled'				
select @CopyEXEfiles = Param_String from #Install_Table where Param_Name = 'CopyEXEfiles'				
select @CopyEXEPath	 = Param_String from #Install_Table where Param_Name = 'CopyEXEPath'			
select @ReportsPerYear	= Param_Int from #Install_Table where Param_Name = 'ReportsPerYear'					
select @ReplyToAddress	= Param_String from #Install_Table where Param_Name = 'ReplyToAddress'					
select @Domain = Param_String from #Install_Table where Param_Name = 'Domain'								
select @InstallDBATemplate = Param_String from #Install_Table where Param_Name = 'InstallDBATemplate'			 		
select @CONFIGURE_SQL_Agent	= Param_String from #Install_Table where Param_Name = 'CONFIGURE_SQL_Agent'		 	
select @RunWeeklyJob = Param_String from #Install_Table where Param_Name = 'RunWeeklyJob'						
select @MonthlyJobStartDay = Param_Int from #Install_Table where Param_Name = 'MonthlyJobStartDay'					
select @WeeklyJobStartTime = Param_Int from #Install_Table where Param_Name = 'WeeklyJobStartTime'					
select @SQLPMF_location	= Param_String from #Install_Table where Param_Name = 'SQLPMF_location'				
select @RunBackupReportOnly	= Param_String from #Install_Table where Param_Name = 'RunBackupReportOnly'			
select @Servermake = Param_String from #Install_Table where Param_Name = 'Servermake'			 				
select @Servermodel	= Param_String from #Install_Table where Param_Name = 'Servermodel'					
select @TemplateBackups	= Param_String from #Install_Table where Param_Name = 'TemplateBackups'				
select @TemplateLogBackups = Param_String from #Install_Table where Param_Name = 'TemplateLogBackups'					


if @InstallDBATemplate = 'Y'
begin

	if object_id('SSLDBA..tbl_Param') is null 
	begin
		set @OutputMessage = 'Looks like you didn''t add the DBA install script. Stopping Script - Install Script Incomplete!'		
		raiserror (@OutputMessage, 11, 1) with nowait
		return
	end

	print 'Updating tbl_Param'
	update SSLDBA..tbl_Param set TextValue = @CustomerCode where Param='CustCode'
	update SSLDBA..tbl_Param set TextValue = @ClientName where Param='CustomerName'

	if (select serverproperty('isclustered')) = 1
		update SSLDBA..tbl_Param set TextValue = 'Y' where Param='IsCluster'

	if exists (select * from #Install_Table t where t.Param_Name = 'Extension24x7' and t.Param_String = 'Y')
		update dbo.tbl_Param set TextValue = 'Y' where Param = '24x7'

	if exists (select * from #Install_Table t where t.Param_Name = 'ExtensionIsCluster' and t.Param_String = 'Y')
		update dbo.tbl_Param set TextValue = 'Y' where Param = 'IsCluster'

	if exists (select * from #Install_Table t where t.Param_Name = 'ExtensionIsLogShippingPrimary' and t.Param_String = 'Y')
		update dbo.tbl_Param set TextValue = 'Y' where Param = 'IsLogShippingPrimary'
	
	if exists (select * from #Install_Table t where t.Param_Name = 'ExtensionIsLogShippingSecondary' and t.Param_String = 'Y')
		update dbo.tbl_Param set TextValue = 'Y' where Param = 'IsLogShippingSecondary'

	if exists (select * from #Install_Table t where t.Param_Name = 'ExtensionPMFInstalled' and t.Param_String = 'Y')
		update dbo.tbl_Param set TextValue = 'Y' where Param = 'PMFInstalled'

	if exists (select * from #Install_Table t where t.Param_Name = 'ExtensionReplication' and t.Param_String = 'Y')
		update dbo.tbl_Param set TextValue = 'Y' where Param = 'ReplicationExtension'


	update SSLDBA..tbl_Param set NumValue = @DBBackupStartTime where Param='DailyBackupStartTime'

	update SSLDBA..tbl_Param set NumValue = @MonthlyJobStartDay where Param='MonthlyJobStartDay'
	if exists (select 1 from master.sys.databases where name = 'SSLMDW') 
		update SSLDBA..tbl_Param set TextValue = 'Y' where Param='PMFInstalled'
	
	--server make
	update SSLDBA..tbl_Param set TextValue = @Servermake where Param='ServerMake'
	--server model																																					
	update SSLDBA..tbl_Param set TextValue = @Servermodel where Param='ServerModel'
	update SSLDBA..tbl_Param set TextValue = @SLALevel where Param='SLALevel'
	update SSLDBA..tbl_Param set TextValue = @SQLDATA_Location where Param='SQLDATA'
	update SSLDBA..tbl_Param set TextValue = @SQLLOGS_Location where Param='SQLLOGS'
	update SSLDBA..tbl_Param set TextValue = @SQLDATADUMPS_Location where Param='SQLDATADUMPS'
	update SSLDBA..tbl_Param set TextValue = @SQLLOGDUMPS_Location where Param='SQLLOGDUMPS'
	update SSLDBA..tbl_Param set TextValue = @SQLREPORTS_Location where Param='SQLREPORTSDIR'
	update SSLDBA..tbl_Param set TextValue = @SSLTeam where Param='SSLTeam'
	update SSLDBA..tbl_Param set TextValue = @Domain where Param='DomainName'
	update SSLDBA..tbl_Param set TextValue = @DropFolderDir where Param='DropFolderDir'

	if object_id('tempdb..#SSL_SystemInfo') is not null
		drop table #SSL_SystemInfo

	create table #SSL_SystemInfo
	(
		data	varchar(1000)	null
	);

	-- now capture the results
	insert #SSL_SystemInfo exec master..xp_cmdshell 'systeminfo /fo list';
	
	-- "System Manufacturer" (ie. Compaq)
	-- If this is a Virtual Machine, this will be Microsoft, or VM Ware Inc.
	if not exists (select * from #SSL_SystemInfo where data like 'System Manufacturer:%')
		begin
			select @Servermake = 'Not detected'
		end
	else
		select @Servermake = ltrim(substring(data, 25, 1000)) from #SSL_SystemInfo where data like 'System Manufacturer:%'

	-- "System Model" (ie. ProLiant ML350G)
	if not exists (select * from #SSL_SystemInfo where data like 'System Model:%')
		begin
			select @Servermodel = 'Not detected'
		end
	else
		select @Servermodel = ltrim(substring(data, 25, 1000)) from #SSL_SystemInfo where data like 'System Model:%';


	if not exists (select * from #SSL_SystemInfo where data like 'Domain:%')
	begin
		select @Domain = 'Not detected'
	end
	else
		select @Domain = ltrim(substring(data, 25, 1000)) from #SSL_SystemInfo where data like 'Domain:%';

	-- Set up a test to try and prove that Powershell is working
	update SSLDBA.dbo.tbl_Param set TextValue = 'N' where Param = 'IsPowerShellEnabled'
	declare @PowerShellCmd varchar(255)
	set @PowerShellCmd = '@PowerShell -noprofile -command "Invoke-Sqlcmd -Query ''update SSLDBA.dbo.tbl_Param set TextValue = ''''Y'''' where Param = ''''IsPowerShellEnabled'''''' -ServerInstance ' + @ServerName +'"'
	execute master..xp_cmdshell @PowerShellCmd	


	-- Disk information is populated at this point:
	declare @XmlText varchar(max)
	if exists (select * from #Install_Table where Param_Name = 'PowerShellEnabled' and Param_String = 'Y')
		and SSLDBA.dbo.GetParamText ('IsPowerShellEnabled') = 'Y'
	begin

		-- Once we have the basic disk info, get PS to go and find the volume types
		-- and then we can outer join 
		declare @PowerShellResult table
		(
			ResultLine varchar(255)
		)

		declare @RawVolumes table
		(
			VolumeInfo xml
		)

		declare @Volumes table
		(
			Volume varchar(255)
			,FileSystem varchar(15)
			,Capacity varchar(18)
			,FreeSpace varchar(18)
		)

		set @PowerShellCmd = '@PowerShell -noprofile -command "get-WMIObject Win32_Volume | Select @{Name=''DriveLetter''; E={$_.DriveLetter}}, @{Name=''FileSystem''; E={$_.FileSystem}}, @{Name=''Capacity''; E={$_.Capacity}},  @{Name=''FreeSpace''; E={$_.FreeSpace}} | ConvertTo-XML -As String"'

		insert into @PowerShellResult execute master..xp_cmdshell @PowerShellCmd
	
		select @XmlText = ''
		select @XmlText = @XmlText + ltrim(rtrim(ResultLine)) from @PowerShellResult where left(ltrim(rtrim(ResultLine)), 1) = '<'
		select @XmlText = replace(@XmlText, '&#x0;', '')

		insert into @RawVolumes
		select cast(@XmlText as xml);
		
		set ansi_padding on
		
		insert into @Volumes
		select
			m.c.value('(Property[@Name="DriveLetter"]/text())[1]', 'varchar(255)'),
			m.c.value('(Property[@Name="FileSystem"]/text())[1]', 'varchar(15)'),
			m.c.value('(Property[@Name="Capacity"]/text())[1]', 'varchar(18)'),
			m.c.value('(Property[@Name="FreeSpace"]/text())[1]', 'varchar(18)')
		from 
			@RawVolumes as v
			outer apply v.VolumeInfo.nodes('Objects/Object') as m(c)
		order by
			m.c.value('(Property[@Name="DriveLetter"]/text())[1]', 'varchar(255)')
		

		if exists (select * from @Volumes where 
					FreeSpace < ceiling(convert(bigint, Capacity) * 10) / 100)
		begin
			set @OutputMessage =  'Oooops!  The available disk space is already lower than the default Warning threshold of 10%!'
			insert into #OutMessages select 'Error', @OutputMessage
		end	
		
		
		if exists (select * from @Volumes where 
					FreeSpace < ceiling(convert(bigint, Capacity) * 5) / 100)
		begin
			set @OutputMessage =  'Oooops!  The available disk space is already lower than the default Alert threshold of 5%!'
			insert into #OutMessages select 'Error', @OutputMessage
		end

		insert into SSLDBA.dbo.tbl_LogicalDisks
		select 
			v.Volume 
			,row_number() over (order by v.Volume)-1
			,convert(bigint, v.Capacity) / 1024 /1024 
			,ceiling(convert(bigint, v.Capacity) / 1024 / 1024*10) / 100 
			,ceiling(convert(bigint, v.Capacity) / 1024 / 1024*5) / 100 
			,null
			,null
			,'N'
		from 
			@Volumes v
		where 
			Volume is not null
			and v.FileSystem <> 'CDFS'
	end
	else
	begin

		declare @RawData table
		(
			details varchar(1000)
		)
	
		declare @x xml
		declare @Drives table
		(
			Id				smallint identity(1,1)
			,DriveLetter	char(1)
		)

		declare @DriveFreeSpace table
		(
			Id				smallint identity(1,1)
			,DriveSpace		bigint
		)

		declare @DriveSize table
		(
			Id				smallint identity(1,1)
			,DriveSize		bigint
		)

		set ansi_padding on

		insert into @RawData
		exec xp_cmdshell 'wmic logicaldisk where drivetype=3 get name, freespace, size /format:RAWXML'

		select @XmlText = ''
		select @XmlText = @XmlText + ltrim(rtrim(details)) from @RawData where left(ltrim(rtrim(details)), 1) = '<'
		select @XmlText = replace(@XmlText, '&#x0;', '')

		select @x = cast(@XmlText as XML) 


		insert into @Drives
		select
			left(t.s.value('.', 'nvarchar(max)'), 1) as Drive
		from 
			@x.nodes('//PROPERTY[@NAME="Name"]/VALUE') t(s)


		insert into @DriveFreeSpace
		select
			convert(bigint, t.s.value('.', 'nvarchar(max)'))/1024/1024  as FreeSpace
		from 
			@x.nodes('//PROPERTY[@NAME="FreeSpace"]/VALUE') t(s)

		insert into @DriveSize
		select
			convert(bigint, t.s.value('.', 'nvarchar(max)'))/1024/1024 as Size
		from 
			@x.nodes('//PROPERTY[@NAME="Size"]/VALUE') t(s)



		if exists (select * from @Drives d
								inner join @DriveFreeSpace fs on fs.Id = d.Id
								inner join @DriveSize ds on ds.Id = d.Id 
							where 
								ds.DriveSize < ceiling(convert(bigint, ds.DriveSize) * 10) / 100)
		begin
			set @OutputMessage =  'Oooops!  The available disk space is already lower than the default Warning threshold of 10%!'
			insert into #OutMessages select 'Error', @OutputMessage
		end	
		
		
		if exists (select * from @Drives d
								 inner join @DriveFreeSpace fs on fs.Id = d.Id
								 inner join @DriveSize ds on ds.Id = d.Id 
							where 
								ds.DriveSize < ceiling(convert(bigint, ds.DriveSize) * 5) / 100)
		begin
			set @OutputMessage =  'Oooops!  The available disk space is already lower than the default Alert threshold of 5%!'
			insert into #OutMessages select 'Error', @OutputMessage
		end	


		-- This would go into Logical Disks
		insert into SSLDBA.dbo.tbl_LogicalDisks
		select 
			d.DriveLetter
			,d.Id-1
			,ds.DriveSize  
			,ceiling(ds.DriveSize*10) / 100 as MBWarn  
			,ceiling(ds.DriveSize*5) / 100 as MBAlert 
			,null
			,null
			,'N'
		from
			@Drives d
			inner join @DriveFreeSpace fs on fs.Id = d.Id
			inner join @DriveSize ds on ds.Id = d.Id
		order by 
			d.DriveLetter
	end


		
	if (@TemplateBackups='N')
		Update SSLDBA..tbl_Databases set TemplateBackup = 'N'

	if (@TemplateLogBackups='N')
		update SSLDBA..tbl_Databases set LogBackupStart = null, LogBackupFinish = null

	update SSLDBA..tbl_Databases 
		set CopyBackupsTo		= case when @CopyBackupsTo = '' then  NULL else @CopyBackupsTo end
		set @CopyLogBackupsTo	= case when @CopyLogBackupsTo = '' then  NULL else @CopyLogBackupsTo end

	set nocount on

	exec SSLDBA..up_ApplyTemplate

	--TBL_OPERATOR
	update SSLDBA..tbl_Operator set EMailAddress= @ClientOperatorEmail where Operator='In-House DBA'

	if exists (select * from #Install_Table where Param_Name = 'KaseyaServiceAccount' and Param_String <> '')
	begin			
		declare @AccountName nvarchar(128)
		select @AccountName = Param_String from #Install_Table where Param_Name = 'KaseyaServiceAccount' 
		exec sp_addrolemember N'db_owner', @AccountName
	end

	--select * from SSLDBA..tbl_JobHistDetails where Job_name like 'SSL%'

	print 'SQL Services DBA Template installed by ' + @InstallerEmail + ' for ' + @ClientName + ' and expiring on ' + cast(@ContractExpiry as varchar(20));

	--Mail Post install and healthcheck to installer
	set @SQL = 'DBA Template installed on ' + @CustomerCode + ' ' + @@SERVERNAME + ' by ' + @InstallerEmail
		

	
	--Recreate Doctemplate.xml
	declare @CmdString as nvarchar(2000)
	set @CmdString = (select 'osql -n -w8000 -h-1 -dSSLDBA -E -S' + REPLACE(@@SERVERNAME,'\','_') + ' -Q"up_DocTemplateXML" -o"' + TextValue + 'DocTemplate_' + REPLACE(@@SERVERNAME,'\','_') + '.xml"' from SSLDBA.dbo.tbl_Param where Param = 'SQLReportsDir')
	exec xp_cmdshell @CmdString
	
	--Create Template Install Document
	set @CmdString = (select 'echo ' + @CustomerCode +'*'+@@SERVERNAME +'*'+ @InstallerEmail +' >' + TextValue + 'TemplateInstall_'+ REPLACE(@@SERVERNAME,'\','_') + '.txt' from SSLDBA.dbo.tbl_Param where Param = 'SQLReportsDir')
	exec xp_cmdshell @CmdString
		
	set @CmdString = (select TextValue + 'DocTemplate_'+ REPLACE(@@SERVERNAME,'\','_') +'.xml;' + TextValue + 'TemplateInstall_'+ REPLACE(@@SERVERNAME,'\','_') + '.txt' from SSLDBA.dbo.tbl_Param where Param = 'SQLReportsDir')
	print @CmdString



	--Remove the XML file
	set @CmdString = (select 'Del ' + TextValue + 'DocTemplate*.xml' from SSLDBA.dbo.tbl_Param where Param = 'SQLReportsDir')
	print @CmdString
	exec xp_cmdshell @CmdString
		
end

-- Best Practice Changes are implemented here
if @BestPracticeChanges = 'Y'
begin

	--Configure SQL Agent history properties
	set @OutputMessage = 'Reconfiguring SQL Agent history Settings'
	raiserror(@OutputMessage, 10,1) with nowait
	exec msdb.dbo.sp_set_sqlagent_properties @jobhistory_max_rows=100000, @jobhistory_max_rows_per_job=5000

	-- Configure Max Server Memory
	-- if not set, or if set to a value greater than memory in the server:
	-- Reserve (don't allocate to SQL):
		-- 1 GB of RAM for the OS, 
		-- 1 GB for each 4 GB of RAM installed from 4–16 GB
		-- 1 GB for every 8 GB RAM installed above 16 GB 
		-- 1 GB for every 32GB of RAM installed above 32 GB 

	declare @TotalPhysicalMemoryMB int
	declare @MaxServerMemoryMB	bigint
	declare @CalculatedMaxServerMemoryMB bigint
	declare @MemoryToReserveGB int = 1 -- for the OS
	declare @Over32GB int = 0
	declare @Over16GB int = 0
	declare @Over4GB int  = 0

	select @TotalPhysicalMemoryMB = (total_physical_memory_kb / 1024) from sys.dm_os_sys_memory
	select @MaxServerMemoryMB = convert(bigint, value) from master.sys.configurations where name = 'max server memory (MB)'

	-- if not set, or if set to a value greater than memory in the server:
	if @MaxServerMemoryMB = 2147483647 or @MaxServerMemoryMB > @TotalPhysicalMemoryMB
	begin

		set @OutputMessage = 'Max Memory has not been changed from the default of 2147483647'
		raiserror(@OutputMessage, 10,1) with nowait
	
		-- 1 GB of RAM for the OS
		-- 1 GB for each 4 GB of RAM installed from 4–16 GB
		-- 1 GB for every 8 GB RAM installed above 16 GB 
		-- 1 GB for every 32GB of RAM installed above 32 GB 
		
		set @Over32GB = ((@TotalPhysicalMemoryMB / 1024) - 32) / 32 --/ 1024

		set @Over16GB = case 
							when @TotalPhysicalMemoryMB <= 16384 then 0
							when @TotalPhysicalMemoryMB > 32768 then 2 
							else ((@TotalPhysicalMemoryMB / 1024) - 16) / 8 --/ 1024
						end

		set @Over4GB = case when @TotalPhysicalMemoryMB > 4096 
						then 1 +
							case 
								when @TotalPhysicalMemoryMB > 8192 then 2
								when @TotalPhysicalMemoryMB > 16384 then 3
							end
						end

		set @MemoryToReserveGB = @MemoryToReserveGB + @Over4GB +  @Over16GB + @Over32GB

		set @CalculatedMaxServerMemoryMB = @TotalPhysicalMemoryMB - (@MemoryToReserveGB * 1024)

		use master
		exec sp_configure 'show advanced options', 1
		reconfigure with override
		use master
		exec sp_configure 'max server memory (MB)', @CalculatedMaxServerMemoryMB   
		reconfigure with override  
		use master
		exec sp_configure 'show advanced options', 0
		reconfigure with override  


		-- Data and Log file location
		exec xp_instance_regwrite N'HKEY_LOCAL_MACHINE'
		, N'Software\Microsoft\MSSQLServer\MSSQLServer'
		, N'DefaultData'
		, REG_SZ
		, @SQLDATA_Location

		exec xp_instance_regwrite N'HKEY_LOCAL_MACHINE'
		, N'Software\Microsoft\MSSQLServer\MSSQLServer'
		, N'DefaultLog'
		, REG_SZ
		, @SQLLOGS_Location


		-- Security Audit Level - Failure
		exec xp_instance_regwrite N'HKEY_LOCAL_MACHINE', 
			N'Software\Microsoft\MSSQLServer\MSSQLServer', 
			N'AuditLevel', REG_DWORD, 2 -- Failed only

	end

end


-- the the SSLDBA is there then record the parameters we used for the express install
if exists (select * from master.sys.databases where name = 'SSLDBA') 
begin

	declare @results table
	(
		RecordID int
	)

	declare @ReturnValue int

	insert into 
		SSLDBA..tbl_ExpressInstallOptions 
	output 
		Inserted.InstallOptionID into @results 
	select 
		getdate()
		,null
		,@ClientName
		,@CustomerCode
		,@ServerName						
		,@SLALevel						
		,@SSLTeam						
		,@InstallerEmail					
		,@ClientOperatorEmail			
		,@Extension24x7					
		,@ExtensionIsCluster 			
		,@ExtensionIsLogShipPrimary		
		,@ExtensionIsLogShipSecondary	
		,@ExtensionPMFInstalled			
		,@ExtensionReplication			
		,'N'		
		,'N'		
		,'N'		
		,'N'				
		,@ContractExpiry					
		,@MailServer						
		,@DropFolderDir					
		,@KaseyaServiceAccount			
		,@DBBackupStartTime				
		,@WeeklyJobStartDay				
		,@WeeklyJobStartTime				
		,@MonthlyJobStartDay				
		,@SQLDATA_Location				
		,@SQLLOGS_Location				
		,@SQLDATADUMPS_Location			
		,@SQLLOGDUMPS_Location			
		,@SQLREPORTS_Location			
		,@SQLPMF_Location				
		,@CopyBackupsTo					
		,@CopyLogBackupsTo				
		,@BestPracticeChanges			
		,@ConfigureDBMail				
		,@EyesOnlyInstall				
		,@PowershellEnabled				
		,@CopyEXEfiles					
		,@CopyEXEPath					
		,@ReportsPerYear					
		,@ReplyToAddress					
		,@Domain							
		,@InstallDBATemplate				
		,@CONFIGURE_SQL_Agent			
		,@RunWeeklyJob					
		,@RunBackupReportOnly			
		,@Servermake						
		,@Servermodel					
		,@TemplateBackups				
		,@TemplateLogBackups		

		-- capture the output identity
		set @ReturnValue = (select RecordID from @results)
		
		-- store for recording script completion time
		insert into #Install_Table select 'InstallOptionID', null, @ReturnValue

end


if @InstallDBATemplate = 'Y'
begin
	if @EyesOnlyInstall = 'Y'
	begin

		if object_id('tempdb..#TheMaintenancePlans') is not null
			drop table #TheMaintenancePlans

		create table #TheMaintenancePlans
		(
			PlanName			sysname
			,SubPlanName		sysname
			,PlanOwner			varchar(128)
			,JobName			sysname
			,JobID				uniqueidentifier		
			,HasBeenDisabled	bit
		)

		declare @JobID uniqueidentifier

		-- Get the enabled Maintenance Plans
		insert into #TheMaintenancePlans
		select 
			p.name 
			,sp.subplan_name 
			,p.[owner] 
			,j.name 
			,j.job_id
			,0
		from 
			msdb..sysmaintplan_plans p
			inner join msdb..sysmaintplan_subplans sp on p.id = sp.plan_id
			inner join msdb..sysjobs j on sp.job_id = j.job_id
		where 	
			j.[enabled] = 1


		while exists (select * from #TheMaintenancePlans where HasBeenDisabled = 0)
		begin

			select top 1 @JobID = JobID from #TheMaintenancePlans where HasBeenDisabled = 0 order by JobID

			exec msdb.dbo.sp_update_job @job_id = @JobID ,@enabled = 0

			update #TheMaintenancePlans set HasBeenDisabled = 1 where JobID = @JobID

		end

		select 
			PlanName
			,SubPlanName
			,PlanOwner
			,JobName
			,JobID
			,case when HasBeenDisabled = 1 then 'Yes' else 'No' end as HasBeenDisabled
		from 
			#TheMaintenancePlans


		-- set all backups, optimizations and DBCC's to N
		update SSLDBA.dbo.tbl_Databases set WeeklyDefrag = 'N', WeeklyDBCC = 'N', TemplateBackup = 'N'


		if object_id('tempdb..#SSLJobs') is not null
			drop table #SSLJobs

		create table #SSLJobs
		(
			JobID				uniqueidentifier
			,JobName			sysname
			,HasBeenDisabled	bit
		)

		-- Get all SSL jobs except the Dashboard job and the Weekly job
		insert into #SSLJobs
		select 
			j.job_id
			,j.[name]
			,0
		from 
			msdb..sysjobs j
			left outer join msdb..syscategories s on j.category_id = s.category_id
		where 	
			j.name like 'SSL_%'
			and j.name not in ('SSL_SendDashboardData', 'SSL_DailyChecks') 
			and j.[enabled] = 1
			and s.name like 'SSL%'


		while exists (select * from #SSLJobs where HasBeenDisabled = 0)
		begin

			select top 1 @JobID = JobID from #SSLJobs where HasBeenDisabled = 0 order by JobID

			exec msdb.dbo.sp_update_job @job_id = @JobID ,@enabled = 0

			update #SSLJobs set HasBeenDisabled = 1 where JobID = @JobID

		end


		--Run Dashboard Job
		set @JobStatus = 0
		set @SQLJobName='SSL_SendDashboardData'
		exec msdb.dbo.sp_start_job @job_name = @SQLJobName
		while @JobStatus < 1
		begin	
			select 
				@JobStatus = count(*) 
			from 
				msdb.dbo.sysjobhistory 
			where 
				step_id=0 and job_id =(select job_id from msdb.dbo.sysjobs where name = @SQLJobName)	
		
			if @JobStatus < 1
			begin
				print 'Waiting for ' + @SQLJobName + ' to complete'
				waitfor delay '00:00:05'
			end
			else
			begin
				print 'Job ''' + @SQLJobName + ''' has completed!'
			end
		end


		--Enable Dashboard Job if it's run successfully
		if (select top 1 run_status from msdb.dbo.sysjobhistory where step_id=0 and job_id =(select job_id from msdb.dbo.sysjobs where name = @SQLJobName) order by msdb.dbo.agent_datetime(run_date, run_time) desc )=1
		begin
			print 'Dashboard Job has succeeded - Enabling'	
			select @SQLJobName = job_id from msdb.dbo.sysjobs where name = 'SSL_SendDashboardData'  --Switch the name for the id of the job
			exec msdb.dbo.sp_update_job @job_id=@SQLJobName, @enabled=1
		end

		exec msdb.dbo.sp_update_job @job_name='SSL_DailyChecks', @enabled=1

	end
	else -- Eyes Only = 'N'
	begin
		-- Backup SSLDBA and then send the backup report
		exec SSLDBA..up_BackupDatabase 'SSLDBA'
		exec msdb..sp_start_job 'SSL_Backup_All_Databases', @step_name = 'Create Backup Report'


		--Backup Transaction Logs
		declare @name sysname
		declare @DatabaseName sysname
	
		declare db_cursor cursor for  
			select 
				name 
			from 
				msdb.dbo.sysjobs 
			where 
				name like 'SSL_Backup_Log%'
	
		open db_cursor   
		fetch next from db_cursor into @name   

		while @@fetch_status = 0   
		begin   
			print 'Starting Log backup job: ' + @name
			set @SQLJobName=@name
		
			-- wrap the attempt into a try catch to stop a job that might be already runnning error
			begin try
				exec msdb.dbo.sp_start_job @job_name = @SQLJobName
			end try
			begin catch
			end catch
		
			fetch next from db_cursor into @name   
		end   
		close db_cursor   
		deallocate db_cursor

		-- Run the Weekly Job from the Health Check Script step
		begin
			set @JobStatus = 0
			set @SQLJobName='SSL_Weekly_Job'
			set @stepname = 'Run SSL Health Check Script'

			exec msdb.dbo.sp_start_job @job_name = @SQLJobName, @step_name = @stepname

			while @JobStatus < 1
			begin	
				select 
					@JobStatus = count(*) 
				from 
					msdb.dbo.sysjobhistory 
				where 
					step_id=0 and job_id = (select job_id from msdb.dbo.sysjobs where name = @SQLJobName)	
		
			if @JobStatus < 1
			begin
				print 'Waiting for ' + @SQLJobName + ' to complete'
				waitfor delay '00:00:05';
				end
			end
		end

		--Enable Weekly Job if it's run successfully
		if (select top 1 run_status from
					msdb.dbo.sysjobhistory h
					inner join msdb.dbo.sysjobs j on j.job_id = h.job_id
				where 
					j.[name] = 'SSL_Weekly_Job'
					and h.step_id = 0
				order by
					h.run_date desc
					, h.run_time desc) = 1
		begin
			print 'Weekly Job has succeeded - Enabling'	
			select 
				@SQLJobName = job_id 
			from 
				msdb.dbo.sysjobs 
			where 
				name = 'SSL_Weekly_Job' 
		
			exec msdb.dbo.sp_update_job @job_id=@SQLJobName, @enabled=1
		end

		--Run other jobs
		exec msdb.dbo.sp_start_job @job_name = 'SSL_CheckDiskSpace'
		waitfor delay '00:00:10';

		--Enable Weekly Job if it's run successfully
		if (select top 1 run_status from
					msdb.dbo.sysjobhistory h
					inner join msdb.dbo.sysjobs j on j.job_id = h.job_id
				where 
					j.[name] = 'SSL_CheckDiskSpace'
					and h.step_id = 0
				order by
					h.run_date desc
					, h.run_time desc) = 1
		begin
			print 'SSL_CheckDiskSpace job has succeeded - Enabling'	
			select 
				@SQLJobName = job_id 
			from 
				msdb.dbo.sysjobs 
			where 
				name = 'SSL_CheckDiskSpace'  
		
			exec msdb.dbo.sp_update_job @job_id=@SQLJobName, @enabled=1
		end


		exec msdb.dbo.sp_start_job @job_name = 'SSL_CheckLongRunningJobs'
		waitfor delay '00:00:10';

		-- Enable SSL_CheckLongRunningJobs if it succeeded
		if (select top 1 run_status from
					msdb.dbo.sysjobhistory h
					inner join msdb.dbo.sysjobs j on j.job_id = h.job_id
				where 
					j.[name] = 'SSL_CheckLongRunningJobs'
					and h.step_id = 0
				order by
					h.run_date desc
					, h.run_time desc) = 1
		begin
			print 'SSL_CheckLongRunningJobs job has succeeded - Enabling'	
			select 
				@SQLJobName = job_id 
			from 
				msdb.dbo.sysjobs 
			where 
				name = 'SSL_CheckLongRunningJobs' 
		
			exec msdb.dbo.sp_update_job @job_id=@SQLJobName, @enabled=1

			--Update tbl_jobhistdetails
			print 'Updating tbl_jobHistDetails'
			update SSLDBA..tbl_JobHistDetails set Auto_stop='Y', Duration_alarm=600 where Job_name='SSL_Weekly_Job'
			update SSLDBA..tbl_JobHistDetails set Auto_stop='Y', Duration_alarm=200 where Job_name='SSL_Monthly_Report'
			update SSLDBA..tbl_JobHistDetails set Auto_stop='Y', Duration_alarm=7 where Job_name='SSL_SendDashboardData'
			update SSLDBA..tbl_JobHistDetails set Auto_stop='Y', Duration_alarm=600 where Job_name LIKE 'SSL_Optimi%'
			update SSLDBA..tbl_JobHistDetails set Auto_stop='Y', Duration_alarm=180 where Job_name='SSL_Optimise_GenMasterList'

		end


		-- Run SSL_SendDBCCFileWeekly
		exec msdb..sp_start_job @job_name = 'SSL_SendDBCCFileWeekly'
		waitfor delay '00:00:10';

		if (select top 1 run_status from
					msdb.dbo.sysjobhistory h
					inner join msdb.dbo.sysjobs j on j.job_id = h.job_id
				where 
					j.[name] = 'SSL_SendDBCCFileWeekly'
					and h.step_id = 0
				order by
					h.run_date desc
					, h.run_time desc) = 1
		begin
			print 'SSL_SendDBCCFileWeekly job has succeeded - Enabling'	
			select 
				@SQLJobName = job_id 
			from 
				msdb.dbo.sysjobs 
			where 
				name = 'SSL_SendDBCCFileWeekly'  
		
			exec msdb.dbo.sp_update_job @job_id=@SQLJobName, @enabled=1
		end


		-- Run SSL_DailyChecks
		exec msdb..sp_start_job @job_name = 'SSL_DailyChecks'
		waitfor delay '00:00:10';

		if (select top 1 run_status from
					msdb.dbo.sysjobhistory h
					inner join msdb.dbo.sysjobs j on j.job_id = h.job_id
				where 
					j.[name] = 'SSL_DailyChecks'
					and h.step_id = 0
				order by
					h.run_date desc
					, h.run_time desc) = 1
		begin
			print 'SSL_DailyChecks job has succeeded - Enabling'	
			select 
				@SQLJobName = job_id 
			from 
				msdb.dbo.sysjobs 
			where 
				name = 'SSL_DailyChecks'  
		
			exec msdb.dbo.sp_update_job @job_id=@SQLJobName, @enabled=1
		end


		-- Run SSL_SendDashboardData
		exec msdb..sp_start_job @job_name = 'SSL_SendDashboardData'
		waitfor delay '00:00:10';

		if (select top 1 run_status from
					msdb.dbo.sysjobhistory h
					inner join msdb.dbo.sysjobs j on j.job_id = h.job_id
				where 
					j.[name] = 'SSL_SendDashboardData'
					and h.step_id = 0
				order by
					h.run_date desc
					, h.run_time desc) = 1
		begin
			print 'SSL_SendDashboardData job has succeeded - Enabling'	
			select 
				@SQLJobName = job_id 
			from 
				msdb.dbo.sysjobs 
			where 
				name = 'SSL_SendDashboardData'  
		
			exec msdb.dbo.sp_update_job @job_id=@SQLJobName, @enabled=1
		end

		-- Run SSL_Monthly_Report
		exec msdb..sp_start_job @job_name = 'SSL_Monthly_Report'
		waitfor delay '00:00:30';

		if (select top 1 run_status from
					msdb.dbo.sysjobhistory h
					inner join msdb.dbo.sysjobs j on j.job_id = h.job_id
				where 
					j.[name] = 'SSL_Monthly_Report'
					and h.step_id = 0
				order by
					h.run_date desc
					, h.run_time desc) = 1
		begin
			print 'SSL_Monthly_Report job has succeeded - Enabling'	
			select 
				@SQLJobName = job_id 
			from 
				msdb.dbo.sysjobs 
			where 
				name = 'SSL_Monthly_Report'  
		
			exec msdb.dbo.sp_update_job @job_id=@SQLJobName, @enabled=1
		end
		else
		begin
			waitfor delay '00:00:30';

			if (select top 1 run_status from
							msdb.dbo.sysjobhistory h
							inner join msdb.dbo.sysjobs j on j.job_id = h.job_id
						where 
							j.[name] = 'SSL_Monthly_Report'
							and h.step_id = 0
						order by
							h.run_date desc
							, h.run_time desc) = 1
				begin
					print 'SSL_Monthly_Report job has succeeded - Enabling'	
					select 
						@SQLJobName = job_id 
					from 
						msdb.dbo.sysjobs 
					where 
						name = 'SSL_Monthly_Report'  
		
					exec msdb.dbo.sp_update_job @job_id=@SQLJobName, @enabled=1
				end
		end
	end

	-- Set the trace default details
	update SSLDBA.dbo.tbl_Param set TextValue = 'Y' where Param = 'CopyDefaultTraceEnabled' 
	declare @temp varchar(255)
	select @temp = TextValue from dbo.tbl_Param where Param = 'SQLReportsDir'
	update SSLDBA.dbo.tbl_Param set TextValue = @temp where Param = 'CopyDefaultTraceToDir' 

end


-- update the script's completion time 
if exists (select * from #Install_Table where Param_Name = 'InstallOptionID' and isnull(Param_Int, 0) <> 0)
begin
	declare @InstallOptionID int
	select @InstallOptionID = Param_Int from #Install_Table where Param_Name = 'InstallOptionID'
	update SSLDBA..tbl_ExpressInstallOptions set EndTime = getdate() where InstallOptionID = @InstallOptionID
end


set @OutputMessage = 'Completed Automatic Template Deployment and Configuration Process.  Please check the last output in the Results window for any further information or issues.'
raiserror(@OutputMessage, 10,1) with nowait

-- Select out anything that might have been an issue
if exists (select * from #OutMessages)
	select * from #OutMessages 
