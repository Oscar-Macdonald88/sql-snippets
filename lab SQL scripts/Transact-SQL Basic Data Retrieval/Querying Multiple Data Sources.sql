-- From \\Sqlservices.local\ssldfs\SSLTraining\Training Materials\Videos\Pluralsight\SQL Server - Transact-SQL Basic Data Retrieval
-- Module 4: Querying Multiple Data Sources (Video 53+)
-- JOINS, UNIONS, CROSS APPLY, INTERSECT / EXCEPT

-- Inner Join
-- Given two data sources, inner joins return all pairs of rows that match (where they 'intersect').
-- A ∩ B
-- JOIN defaults to 'INNER JOIN', but best to be consistent and descriptive
-- Join conditions is used to filter rows in the ON clause, not the WHERE clause

-- Good Join
SELECT      [p].[Name],
            [od].[ProductID],
            [od].[SalesOrderDetailID],
            [od].[OrderQty]        
FROM        [Production].[Product] AS [p]
INNER JOIN  [Sales].[SalesOrderDetail] AS [od]
    ON      [p].[ProductID] = [od].[ProductID]
ORDER BY    [p].[Name],
            [od].[SalesOrderDetailID];

-- BAD join, DON'T USE!!!
-- If part of the WHERE clause is forgotten (eg you're joining lots of tables together and you forget one of the WHEREs) you will get a cartesian product aka cross-join where all rows in all tables are returned.
SELECT      [p].[Name],
            [od].[ProductID],
            [od].[SalesOrderDetailID],
            [od].[OrderQty]        
FROM        [Production].[Product] AS [p],
            [Sales].[SalesOrderDetail] AS [od]
WHERE       [p].[ProductID] = [od].[ProductID]
ORDER BY    [p].[Name],
            [od].[SalesOrderDetailID];

-- Outer Join
-- LEFT OUTER JOIN (A ⟕ B) returns all rows from the "left" table (A). In other words, it returns all rows from the left table that match the right table AND all rows that DON'T match.
-- RIGHT OUTER JOIN (A ⟖ B) returns all rows from the right table that match the left table AND all rows that DON'T match.
-- FULL OUTER JOIN (A ⟗ B) returns all rows from both tables that match AND all rows from both tables that DON'T match.
-- Output columns for unmatched rows are returned as NULL
-- Put the predicate that specifies the join condition in the ON clause
-- Put the predicate that specifies the outer row filter in the WHERE clause
-- Note: when filtering by NULL values, make sure you use 'IS NULL' rather than '= NULL'

SELECT          [p].[Name],
                [od].[ProductID],
                [od].[SalesOrderDetailID],
                [od].[OrderQty]
FROM            [Production].[Product] AS [p]
LEFT OUTER JOIN [Sales].[SalesOrderDetail] AS [od]
    ON          [p].[ProductID] = [od].[ProductID]
WHERE           [od].[ProductID] IS NULL
ORDER BY        [p].[Name],
                [od].[SalesOrderDetailID];

-- Remember, predicate placement between ON and WHERE is important and can make a difference in the result, even if the statement basically reads the same. 
-- ON clause will return NULL values, WHERE clause filters NULL values

-- Cross Joins / Cartesian Join
-- A multiplied by B
-- Often seen in 'number table' generating including number sequence generation and test data set generation.
-- A cross set may be the result of poor join construction

-- Practical useage - numbers result set aka numbers table:
-- spt_values is an arbitrary system table that has a certain number of rows
-- joins to itself to generate a result set.
SELECT TOP (100000) ROW_NUMBER() OVER (ORDER BY [sv1].[number]) AS [num]
FROM        [master].[dbo].[spt_values] AS [sv1]
CROSS JOIN  [master].[dbo].[spt_values] AS [sv2]

-- Self joins
-- When you want a data source to reference itself, you can use aliases to reference it as separate data sets
-- Supported for INNER, OUTER and CROSS joins
-- Eg: Recursive hierarchy, such as Manager/Employee relationship where the ManagerID is joined to the EmployeeID
-- Video 62 had a bad example where the existing table was altered, so I didn't include it in my notes

-- Equi vs Non-Equi Joins
-- So far, joins have been for equi-joins, i.e. [Table1].[column1] = [Table2].[column1]
-- Non-equi join involves non-equality join conditions
/* Examples:
<>: Not Equal (!= can pass in most DBMS, but not IBM DB2 UDB 9.5 and Microsoft Access 2010)
> : Greater than
< : Less than
>=: Greater than or equal to
<=: Less than or equal to
*/
-- Non-equi join conditions can be coupled with equi join conditions

-- Multi-attribute joins
-- Your join condition can involve more than one column for each input
-- Multi-attribute joins are commonly used for PK/FK associations between data sources involving more than one attribute on each side
-- Eg compare an archived table with its up-to-date counterpart
-- Note, this query will not work as [BusinessEntityAddressArchive] doesn't exist in AdventureWorks
-- See video 66 for full tutorial

SELECT  [bea].[BusinessEntityID],
        [bea].[AddressID],
        [bea].[AddressTypeID],
        [bea].[rowguid],
        [bea].[ModifiedDate]
FROM    [Person].[BusinessEntityAddress] AS [bea]
LEFT OUTER JOIN [Person].[BusinessEntityAddressArchive] AS [abea]
-- this is where the multiple attributes are used to create a unique identifier (PKish)
    ON  [bea].[BusinessEntityID] = [abea].[BusinessEntityID] 
    AND [bea].[AddressID] = [abea].[AddressID] 
    AND [bea].[AddressTypeID] = [abea].[AddressTypeID]
WHERE   [bea].[BusinessEntityID] IS NULL;

-- Joining more than two tables
-- When joining more than 2 tables, multiple JOIN operators are used in the query
-- They are processed *logically* in ordinal position, not necessarily how they are processed *physically* (may be reordered)
-- When using OUTER, the order in which you write various JOINs matters
-- INNER JOINs remove NULLs from the datas set(?) Replace with OUTER JOIN to include NULLs 
-- inner join
SELECT  [p].[Name] AS [ProductName],
        [pc].[Name] AS [CategoryName],
        [ps].[Name] AS [SubcategoryName]
FROM    [Production].[Product] AS [p]
    INNER JOIN [Production].[ProductSubcategory] AS [ps]
        ON [p].[ProductSubcategoryID] = [ps].[ProductSubcategoryID]
    INNER JOIN [Production].[ProductCategory] AS [pc]
        ON [ps].[ProductCategoryID] = [pc].[ProductCategoryID]
ORDER BY [ProductName], [CategoryName], [SubcategoryName]

-- CROSS APPLY Operator (works like an inner join)
-- Execute a table-values function (TVF) or sub-query for each row returned by the outer left data source
-- OUTER REPLY returns non-NULLs and NULLs

--TVF that returns data for the specified contact (ID in parentheses)
SELECT  [c].[BusinessEntityType],
        [c].[FirstName],
        [c].[LastName]
FROM [dbo].[ufnGetContactInformation] (3) AS [c]

-- CROSS APPLY
SELECT  [c].[BusinessEntityType],
        [c].[FirstName],
        [c].[LastName]
FROM [Person].[Person] AS [p]
CROSS APPLY [dbo].[ufnGetContactInformation] ([p].[BusinessEntityID]) AS [c]
WHERE [p].[LastName] LIKE 'Abo%'

-- OUTER APPLY (returns matched and unmatched left-input rows)
SELECT  [c].[BusinessEntityType],
        [c].[FirstName],
        [c].[LastName]
FROM [Person].[Person] AS [p]
OUTER APPLY [dbo].[ufnGetContactInformation] ([p].[BusinessEntityID]) AS [c]
WHERE [p].[LastName] LIKE 'Abo%'

-- Sub-queries aka derived tables
-- Defined in FROM within parentheses
-- can be given table aliases
-- can be joined like any other data source
-- works in RAM
-- ORDER BY not permitted
-- Requires explicit, unique column names 

-- Joining a sub-query 
SELECT      [od].[SalesOrderDetailID],
            [od].[SalesOrderID],
            [soh].[SalesPersonID]
FROM        [Sales].[SalesOrderDetail] AS [od]
INNER JOIN  (
    -- this is where you can put a sub-query
    SELECT  [SalesOrderID], [SalesPersonID]
    FROM    [Sales].[SalesOrderHeader]
    WHERE   [AccountNumber] = '10-4020-000510'
) AS [soh]
ON      [od].[SalesOrderID] = [soh].[SalesOrderID];

-- Equivalent without sub-queries
SELECT  [od].[SalesOrderDetailID],
        [od].[SalesOrderID],
        [soh].[SalesPersonID]
FROM        [Sales].[SalesOrderDetail] AS [od]
INNER JOIN  [Sales].[SalesOrderHeader] AS [soh]
ON      [od].[SalesOrderID] = [soh].[SalesOrderID]
WHERE   [AccountNumber] = '10-4020-000510';

-- UNION Operator:
-- Combines 2+ SELECT statements into a single result set
-- UNION eliminates duplicates
-- UNION ALL retains each data set, including duplicates and is less resource intensive.
-- Prefer UNION ALL over UNION

SELECT  [ProductID],
        [UnitPrice]
FROM [Sales].[SalesOrderDetail]
WHERE [ProductID] BETWEEN 1 AND 799
UNION -- ALL -- uncomment ALL to allow duplicates
SELECT  [ProductID], 
        [UnitPrice]
FROM [Sales].[SalesOrderDetail]
WHERE [ProductID] BETWEEN 800 AND 1000;

-- INTERSECT and EXCEPT Operators
-- These compare the two SELECT statements
-- INTERSECT returns distinct values returned by both the left and right sides, eliminating unmatched values.
-- EXCEPT returns distinct values from the left (first) SELECT that are not found in the right (second)
-- These help find data source discrepancies 
--      (test whether one query has the same logical results as another)
--      (Find missing rows if a data extraction process is suspected to be faulty)

-- I got lazy and didn't follow the video here
-- Which rows match between the two tables?
SELECT * -- statement A
FROM [Sales].[SalesOrderDetail]
INTERSECT
SELECT * -- statement B
FROM [Sales].[SalesOrderDetail]

-- Which rows are in A but not in B?
SELECT * -- statement A
FROM [Sales].[SalesOrderDetail]
EXCEPT
SELECT * -- statement B
FROM [Sales].[SalesOrderDetail]

-- Data Types and Joining Tables
-- Be aware of data tyes when joining between data sources.
-- Joining works on same data types, implicit conversion, but NOT on incompatible data.
-- Implicit conversion is resource intensive, however.
-- Use consistent naming/data type variable conventions for quick and error-free joining

-- Common Table Expressions (CTEs)
-- Similar to a derived table, but can allow for clear query construction rather than a derived table approach
--      Minimizes nesting of data sets
--      Allows you to isolate more complicated logic
-- Define 1+ CTEs, then use them for the scope of a specific statement
-- CTEs can also be recursive

-- simple CTE reference
WITH [ProductQty] /*([PID], [LID], [Shelf], [Bin], [Qty]) -- Optional target column list*/ AS(
        SELECT  [ProductID],
                [LocationID],
                [Shelf],
                [Bin],
                [Quantity]
        FROM    [Production].[ProductInventory]
)
SELECT  [ProductID], 
        SUM([Quantity]) AS [SumQuantity]
        /*, [PID], [LID], [Shelf], [Bin], [Qty] -- Optional target column list */
FROM [ProductQty]
GROUP BY [ProductID];

-- Multiple references to the same CTE
WITH [ProductQty] ([PID], [LID], [Shelf], [Bin], [Qty]) AS(
        SELECT  [ProductID],
                [LocationID],
                [Shelf],
                [Bin],
                [Quantity]
        FROM    [Production].[ProductInventory]
)
SELECT [p1].[PID], 
        SUM([p1].[Qty]) AS [ShelfQty_A],
        SUM([p2].[Qty]) AS [ShelfQty_B]
-- Join the CTE to itself
FROM [ProductQty] AS [p1]
INNER JOIN [ProductQty] AS [p2]
        ON [p1].[PID] = [p2].[PID]
WHERE   [p1].[Shelf] = 'A' AND
        [p2].[Shelf] = 'B'
GROUP BY [p1].[PID];

-- Multiple CTEs per statement
-- CTE 1
WITH [ProductQty] AS(
        SELECT  [ProductID],
                [LocationID],
                [Shelf],
                [Bin],
                [Quantity]
        FROM    [Production].[ProductInventory]
),
-- CTE 2
        [ListPriceHistory] AS(
        SELECT  [ProductID],
                [StartDate],
                [EndDate],
                [ListPrice]
        FROM    [Production].[ProductListPriceHistory]
        WHERE   [ListPrice] > 10.00   
)
SELECT  [p].[ProductID],
        SUM([p].[Quantity]) AS [SumQuantity]
-- Join the two CTEs together
FROM    [ProductQty] AS [p]
INNER JOIN [ListPriceHistory] AS [lp]
        ON [p].[ProductID] = [lp].[ProductID]
GROUP BY [p].[ProductID];