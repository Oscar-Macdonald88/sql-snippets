SELECT 
      [DatabaseName]
      ,[CommandType]
      ,[Command]
      ,[StartTime]
      ,[EndTime]
      ,DATEDIFF(minute, StartTime, EndTime) as [Duration (minutes)]
      ,[ErrorNumber]
      ,[ErrorMessage]
  FROM [DBAToolset].[dbo].[CommandLog]
  where 1=1
  -- and CommandType = 
  -- 'BACKUP_LOG'
  -- 'BACKUP_DATABASE'
  order by StartTime desc