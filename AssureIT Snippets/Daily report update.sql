USE [EIT_DBA]
  GO
  -- Non Critcal Reports come in on a Monday. Goal: reduce non-critical reports numbers weekly
  UPDATE [EIT_DBA].[report].[ReportConfiguration]
  SET ActiveDays = 2
  WHERE IsCritical = 0;
  -- Update Error logs to non-crtical - justification: we get errors throughout the day, this will be a summary of errors instead.
  -- error logs are still going to come through daily so please give feedback if these can reduce too.
  UPDATE [EIT_DBA].[report].[ReportConfiguration]
  SET IsCritical = 0 
  WHERE ReportName IN ('Errorlog findings','SQL Agent Errorlog findings');
  -- disable 'Duplicate indexes','Unused indexes' and 'SQL Server Agent jobs unscheduled'
  UPDATE [EIT_DBA].[report].[ReportConfiguration]
  SET IsEnabled = 0 
  WHERE ReportName IN ('Duplicate indexes','Unused indexes','SQL Server Agent jobs unscheduled');
  GO