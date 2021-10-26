-- Stored Procedures and Functions

-- Stored Procedure:
-- Group of statements that are stored on the server
-- Input / output params, can return sets of rows
-- They provide security boundaries
-- The procedure will work as long as the owner of the stored procedure also owns the table
-- Always use two part naming convention to reduce impact on resources
CREATE PROCEDURE SchemaName.ProcedureName -- shorthand CREATE PROC
-- WITH ENCRYPTION -- optional, not recommended
AS
BEGIN
    -- Enter queries here (can return multiple result sets)
    SELECT *
    FROM TableName
END;
GO

-- To change an already existing stored procedure:
ALTER PROCEDURE SchemaName.ProcedureName
AS
BEGIN
    -- Enter queries here
    SELECT *
    FROM TableName
END;
GO
-- To run a stored procedure
EXECUTE SchemaName.ProcedureName; -- shorthand EXEC

-- EXECUTE can also be used on other objects such as dynamic SQL statements stored in a string

-- Qualify object names inside stored procedures (SchemaName.ObjectName)
-- Apply consistent naming conventions and don't use the sp_ prefix (doesn't stand for stored procedure, more like system stored procedure).
-- Instead, use something like usp_ for user stored procedure or similar.
-- Keep to one prodecure for each task

-- To see the list of procedures:
SELECT SCHEMA_NAME(schema_id) AS SchemaName,
    name AS ProcedureName
FROM sys.procedures;
GO

-- Using Input Parameters
CREATE PROC SchemaName.ProcedureName
    @Param1 int = 5, @Param2 datetime
AS
BEGIN
    -- Enter queries here (can return multiple result sets)
    SELECT *
    FROM TableName
    WHERE TableName.IntColumn = @Param1 AND TableName.DateColumn = @Param2
END;
GO

-- Parameters can be passed either in order OR by name, BUT not in a combination of the two

-- Using Output Parameters
CREATE PROC SchemaName.ProcedureName
    @Param1 int = 5, @Param2 datetime, @ReturnVal int OUTPUT -- OUTPUT must be specified when creating the procedure 
AS
BEGIN
    -- Enter queries here (can return multiple result sets)
    SELECT *
    FROM TableName
    WHERE TableName.IntColumn = @Param1 AND TableName.DateColumn = @Param2;
    SET @ReturnVal = @Param1 * @Param1; 
END;
GO

DECLARE @Param1 int = 4;
DECLARE @Param2 datetime = GETDATE();
DECLARE @ReturnVal int;
EXEC SchemaName.ProcedureName @Param1, @Param2, @ReturnVal OUTPUT; -- OUTPUT must be specified when executing the procedure
SELECT @ReturnVal;

-- To delete a procedure:
DROP PROC SchemaName.TableName;

-- Demo
USE AdventureWorks;
GO

CREATE PROC Production.GetProductsAndModelsByColor
    @Color nvarchar(15)
AS
BEGIN
    -- Row Set 1
    SELECT  p.ProductID,
            p.Name,
            p.Size,
            p.ListPrice
    FROM Production.Product AS p
    WHERE p.Color = @Color
    ORDER BY p.ProductID;

    -- Row Set 2
    SELECT  p.ProductID,
            pm.ProductModelID,
            pm.Name AS ModelName
    FROM Production.Product AS p
    INNER JOIN Production.ProductModel AS pm
    ON p.ProductModelID = pm.ProductModelID
    WHERE p.Color = @Color
    ORDER BY p.ProductID, pm.ProductModelID;
END;
GO

EXEC Production.GetProductsAndModelsByColor 'Red';
GO

-- This procedure has a bug: can't get products back that have not color .
EXEC Production.GetProductsAndModelsByColor NULL;
GO -- Returns both empty result sets

-- Change the procedure to deal with NULLs
ALTER PROC Production.GetProductsAndModelsByColor
    @Color nvarchar(15)
AS
BEGIN
    -- Row Set 1
    SELECT  p.ProductID,
            p.Name,
            p.Size,
            p.ListPrice
    FROM Production.Product AS p
    WHERE (p.Color = @Color) OR (p.Color IS NULL AND @Color IS NULL) -- here is the extra functionality to deal with NULLs
    ORDER BY p.ProductID;

    -- Row Set 2
    SELECT  p.ProductID,
            pm.ProductModelID,
            pm.Name AS ModelName
    FROM Production.Product AS p
    INNER JOIN Production.ProductModel AS pm
    ON p.ProductModelID = pm.ProductModelID
    WHERE (p.Color = @Color) OR (p.Color IS NULL AND @Color IS NULL)-- here is the extra functionality to deal with NULLs
    ORDER BY p.ProductID, pm.ProductModelID;
END;
GO

-- Run the query again to confirm it now returns items without color if NULL is given
EXEC Production.GetProductsAndModelsByColor NULL;
GO

-- Functions
-- A routing that is used to encapsulate frequently performed logic
-- Must have a return value
-- No execution plan reuse
-- Types
--  Scalar (returns a single value and usually includes parameters)
--  Table-valued
--      Inline
--      Multistatement

-- Scalar Function
-- This example seems to have an incorrectly written return statement
/*
CREATE FUNCTION dbo.ExtractProtocolFromURL (@URL nvarchar(1000)) -- functions require parentheses around parameters
RETURNS nvarchar(1000) -- remember that functions must have a return value
AS BEGIN
    -- CHARINDEX ( expressionToFind , expressionToSearch [ , start_location ] ) Returns int
    -- Look for ':' within @URL from index 1   
    CASE WHEN CHARINDEX(N':',@URL, 1) >= 1
    -- if it's found, get all the characters from the start to the index where ':' was found
    THEN RETURN SUBSTRING(@URL, 1, CHARINDEX(N':',@URL, 1) - 1)
END
GO
*/
-- This is MY way of writing ExtractProtocolFromURL
DECLARE FUNCTION dbo.ExtractProtocolFromURL (@URL nvarchar(1000)) -- functions require parentheses around parameters
RETURNS nvarchar(1000) -- remember that functions must have a return value
AS BEGIN
    -- CHARINDEX ( expressionToFind , expressionToSearch [ , start_location ] ) Returns int
    -- Look for ':' within @URL from index 1
    -- if it's found, get all the characters from the start to the index where ':' was found   
    DECLARE @ReturnVal nvarchar(1000);
    IF CHARINDEX(N':',@URL, 1) >= 1
        SET @ReturnVal = SUBSTRING(@URL, 1, CHARINDEX(N':',@URL, 1) - 1)
    RETURN @ReturnVal
END;
GO

SELECT dbo.ExtractProtocolFromURL(N'https://www.google.com');
SELECT dbo.ExtractProtocolFromURL(N'https://www.google.com:8080');
SELECT dbo.ExtractProtocolFromURL(N'www.google.com');

-- Demo
USE master;
GO
DROP DATABASE IF EXISTS demodb;
GO
CREATE DATABASE demodb;
GO
USE demodb;
GO

CREATE FUNCTION dbo.EndOfPreviousMonth (@DateParam date)
RETURNS date
AS BEGIN
    RETURN DATEADD(day, 0 - DAY(@DateParam), @DateParam);
END;
GO

SELECT dbo.EndOfPreviousMonth(SYSDATETIME());
SELECT dbo.EndOfPreviousMonth('2010-01-01');

-- Determinism (i guess that's what it's called)
-- Determine if the given function is deterministic.
-- A function is deterministic if if it always has the same result if it's given the same parameters.
SELECT OBJECTPROPERTY(OBJECT_ID('dbo.EndOfPreviousMonth'), 'IsDeterministic');
GO
-- In this case it isn't deterministic because it relies on an incoming value that changes the output.

DROP FUNCTION dbo.EndOfPreviousMonth;
GO

-- Table-Valued Functions (TVF)
-- Returns a TABLE data type
-- Inline TVFs have a function body with only a *single* SELECT statement
-- Multistatement TVFs construct, populate, and return a table within the function
--  Can be used to replace views where more complex logic is needed

-- Demo
USE AdventureWorks;
GO

CREATE FUNCTION Sales.GetLastOrdersForCustomer (@CustomerID int, @NumberOfOrders int)
RETURNS TABLE -- this sets the function as a TVF
AS RETURN
(
    SELECT TOP (@NumberOfOrders)
        soh.SalesOrderID,
        soh.OrderDate,
        soh.PurchaseOrderNumber
    FROM Sales.SalesOrderHeader AS soh
    WHERE soh.CustomerID = @CustomerID
    ORDER BY soh.OrderDate DESC
);
GOUSE AdventureWorks;
GO

CREATE FUNCTION Sales.GetLastOrdersForCustomer (@CustomerID int, @NumberOfOrders int)
RETURNS TABLE -- this sets the function as a TVF
AS RETURN
(
    SELECT TOP (@NumberOfOrders)
        soh.SalesOrderID,
        soh.OrderDate,
        soh.PurchaseOrderNumber
    FROM Sales.SalesOrderHeader AS soh
    WHERE soh.CustomerID = @CustomerID
    ORDER BY soh.OrderDate DESC
);
GO

SELECT * FROM Sales.GetLastOrdersForCustomer(17288, 2);
GO

-- CROSS APPLY Operator (works like an inner join)
-- Execute a table-values function (TVF) or sub-query for each row returned by the outer left data source
-- OUTER REPLY returns non-NULLs and NULLs
SELECT
    c.CustomerID,
    c.AccountNumber,
    glofc.SalesOrderID,
    glofc.OrderDate
    -- I just found out that you can use a wildcard to get all colums from a table or table alias
    -- eg: glofc.* gets all columns from glofc!
FROM Sales.Customer AS c
CROSS APPLY Sales.GetLastOrdersForCustomer(c.CustomerID, 3) AS glofc
ORDER BY c.CustomerID, glofc.SalesOrderID;

