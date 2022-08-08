declare @start datetime = getdate()
declare @end datetime = datediff(hour, 1, @start)
declare @comment varchar(255) = 'OM: SCTASK0097894 refreshing WFCTRN'
exec EIT_DBA..BrownOutSet @start, @end, @comment

-- update EIT_DBA.alert.BrownOut set EndsAt = getdate() where comment = @comment