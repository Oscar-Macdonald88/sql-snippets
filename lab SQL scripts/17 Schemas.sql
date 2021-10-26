-- Schemas
-- A security container (lets you group objects together to give someone permissions on that group)
-- Also allows to group objects by their function.
-- Logically group database objects
-- Use the schema name when referencing database objects to aid name resolution and provide boundaries 
-- eg Development and Production schemas
-- [Server].[Database].[Schema].[Object]

CREATE SCHEMA [SchemaName] AUTHORIZATION [UserName] -- good idea if you specify an owner of the schema eg 'dbo' (there is a user called dbo in every install)


CREATE TABLE SchemaName.ItemName
(
    columns
)
-- eg
CREATE TABLE drink.Item
(
    col1 INT
)

CREATE TABLE dessert.Cake
(
    col1 INT
)

GRANT EXECUTE ON SCHEMA::SchemaName TO [UserName]
ALTER AUTHORIZATION ON SCHEMA::SchemaName TO dbo

-- double colon (::) is a scope qualifier.

-- To find out who owns what

SELECT * FROM sys.objects

-- Default Schema and Name Resolution
-- 1. Try user's default schema (if defined)
-- 2. Else try dbo schema
-- 3. Else return object not found error
-- Can create conjestion with schema resolution.