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

SELECT
MN.locked_page_allocations_kb
FROM sys.dm_os_memory_nodes MN
INNER JOIN sys.dm_os_nodes N 
ON MN.memory_node_id = N.memory_node_id
WHERE N.node_state_desc <> 'ONLINE DAC'

SELECT sql_memory_model_desc FROM sys.dm_os_sys_info;
```

If lock pages in memory is enabled, the value will be greater than 0.

To enable Lock Pages in Memory
You have to add the sql server service account to the Lock pages in memory policy.
You can check how to do it [here](https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/enable-the-lock-pages-in-memory-option-windows?view=sql-server-2017).

The following values of sql_memory_model_desc indicate the status of LPIM:

- CONVENTIONAL. Lock pages in memory privilege isn't granted.
- LOCK_PAGES. Lock pages in memory privilege is granted.
- LARGE_PAGES. Lock pages in memory privilege is granted in Enterprise mode with Trace Flag 834 enabled. This is an advanced configuration and not recommended for most environments. For more information and important caveats, see Trace Flag 834.


For Health check report:

```sql
if (SELECT
MN.locked_page_allocations_kb
FROM sys.dm_os_memory_nodes MN
INNER JOIN sys.dm_os_nodes N 
ON MN.memory_node_id = N.memory_node_id
WHERE N.node_state_desc <> 'ONLINE DAC')= 0
BEGIN
    select serverproperty('servername'), '', 50, 'Server Info', 'Lock Pages in Memory Not Enabled', NULL, 'Consider enabling LPIM to keep data in memory for longer'
end
go
```