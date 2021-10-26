/*
GT 01/2014: This script removes the step 2 (e-mail step) from the LS_ Backup, Copy and Restore jobs which is called on failure of Step 1
We need to run this when we are no longer required by SLA to monitor the Log shipping on an instance.
--Run this script excerpt first (Select name from sysjobs Where name LIKE 'LS[^_ ]%') first to ensure you are selecting the correct jobs to amend--
*/
use msdb
Go
Declare @JobName Varchar (150)

Declare JobName_Cursor Cursor For
Select name from sysjobs Where name LIKE 'LS[^_ ]%'--<--We need to check this carefully to ensure we select only the jobs we want to amend!!!!!!!

Open JobName_Cursor
       Fetch next from JobName_Cursor Into @JobName

       While @@Fetch_Status = 0

              Begin

                     Exec msdb.dbo.sp_delete_jobstep @job_name=@JobName, @Step_id = 2;
                     Exec msdb.dbo.sp_update_jobstep @job_name = @JobName, @Step_id = 1, @on_fail_action = 2; @on_success_action=1;
                     Fetch next from JobName_Cursor Into @JobName

              End

Close JobName_Cursor
Deallocate JobName_Cursor
