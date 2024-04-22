declare @start datetime ;
set @start = getdate();
declare @end datetime ;
set @end = dateadd(hour, 3, @start);
declare @comment varchar(255);
set @comment = 'OM:'
exec EIT_DBA..BrownOutSet @start, @end, @comment

select * from EIT_DBA.alert.BrownOut where comments = @comment

-- update EIT_DBA.alert.BrownOut set EndsAt = getdate() where comments = @comment