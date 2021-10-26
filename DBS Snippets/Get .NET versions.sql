--Get .NET Versions
	EXEC master.dbo.xp_regread 'HKEY_LOCAL_MACHINE', 'SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.0', 'Version'
	EXEC master.dbo.xp_regread 'HKEY_LOCAL_MACHINE', 'SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5', 'Version'
	EXEC master.dbo.xp_regread 'HKEY_LOCAL_MACHINE', 'SOFTWARE\Microsoft\NET Framework Setup\NDP\v4.0\Client', 'Version'
	EXEC master.dbo.xp_regread 'HKEY_LOCAL_MACHINE', 'SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Client', 'Version'