declare @disk nvarchar(5) = 'C:' -- set this to the disk you want
declare @start_dttm datetime = getdate() - 1 -- set this to the start datetime you want
declare @end_dttm  datetime = getdate() -- set this to the end datetime you want
declare @CounterType nvarchar(255) = 'Avg. Disk sec/Read' -- set to either 'Avg. Disk sec/Read' or 'Avg. Disk sec/Write' 

  select 
  cde.InstanceName
  ,cde.CounterName
  ,cda.CounterDateTime
  ,cda.CounterValue
    FROM [EIT_DBA].[dbo].[CounterData] cda
  join [EIT_DBA].[dbo].[CounterDetails] cde
  on cde.CounterID = cda.CounterID
  where cde.InstanceName = @disk
  and cde.CounterName = @CounterType
  and [CounterDateTime] > @start_dttm
  and [CounterDateTime] < @end_dttm

    select @CounterType as [Counter Name], avg(cda.CounterValue) as [Average]
      FROM [EIT_DBA].[dbo].[CounterData] cda
  join [EIT_DBA].[dbo].[CounterDetails] cde
  on cde.CounterID = cda.CounterID
  where cde.InstanceName = @disk
  and cde.CounterName = @CounterType
  and [CounterDateTime] > @start_dttm
  and [CounterDateTime] < @end_dttm