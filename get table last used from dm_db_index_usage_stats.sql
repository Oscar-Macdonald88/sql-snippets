
SELECT
    DB_NAME()                                  AS database_name,
    s.name                                     AS schema_name,
    t.name                                     AS table_name,
    CASE 
        WHEN i.index_id = 0 THEN '(HEAP)'
        ELSE i.name
    END                                        AS index_name,
    ius.last_user_seek,
    ius.last_user_scan,
    ius.last_user_lookup,
    ius.last_user_update
FROM sys.tables AS t
JOIN sys.schemas AS s
  ON s.schema_id = t.schema_id
-- Every user table has at least one row in sys.indexes:
--   - HEAP (index_id = 0) if no clustered index
--   - clustered/nonclustered/columnstore/etc. otherwise
JOIN sys.indexes AS i
  ON i.object_id = t.object_id
-- LEFT JOIN to the DMV so missing usage rows come back as NULL
LEFT JOIN sys.dm_db_index_usage_stats AS ius
  ON ius.database_id = DB_ID()
 AND ius.object_id   = i.object_id
 AND ius.index_id    = i.index_id
ORDER BY
    s.name, t.name, i.index_id;
