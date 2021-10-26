--Search all databases for a Login
	DECLARE @database VARCHAR(255), @login VARCHAR(255), @params nvarchar(500), @count INT, @CMD NVARCHAR(2000)
	SELECT 
		@login = '%LOGIN_NAME%',
		@database = '', -- Leave this blank
		@params = '@result INT OUTPUT'
	WHILE (1=1) BEGIN
		SELECT TOP 1 @database = name FROM sys.databases WHERE name > @database AND state = 0 ORDER BY name
		IF (@@rowcount = 0)
			BREAK
		SET @CMD = 'SELECT @result = COUNT(*) FROM ['+@database+'].sys.database_principals WHERE (type=''S'' or type = ''U'') AND LOWER(name) LIKE '''+LOWER(@login)+'''';
		EXECUTE sp_executesql @CMD, @params, @result=@count OUTPUT;
		PRINT CONVERT(VARCHAR(10), @count)+' = '+@database
		IF (@count > 0) BEGIN
			SET @CMD = 'SELECT '''+@database+''' AS [Database], * FROM ['+@database+'].sys.database_principals WHERE (type=''S'' or type = ''U'') AND LOWER(name) LIKE '''+LOWER(@login)+'''';
			EXECUTE sp_executesql @CMD
		END
	END