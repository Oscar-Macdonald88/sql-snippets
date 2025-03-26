USE [distribution]
GO
select * from dbo.MSReplication_monitordata
where status >= 5 
or warning <> 0
or cur_latency >= 30