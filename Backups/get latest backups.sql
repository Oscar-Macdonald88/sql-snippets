-- get latest full, diff and log backup
with backup_cte as
(
    select
        database_name,
        backup_type =
            case type
                when 'D' then 'full'
                when 'L' then 'log'
                when 'I' then 'differential'
                else 'other'
            end,
        backup_start_date,    
        backup_finish_date,
        datediff(minute, backup_start_date, backup_finish_date) as backup_time_minutes,
        rownum = 
            row_number() over
            (
                partition by database_name, type 
                order by backup_finish_date desc
            )
    from msdb.dbo.backupset
)
select
    database_name,
    backup_type,
    backup_start_date,    
    backup_finish_date,
    backup_time_minutes
from backup_cte
where rownum = 1
order by database_name;