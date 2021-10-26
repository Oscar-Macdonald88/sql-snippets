/*Database Mail
SQL Server's method for sending SMTP emails
Designed to be a robust and resillient system.
*/
sp_configure 'Database Mail XPs' = 1
RECONFIGURE

-- or in SSMS -> Connect -> Management -> Rclick Database Mail -> Configure Database Mail -> Yes

/* Profiles and Accounts
Configure Database Mail -> Set up Database Mail
For SSL, both Profile and Account are set to ManageSQL. 
There are other ways to categorize Profiles eg DiskSpaceAlert and Accounts eg DiskSpaceAlertAcct and Display name eg Disk Space Alert.

Once it's all set up, SSMS -> Connect -> Management -> Rclick Database Mail -> Send Test Email
*/