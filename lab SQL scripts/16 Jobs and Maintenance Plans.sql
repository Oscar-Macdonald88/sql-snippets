-- Jobs and Maintenance Plans

-- When creating a maintenance plan, if you need to retain up to a period of backup files (eg the last 2 days of backups) do the following:
-- Taken from https://social.msdn.microsoft.com/Forums/sqlserver/en-US/f09c12b1-ed56-48ce-95e1-7c53d7634dba/how-to-create-a-database-backup-job-that-will-keep-just-two-days-backup-file?forum=sqldatabaseengine

--keep the recent 2 days bak files, like testdb20110708.bak and testdb20110709.bak

--We can use Maintenance cleanup task [in SSMS] to achieve this.

--drag and drop Maintenance cleanup task from ToolBox >>edit >>select backup files>>provide your backup files location>>file extension as Bak>>Check Delete files as ..>>Provide X weeks/days/hours in Delete files older than following box.