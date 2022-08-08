if exists(select 1 from sys.databases where name = 'dbautils' and page_verify_option_desc <> 'CHECKSUM')
begin
insert into [EIT_DBA].[dbo].[EIT_monitoring_exclusions_report] ([exclusion_code]
      ,[column_name]
      ,[exclusion]
      ,[is_enabled]
      ,[is_reported]
      ,[active_weekdays]
      ,[comments])

values (
'page_verify',	'Database_Name',	'''dbautils''',	'y',	'n',	127,	'OM: dbautils is a DBA db and not a user db, page verification is less of concern, any DBA data thats needed is preserved in EIT_DBA')
delete from [EIT_DBA].[dbo].[EIT_monitoring_exclusions_report] where exclusion_code = 'page_verify' and exclusion = '''dbautils''' and comments = 'DL:remediation exclustion'
end