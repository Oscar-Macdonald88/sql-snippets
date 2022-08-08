-- Run on CERBERUS to get an output SQLCMD script to put in a mass brownout
--Review the output before running!
declare @customercode varchar(10) = 'TWL'
declare @comments varchar (max) = 'OM: Microsoft Monthly Patching - May 2022'
drop table if exists #temp_servers
create table #temp_servers  (name nvarchar(255), start_dttm datetime)
insert into #temp_servers values 
('servername1', 'dttm1'),
('servername2', 'dttm2') --etc
-- Adds wildcards to the end to get all instances associated with the server
-- WARNING: This can include other servers that have similar names but aren't included in the patching! Review the output before running!
update #temp_servers set name = name + '%'
select ':CONNECT ' + i.InstanceName + ' ' + CHAR(13)+ '
DECLARE @secondary nvarchar(255) ' + CHAR(13)+ '
DECLARE @cmd nvarchar(max) ' + CHAR(13)+ '
SET @secondary = (select top 1 value from [EIT_DBA].[dbo].[EIT_monitoring_config] where configuration = ''dr_partner'') ' + CHAR(13)+ '
EXECUTE EIT_DBA.dbo.BrownOutSet ''' + convert(varchar(25), dateadd(minute, -45, t.start_dttm), 120) + ''', ''' + convert(varchar(25), dateadd(hour, 2, t.start_dttm), 120) + ''', '''+ @comments +''' ' + CHAR(13)+ '
if @secondary <> '''' set @cmd = ''EXECUTE '' + @secondary + ''.EIT_DBA.dbo.BrownOutSet ''''' + convert(varchar(25), dateadd(minute, -45, t.start_dttm), 120) + ''''', ''''' + convert(varchar(25), dateadd(hour, 2, t.start_dttm), 120) + ''''', ''''' + @comments + ''''''' ' + CHAR(13)+ '
EXECUTE sp_executesql @cmd ' + CHAR(13)+ '
GO'
from SQLMSP.msp.vInventory i
join #temp_servers t on
 i.InstanceName like t.name
 where i.CustomerCode = @customercode
 and i.IsActive = 1
 drop table #temp_servers
