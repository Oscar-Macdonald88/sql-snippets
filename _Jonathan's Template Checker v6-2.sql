declare
	@READMODE varchar(20) = 'READONLY', -- READWRITE READONLY
	@Components varchar(20) = 'AdUpOfOnDeRe', -- AdUpOfOnDeRe
	@ForceOverWrite varchar(20) = 'MATCH', -- GLOBAL FORCE MATCH
	@ForceMatchDB varchar(50) = '%%', --DB Name Here
	@SingleDB varchar(50) = '%%', --DB Name Here
	@ExcludeDB varchar(50) = '', --DB Name Here
	@AutoApplyTemplate varchar(20) = 'MANUAL', -- MANUAL APPLY
/*
Jonathan's Mostly Automated tbl_Databases updater for V6.2 or greater
WARNING: Use of this script will provide a 'Best-Guess' based of other entries in TBL_Databases. !!!!!!!!!!!PLEASE REVIEW ALL ADDITIONS!!!!!!!!!!!
 
1)Run whole script in READONLY 2)Check Variables above 3)Run whole script in READWRITE 4)Apply Template and Weekly job 5)Backup Databases
exec SSLDBA..up_ApplyTemplate;
exec msdb..sp_start_job N'SSL_Weekly_Job', @step_name='Run SSL Health Check Script';
GO
 
GO
*/
	@MatchDB varchar(255),
	@DBToMatch varchar(255),
	@GlobalMatch varchar(255),
	@Name varchar(255);
 
declare @HDB table (dbname varchar(200), size varchar(20), owner varchar(50), dbid int, created datetime, status varchar(4000), compat int);
insert @HDB exec sp_helpdb;
 
select *, ('exec SSLDBA..up_BackupDatabase @DatabaseName = ''' + [name] + '''' + ', @BackupType = ''F''' + case when (recovery_model_desc = 'FULL') and not exists(select primary_database from msdb..log_shipping_primary_databases where primary_database = [name]) then 'exec SSLDBA..up_BackupDatabase @DatabaseName = ''' + [name] + '''' + ', @BackupType = ''T''' else '' end) as 'BackupScript'
into #SDB from sys.databases left join @HDB on [@HDB].dbname = [name]
 
select * into #TDB from SSLDBA..tbl_Databases where Type = 'OLTP' and DatabaseName like @SingleDB and DatabaseName not like @ExcludeDB
select * into #TBK from SSLDBA..tbl_DatabaseBackups
select * into #TBFC from SSLDBA..tbl_DatabaseBackupFileConfig
 
select top (1) #TDB.* into #SSLDBDump from #TDB inner join #SDB on #TDB.DatabaseName = #SDB.[name] where DatabaseName like @ForceMatchDB and state_desc not in ('OFFLINE', 'RESTORING') order by DatabaseName;
set @GlobalMatch = (SELECT DatabaseName COLLATE Latin1_General_CI_AI FROM #SSLDBDump)
 
select * into #TUD
from (
	select @READMODE + ': ' + @ForceOverWrite + ' ' + @SingleDB + ' ' + @ExcludeDB as 'Action', convert(varchar, (SERVERPROPERTY('Servername'))) as 'Name', '--' as 'Size', '--' as 'Recovery', 'Fallback: ' + @GlobalMatch as 'Match', '--' as 'Owner', '--' as 'T-SQL_Backup', '--' as 'Connectwise entry'
 
	union all
 
	select 'ADD', #SDB.[name], RTRIM(LTRIM(#SDB.size)), #SDB.recovery_model_desc, (case @ForceOverWrite when 'MATCH' then 'No Direct match found' else 'Direct matching disabled' end), #SDB.owner, (
			case (select top 1 TemplateBackup from #TBK where DatabaseName = @GlobalMatch) when 'N' then '--No Backup' else (#SDB.BackupScript) end
			), 'Database ' + CONVERT(varchar, #SDB.[name]) + ' Added to template,       Recovery: ' + ISNULL(CAST (#SDB.recovery_model_desc AS VARCHAR) COLLATE SQL_Latin1_General_CP1_CI_AS,'')
	from #SDB
	where #SDB.[name] not in (select DatabaseName from SSLDBA..tbl_Databases) and @Components like '%Ad%'
 
	union all
 
	select state_desc /*OFFLINE*/, #TDB.DatabaseName, '', #SDB.recovery_model_desc, '', '', '', 'Database ' + #SDB.[name] + ' is ' + #SDB.state_desc + '. Configured as Offline in template'
	from #SDB left join #TDB on (#SDB.[name] = #TDB.DatabaseName)
	where (state_desc = 'OFFLINE' or state_desc = 'RESTORING') and (exists(select * from #TBK where DatabaseName = #TDB.DatabaseName and DailyBackup = 'Y' and TemplateBackup = 'Y') or #TDB.WeeklyDBCC = 'Y' or #TDB.WeeklyDefrag = 'Y' or #TDB.ReportSpaceUsed = 'Y') and @Components like '%Of%'
 
	union all
 
	select state_desc /*ONLINE*/, DatabaseName, '', #SDB.recovery_model_desc, '', '', '', 'Database ' + DatabaseName + ' is ' + #SDB.state_desc + '. Configured as Online in template'
	from #SDB left join #TDB on #SDB.[name] = #TDB.DatabaseName
	where #TDB.status like '%OFFLINE%' and state_desc = 'ONLINE' and @Components like '%On%'
 
	union all
 
	select 'DELETE', DatabaseName, '', '', '', '', '', 'Database ' + DatabaseName + ' Removed from template'
	from #TDB
	where #TDB.DatabaseName not in (select [name] from #SDB) and @Components like '%De%'
 
	union all
 
	select 'RECONFIGURE', #TDB.DatabaseName, '', #SDB.recovery_model_desc, '', suser_sname(#SDB.owner_sid), #SDB.BackupScript, 'Database ' + #TDB.DatabaseName + ' reconfigured for use in ' + 
	case when #TDB.DatabaseName in (select primary_database from msdb..log_shipping_primary_databases) then 'LogShipping' else #SDB.recovery_model_desc end
	from #TDB inner join #SDB on #TDB.DatabaseName = #SDB.[name]
	where exists(select * from #TBK where DatabaseName = #TDB.DatabaseName and DailyBackup = 'Y' and TemplateBackup = 'Y' and BackupType = 'F')
		and ((#SDB.recovery_model_desc = 'SIMPLE' and exists(select * from #TBK where DatabaseName = #TDB.DatabaseName and BackupType = 'T' and DailyBackup = 'Y' and TemplateBackup = 'Y'))
		or (#SDB.recovery_model_desc != 'SIMPLE' and #SDB.is_read_only = 0 
		and (exists(select * from #TBK where DatabaseName = #TDB.DatabaseName and BackupType = 'T' and DailyBackup = 'N' and TemplateBackup = 'N') and not exists(select primary_database from msdb..log_shipping_primary_databases where primary_database = #TDB.DatabaseName)) or (exists(select * from #TBK where DatabaseName = #TDB.DatabaseName and BackupType = 'T' and DailyBackup = 'Y' and TemplateBackup = 'Y') and (exists(select primary_database from msdb..log_shipping_primary_databases where primary_database = #TDB.DatabaseName)))) and #SDB.state_desc = 'ONLINE' and @Components like '%Re%')
) i
 
--------------------------- Matching System ---------------------------
if (@ForceOverWrite = 'MATCH' and @ForceMatchDB = '%%')
begin
	select * into #MatchDBs from #TUD where #TUD.[Action] in ('ADD', 'ONLINE', 'RECONFIGURE')
 
	while exists (select * from #MatchDBs)
	begin
		set @DBToMatch = (select top (1) [Name] from #MatchDBs)
		set @SingleDB = @DBToMatch
 
		while ((LEN(@SingleDB) > 3) and @MatchDB is null)
		begin
			set @MatchDB = (select top (1) DatabaseName from #TDB where Type = 'OLTP' and DatabaseName like @SingleDB + '%' and DatabaseName != @DBToMatch)
			if (@MatchDB is not null)
			begin
				update #TUD set #TUD.[Match] = @MatchDB where #TUD.[Name] = @DBToMatch
				insert into #SSLDBDump select top (1) * from #TDB where DatabaseName = @MatchDB
				update top (1) #SSLDBDump set DatabaseName = @DBToMatch where DatabaseName = @MatchDB
				break
			end
			set @SingleDB = LEFT(@SingleDB, LEN(@SingleDB) - 1)
		end
 
		if (@MatchDB is null)
		begin
			delete from #SSLDBDump where DatabaseName = @GlobalMatch
			insert into #SSLDBDump select top (1) * from #TDB where DatabaseName = @GlobalMatch
			update #SSLDBDump set DatabaseName = @DBToMatch where DatabaseName = @GlobalMatch
		end
		set @MatchDB = null
		delete top (1)
		from #MatchDBs
	end
 
	drop table #MatchDBs;
end
 
select * from #TUD
 
--------------------------- Read/Write Systems ---------------------------
if (@READMODE = 'READWRITE' and (select COUNT(*)from #TUD) > 1)
begin
	delete from SSLDBA..tbl_Databases where DatabaseName in (select [Name] from #TUD where Action in ('DELETE', 'ONLINE', 'RECONFIGURE'))
 
	update #TUD set Action = 'ADD' where Action in ('ONLINE', 'RECONFIGURE')
 
	while exists (select * from #TUD where Action = 'ADD')
	begin
		set @Name = (select top (1) #SDB.[name] from #SDB inner join #TUD on #TUD.Name = #SDB.[name] where #SDB.[name] not in (select DatabaseName from SSLDBA..tbl_Databases) and Action != 'OFFLINECHECK')
 
		if (select COUNT(*) from #TDB) = 0
		begin
			insert into SSLDBA..tbl_Databases (DatabaseName) values (@Name)
		end
		else if (select COUNT(*) from #SSLDBDump where DatabaseName = @Name) = 1
		begin
			update #SSLDBDump set status = #SDB.status from #SDB where #SDB.[name] = @Name;
			insert into SSLDBA..tbl_Databases select * from #SSLDBDump where DatabaseName = @Name
		end
		else if (select COUNT(*) from #SSLDBDump) = 1
		begin
			update #SSLDBDump set DatabaseName = @Name
			insert into SSLDBA..tbl_Databases select * from #SSLDBDump
		end
 
		update top (1) #TUD set Action = 'OFFLINECHECK' where Action = 'ADD'
	end
 
	update SSLDBA..tbl_Databases set WeeklyDBCC = 'N', WeeklyDefrag = 'N', ReportSpaceUsed = 'N'
	where (select is_read_only from #SDB where [name] = DatabaseName) = 1 
	or DatabaseName in (select [Name] from #TUD where Action in ('OFFLINE', 'RESTORING') or (Action = 'OFFLINECHECK' and Name in (select [Name] from #SDB where state_desc in ('OFFLINE', 'RESTORING'))))
	update SSLDBA..tbl_DatabaseBackups set DailyBackup = 'N', TemplateBackup = 'N'
	where (select is_read_only from #SDB where [name] = DatabaseName) = 1 
	or DatabaseName in (select [Name] from #TUD where Action in ('OFFLINE', 'RESTORING') or (Action = 'OFFLINECHECK' and Name in (select [Name] from #SDB where state_desc in ('OFFLINE', 'RESTORING'))))
 
	if (@AutoApplyTemplate = 'APPLY') begin set @AutoApplyTemplate = 'RUNAPPLY' end
end
 
--------------------------- Final Select ---------------------------
select #SDB.[name] as 'Name', size as 'Size', state_desc as 'State', recovery_model_desc as 'Recovery', (select DailyBackup + ':' + TemplateBackup from #TBK where DatabaseName = #SDB.[name] and BackupType = 'F') as 'Full BKP D:T', (select DailyBackup + ':' + TemplateBackup from #TBK where DatabaseName = #SDB.[name] and BackupType = 'T') as 'Log BKP  D:T', 'UPDATE SSLDBA..tbl_DatabaseBackups SET DailyBackup = ''' + (select DailyBackup from #TBK where DatabaseName = #SDB.[name] and BackupType = 'F') + ''', TemplateBackup = ''' + (select TemplateBackup from #TBK where DatabaseName = #SDB.[name] and BackupType = 'F') + ''' WHERE DatabaseName = ''' + #SDB.[name] + ''' and BackupType = ''F''; UPDATE SSLDBA..tbl_DatabaseBackups SET DailyBackup = ''' + (select DailyBackup from #TBK where DatabaseName = #SDB.[name] and BackupType = 'T') + ''', TemplateBackup = ''' + (select TemplateBackup from #TBK where DatabaseName = #SDB.[name] and BackupType = 'T') + ''' WHERE DatabaseName = ''' + #SDB.[name] + ''' and BackupType = ''T'';' as 'Backup Status', (case (select TemplateBackup from #TBK where DatabaseName = #SDB.[name] and BackupType = 'F') when 'N' then 'No Backup' else (#SDB.BackupScript) end
	) as 'T-SQL_Backup', '---------------------->' as 'TBLDatabases', tbl_Databases.*
from #SDB
inner join SSLDBA..tbl_Databases on #SDB.[name] = DatabaseName
order by #SDB.recovery_model_desc asc, #SDB.[name] asc;
 
--commit
 
if @AutoApplyTemplate = 'RUNAPPLY' begin
	if (select TextValue from SSLDBA..tbl_Param where Param = 'TemplateOverrideRequired') = 'N'
	begin
		exec SSLDBA..up_ApplyTemplate;
 
		exec msdb..sp_start_job N'SSL_Weekly_Job', @step_name = 'Run SSL Health Check Script';
	end
	else
	begin
		select 'Cannot Auto Apply template' as 'TemplateOverrideRequired'
	end
end
 
 
drop table #TDB, #SDB, #SSLDBDump, #TBK, #TBFC, #TUD