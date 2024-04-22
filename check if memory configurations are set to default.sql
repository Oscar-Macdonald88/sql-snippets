SELECT s1.[name], s1.[value], s1.[value_in_use]
FROM sys.configurations s1
join sys.configurations s2
on s1.name = s2.name
WHERE (s1.[name] = 'min server memory (MB)' OR s2.[name] = 'max server memory (MB)')
and (s1.value = 0 or s2.value = 2147483647)
