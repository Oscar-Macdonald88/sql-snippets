drop table if exists #temp_events
SELECT event_data = CONVERT(XML, event_data) 
  INTO #temp_events
    FROM
        sys.fn_xe_file_target_read_file(
            'G:\SQLMaintenance\LoginAudit*.xel',
            null, null, null)  AS f;

SELECT 
  ts    = event_data.value(N'(event/@timestamp)[1]', N'datetime'),
  [db_name] = db_name(event_data.value(N'(event/data[@name="database_id"]/value)[1]', N'int')),
  user_name  = event_data.value(N'(event/action[@name="session_nt_username"]/value)[1]', N'nvarchar(max)')
FROM #temp_events
WHERE
  event_data.value(N'(event/data[@name="session_nt_username"]/value)[1]', N'nvarchar(max)') = N'ASM_LOGIN'