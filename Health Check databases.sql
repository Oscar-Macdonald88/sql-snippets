select 
SERVERPROPERTY('servername') as Server_Name
, d.name as database_name
, suser_sname(d.owner_sid) as owner_name
, d.create_date
, d.compatibility_level
, case when d.compatibility_level = master.compatibility_level then 1 else 0 end as compatibility_level_matches_master
, d.user_access_desc
, d.is_read_only
, d.is_auto_close_on
, d.is_auto_shrink_on
, d.state_desc
, ROUND(SUM(CAST(mf.size AS bigint)) * 8 / 1024, 0) as Size_MBs
from sys.master_files mf
    join sys.databases d 
    on d.database_id = mf.database_id
	cross join sys.databases master
	where master.database_id = 1
	group by d.name, d.owner_sid, d.create_date, d.compatibility_level, master.compatibility_level, d.user_access_desc, d.is_read_only, d.is_auto_close_on, d.is_auto_shrink_on, d.state_desc
-- haven't worked out how to get the size of each file separately into their own columns, so best to just go with database size.