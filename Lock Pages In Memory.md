To check if Lock Pages in Memory is enabled
Run the following query:

```sql
/*Lock pages in memory*/
SELECT
MN.locked_page_allocations_kb
FROM sys.dm_os_memory_nodes MN
INNER JOIN sys.dm_os_nodes N 
ON MN.memory_node_id = N.memory_node_id
WHERE N.node_state_desc <> 'ONLINE DAC'
```

If lock pages in memory is enabled, the value will be greater than 0.

To enable Lock Pages in Memory
You have to add the sql server service account to the Lock pages in memory policy.
You can check how to do it [here](https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/enable-the-lock-pages-in-memory-option-windows?view=sql-server-2017).