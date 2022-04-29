select serverproperty('servername'), name, is_disabled, is_policy_checked, is_expiration_checked, 
[Empty Password] = case PWDCOMPARE('',password_hash) when 1 then 'Yes' else 'No' end,
'Password same as user name' = case PWDCOMPARE(name,password_hash) when 1 then 'Yes' else 'No'end
from sys.sql_logins
where name <> 'sa' and name not like '##MS%' and (is_policy_checked = 0 or is_expiration_checked = 0 or PWDCOMPARE('',password_hash) = 1 or PWDCOMPARE(name,password_hash) = 1)