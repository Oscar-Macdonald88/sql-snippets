USE EIT_DBA
declare @exclusion_code nvarchar (255) = 'database_not_online'
declare @column_name nvarchar (255) = 'Database_Name'
declare @exclusion nvarchar (255) = '%'
set @exclusion = ''''+ @exclusion + ''''
declare @comments nvarchar (255) = 'OM: Server will be decommed soon, not of concern'
insert into [EIT_DBA].[dbo].[EIT_monitoring_exclusions_report] (exclusion_code, column_name, exclusion, is_enabled, is_reported, active_weekdays, comments)
  values
  (@exclusion_code, @column_name, @exclusion, 'y', 'n', 127, @comments)
  SELECT *
  FROM [EIT_DBA].[dbo].[EIT_monitoring_exclusions_report]

  --insert into EIT_DBA..EIT_monitoring_exclusions_report (exclusion_code, column_name, exclusion, is_enabled, is_reported, active_weekdays, comments)
--values ('privileged_users', 'Login_Name', '''SCEG\AKL IT DBA''', 'y', 'n', 127, 'OM: SCEG\AKL IT DBA is required for all DBA access')