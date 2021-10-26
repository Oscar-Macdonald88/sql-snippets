--John Pan's Stats Health query
SELECT DISTINCT
        tablename = object_name(i.object_id),
        o.type_desc,
        index_name = i.[name],
        statistics_update_date = STATS_DATE(i.object_id, i.index_id),
        si.rowmodctr
FROM    sys.indexes i ( nolock )
        JOIN sys.objects o ( nolock ) on i.object_id = o.object_id
        JOIN sys.sysindexes si ( nolock ) on i.object_id = si.id
                                             and i.index_id = si.indid
where   o.type != 'S'  --ignore system objects
        and STATS_DATE(i.object_id, i.index_id) is not null
order by si.rowmodctr desc