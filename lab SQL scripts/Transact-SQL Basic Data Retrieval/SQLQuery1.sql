USE AdventureWorks;

-- check available data source columns using a stored procedure
EXEC sp_help 'Production.TransactionHistory'

SELECT	[TransactionID],
		[ProductID],
		[Quantity], 
		[ActualCost], 
		-- you can also add aliases in the middle of actual data sets
		'Batch 1' AS [BatchID],
		-- create a new column as the result of an operation:
		([Quantity] * [ActualCost]) AS [TotalCost]
FROM [Production].[TransactionHistory];

-- Aliases
-- An alias can replace original column names or provide column names for expression where none exist
-- They can simplify long column names
-- Use AS is best practice method
SELECT	[Name] AS [DepartmentName],	-- recommended approach
		[Name] [DepartmentName],	-- not recommended approach
		[GroupName] AS [GN]			-- you can take a group name and rename to a shorter, more readable format
FROM [HumanResources].[Department]

-- Identifiers
-- DB objects are referred to in queries using their object name
-- Object names are also referred to as identifiers
-- Delimited identifiers are enclosed in double quotation marks