-- Server-level configurations
USE master

-- to see available config options:
EXEC sp_configure;

-- to use advanced options:
EXEC sp_configure 'show advanced options', [0 | 1];
RECONFIGURE;
-- advanced options can't be changed until they are shown
-- some options require a restart of SS before working

EXEC sp_configure 'backup compression default', [0 | 1];
-- compressed backups take less time and are smaller than uncompressed backups, can usually prevent surprising backups that take up too much disk space.

EXEC sp_configure 'blocked process threshold (s)', [0 - 86400];
-- number of seconds to wait before logging blocked processes. A rule of thumb is around 5 seconds, but every instance is different.

EXEC sp_configure 'clr enabled', [0 | 1];
-- in order to use user written common language runtime (CLR) stored procedures and functions you need to turn this on.
-- the system CLR procedures and functions will work regardless

EXEC sp_configure 'Database Mail XPs', [0 | 1];
-- self explanatory

EXEC sp_configure 'fill factor (%)', [0-100]; -- 0 = 100
-- Reduces the amount of fragmentation in tables by leaving an amount of space in the page. Default = 0 (100)
-- Common values are 90 or 80% (lecturer uses 80)

EXEC sp_configure 'max degree of parallelism', [0 - 32767];
-- Basically, how many CPUs per process
-- 1, 2, 4 are common values
-- very important in OLTP (Online Transaction Processing) systems with lots of CPUs, where all of the transactions should be small and short and quick. 
-- Less important in DSS (Descision Sytstem aka reporting): has larger transactions.
-- Query option MAXDOP overrides this setting and requests CPU use

EXEC sp_configure 'remote access', [0 | 1];
-- allows remote access

EXEC sp_configure 'remote admin connections', [0 | 1];
-- sets aside some resources (1 CPU) for a single admin connection

EXEC sp_configure 'xp cmdshell', [0 | 1];
-- xp (extended stored procedure, which is implemented in SS as a DLL (dynamic link library?)) DOS access from T-SQL on the server
-- Dangerous, extremely insecure, but very useful, eg
xp_cmdshell 'ping localhost'
-- by default, only admins have access to xp_cmdshell, but non-admins can be granted rights ('control server' permissions)