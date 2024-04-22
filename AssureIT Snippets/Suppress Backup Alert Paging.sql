USE EIT_DBA
GO

WITH ErrorsToExclude(ErrorNumber, Severity) AS (
	SELECT 3041,	16	UNION ALL	/* BACKUP failed to complete the command %.*ls. Check the backup application log for detailed messages.*/
	SELECT 18210,	16	UNION ALL	/* %s: %s failure on backup device '%s'. Operating system error %s. */
	SELECT 18204,	16	UNION ALL	/* %s: Backup device '%s' failed to %s. Operating system error %s. */
	SELECT 3201,	16				/* Cannot open backup device '%ls'. Operating system error %ls. */
)
INSERT INTO dbo.EIT_monitoring_config_alert
SELECT
	'Custom_' + CONVERT(VARCHAR(10), Severity) + '_' + CONVERT(VARCHAR(10), ErrorNumber)
	,Severity
	,ErrorNumber
	,'y'
	,'y'
	,'y'
	,0
	,0
	,'n'
	,3
	,'Custom Sev ' + CONVERT(VARCHAR(10), Severity) + ' alert page override to not page for backup failures from error number ' + CONVERT(VARCHAR(10), ErrorNumber) + '.'
FROM
	ErrorsToExclude
WHERE
	NOT EXISTS(SELECT * FROM dbo.EIT_monitoring_config_alert WHERE [severity_number] = Severity AND [error_number] = ErrorNumber);