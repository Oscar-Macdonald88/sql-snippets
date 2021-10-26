--Run on primary
declare @Days int = 1 --Number of days to look back in backup history (Unless more then 1 day behind this should never require changing)
declare @LastRestore table (DBName varchar(255), LastRestore varchar(255), DataTime datetime)
declare @RestoresToComplete table (DBName varchar(255), Files int, BytesRemaining int, CurrentBackup varchar(255), CurrentRestore varchar(255), BackupTime datetime)
 
--\/ \/ \/ INSERTS HERE \/ \/ \/
 
 
 
--/\ /\ /\ INSERTS HERE /\ /\ /\
 
select distinct
	database_name,
	bs.backup_start_date,
	compressed_backup_size,
	REVERSE(LEFT(REVERSE(physical_device_name), isnull(CHARINDEX('\', REVERSE(physical_device_name)) - 1 ,0))) as 'file_location'
into #LastBackup
from msdb..backupfile bf
inner join msdb..backupset bs on bf.backup_set_id = bs.backup_set_id
inner join msdb..log_shipping_primary_databases on database_name = primary_database
inner join msdb..backupmediafamily bmf on bmf.media_set_id = bs.media_set_id
where
	bf.file_type = 'L'
	and bs.backup_start_date > GETDATE() - @Days
	and database_name in (
		select DBName
		from @LastRestore
		)
 
declare
	@DBName varchar(255),
	@LastDBRestore varchar(255),
	@MBToRestore int,
	@FileCount int,
	@DataTime varchar(255),
	@CurrentBackup varchar(255),
	@File varchar(255),
	@BackupStart datetime
 
set @DataTime = (select top (1) DataTime from @LastRestore)
 
while exists (select DBName from @LastRestore)
begin
	set @DBName = (select top (1) DBName from @LastRestore)
	set @LastDBRestore = (select top (1) LastRestore from @LastRestore )
	set @CurrentBackup = (select top (1) file_location from #LastBackup where database_name = @DBName order by backup_start_date desc)
	set @BackupStart = (select backup_start_date from #LastBackup where file_location = @LastDBRestore)
 
	delete
	from #LastBackup
	where backup_start_date <= @BackupStart
		and database_name = @DBName
 
	insert into @RestoresToComplete
	values (
		@DBName,
		(select COUNT(*) from #LastBackup where database_name = @DBName),
		(select SUM(compressed_backup_size / 1024 / 1024) from #LastBackup where database_name = @DBName),
		@CurrentBackup,
		@LastDBRestore,
		@BackupStart
		)
 
	delete
	from @LastRestore
	where DBName = @DBName
end
 
drop table #LastBackup
 
select
	secondary_server as 'SecondaryName',
	'SELECT secondary_database as ''DBName'', ''INSERT INTO @LastRestore VALUES('''''' + secondary_database + '''''','''''' + REVERSE(LEFT(REVERSE(last_restored_file), CHARINDEX(''\'', REVERSE(last_restored_file)) -1)) + '''''','''''' + CONVERT(VARCHAR(255), GETUTCDATE()) + '''''')'' AS ''LastRestored'' FROM msdb..log_shipping_secondary_databases' as 'GetData',
	CONVERT(varchar(10), DATEDIFF(MINUTE, @DataTime, GETUTCDATE())) + ' Minutes' as 'DataAge',
	(
		select COUNT(primary_database)
		from msdb..log_shipping_primary_databases
		) as 'LogShippedDBs'
from msdb..log_shipping_primary_secondaries
group by secondary_server
 
select
	DBName,
	Files,
	CAST(ROUND(BytesRemaining, 0, 3) as numeric(36, 3)) as 'MBRemaining',
	CAST(ROUND(BytesRemaining, 0, 3) as numeric(36, 3)) / 1024 as 'GBRemaining',
	CurrentBackup,
	CurrentRestore,
	'SELECT DISTINCT database_name AS ''DBName'', bs.backup_start_date AS ''BackupTime'', CAST(ROUND(compressed_backup_size, 0, 3) AS numeric(36,3))/1024/1024 AS ''BackupSizeMB'', REVERSE(LEFT(REVERSE(physical_device_name), CHARINDEX(''\'', REVERSE(physical_device_name)) -1)) AS ''BackupFile'', physical_device_name AS ''FullBackupPath'' FROM msdb..backupfile bf INNER JOIN msdb..backupset bs ON bf.backup_set_id = bs.backup_set_id INNER JOIN msdb..log_shipping_primary_databases ON database_name = primary_database INNER JOIN msdb..backupmediafamily bmf ON bmf.media_set_id = bs.media_set_id WHERE bf.File_Type = ''L'' AND bs.backup_start_date > ''' + CONVERT(varchar(255), BackupTime) + ''' AND database_name = ''' + DBName + ''' ORDER BY backup_start_date' as 'FilesToRestore'
from @RestoresToComplete
order by Files desc,
	BytesRemaining desc
go