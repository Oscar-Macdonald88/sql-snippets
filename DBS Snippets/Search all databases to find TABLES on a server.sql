--Search through ALL databases looking for a table.
	EXEC sp_MSforeachdb @command1='
		DECLARE @table VARCHAR(255)
		SET @table = ''%tbl_Data%''		--VARIABLE: Set table name here!
		IF (SELECT COUNT(*) FROM [?].INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME LIKE @table)>0
		BEGIN
			SELECT * FROM [?].INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME LIKE @table
		END
	';