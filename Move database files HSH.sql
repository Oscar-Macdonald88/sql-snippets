/*
Fill the variables and run the script (safe: select only)
The first select shows physical files for database.
The second select is the generated script for locations change. Copy it out and review.
Works with multiple files (e.g. .mdf, .ndfs, and multiple .ldfs) as long as are all going into the same respective directory.
*/
DECLARE 
    @dbName nvarchar(255) = 'TestPermissions',
    @NewDirDAT nvarchar(255) = 'C:\test\Data',    -- include backslash at end
    @NewDirLOG nvarchar(255) = 'C:\test\Logs'        -- include backslash at end

DECLARE @OldDirDAT nvarchar(255) = (select physical_name from sys.master_files where database_id = db_id(@dbName) and type_desc = 'ROWS')
DECLARE @OldDirLOG nvarchar(255) = (select physical_name from sys.master_files where database_id = db_id(@dbName) and type_desc = 'LOG')

    -- Execute script
DECLARE @ChangeDir_Files TABLE(
        Logical_Name sysname, 
        Physical_Name nvarchar(MAX)
)
    
DECLARE @ChangeDir_Script TABLE(
    Script_Lines_copy_me_to_new_window varchar(MAX)
)
INSERT INTO @ChangeDir_Files 
    SELECT name, RIGHT(physical_name, CHARINDEX('\', REVERSE(physical_name)) -1)
    FROM sys.master_files
    WHERE database_id = DB_ID(@dbName)
INSERT INTO @ChangeDir_Script VALUES
('-- manually check script before using')
WHILE(1=1)
BEGIN
DECLARE @current_logical_name varchar(MAX) =(SELECT TOP 1 Logical_Name FROM @ChangeDir_Files)
DECLARE @current_physical_name varchar(MAX) = (SELECT TOP 1 Physical_Name FROM @ChangeDir_Files)
IF @current_physical_name is NULL
    BREAK;
    IF    @current_physical_name LIKE '%.[mn]df'
    BEGIN
        INSERT INTO @ChangeDir_Script VALUES 
            (''),
            ('ALTER DATABASE '+@dbName),
            ('MODIFY FILE (NAME = '+@current_logical_name+ ', FILENAME = '''+@NewDirDAT+@current_physical_name+''')'),
            ('GO')
    END ELSE
    BEGIN
        INSERT INTO @ChangeDir_Script VALUES 
            (''),
            ('ALTER DATABASE '+@dbName),
            ('MODIFY FILE (NAME = '+@current_logical_name+ ', FILENAME = '''+@NewDirLOG+@current_physical_name+''')'),
            ('GO')
    END
    
    DELETE TOP(1) FROM @ChangeDir_Files
    IF @@rowcount = 0
        BREAK;
END
IF EXISTS (SELECT name FROM master.dbo.sysdatabases WHERE name = @dbName)
BEGIN
    INSERT INTO @ChangeDir_Script VALUES
    (''),
    ('-- RUN ON OLD SERVER'),
    ('ALTER DATABASE '+@dbName+' SET OFFLINE WITH ROLLBACK IMMEDIATE'),
    (''),
	('exec xp_cmdshell ''move ' +@OldDirDAT+ ' ' + @NewDirDAT + ''''),
	(''),
	('exec xp_cmdshell ''move ' +@OldDirLOG+ ' ' + @NewDirLOG + ''''),
    (''),
    ('-- RUN ON NEW SERVER'),
    ('-- ALTER DATABASE '+@dbName+' SET ONLINE '),
    (''),
    ('USE [master]'),
    ('GO'),
    ('CREATE DATABASE ['+@dbName+'] ON'),
    ('(FILENAME = N''' + @NewDirDAT+@current_physical_name+''')'),
    ('(FILENAME = N''' + @NewDirLOG+@current_physical_name+''')'),
    ('FOR ATTACH'),
    ('GO')
END
ELSE
BEGIN
    INSERT INTO @ChangeDir_Script VALUES
    ('-- database '+@dbName+' not found')
    
END
SELECT name, physical_name
FROM sys.master_files
WHERE database_id = DB_ID(@dbName);
select * from @ChangeDir_Script