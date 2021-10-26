-- Performance Script: Repeatedly capture SPID details over a period of time
	declare 
		@DelaySec	int = 1,	--Set: The delay between "snapshots"
		@Loops		int = 15,	--Set: The number of loops capturing "snapshots"
		@KeepData	bit = 1,	--Set: Do you want to keep the data between runs (F5) of this script?
		@StoreQuery	int = 1,	--Set: Do you want to capture the full query? [1 = Yes (first only), 2 = Yes (all) or 0 = No]
		@IgnoreSys	bit = 1,	--Set: Ignore system SPIDs below 50
		@StartTime	datetime = getdate(),
		@WaitUntil	datetime;
 
	if (@KeepData = 0 and object_id('tempdb..#SysProcessesLog') is not null)
	begin
		drop table #SysProcessesLog;
	end
 
	if (object_id('tempdb..#SysProcessesLog') is null)
	begin
		create table #SysProcessesLog (
			SPID			smallint,
			KPID			int,
			DatabaseName	nvarchar(255),
			Host			nvarchar(128),
			[Login]			nvarchar(128),
			Program			nvarchar(128),
			Command			nvarchar(16),
			Blocked			smallint,
			[CPU]			bigint,
			[Disk]			bigint,
			[Mem]			bigint,
			login_time		datetime,
			last_batch		datetime,
			[Statement]		nvarchar(4000),
			SnapshotNumber	int,
			SnapshotTime	datetime
		);
	end
 
 	while (isnull((select max(SnapshotNumber) from #SysProcessesLog), 0) - isnull((select max(SnapshotNumber) from #SysProcessesLog where SnapshotTime < @StartTime), 0)) < @Loops
	begin
 
 		if (datediff(ms, isnull((select max(SnapshotTime) from #SysProcessesLog), getdate()), getdate()) < 1000)
		begin
			set @WaitUntil = dateadd(second, @DelaySec, getdate())
			waitfor time @WaitUntil;
		end
 
		insert into #SysProcessesLog
		select 
			spid as [SPID], 
			kpid as [KPID],
			db_name(dbid) as [DatabaseName],
			hostname as [Host],
			loginame as [Login],
			[program_name] as [Program],
			cmd as [Command],
			blocked as [Blocked],
			cpu as [CPU],
			physical_io as [Disk],
			memusage as [Mem],
			login_time,
			last_batch,
			case 
				when (@StoreQuery = 1 and not exists (select top 1 1 from #SysProcessesLog spl where spl.SPID = sp.spid and spl.KPID = sp.kpid and spl.login_time = sp.login_time)) then substring((select [text] from fn_get_sql(sql_handle)), 1, 4000) 
				when (@StoreQuery = 2) then substring((select [text] from fn_get_sql(sql_handle)), 1, 4000) 
				else null 
			end as [Statement],
			isnull((select max(SnapshotNumber)+1 from #SysProcessesLog), 1) as [SnapshotNumber],
			getdate() as [SnapshotTime]
		from sys.sysprocesses sp
		where (@IgnoreSys = 0 or spid >= 50);
	end
 
 
	--Output results, you can run / edit this section multiple times. The data is stored in #SysProcessesLog :).
	;with PerformanceSummary as (
		select 
			SPID,
			kpid as [KPID],
			max(DatabaseName) as [DatabaseName],
			max(Host) as [Host],
			max([Login]) as [Login],
			'' as [- change -],
			max(CPU) - min(CPU) as [ChangeCPU],
			max([Disk]) - min([Disk]) as [ChangeDisk],
			max([Mem]) - min([Mem]) as [ChangeMem],
			'' as [- avg -],
			avg(CPU) as [AvgCPU],
			avg([Disk]) as [AvgDisk],
			avg([Mem]) as [AvgMem],
			max(Blocked) [Blocked],
			max(Program) as [Program],
			max(Command) as [Command],
			login_time,
			max(last_batch) as [last_batch],
			max([Statement]) as [Statement],
			max([SnapshotTime]) as [last_snapshot],
			count([SnapshotNumber]) as [TotalSnapshots]
		from #SysProcessesLog
		group by 
			SPID,
			KPID,
			[login_time]
	), ParallelismPS as (
		select 
			SPID,
			max(DatabaseName) as [DatabaseName],
			max(Host) as [Host],
			max([Login]) as [Login],
			'' as [- Change ->],
			sum([ChangeCPU]) as [ChangeCPU],
			sum([ChangeDisk]) as [ChangeDisk],
			sum([ChangeMem]) as [ChangeMem],
			'' as [- Lifetime ->],
			sum([AvgCPU]) as [LifeCPU],
			sum([AvgDisk]) as [LifeDisk],
			sum([AvgMem]) as [LifeMem],
			'' as [- Detail ->],
			count(distinct case when (Blocked <> 0) then blocked else null end) [Blocked],
			case when (max(Program) like '%Job 0x%') then 'Agent Job: "' + (select top 1 name FROM msdb.dbo.sysjobs where max(Program) like '%'+master.dbo.fn_varbintohexstr(job_id)+'%') + '"' else max(Program) end as [Program],
			max(Command) as [Command],
			login_time,
			max(last_batch) as [last_batch],
			max([last_snapshot]) as [last_snapshot],
			max([Statement]) as [Statement],
			max([TotalSnapshots]) as [TotalSnapshots],
			count(distinct KPID) as [DistinctKPIDs],
			case when (count(distinct KPID) > 1) then 'Possibly' else 'No' end as [Parallelism]
		from PerformanceSummary
		where SPID <> @@SPID
		group by 
			SPID, 
			[login_time]
	)
	select * 
	from ParallelismPS
	where 1=1
		and DatabaseName	like '%%'
		and Host			like '%%'
		and [Login]			like '%%'
		and Program			like '%%'
	order by 
		isnull(nullif([ChangeCPU], 0), 1)+isnull(nullif([ChangeDisk], 0), 1)+isnull(nullif([ChangeMem], 0), 1) desc,
		isnull(nullif([LifeCPU], 0), 1)+isnull(nullif([LifeDisk], 0), 1)+isnull(nullif([LifeMem], 0), 1) desc;
 
	/* -- Inspect a single SPID
		select 
			*,
			'' as [- change -],
			[CPU] - LAG([CPU], 1, [CPU]) OVER (ORDER BY SnapshotNumber) AS [ChangeCPU],
			[Disk] - LAG([Disk], 1, [Disk]) OVER (ORDER BY SnapshotNumber) AS [ChangeDisk],
			[Mem] - LAG([Mem], 1, [Mem]) OVER (ORDER BY SnapshotNumber) AS [ChangeMem]
		from #SysProcessesLog 
		where SPID = 206	--Set: Update the SPID you're interested in
 
	*/