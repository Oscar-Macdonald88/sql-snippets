
declare
	@domain_email varchar(255) = '', --INSERT EMAIL DOMAIN HERE eg @water.co.nz
	@smtp varchar(255) = '', -- INSERT SMTP ADDRESS HERE eg outlook.water.internal
	@port_number int = 25, -- Default is 25 but this can be changed if the client uses a non-standard port
	@is_ssl_enabled bit = 0 -- Set this to 1 if the client uses SSL/TLS 

declare
	@Set_email_address varchar(255) = -- set this
	@Set_display_name varchar(255) = -- set this
if exists (select 1 from msdb.dbo.sysmail_profile where name = 'ManagedSQL')
begin
	exec msdb.dbo.sysmail_delete_profile_sp @profile_name = 'ManagedSQL'
end

--#################################################################################################
-- BEGIN Mail Settings ManagedSQL
--#################################################################################################
--CREATE Profile [ManagedSQL]
execute msdb.dbo.sysmail_add_profile_sp
	@profile_name = 'ManagedSQL',
	@description = 'mail profile used for managing this SQL installation';

if not exists (select 1 from msdb.dbo.sysmail_account where name = 'ManagedSQL') begin
	--CREATE Account [FS_DBA]
	execute msdb.dbo.sysmail_add_account_sp
		@account_name = 'ManagedSQL',
		@email_address = @Set_email_address,
		@display_name = @Set_display_name,
		@replyto_address = 'dba@sqlservices.com',
		@description = 'mail profile used for managing this SQL installation',
		@mailserver_name = @smtp,
		@mailserver_type = 'SMTP',
		@port = @port_number,
		@use_default_credentials = 0,
		@enable_ssl = @is_ssl_enabled;
end --IF EXISTS account

if not exists (select 1 from msdb.dbo.sysmail_profileaccount pa inner join msdb.dbo.sysmail_profile p on pa.profile_id = p.profile_id inner join msdb.dbo.sysmail_account a on pa.account_id = a.account_id where p.name = 'ManagedSQL' and a.name = 'ManagedSQL')
begin
	-- Associate Account [ManagedSQL] to Profile [ManagedSQL]
	execute msdb.dbo.sysmail_add_profileaccount_sp
		@profile_name = 'ManagedSQL',
		@account_name = 'ManagedSQL',
		@sequence_number = 1;
end --IF EXISTS associate accounts to profiles

use master
go

sp_configure 'show advanced options', 1
go

reconfigure
with override
go
sp_configure 'Database Mail XPs', 1
go
reconfigure
go

select TextValue from tbl_Param where Param = 'DropFolderDir'

update tbl_Param set
	TextValue = null
where
	Param = 'DropFolderDir'

select TextValue from tbl_Param where Param = 'DropFolderDir'

exec msdb..sp_start_job N'SSL_SendDashboardData', @step_name = 'Send alert if PowerShell is disabled or unavailable';
go

exec msdb..sp_start_job N'SSL_SendDBCCFileWeekly', @step_name = 'Zip DBCC file';
go

waitfor delay '00:00:05'

select top 10
	recipients,
	subject,
	body,
	sent_status,
	send_request_date,
	sent_date
from
	msdb..sysmail_allitems
--where body like '%An alert was generated as a database has run out of space.%'
order by
	send_request_date desc
