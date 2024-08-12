-- Work in progress

-- Get the largest index in the database, then determines if there is enough space (at least 120% the size of the index) in the filegroup data files, log files, and disks.

-- Missing functionality: doesn't account for file growth across multiple data or log files.

declare @sqlcmd nvarchar(max)='
with cte as
(
SELECT TOP 1
    i.name as index_name,
    OBJECT_SCHEMA_NAME(i.object_id) as SchemaName,
    OBJECT_NAME(i.object_id) as TableName,
	ps.page_count / 128 as index_size_MB,
	sum(fileproperty(df.name,''SpaceUsed''))/128 AS [FilegroupUsedSpaceMB],
	(sum(df.size)-sum(fileproperty(df.name,''SpaceUsed'')))/128 AS [FilegroupUnusedSpaceMB],
	CASE WHEN df.max_size = -1 and df.growth <> 0 THEN sum(fdd.free_mb) -- Maximum size for unlimited growth is limited to free disk space
		WHEN df.max_size = 0 THEN df.size / 128 -- No growth is allowed
        ELSE df.max_size / 128 -- Convert max_size from pages to MB
    END as filegroup_max_size,
	sum(fileproperty(lf.name,''SpaceUsed''))/128 AS [LogUsedSpaceMB],
	(sum(lf.size)-sum(fileproperty(lf.name,''SpaceUsed'')))/128 AS [LogUnusedSpaceMB],
	CASE WHEN lf.max_size = -1 and lf.growth <> 0 THEN sum(fld.free_mb) -- Maximum size for unlimited growth is limited to free disk space
		WHEN lf.max_size = 0 THEN lf.size / 128 -- No growth is allowed
        ELSE lf.max_size / 128 -- Convert max_size from pages to MB
    END as log_file_max_size,
	sum(fdd.free_mb) as total_filegroup_drives_free_space,
	sum(fld.free_mb) as total_log_drives_free_space
FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) AS ps
    inner join sys.indexes i
	on i.object_id = ps.object_id
	join sys.database_files df
	on i.data_space_id = df.data_space_id
	cross join sys.database_files lf
	join [EIT_DBA].[dbo].[vEIT_DiskSpace] fdd
	on left(df.physical_name,1) = left(fdd.drive,1)
	join [EIT_DBA].[dbo].[vEIT_DiskSpace] fld
	on left(lf.physical_name,1) = left(fld.drive,1)
WHERE
    ps.index_id > 0
	and lf.type_desc = ''LOG''
group by i.name, i.object_id, ps.page_count, i.data_space_id, df.size, df.max_size, df.growth, lf.size, lf.max_size, lf.growth, fdd.free_mb, fld.free_mb
ORDER BY
    ps.page_count desc
)
select * from cte 
where index_size_MB * 1.2 > FilegroupUnusedSpaceMB + filegroup_max_size
OR index_size_MB * 1.2 > LogUnusedSpaceMB + log_file_max_size'
EXEC [EIT_DBA].[dbo].[dba_ForEachDB] @statement = @sqlcmd, @name_pattern = '[USER]'