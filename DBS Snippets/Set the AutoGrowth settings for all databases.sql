--Automatically set AutoGrowth Settings to our recommended 10% / Unlimited
	;WITH GrowthRates AS (
		SELECT 
			DB_NAME(dbid) AS [Database],
			CASE WHEN (groupid=0) THEN 'Log' ELSE 'Data' END AS [Type],
			[size] / 128 AS [Size_MB],'' AS [-],
			CASE WHEN (maxsize = 268435456) THEN '2TB' WHEN (maxsize = -1) THEN 'Max' ELSE CONVERT(VARCHAR(20), maxsize/128)+'MB' END AS [maxsize],
			CASE 
				WHEN (CONVERT(INT,status & 0x100000) = 1048576) THEN CONVERT(VARCHAR(10), growth)+'%' 
				ELSE CONVERT(VARCHAR(10), growth / 128)+'MB' 
			END AS [GrowthRate],
			CASE 
				WHEN (CONVERT(INT,status & 0x100000) = 1048576 AND growth < 10) THEN '*'		--If the Autogrowth percent is less than 10%, it could be a problem.
				WHEN (CONVERT(INT,status & 0x100000) <> 1048576 AND growth < (50*128)) THEN '*'	--Autogrowth must be 50MB of larger, otherwise it's wrong (according to me)
				ELSE ''
			END AS [Warn],
			'ALTER DATABASE ['+DB_NAME(dbid)+'] MODIFY FILE ( NAME = N'''+name+''', FILEGROWTH = '
			+ CASE 
				WHEN ([size] / 128 / 1024 > 1000) THEN '1%' --If the Database File is larger than 1TB, use a 1% Auto-Growth
				WHEN ([size] / 128 / 1024 >  500) THEN '2%'
				WHEN ([size] / 128 / 1024 >  200) THEN '3%'
				WHEN ([size] / 128 / 1024 >  100) THEN '4%'
				WHEN ([size] / 128 / 1024 >   50) THEN '5%' --If the Database File is larger than 50GB, use a 5% Auto-Growth 
				ELSE '10%'
			END + ', MAXSIZE = UNLIMITED)' AS [T-SQL_SetGrowth] 
		FROM master.sys.sysaltfiles 
	) 
	SELECT * 
	FROM GrowthRates
	WHERE 
		[Database] LIKE '%%'
		--AND [Warn] <> ''
	ORDER BY [Database], [Type]