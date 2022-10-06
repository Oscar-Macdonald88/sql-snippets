-- sometimes when syspolicy_purge_history runs on a named instance it can try to connect to the default instance.
-- make sure syspolicy_purge_history is updated on all instances on the server.
EXEC msdb.dbo.sp_update_jobstep @job_name = 'syspolicy_purge_history',
           @step_name = 'Erase Phantom System Health Records.',
           @step_id = 3,
           @command = N'#if (''$(ESCAPE_SQUOTE(INST))'' -eq ''MSSQLSERVER'') {$a = ''\DEFAULT''} ELSE {$a = ''''};
#(Get-Item SQLSERVER:\SQLPolicy\$(ESCAPE_NONE(SRVR))$a).EraseSystemHealthPhantomRecords()
$SQLServerConnection = New-Object System.Data.SqlClient.SqlConnection
$SQLServerConnection.ConnectionString = "Data Source=$(ESCAPE_NONE(SRVR));Initial Catalog=master;Integrated Security=SSPI;Application Name=syspolicy_purge_history"
$PolicyStoreConnection = New-Object Microsoft.SqlServer.Management.Sdk.Sfc.SqlStoreConnection($SQLServerConnection)
$PolicyStore = New-Object Microsoft.SqlServer.Management.Dmf.PolicyStore ($PolicyStoreConnection)
$PolicyStore.EraseSystemHealthPhantomRecords()'