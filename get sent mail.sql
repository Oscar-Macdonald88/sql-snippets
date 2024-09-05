SELECT TOP 100 mail.mailitem_id,
    PROFILE.name AS profile_name,
    recipients,
    copy_recipients,
    blind_copy_recipients,
    subject,
    body,
    --body_format, importance, sensitivity, file_attachments, attachment_encoding, query, execute_query_database, attach_query_result_as_file, query_result_header, exclude_query_output, append_query_error
    send_request_date,
    --send_request_user,
    account.name AS account_name,
    sent_status,
    sent_date
-- ,last_mod_date, last_mod_user
FROM msdb..sysmail_allitems mail
LEFT JOIN msdb..sysmail_profile PROFILE ON mail.profile_id = PROFILE.profile_id
LEFT JOIN msdb..sysmail_account account ON mail.sent_account_id = account.account_id
ORDER BY send_request_date DESC
