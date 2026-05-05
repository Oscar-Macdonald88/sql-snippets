-- Reads the sys.event_log, which usually shows successfull\failed connection attempts
-- Converts from UTC to NZST. CHECK FOR DAYLIGHT SAVINGS DIFFERENCE!
select top 1000 database_name, DATEADD(hour, 13, start_time) as start_time_nzst, DATEADD(hour, 13, end_time) as end_time_nzst, event_category, event_type, event_subtype_desc, severity, event_count, description, additional_data 
from sys.event_log 
--where DATEADD(hour, 13, start_time) > ''
--where event_type <> 'connection_successful'
order by start_time desc