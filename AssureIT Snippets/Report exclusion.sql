USE EIT_DBA
declare @exclusion_code nvarchar (255) = ''
declare @column_name nvarchar (255) = ''
declare @exclusion nvarchar (255) = ''
declare @comments nvarchar (255) = 'OM: '
insert into [EIT_DBA].[dbo].[EIT_monitoring_exclusions_report] (exclusion_code, column_name, exclusion, is_enabled, is_reported, active_weekdays, comments)
  values
  (@exclusion_code, @column_name, @exclusion, 'y', 'n', 127, @comments)
  SELECT *
  FROM [EIT_DBA].[dbo].[EIT_monitoring_exclusions_report]