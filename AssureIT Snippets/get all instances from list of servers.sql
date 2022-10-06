create table #TheirInventory (servername varchar(255), starttime datetime, endtime datetime)
insert into #TheirInventory values
('AKSDSQL1601N1',CAST('2022/09/20 00:00' as datetime), CAST('2022/09/20 06:00' as datetime)),
('AKSRSQL1701N1',CAST('2022/09/20 00:00' as datetime), CAST('2022/09/20 06:00' as datetime)),
('AKSTSQL08',CAST('2022/09/20 00:00' as datetime), CAST('2022/09/20 06:00' as datetime)),
('AKSTSQL1602',CAST('2022/09/20 00:00' as datetime), CAST('2022/09/20 06:00' as datetime)),
('AKSTSQL1701N2',CAST('2022/09/20 00:00' as datetime), CAST('2022/09/20 06:00' as datetime)),
('AKSTSQL1901N4',CAST('2022/09/20 00:00' as datetime), CAST('2022/09/20 06:00' as datetime)),
('AKSTSQL20',CAST('2022/09/20 00:00' as datetime), CAST('2022/09/20 06:00' as datetime)),
('AKSTSQL26',CAST('2022/09/20 00:00' as datetime), CAST('2022/09/20 06:00' as datetime)),
('HMSTSQL1601',CAST('2022/09/20 00:00' as datetime), CAST('2022/09/20 06:00' as datetime)),
('QTSTSQL1901',CAST('2022/09/20 00:00' as datetime), CAST('2022/09/20 06:00' as datetime)),
('AKSDSQLSN01',CAST('2022/09/21 00:00' as datetime), CAST('2022/09/21 06:00' as datetime)),
('AKSRSQL1701N2',CAST('2022/09/21 00:00' as datetime), CAST('2022/09/21 06:00' as datetime)),
('AKSTSQL09',CAST('2022/09/21 00:00' as datetime), CAST('2022/09/21 06:00' as datetime)),
('AKSTSQL1603',CAST('2022/09/21 00:00' as datetime), CAST('2022/09/21 06:00' as datetime)),
('AKSTSQL1901N1',CAST('2022/09/21 00:00' as datetime), CAST('2022/09/21 06:00' as datetime)),
('AKSTSQL1902N1',CAST('2022/09/21 00:00' as datetime), CAST('2022/09/21 06:00' as datetime)),
('AKSTSQL22',CAST('2022/09/21 00:00' as datetime), CAST('2022/09/21 06:00' as datetime)),
('AKSTSQL30N1',CAST('2022/09/21 00:00' as datetime), CAST('2022/09/21 06:00' as datetime)),
('AKSTSRS1901',CAST('2022/09/21 00:00' as datetime), CAST('2022/09/21 06:00' as datetime)),
('HMSTSQL1901',CAST('2022/09/21 00:00' as datetime), CAST('2022/09/21 06:00' as datetime)),
('AKSRSQL1601N1',CAST('2022/09/22 00:00' as datetime), CAST('2022/09/22 06:00' as datetime)),
('AKSTSQL10',CAST('2022/09/22 00:00' as datetime), CAST('2022/09/22 06:00' as datetime)),
('AKSTSQL1603_Sandpit',CAST('2022/09/22 00:00' as datetime), CAST('2022/09/22 06:00' as datetime)),
('AKSTSQL1901N2',CAST('2022/09/22 00:00' as datetime), CAST('2022/09/22 06:00' as datetime)),
('AKSTSQL1902N2',CAST('2022/09/22 00:00' as datetime), CAST('2022/09/22 06:00' as datetime)),
('AKSTSQL24',CAST('2022/09/22 00:00' as datetime), CAST('2022/09/22 06:00' as datetime)),
('AKSTSQL30N2',CAST('2022/09/22 00:00' as datetime), CAST('2022/09/22 06:00' as datetime)),
('AKSRSQL1601N2',CAST('2022/09/23 00:00' as datetime), CAST('2022/09/23 06:00' as datetime)),
('AKSTSQL1601',CAST('2022/09/23 00:00' as datetime), CAST('2022/09/23 06:00' as datetime)),
('AKSTSQL1701N1',CAST('2022/09/23 00:00' as datetime), CAST('2022/09/23 06:00' as datetime)),
('AKSTSQL1901N3',CAST('2022/09/23 00:00' as datetime), CAST('2022/09/23 06:00' as datetime)),
('AKSTSQL1903',CAST('2022/09/23 00:00' as datetime), CAST('2022/09/23 06:00' as datetime)),
('AKSTSQL25',CAST('2022/09/23 00:00' as datetime), CAST('2022/09/23 06:00' as datetime)),
('AKSTSQL32',CAST('2022/09/23 00:00' as datetime), CAST('2022/09/23 06:00' as datetime)),
('QTSTSQL1601',CAST('2022/09/23 00:00' as datetime), CAST('2022/09/23 06:00' as datetime));
with MyInventory (ServerName, InstanceName) as
(
select distinct
case
    when CHARINDEX('\', InstanceName) > 0 -- Check if there's a backslash in the instance name
    then rtrim(left(InstanceName, CHARINDEX('\', InstanceName) - 1)) -- gets all characters before the backslash
    else InstanceName -- If there's no backslash, just return the server name
end as ServerName,
InstanceName
from SQLMSP.msp.vinventory where customercode='SCEG' and isactive = 1
)
select M.ServerName, M.InstanceName, T.starttime, T.endtime from MyInventory M
join #TheirInventory T on M.ServerName = T.servername
order by T.starttime, M.ServerName, M.InstanceName

drop table #TheirInventory