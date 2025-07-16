-- If you're backing up to Azure Blob storage and you're getting error 3013, you need to
-- make these adjustments to Ola backup script to ensure it works correctly.
-- If you keep getting this error, keep lowering the MaxFileSize by 10000 until it works.
EXECUTE [dbo].[DatabaseBackup]
@Databases = 'USER_DATABASES',
@URL = 'https://staalduksuatdbk042.blob.core.windows.net/sqldaily', --example URL, replace with your own.
@BackupType = 'FULL',
@Verify = 'Y',
@CleanupTime = NULL,
@CheckSum = 'Y',
@LogToTable = 'Y',
@MaxFileSize = 200000,
@CopyOnly='Y',
@Compress='Y',
@BlockSize=65536,
@MaxTransferSize=4194304