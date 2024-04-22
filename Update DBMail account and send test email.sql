EXEC msdb.dbo.sysmail_update_account_sp
    @account_name = 'EIT_Maintenance',
    @mailserver_name = 'mx1.restaurantbrands.co.nz',
    @use_default_credentials = 1

declare @body varchar(255) 
select @body = 'Test email from '+cast (@@servername as varchar (255))

EXEC msdb..sp_send_dbmail @profile_name='EIT_Maintenance',
@recipients='oscar.macdonald@servian.com;oscar.macdonald@cognizant.com;logdrop.sql@enterpriseit.co.nz',
@subject=@body,
@body='This is the body of the test message.'
WAITFOR DELAY '00:00:02';  
select top 1 subject, sent_status from msdb..sysmail_allitems order by send_request_date desc