--13.1: Ensure appropriate number of TempDB files.
	DECLARE
		@cpu_count INT, 
		@file_count INT,
		@counter INT
 
	SELECT @cpu_count = cpu_count FROM sys.dm_os_sys_info
	SELECT @file_count = COUNT(*) FROM tempdb.sys.database_files WHERE [type] = 0
 
	SELECT '13.1:' AS [Step], 'Ensure appropriate number of TempDB files.' AS [Instruction], '' AS [-],  @cpu_count AS [CPUs], @file_count AS [TempDB_Files]	
	IF (@cpu_count > @file_count) BEGIN
		DECLARE @NewFiles TABLE (number VARCHAR(10))
		SET @counter = @file_count
		WHILE (@counter < @cpu_count) BEGIN
			INSERT INTO @NewFiles (number) VALUES (CONVERT(VARCHAR(10), @counter+1))
			SET @counter = @counter+1;
		END
 
		;WITH PrimaryDataFile AS (
			SELECT 
				LEFT(physical_name, LEN(physical_name) - CHARINDEX('\',REVERSE(physical_name), 1) + 1) AS [path],
				REPLACE(REVERSE(LEFT(REVERSE(physical_name), CHARINDEX('\', REVERSE(physical_name), 1) - 1)), '.mdf', '') [filename],
				CASE 
					WHEN (is_percent_growth = 0) THEN CONVERT(VARCHAR(50), (([growth] / 128) * 1024)) + 'KB'
					WHEN (is_percent_growth = 1) THEN CONVERT(VARCHAR(50), [growth]) + '%'
				END AS [filegrowth],
				CONVERT(VARCHAR(50), ((size / 128) * 1024)) AS [size],
				[name],
				[number]
			FROM @NewFiles nf
			CROSS JOIN tempdb.sys.database_files df
			WHERE [type] = 0 AND [file_id] <= 2 AND LOWER(physical_name) LIKE '%.mdf'
		)
		SELECT
			'13.1:' AS [Step], 'ALTER DATABASE [tempdb] ADD FILE (NAME = N''' + [name] + '_' + [number] + ''', FILENAME = N''' + [path] + [filename] + '_' + [number] + '.ndf'', SIZE = ' + [size] + 'KB, FILEGROWTH = ' + [filegrowth] + ')' AS [T-SQL_AddTempDBFiles]
		FROM PrimaryDataFile
	END ELSE IF (@cpu_count = @file_count) BEGIN
		SELECT '13.1:' AS [Step], 'Appropriate number of TempDB files exist.' AS [Status]
	END ELSE IF (@cpu_count < @file_count) BEGIN
		SELECT '13.1:' AS [Step], '* There are more TempDB files than CPUs - please review.' AS [Status]
	END
	RETURN