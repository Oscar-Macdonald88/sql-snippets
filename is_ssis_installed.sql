DECLARE @xp_cmd_enabled bit = CONVERT(bit, (SELECT value_in_use FROM  sys.configurations WHERE [name] = 'xp_cmdshell'))

if @xp_cmd_enabled = 0
begin
    exec sp_configure 'xp_cmdshell', 1
    go
    reconfigure
    go
end
IF OBJECT_ID('tempdb..#services') IS NOT NULL DROP TABLE #services;
CREATE TABLE #services (cmdshell_output varchar(max));

INSERT INTO #services
EXEC /**/xp_cmdshell/**/ 'net start' /* added comments around command since some firewalls block this string TL 20210221 */

IF EXISTS (SELECT 1 
            FROM #services 
            WHERE cmdshell_output LIKE '%SQL Server Integration Services%')
and not exists (select 1 from sys.databases where name = 'SSISDB')
begin
    select serverproperty('servername'), '', 200, 'Performance', 'SSIS installed and not in use', NULL, 'If SQL Server Integration Services is installed but not in use, it will use up resources unneccesarily. Consider uninstalling SSIS to save resources.'
end

if @xp_cmd_enabled = 0
begin
    exec sp_configure 'xp_cmdshell', 0
    go
    reconfigure
    go
end