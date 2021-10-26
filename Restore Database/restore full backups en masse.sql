/************************************************************************
Disclaimer: This script has the following requirements:
The restored databases will have the same name as the backed up databases
The same file locations from the backed up database must be available
Only full backup files should be stored in the @directory.

To restore log backups, see 'restore transaction log backups en masse.sql'
*************************************************************************/

DECLARE @directory nvarchar(128) = 'C:\SQLDataDumps\' -- Specify the directory where the full backups are

create table #temp_backup_files (
    BackupID INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,
    filename varchar(400),
    )

declare @cmd varchar(200) = 'dir /b ' + @directory
declare @filename varchar(255)
insert into #temp_backup_files exec xp_cmdshell @cmd
delete from #temp_backup_files where filename is NULL

create table #temp_header (
    BackupName nvarchar(128),
    BackupDescription nvarchar(255),
    BackupType smallint,
    ExpirationDate datetime,
    Compressed bit,
    Position smallint,
    DeviceType tinyint,
    UserName nvarchar(128),
    ServerName nvarchar(128),
    DatabaseName nvarchar(128),
    DatabaseVersion int,
    DatabaseCreationDate datetime,
    BackupSize numeric(20,0),
    FirstLSN numeric(25,0),
    LastLSN numeric(25,0),
    CheckpointLSN numeric(25,0),
    DatabaseBackupLSN numeric(25,0),
    BackupStartDate datetime,
    BackupFinishDate datetime,
    SortOrder smallint,
    CodePage smallint,
    UnicodeLocaleId int,
    UnicodeComparisonStyle int,
    CompatibilityLevel tinyint,
    SoftwareVendorId int,
    SoftwareVersionMajor int,
    SoftwareVersionMinor int,
    SoftwareVersionBuild int,
    MachineName nvarchar(128),
    Flags int,
    BindingID uniqueidentifier,
    RecoveryForkID uniqueidentifier,
    Collation nvarchar(128),
    FamilyGUID uniqueidentifier,
    HasBulkLoggedData bit,
    IsSnapshot bit,
    IsReadOnly bit,
    IsSingleUser bit,
    HasBackupChecksums bit,
    IsDamaged bit,
    BeginsLogChain bit,
    HasIncompleteMetaData bit,
    IsForceOffline bit,
    IsCopyOnly bit,
    FirstRecoveryForkID uniqueidentifier,
    ForkPointLSN numeric(25,0) NULL,
    RecoveryModel nvarchar(60),
    DifferentialBaseLSN numeric(25,0) NULL,
    DifferentialBaseGUID uniqueidentifier,
    BackupTypeDescription nvarchar(60),
    BackupSetGUID uniqueidentifier NULL,
    CompressedBackupSize bigint,
    containment tinyint not NULL,
    KeyAlgorithm nvarchar(32),
    EncryptorThumbprint varbinary(20),
    EncryptorType nvarchar(32)
)
create table #temp_label (
    MediaName nvarchar(128),
    MediaSetId uniqueidentifier,
    FamilyCount int,
    FamilySequenceNumber int,
    MediaFamilyId uniqueidentifier,
    MediaSequenceNumber int,
    MediaLabelPresent tinyint,
    MediaDescription nvarchar(255),
    SoftwareName nvarchar(128),
    SoftwareVendorId int,
    MediaDate datetime,
    Mirror_Count int,
    IsCompressed bit,
)

Declare @file_name nvarchar(128)
declare @database_name nvarchar(128)
declare @BackupType smallint
declare @FamilyCount int
declare @FamilySequenceNumber int
declare @sql_cmd nvarchar(200)
declare @row_count int = 0
declare @cursor int = 1

set @row_count = (select count(1) from #temp_backup_files) + 1

create table #output (
    PK_ID int IDENTITY (1,1) NOT NULL,
    Name nvarchar(128), 
    sql_cmd nvarchar(200)
)

while @cursor < @row_count
BEGIN
    Select Top 1 @file_name = filename From #temp_backup_files where BackupID = @cursor
	set @sql_cmd = 'RESTORE HEADERONLY FROM DISK = '''+@directory + @file_name + ''''
	INSERT INTO #temp_header exec sp_executesql @sql_cmd
    set @sql_cmd = 'RESTORE LABELONLY FROM DISK = '''+@directory + @file_name + ''''
	INSERT INTO #temp_label exec sp_executesql @sql_cmd
	set @database_name = (select top 1 DatabaseName from #temp_header)
	set @BackupType = (select top 1 BackupType from #temp_header)
	set @FamilyCount = (select top 1 FamilyCount from #temp_label)
	set @FamilySequenceNumber = (select top 1 FamilySequenceNumber from #temp_label)
	if not exists (select top 1 name from #output where name = @database_name)
	begin
		if @FamilySequenceNumber = 1
		begin
			insert into #output (Name, sql_cmd) values (@database_name, 'RESTORE Database ['+ @database_name +'] FROM DISK='''+ @directory + @file_name + '''')
		end
	end
	else
	begin
		if @FamilySequenceNumber = 2
		begin
			update #output set sql_cmd = sql_cmd + ', DISK='''+ @directory + @file_name + '''' where Name = @database_name
		end
	end
    truncate table #temp_header
    truncate table #temp_label
    set @cursor = @cursor + 1
    --delete from #temp_backup_files where filename = @file_name
End

update #output set sql_cmd = sql_cmd + ' WITH REPLACE, NORECOVERY;'
select * from #output

select distinct 'restore database ' + name + ' with recovery' from #output

drop table #temp_backup_files
drop table #temp_header
drop table #temp_label
drop table #output