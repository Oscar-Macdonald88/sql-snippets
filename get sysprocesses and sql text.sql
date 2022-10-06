select p.spid,
    db_name(p.dbid) as db_name,
    suser_sname(p.sid) as username,
    p.nt_username,
    p.loginame,
    p.hostname,
    p.program_name,
    p.cmd,
    t.text as sql_text,
    p.status,
    p.blocked,
    p.waittime,
    p.lastwaittype,
    p.waitresource,
    p.cpu,
    p.physical_io,
    p.memusage,
    p.login_time,
    p.last_batch,
    p.open_tran
from sys.sysprocesses p
    cross apply sys.dm_exec_sql_text(p.sql_handle) as t
	where 1=1
	--and p.spid = 
	--and db_name(p.dbid) = ''
	--and suser_sname(p.sid) = ''
	--and p.hostname = ''
	--and p.program_name = ''
	--and p.cmd = ''
	--and t.text = ''
	--and p.status = ''
	--and p.blocked = 
	--and p,lastwaittype = ''
	--and cpu > 
	--and physical_io >
	--and login_time > GETDATE() - 1
	--and last_batch > GETDATE() - 1

