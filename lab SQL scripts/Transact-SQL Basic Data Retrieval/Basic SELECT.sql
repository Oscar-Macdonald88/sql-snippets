-- From \\Sqlservices.local\ssldfs\SSLTraining\Training Materials\Videos\Pluralsight\SQL Server - Transact-SQL Basic Data Retrieval
-- Module 3: Basic SELECT 
USE AdventureWorks;
-- using aliases, you can create on-the-fly result sets
-- these can also be added in the middle of actual data sets
SELECT	'1' AS [col01],
		'A' AS [col02];

-- check available data source columns using a stored procedure
-- Shows column names, data type, and other things including collation
EXEC sp_help 'Production.TransactionHistory'

-- Bookmark ep 28

-- FROM Clause
-- Defines the data source for the SELECT statement
-- Example sources include Tables, Views, Derived tables (sub-queries), temporary tables, table variables, Functions (table-valued function)
-- Maximum 256 data sources per statement
SELECT 	[Name]
FROM 	[HumanResources].[Department];
--		[Schema name]	 [Table name]

-- Check which views are in the database
SELECT 	SCHEMA_NAME(schema_id) AS [Schema],
		[Name]
FROM 	sys.views;

-- Access a View as a data source in the FROM statement:
SELECT 	[BusinessEntityID],
		[Name]
FROM 	[Sales].[vStoreWithAddresses];

-- Table variable
-- This only exists within the same batch,
-- Stored in memory.
-- A 'GO' statement separates batches
-- creates a new variable as a table
DECLARE @Orders TABLE
	(OrderID INT NOT NULL PRIMARY KEY,
	OrderDT DATETIME NOT NULL);

-- inserts an entry into the table variable
INSERT @Orders
VALUES (1, GETDATE());

-- use table variable as a data source
SELECT [OrderID], [OrderDT]
FROM @Orders;

-- Table Aliases
-- As well as the normal uses (human readability, shortening names) Don't forget to use good naming convention!
-- You can use Table Aliases for self-join scenarios:
-- dbo.Employee AS e1
-- dbo.Employee AS e2
-- JOIN e1, e2 WEHRE e1.ID = e2.ID
SELECT [dept].[Name] AS [Department Name]
FROM [HumanResources].[Department] AS [dept]
-- dept could also be 'd', as long as it makes sense. Don't use 'q' or something equally confusing.

-- Expressions, Operators, Predicates
-- Expressions are symbols and operators evaluated to produce a single data value
-- Operators are symbols specifying an action applied to an expression[s]
-- Predicates == TRUE || FALSE || UNKNOWN. Used in search conditions in WHERE, HAVING, or join conditions in FROM. Predicates play a big role in indexing strategy and query performance.

-- WHERE
-- Define which rows are returned by the statement
-- AND, OR, NOT (<>)
-- Define evaluation order using parentheses

-- DISTINCT
-- removes duplicate rows from the final result set
-- If you have multiple NULL values, where there are multiple rows where the column value is NULL, the NULL values are treated as equal and are removed if DISTINCT is declared.
-- While DISTINCT can be useful for reporting, be sure that such an operation is actually needed (causes performance overhead)

-- TOP
-- Limits rows returned, common with ORDER BY for predictability purposes
-- You can specify by rowes or percentage (fractional percentages are rounded up)
-- WITH TIES returns additional rows that match the values of the last row returned based on ORDER BY or if a WHERE clause is given. It will go over the limit specified by TOP if there are enough rows that 'tie' i.e. match the last row based on ORDER BY
-- can also be used for INSERT, UPDATE, MERGE, DELETE
SELECT TOP (10)
		[FirstName],
		[StartDate]
FROM [HumanResources].[vEmployeeDepartmentHistory] AS [edh]
ORDER BY [edh].[StartDate]

SELECT TOP (10) PERCENT
		[FirstName],
		[StartDate]
FROM [HumanResources].[vEmployeeDepartmentHistory] AS [edh]
ORDER BY [edh].[StartDate]

SELECT TOP (5) WITH TIES
			[FirstName],
			[StartDate]
FROM 		[HumanResources].[vEmployeeDepartmentHistory] AS [edh]
WHERE 		[edh].[StartDate] = '2008-01-06'
ORDER BY 	[edh].[StartDate];

-- GROUP BY
-- Group rows into a summarized set, with one row per group.
-- Typically used in conjunction with aggregate functions in the SELECT clause eg: COUNT()
-- Grouped by one or more non-aggregated columns or expressions
-- Can be used in conjunction with GROUPING SETS for multiple groups
-- Predicates can be applied to groups with HAVING

SELECT		[sod].[ProductID],
			SUM([sod].[OrderQty]) AS [Number of Orders]
FROM 		[Sales].[SalesOrderDetail] as [sod]
GROUP BY	[sod].[ProductID] -- the GROUP BY is required to show the number of orders for each ProductID. Without it, you would get 'Column 'ProductID' is invalid in the select list because it is not contained in either an aggregate function or the GROUP BY clause.'
ORDER BY [Number of Orders] DESC;

-- GROUP BY with multiple fields
SELECT		[sod].[ProductID],
			[sod].[SpecialOfferID],
			SUM([sod].[OrderQty]) AS [Number of Orders]
FROM 		[Sales].[SalesOrderDetail] as [sod]
GROUP BY	[sod].[ProductID],
			[sod].[SpecialOfferID]
ORDER BY 	[sod].[ProductID],
			[sod].[SpecialOfferID];

-- GROUPING SETS: a way to combine multiple groupings without running multiple queries and creating UNIONs
SELECT		[sod].[ProductID],
			[sod].[SpecialOfferID],
			SUM([sod].[OrderQty]) AS [Number of Orders]
FROM 		[Sales].[SalesOrderDetail] as [sod]
GROUP BY GROUPING SETS
			-- two queries, one that groups by ProductID and SpecialOfferID, and another that groups just by SpecialOfferID, combined into one result set. 
			(([sod].[ProductID],
			[sod].[SpecialOfferID]),
			([sod].[SpecialOfferID]))
ORDER BY 	[sod].[ProductID],
			[sod].[SpecialOfferID];

-- HAVING
-- Used to filter groups
-- Applies a predicate to a group
-- Similar to WHERE, but instead of filtering individual rows, you're filtering groups or sets
-- Used only (just?) with SELECT statements
-- Pay attention to performance impact of HAVING vs WHERE:
-- WHERE clause filters sooner than HAVING, so if you don't filter unnecessary data in the WHERE clause it will impact HAVING later in the query.
-- Use Include Actual Execution Plan to monitor performance
SELECT		[sod].[ProductID],
			[sod].[SpecialOfferID],
			SUM([sod].[OrderQty]) AS [Number of Orders]
FROM 		[Sales].[SalesOrderDetail] as [sod]
GROUP BY	[sod].[ProductID],
			[sod].[SpecialOfferID]
HAVING		SUM([sod].[OrderQty]) >= 100
ORDER BY 	[sod].[ProductID],
			[sod].[SpecialOfferID];

-- ORDER BY
-- You know this

-- Query Paging
-- A common requirement for applications is to 'page' through result sets eg 'return first ten rows of the results, then the next ten rows, etc. (similar to yield in programming?)
-- expand the ORDER BY clause with OFFSET and FETCH:
--	OFFSET specifies the number of rows to skip before starting
--	FETCH specifies the number of rows (after OFFSET)

-- Return the first 25 rows
SELECT		[e].[FirstName],
			[e].[LastName],
			[e].[AddressLine1]
FROM 		[HumanResources].[vEmployee] AS [e]
ORDER BY	[e].[LastName], [e].[FirstName]
	OFFSET 25 ROWS
	FETCH NEXT 25 ROWS ONLY;

-- Binding Order
-- The logical Binding Order of a SELECT statement defines which objects and references are available to WHICH clauses within a query and in what order.
/* Logical processing order:
1. 	FROM
2. 	ON
3. 	JOIN
4. 	WHERE
5. 	GROUP BY
6. 	HAVING
7. 	SELECT
8. 	DISTINCT
9. ORDER BY
10. TOP
*/