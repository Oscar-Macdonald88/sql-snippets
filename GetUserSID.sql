SELECT sp.[name], sp.[sid], sp.is_disabled, sp.default_database_name, sp.default_language_name
FROM master.sys.server_principals AS sp
where sp.name = ''