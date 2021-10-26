use SSLDBA
go

declare
	@DropFolderDir varchar(255) = '' -- Insert path to drop folder directory here eg C:\SQLReports\DropFolder

update tbl_Param set
	TextValue = @DropFolderDir
where
	Param = 'DropFolderDir'

exec SSLDBA..up_ApplyTemplate

exec msdb..sp_start_job N'SSL_SendDashboardData', @step_name = 'Send alert if PowerShell is disabled or unavailable';
go

-- After re-enabling Kaseya you will need to keep an eye on the DropFolderDir and ensure files are being loaded successfully.