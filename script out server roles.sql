select 
		r.name as server_role,
		p.name as role_member,
		'EXEC master..sp_addsrvrolemember N' + '''' + p.name + '''' + ', N' + '''' + r.name + '''' + ';' as [T-SQL]
	from sys.server_role_members rm
	inner join sys.server_principals p on (rm.member_principal_id = p.principal_id)
	inner join (
		select principal_id, name
		from sys.server_principals
		where type_desc = 'SERVER_ROLE'
	) r on rm.role_principal_id = r.principal_id
	where 
		p.name not like '#%'
		and p.name not like 'NT %'
		and p.type_desc <> 'SERVER_ROLE'
		and p.name not in ('sa')
	order by 
		r.[name],
		p.[name];