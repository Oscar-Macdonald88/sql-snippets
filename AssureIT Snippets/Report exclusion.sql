USE EIT_DBA
declare @exclusion_code nvarchar (255)
set @exclusion_code = ''
declare @column_name nvarchar (255) 
set @column_name = ''
declare @exclusion nvarchar (255)
set @exclusion = ''
set @exclusion = ''''+ @exclusion + ''''
declare @end_date datetime
set @end_date = DATEADD(month, 3, getdate())
declare @comments nvarchar (255) 
set @comments = 'OM: '
insert into [EIT_DBA].[dbo].[EIT_monitoring_exclusions_report] (exclusion_code, column_name, exclusion, is_enabled, is_reported, active_weekdays
--, end_date
,comments)
  values
  (@exclusion_code, @column_name, @exclusion, 'y', 'n', 127
  --,@end_date
  ,@comments)
  SELECT *
  FROM [EIT_DBA].[dbo].[EIT_monitoring_exclusions_report]

  --insert into EIT_DBA..EIT_monitoring_exclusions_report (exclusion_code, column_name, exclusion, is_enabled, is_reported, active_weekdays, comments)
--values ('privileged_users', 'Login_Name', '''SCEG\AKL IT DBA''', 'y', 'n', 127, 'OM: SCEG\AKL IT DBA is required for all DBA access')