
SELECT da.CounterDateTime, da.CounterValue
  FROM [EIT_DBA].[dbo].[CounterData] da
  join [EIT_DBA].[dbo].[CounterDetails] de
  on da.CounterID = de.CounterID
  where 
  de.ObjectName = 'Processor'
  and de.CounterName = '% Processor Time' 
  and de.InstanceName = '_Total'
  and da.CounterValue > 0
  --and da.CounterDateTime > getdate() - 7