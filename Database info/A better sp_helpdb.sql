-- A Better sp_helpdb
DECLARE @sp_helpdb TABLE(name VARCHAR(MAX), db_size nvarchar(13), owner VARCHAR(MAX), dbid smallint, created nvarchar(11), status nvarchar(600), compatibility_level tinyint)
	INSERT INTO @sp_helpdb EXEC sp_helpdb
 	SELECT 
		*
	FROM @sp_helpdb
	WHERE 1=1 /* UNCOMMENT AND USE ANY OF THE BELOW FILTERS */
		--AND [name] LIKE '%%'
		--AND owner LIKE '%%'
		--AND dbid = 