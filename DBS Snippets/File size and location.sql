DECLARE @database sysname, @CMD NVARCHAR(4000)
	DECLARE @shrinkable TABLE (databaseName NVARCHAR(250), logicalName NVARCHAR(250), physicalName NVARCHAR(500), FileSizeMB DECIMAL(38,2), UsedSpaceMB DECIMAL(38,2), UnusedSpaceMB DECIMAL(38,2), Shrink_TSQL NVARCHAR(2000))
	SET @database = ''
	WHILE (1=1) BEGIN
		SELECT TOP 1 @database = name FROM sys.databases WHERE name > @database AND state = 0 ORDER BY name
		IF (@@rowcount = 0)
			BREAK
		ELSE BEGIN
			SET @CMD = '
				USE ['+@database+'];
				WITH FileSpaceReport AS (
					SELECT DB_NAME() AS [Database], name, filename,
						size/128 AS [FileSizeMB],
						fileproperty(name,''SpaceUsed'')/128 AS [UsedSpaceMB],
						(size-fileproperty(name,''SpaceUsed''))/128 AS [UnusedSpaceMB]
					FROM sysfiles
				)
				SELECT *, 
					''PRINT ''''USE ['+@database+']''''+CHAR(13)+CHAR(10)+''''GO''''+CHAR(13)+CHAR(10)+''''DBCC SHRINKFILE (N''''''''''+name+'''''''''' , ''+CONVERT(VARCHAR(32),CONVERT(INT, FileSizeMB-(UnusedSpaceMB/4)))+'')''''+CHAR(9)+''''--ACTUAL: ''+CONVERT(VARCHAR(32),UsedSpaceMB)+''MB used of ''+CONVERT(VARCHAR(32),FileSizeMB)+''MB''''+CHAR(13)+CHAR(10)+''''GO''''+CHAR(13)+CHAR(10)+CHAR(13)+CHAR(10)'' AS [Shrink_T-SQL]
				FROM FileSpaceReport
			'
			BEGIN TRY
				INSERT INTO @shrinkable EXECUTE sp_executesql @CMD;
			END TRY
			BEGIN CATCH
				INSERT INTO @shrinkable 
				SELECT @database, '', '', 0, 0, 0, '--Unable to open database';
			END CATCH
		END
	END
	SELECT databaseName, logicalName, physicalName, s.log_reuse_wait_desc, '' AS [---], FileSizeMB, UsedSpaceMB, UnusedSpaceMB AS [*UnusedSpaceMB*], CONVERT(VARCHAR(20),CONVERT(DECIMAL(38,2),((UnusedSpaceMB+1)/(FileSizeMB+1))*100))+'% free' AS [Ratio], '' AS [---], Shrink_TSQL
	FROM @shrinkable
	join sys.databases s on s.name = databasename -- COLLATE Latin1_General_CI_AS -- if needed
	WHERE physicalName LIKE '%:%.[lmn]df' --Remove the "l", "m" or "n" for different file types. Replace the first % with the drive letter of concern.
		--AND UnusedSpaceMB > 0	--Set the unused space threshold
		AND databaseName LIKE '%%'	--Set the Database Name here
	ORDER BY UnusedSpaceMB DESC	--Remove this line for order by databaseName
	RETURN