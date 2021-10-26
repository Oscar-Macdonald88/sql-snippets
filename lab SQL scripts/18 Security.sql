/*
Security
Server-Level Security
*/
CREATE LOGIN [ServerName\UserName] FROM WINDOWS 

CREATE LOGIN [ServerName\sqladmins] FROM WINDOWS -- creates a group access if it exists on windows

CREATE LOGIN [MyLogin] WITH PASSWORD=N'supersecure' MUST_CHANGE
, DEFAULT_DATABASE = [master]
, CHECK_EXPIRATION = ON
, CHECK_POLICY = ON

-- Server Roles
sp_srvrolepermission 'dbcreator' -- or disk admin or any other server role
-- DON'T HAND OUT sa ROLE TO EVERY TOM, DICK AND HARRY, the exeption is in pre-production setup
-- add user to server role
ALTER SERVER ROLE [sysadmin]
ADD MEMBER [ServerName\UserName]
GO

-- create new role and add user
CREATE SERVER ROLE [UserRole]
ALTER SERVER ROLE [UserRole]
ADD MEMBER [ServerName\UserName]
GO

-- Granting Server-Level Permissions
-- Rclick server - > Properties -> Permissions
-- Grant: can perform the action
-- With Grant, can Grant others the permission
-- Deny is deny
-- Good permission examples:
--  Alter any database / login / server role/audit / server state
--  Connect SQL
--  Control server (gives non-sql admin the ability to run xp command shell)
--  Create database
--  Shutdown
--  View server state
--  View any database

GRANT VIEW SERVER STATE, CONTROL SERVER TO [ServerName\UserName] -- COMMA SEPARATED VIEW PERMISSIONS

-- Database-Level Security
-- Very complex
-- Database Users
USE [DatabaseName]
GO
CREATE USER [UserName] FOR LOGIN [LoginName] WITH DEFAULT_SCHEMA = [dbo]
GO

-- Handy tool:
REVERT

-- Context switching
-- Execute allows users and roles to execute procedures
EXECUTE AS USER = 'UserName'

-- Permission granting
GRANT EXECUTE, VIEW DEFINITION TO [UserName]
GRANT EXECUTE ON [ProcedureName] TO [UserName]
GRANT SELECT, DELETE, INSERT ON [dbo.TableName] TO [UserName]
--  Application Roles

-- Roles (groups)
--  Database Roles (what can the user do to the DB)
--   note: db_ddladmin can do a lot like creating, reading, writing
CREATE ROLE [RoleName]

ALTER ROLE [RoleName]
ADD MEMBER [UserName]