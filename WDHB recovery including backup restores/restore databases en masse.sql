/*******************************************************************************
Disclaimer: This script has the following requirements:
Only files from the backups being restored should be in the specified directory
The restored databases will have the same name as the backed up databases

This script reads the headers and labels of each backup in the specified
directory. It selects the latest full backup for each database, then the latest
differential backup for each database if present, then all subsequent 
log backups. Multi-file backups are supported. The output is a new script which 
can be used to restore all databases found from the backups
*************************************************************************/
/************************************************************************
PARAMETERS
*************************************************************************/
-- Specify the directory where the log backups are
-- This must have a backslash at the end!
DECLARE @directory NVARCHAR(128) = 'C:\test\'

/************************************************************************
SCRIPT - DO NOT EDIT BELOW THIS LINE UNLESS YOU'VE GOT BIG BRAIN TIME
*************************************************************************/
-- set initial parameters
-- if any result returns null (which shouldn't happen in the best case scenario)
-- setting this parameter will esnure the entire nvarchar isn't nulled
SET CONCAT_NULL_YIELDS_NULL OFF
SET NOCOUNT ON

-- wipe out any remnants of the previous run
DROP PROCEDURE IF EXISTS #get_latest_LSNs
DROP PROCEDURE IF EXISTS #populate_backups_to_restore
DROP TABLE IF EXISTS #temp_databases
DROP TABLE IF EXISTS #temp_backup_files
DROP TABLE IF EXISTS #temp_header
DROP TABLE IF EXISTS #temp_label
DROP TABLE IF EXISTS #potential_backups
DROP TABLE IF EXISTS #temp_LSNs
DROP TABLE IF EXISTS #backups_to_restore

	-- used to get the result of the 'dir' command
CREATE TABLE #temp_backup_files (
	ID INT IDENTITY(1, 1) NOT NULL --used for iterating
	,filename VARCHAR(400)
	)

DECLARE @cmd VARCHAR(200) = 'dir /b ' + @directory

INSERT INTO #temp_backup_files
EXEC xp_cmdshell @cmd

DELETE
FROM #temp_backup_files
WHERE filename IS NULL

-- store the results of RESTORE HEADERONLY. Holds one value at a time.
CREATE TABLE #temp_header (
	BackupName NVARCHAR(128)
	,BackupDescription NVARCHAR(255)
	,BackupType SMALLINT
	,ExpirationDate DATETIME
	,Compressed BIT
	,Position SMALLINT
	,DeviceType TINYINT
	,UserName NVARCHAR(128)
	,ServerName NVARCHAR(128)
	,DatabaseName NVARCHAR(128)
	,DatabaseVersion INT
	,DatabaseCreationDate DATETIME
	,BackupSize NUMERIC(20, 0)
	,FirstLSN NUMERIC(25, 0)
	,LastLSN NUMERIC(25, 0)
	,CheckpointLSN NUMERIC(25, 0)
	,DatabaseBackupLSN NUMERIC(25, 0)
	,BackupStartDate DATETIME
	,BackupFinishDate DATETIME
	,SortOrder SMALLINT
	,CodePage SMALLINT
	,UnicodeLocaleId INT
	,UnicodeComparisonStyle INT
	,CompatibilityLevel TINYINT
	,SoftwareVendorId INT
	,SoftwareVersionMajor INT
	,SoftwareVersionMinor INT
	,SoftwareVersionBuild INT
	,MachineName NVARCHAR(128)
	,Flags INT
	,BindingID UNIQUEIDENTIFIER
	,RecoveryForkID UNIQUEIDENTIFIER
	,Collation NVARCHAR(128)
	,FamilyGUID UNIQUEIDENTIFIER
	,HasBulkLoggedData BIT
	,IsSnapshot BIT
	,IsReadOnly BIT
	,IsSingleUser BIT
	,HasBackupChecksums BIT
	,IsDamaged BIT
	,BeginsLogChain BIT
	,HasIncompleteMetaData BIT
	,IsForceOffline BIT
	,IsCopyOnly BIT
	,FirstRecoveryForkID UNIQUEIDENTIFIER
	,ForkPointLSN NUMERIC(25, 0) NULL
	,RecoveryModel NVARCHAR(60)
	,DifferentialBaseLSN NUMERIC(25, 0) NULL
	,DifferentialBaseGUID UNIQUEIDENTIFIER
	,BackupTypeDescription NVARCHAR(60)
	,BackupSetGUID UNIQUEIDENTIFIER NULL
	,CompressedBackupSize BIGINT
	,containment TINYINT NOT NULL
	)

-- RESTORE HEADERONLY has additional entries in the result set after 
-- SQL 2014 CU1.  If the server is running a version equal to or greater than 
-- this, the additional entries need to be added.
DECLARE @Major INT = cast(SERVERPROPERTY('ProductMajorVersion') AS INT)
DECLARE @Build INT = cast(SERVERPROPERTY('ProductBuild') AS INT)
DECLARE @HeaderFlag BIT = 0

BEGIN TRY
	IF @Major > 12
	BEGIN
		SET @HeaderFlag = 1
	END
	ELSE
	BEGIN
		IF @Major = 12
			AND @Build >= 4416
		BEGIN
			SET @HeaderFlag = 1
		END
	END

	IF @HeaderFlag = 1
	BEGIN
		ALTER TABLE #temp_header ADD 
			KeyAlgorithm NVARCHAR(32)
			,EncryptorThumbprint VARBINARY(20)
			,EncryptorType NVARCHAR(32)
	END
END TRY

BEGIN CATCH
	PRINT ('Error updating columns in #temp_header');
	THROW;
END CATCH

-- store the results of RESTORE LABELONLY. Holds one value at a time.
CREATE TABLE #temp_label (
	MediaName NVARCHAR(128)
	,MediaSetId UNIQUEIDENTIFIER
	,FamilyCount INT
	,FamilySequenceNumber INT
	,MediaFamilyId UNIQUEIDENTIFIER
	,MediaSequenceNumber INT
	,MediaLabelPresent TINYINT
	,MediaDescription NVARCHAR(255)
	,SoftwareName NVARCHAR(128)
	,SoftwareVendorId INT
	,MediaDate DATETIME
	,Mirror_Count INT
	,IsCompressed BIT
	)

-- This table stores the details of all backups, but not all of them will be 
-- necessarily used, so backups are considered 'potential' in this table.
CREATE TABLE #potential_backups (
	ID INT IDENTITY(1, 1) NOT NULL --used for iterating
	,DatabaseName NVARCHAR(128)
	,pathandfilename VARCHAR(255)
	,BackupType SMALLINT
	,FirstLSN NUMERIC(25, 0)
	,LastLSN NUMERIC(25, 0)
	,DatabaseBackupLSN NUMERIC(25, 0)
	,FamilyCount INT
	,FamilySequenceNumber INT
	)

DECLARE @filename VARCHAR(255)
DECLARE @sql_cmd NVARCHAR(max)
DECLARE @backup_files_row_count INT = (
		SELECT count(1)
		FROM #temp_backup_files
		) + 1
DECLARE @backup_files_iterator INT = 1

-- Populate #potential_backups 
WHILE @backup_files_iterator < @backup_files_row_count
BEGIN
	SELECT TOP 1 @filename = filename
	FROM #temp_backup_files
	WHERE ID = @backup_files_iterator

	SET @sql_cmd = 'RESTORE HEADERONLY FROM DISK = ''' + @directory + @filename + ''''

	BEGIN TRY
		INSERT INTO #temp_header
		EXEC sp_executesql @sql_cmd
	END TRY

	BEGIN CATCH
		PRINT ('Error reading header from file ' + @directory + @filename);
		THROW;
	END CATCH

	SET @sql_cmd = 'RESTORE LABELONLY FROM DISK = ''' + @directory + @filename + ''''

	BEGIN TRY
		INSERT INTO #temp_label
		EXEC sp_executesql @sql_cmd
	END TRY

	BEGIN CATCH
		PRINT ('Error reading label from file ' + @directory + @filename);
		THROW;
	END CATCH

	INSERT INTO #potential_backups
	SELECT TOP 1 DatabaseName
		,@directory + @filename
		,BackupType
		,FirstLSN
		,LastLSN
		,DatabaseBackupLSN
		,FamilyCount
		,FamilySequenceNumber
	FROM #temp_header
	INNER JOIN #temp_label ON 1 = 1

	TRUNCATE TABLE #temp_header

	TRUNCATE TABLE #temp_label

	SET @backup_files_iterator = @backup_files_iterator + 1
END
GO

-- This is the final result table. At the end it will contain 1 full backup, 
-- 0 or 1 differential backups, and 0 or more log backups. All backups will
-- include each file from the family, and all backups will be part of the 
-- same log sequence
CREATE TABLE #backups_to_restore (
	ID INT IDENTITY(1, 1) NOT NULL --used to keep track of order
	,DatabaseName NVARCHAR(128)
	,BackupType SMALLINT
	,FirstLSN NUMERIC(25, 0)
	,LastLSN NUMERIC(25, 0)
	,DatabaseBackupLSN NUMERIC(25, 0)
	,sqlcmd NVARCHAR(255)
	)
GO

-- Receives details about a certain backup and puts the backup into 
-- #backups_to_restore
CREATE PROCEDURE #populate_backups_to_restore @BackupType INT
	,@DatabaseName NVARCHAR(128)
	,@FirstLSN NUMERIC(25, 0)
	,@LastLSN NUMERIC(25, 0)
	,@DatabaseBackupLSN NUMERIC(25, 0) = 00000000000000000
AS
DECLARE @family_iterator INT = 1
DECLARE @family_count INT
DECLARE @sql_cmd NVARCHAR(255) = 'RESTORE ' + CASE @BackupType
		WHEN 2
			THEN 'LOG ['
		ELSE 'DATABASE [' -- used for full and differential restores
		END + @DatabaseName + '] FROM '

-- find the number of members in the family.
SELECT TOP 1 @family_count = FamilyCount
FROM #potential_backups
WHERE DatabaseName = @DatabaseName
	AND BackupType = @BackupType
	AND FirstLSN = @FirstLSN
	AND LastLSN = @LastLSN
	AND FamilySequenceNumber = 1

-- add each member of the family to the restore command
WHILE @family_iterator <= @family_count
BEGIN
	SET @sql_cmd = @sql_cmd + 'DISK = ''' + (
			SELECT TOP 1 pathandfilename
			FROM #potential_backups
			WHERE DatabaseName = @DatabaseName
				AND BackupType = @BackupType
				AND FirstLSN = @FirstLSN
				AND LastLSN = @LastLSN
				AND FamilySequenceNumber = @family_iterator
			) + ''''
	SET @family_iterator = @family_iterator + 1

	IF @family_iterator <= @family_count
		-- there are more members of the family (DISKs) to add to the restore 
		-- in a comma separated format
		SET @sql_cmd = @sql_cmd + ', ' 
	ELSE
		-- this is the last member of the family, end with the final 'WITH' 
		-- arguments
		SET @sql_cmd = @sql_cmd + ' WITH REPLACE, NORECOVERY' 
END

-- once the complete restore command has been created, we can add it to 
--#backups_to_restore
INSERT INTO #backups_to_restore
VALUES (
	@DatabaseName
	,@BackupType
	,@FirstLSN
	,@LastLSN
	,@DatabaseBackupLSN
	,@sql_cmd
	)

RETURN
GO

-- this keeps track of each database that has backups
CREATE TABLE #temp_databases (
	ID INT IDENTITY(1, 1) NOT NULL --used for iterating
	,DatabaseName NVARCHAR(128)
	)

INSERT INTO #temp_databases
SELECT DISTINCT DatabaseName
FROM #potential_backups
ORDER BY DatabaseName

DECLARE @databases_iterator INT = 1
DECLARE @database_count INT = (
		SELECT count(1)
		FROM #temp_databases
		) + 1
DECLARE @DatabaseName NVARCHAR(128)
DECLARE @FirstLSN NUMERIC(25, 0)
DECLARE @LastLSN NUMERIC(25, 0)
-- used to keep track of the FirstLSN that belongs to the full backup
DECLARE @DatabaseBackupLSN NUMERIC(25, 0) 

WHILE @databases_iterator < @database_count
BEGIN
	-- get the name of the next database
	SELECT TOP 1 @DatabaseName = DatabaseName
	FROM #temp_databases
	WHERE ID = @databases_iterator

	-- Restore full
	SELECT TOP 1 @FirstLSN = FirstLSN
		,@LastLSN = LastLSN
	FROM #potential_backups
	WHERE DatabaseName = @DatabaseName
		AND BackupType = 1
	ORDER BY FirstLSN DESC

	-- the DatabaseBackupLSN isn't required for the full backup so it's omitted
	-- from this execution
	EXEC #populate_backups_to_restore 1
		,@DatabaseName
		,@FirstLSN
		,@LastLSN 

	SET @DatabaseBackupLSN = (
			SELECT TOP 1 FirstLSN
			FROM #backups_to_restore
			WHERE DatabaseName = @DatabaseName
				AND BackupType = 1
			)

	-- Restore differential
	-- Check if a valid differential backup exists. The FirstLSN for the diff 
	-- must be equal to or greater than that of the full backup
	IF EXISTS (
			SELECT TOP 1 BackupType
			FROM #potential_backups
			WHERE DatabaseName = @DatabaseName
				AND BackupType = 5
				AND DatabaseBackupLSN = @DatabaseBackupLSN
				AND FirstLSN >= @FirstLSN
			)
	BEGIN
		SELECT TOP 1 @FirstLSN = FirstLSN
			,@LastLSN = LastLSN
		FROM #potential_backups
		WHERE DatabaseName = @DatabaseName
			AND BackupType = 5
			AND DatabaseBackupLSN = @DatabaseBackupLSN
		ORDER BY FirstLSN DESC

		EXEC #populate_backups_to_restore 5
			,@DatabaseName
			,@FirstLSN
			,@LastLSN
			,@DatabaseBackupLSN
	END

	-- Restore logs
	-- Check if a valid differential backup exists. The FirstLSN for the diff must 
	-- be equal to or greater than that of the full backup or differential backup
	-- If a differential was found then @LastLSN will have changed to the LastLSN 
	-- of the differential
	IF EXISTS (
			SELECT TOP 1 BackupType
			FROM #potential_backups
			WHERE DatabaseName = @DatabaseName
				AND BackupType = 2
				AND LastLSN >= @LastLSN
				AND DatabaseBackupLSN = @DatabaseBackupLSN
			)
	BEGIN
		SELECT TOP 1 @FirstLSN = FirstLSN
			,@LastLSN = LastLSN
		FROM #potential_backups
		WHERE DatabaseName = @DatabaseName
			AND BackupType = 2
			AND LastLSN >= @LastLSN
			AND DatabaseBackupLSN = @DatabaseBackupLSN
		ORDER BY FirstLSN

		EXEC #populate_backups_to_restore 2
			,@DatabaseName
			,@FirstLSN
			,@LastLSN
			,@DatabaseBackupLSN

		-- Get all subsequent log backups if they exist.
		-- Find the LastLSN of the latest log backup and use it as the 
		DECLARE @LatestLSN NUMERIC(25, 0) = (
				SELECT TOP 1 LastLSN
				FROM #potential_backups
				WHERE DatabaseName = @DatabaseName
					AND BackupType = 2
					AND DatabaseBackupLSN = @DatabaseBackupLSN
				ORDER BY LastLSN DESC
				)

		WHILE @LastLSN <> @LatestLSN
		BEGIN
			SET @FirstLSN = @LastLSN
			SET @LastLSN = (
					SELECT TOP 1 LastLSN
					FROM #potential_backups
					WHERE DatabaseName = @DatabaseName
						AND BackupType = 2
						AND FirstLSN = @FirstLSN
					)

			EXEC #populate_backups_to_restore 2
				,@DatabaseName
				,@FirstLSN
				,@LastLSN
				,@DatabaseBackupLSN
		END
	END

	SET @databases_iterator = @databases_iterator + 1
END

-- Show the results

SELECT DatabaseName
	,BackupType
	,FirstLSN
	,LastLSN
	,sqlcmd
FROM #backups_to_restore
ORDER BY ID

-- Final restore command

SELECT 'RESTORE DATABASE ' + DatabaseName + ' WITH RECOVERY' AS Recover_sqlcmd
FROM #temp_databases

-- cleanup

DROP PROCEDURE IF EXISTS #get_latest_LSNs
DROP PROCEDURE IF EXISTS #populate_backups_to_restore
DROP TABLE IF EXISTS #temp_databases
DROP TABLE IF EXISTS #temp_backup_files
DROP TABLE IF EXISTS #temp_header
DROP TABLE IF EXISTS #temp_label
DROP TABLE IF EXISTS #potential_backups
DROP TABLE IF EXISTS #temp_LSNs
DROP TABLE IF EXISTS #backups_to_restore
