-- MUST BE RUN IN **SQLCMD** MODE

:Connect 10.121.47.92

USE [master]

-- remove database from AG

ALTER AVAILABILITY GROUP [2017-TESTING-AG-V2] REMOVE DATABASE [Test_AlwaysOn_Restore];  
GO

-- restore database on Primary

RESTORE DATABASE [Test_AlwaysOn_Restore] FROM  DISK = N'\\LAB-2K16SQL1\SQLDataDumps\Test_AlwaysOn_Restore.bak' WITH  FILE = 1, recovery,  NOUNLOAD,  REPLACE,  STATS = 10

GO

-- Ensure database is in full recovery

ALTER DATABASE [Test_AlwaysOn_Restore] SET RECOVERY FULL WITH NO_WAIT 
GO 

-- take log backup to shared location

BACKUP LOG [Test_AlwaysOn_Restore] TO  DISK = N'\\LAB-2K16SQL1\SQLDataDumps\test_log.trn' WITH NOFORMAT, INIT,  NAME = N'Test_AlwaysOn_Restore-log backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO

-- add the database to AlwaysOn on the primary

ALTER AVAILABILITY GROUP [2017-TESTING-AG-V2] ADD DATABASE [Test_AlwaysOn_Restore];  
GO 

:Connect 10.121.47.93

-- Wait for the replica to start communicating
begin try
declare @conn bit
declare @count int
declare @replica_id uniqueidentifier 
declare @group_id uniqueidentifier
set @conn = 0
set @count = 30 -- wait for 5 minutes 

if (serverproperty('IsHadrEnabled') = 1)
	and (isnull((select member_state from master.sys.dm_hadr_cluster_members where upper(member_name COLLATE Latin1_General_CI_AS) = upper(cast(serverproperty('ComputerNamePhysicalNetBIOS') as nvarchar(256)) COLLATE Latin1_General_CI_AS)), 0) <> 0)
	and (isnull((select state from master.sys.database_mirroring_endpoints), 1) = 0)
begin
    select @group_id = ags.group_id from master.sys.availability_groups as ags where name = N'2017-TESTING-AG-V2'
	select @replica_id = replicas.replica_id from master.sys.availability_replicas as replicas where upper(replicas.replica_server_name COLLATE Latin1_General_CI_AS) = upper(@@SERVERNAME COLLATE Latin1_General_CI_AS) and group_id = @group_id
	while @conn <> 1 and @count > 0
	begin
		set @conn = isnull((select connected_state from master.sys.dm_hadr_availability_replica_states as states where states.replica_id = @replica_id), 1)
		if @conn = 1
		begin
			-- exit loop when the replica is connected, or if the query cannot find the replica status
			break
		end
		waitfor delay '00:00:10'
		set @count = @count - 1
	end
end
end try
begin catch
	-- If the wait loop fails, do not stop execution of the alter database statement
end catch

-- restore database on secondary
RESTORE DATABASE [Test_AlwaysOn_Restore] FROM  DISK = N'\\LAB-2K16SQL1\SQLDataDumps\Test_AlwaysOn_Restore.bak' WITH  FILE = 1, norecovery,  NOUNLOAD,  REPLACE,  STATS = 10

GO

RESTORE LOG [Test_AlwaysOn_Restore] FROM  DISK = N'\\LAB-2K16SQL1\SQLDataDumps\test_log.trn' with norecovery, stats = 10
GO

ALTER DATABASE [Test_AlwaysOn_Restore] SET HADR AVAILABILITY GROUP = [2017-TESTING-AG-V2];

GO
