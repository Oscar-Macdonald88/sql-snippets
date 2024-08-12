select top 100 mail.mailitem_id, profile.name as profile_name, recipients, copy_recipients, blind_copy_recipients, subject, body, 
--body_format, importance, sensitivity, file_attachments, attachment_encoding, query, execute_query_database, attach_query_result_as_file, query_result_header, exclude_query_output, append_query_error
send_request_date ,
--send_request_user,
account.name as account_name, sent_status, sent_date
-- ,last_mod_date, last_mod_user
from msdb..sysmail_allitems mail
join msdb..sysmail_profile profile on mail.profile_id = profile.profile_id
join msdb..sysmail_account account on mail.sent_account_id = account.account_id
order by send_request_date desc