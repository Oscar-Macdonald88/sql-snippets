-- Module 5: Using Functions
-- Common and useful built-in functions that can be used within data retrieval queries

-- Aggregate Functions
-- AVG: Averages of values in a group
-- CHECKSUM_AGG: Checksum (hash value ovber a list of arguments) of values in a group. Result is a hash index which can be used for equality searches over a set of columns 
-- COUNT: Return the number of items in a group (int)
-- COUNT_BIG: Same as COUNT but with bigint returned
    -- With DISTINCT, these return the number of unique non-null values
    -- COUNT(*) (or BIG_COUNT) specifies all rows - including null values
-- MIN and MAX: min and max values in an expression, both ignore null values
-- SUM: Sum of all values, NULLs are ignored, DISTINCT returns SUM of unique values
-- STDEV returns the standard deviation of all values in the expression
--      Asumes partial sampling of the whole population
-- STDEVP returns the standard deviation ***for the entire population*** of all values in the expression
-- VAR: statistical variance of all values on the specified expression
-- VARP: statistical variance ***for the entire population*** of all values in the specified expression

-- CHECKSUM(*)
USE AdventureWorks
SELECT CHECKSUM(*) [CheckSumVal], [ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]
FROM [Production].[Product] AS [p];

-- Use CHECKSUM_AGG to see if a table has changed at all
SELECT CHECKSUM_AGG(CHECKSUM(*)) AS [TableCheckSum]
FROM [Production].[Product];

-- CHECKSUM and CHECKSUM_AGG are useful if you have two tables that are supposed to be identical but you don't know if they are.
    -- CHECKSUM(*) can detect changes in rows
    -- CHECKSUM_AGG can detect changes on the table level

-- STDEV
SELECT STDEV(ListPrice) AS [STDEVListPrice]
FROM [Production].[ProductListPriceHistory];

--STDEVP
SELECT STDEVP(ListPrice) AS [STDEVPListPrice]
FROM [Production].[ProductListPriceHistory];

--VAR
SELECT VAR(ListPrice) AS [VARListPrice]
FROM [Production].[ProductListPriceHistory];

--VARP
SELECT VARP(ListPrice) AS [VARPListPrice]
FROM [Production].[ProductListPriceHistory];

-- Mathematical Functions
-- 20+ math functions included natively in SQL Server
-- CEILING
-- FLOOR
-- ROUND (to the specified number of digits)
--  Rounding with negative numbers (eg -1) rounds in the opposite direction to the decimal point: eg rounds 33 to 30
-- PI
-- POWER (to the specified power)
-- SQRT
-- RAND (0 to 1 with optional seed)
SELECT RAND() AS Randomvals;
GO 5;

-- OVER
-- Applicable to ranking, aggregate and analytic functions
-- Defines a "window" within a specific query result set:
--  Like a user-defined row set within the total result set
-- Allows you to apply aggregations to rows without using a GROUP BY
--  Window functions can then compute values for individual rows within the window

-- Ranking Functions
-- ROW_NUMBER: Sequential number of a row within a result set partition
-- RANK: (similar to ROW_NUMBER) returns a rank of a row within the partition of the result set
--  Rank is calculated as 1 + n where n = number of ranks before the row
--  Tied rows based on logical order get the same rank
-- DENSE_RANK: same as rank but with no gaps in ranking values
-- NTILE: Map rows into equally sized row groups
--  Function takes a number of groups to split the results into
--  Group sizes will differ when not evenly divisible (eg 26 results split into 5 will result in 5 per group for 4 groups while 1 group will have 6)

-- Give a row number to each product name, different to product ID
SELECT p.ProductID, p.name,
    ROW_NUMBER() OVER (order by p.ProductID) as RowNum
from Production.Product as p
order by p.ProductID

-- Order products into 'windows' by their color, each with a unique ID within the context of its window
SELECT p.Color, p.name,
    ROW_NUMBER() OVER (PARTITION BY p.Color order by p.Name) as RowNum
from Production.Product as p
WHERE p.Color IS NOT NULL
order by p.Color, p.Name

-- Assign a RANK to each group
-- you'll see that each 'window' has a shared rank based on the first entry of the ORDER BY (in this case: 1, 6, 10...)
SELECT p.Name, p.StandardCost,
    RANK() OVER (order by p.StandardCost DESC) as CostRank
from Production.Product as p
order by p.StandardCost DESC

-- Or you can provide a rank increasing in logical window sequence using DENSE_RANK(1, 2, 3...)
SELECT p.Name, p.StandardCost,
    DENSE_RANK() OVER (order by p.StandardCost DESC) as CostRank
from Production.Product as p
order by p.StandardCost DESC

-- NTILE(number of groups)
-- Splits the groups into the number of groups.
SELECT p.Name, p.StandardCost,
    NTILE(5) OVER (order by p.StandardCost DESC) as CostRank
from Production.Product as p
order by p.StandardCost DESC

-- Conversion Functions
-- PARSE: convert string to date/time or number
--  PARSE('string' AS <data-type>)
--  PARSE('string' AS <data-type> USING <style>) style example: 'en-US' or 'en-GB'
-- TRY_PARSE: if parse fails, returns NULL
-- TRY_CONVERT: Converts between data types, returns NULL if fails
-- (TRY_)CAST / (TRY_)CONVERT (legacy): Converts between data types
--  CAST(expression AS <data type> [data type length])
--  CONVERT(<data type> [<data type length>], expression, [<style>]) eg date formatting to US or GB

-- Validating Data Types: returns boolean if an input expression is a valid data type
-- ISDATE, ISNUMERIC

-- System Time Functions
-- SYSDATETIME(): Date and time of SQL Server instance, returns datetime2 data type
-- SYSDATETIMEOFFSET(): Same, but includes time zone offset and returns datetimeoffset
-- SYSUTCDATETIME(): Same, but returns UTC as datetime2
-- Lower precision functions: CURRENT_TIMESTAMP(), GETDATE(), GETUTCDATE()

-- Returning Date and Time parts:
-- DAY, MONTH, YEAR 
-- DATEPART: eg year (yy or yyyy), quarter (qq or q), month, day, hour, minute, second, milliseconds
-- DATENAME: Returns string representing datepart

-- Constructing Date and Time Values:
-- DATEFROMPARTS(year, month, day): returns date data type
-- DATETIMEFROMPARTS(year, month, day, hour, min, sec, milli): returns datetime data type
-- DATETIME2FROMPARTS(year, month, day, hour, min, sec, fractions, precision): returns datetime2 data type
-- DATETIMEOFFSETFROMPARTS(year, month, day, hour, min, sec, fractions, hour_offset, minute_offset, precision): returns datetimeoffset data type
-- SMALLDATETIMEFROMPARTS(year, month, day, hour, min): returns smalldatetime data type
-- TIMEFROMPARTS(hour, min, sec, fractions, precision): returns time data type

-- Calculating Time Differences
-- DATEDIFF(datepart, start_date, end_date): returns difference between start_date and end_date as int data type based on datepart

-- Modifying Dates
-- DATEADD(datepart, number, date): returns new datetime value with the number to add (or subtract) based on datepart on the input date
-- EOMONTH(date, [months_to_add]): returns the last day of the month for a specified date. months_to_add specifies an optional number of months to add to the start date
-- SWITCHOFFSET(datetimeoffset, timezone): changes input value to a new time zone offset
-- TODATETIMEOFFSET(datetime2, timezone): converts input value to a datetimeoffset value

-- Logical Functions
-- CHOOSE(1_based_index, val_1, val_2, ... val_n): choose an item in a list of values. values in the list can be of any data type
-- IIF(boolean_expression, true_return, false_return): return one of two values based on a Boolean expression. Stands for Inline IF
-- CASE expression (switch): compare an expression to a set of expressions in order to determine the result
select  pch.ProductID,
        pch.StartDate,
    case pch.ProductID
        when 707 then 'Platinum'
        when 711 then 'Silver'
        when 713 then 'Gold'
        else 'Standard'
    end
    as [ProductStatus],
    case
        when (pch.StartDate between '1/3/2010' and '12/31/2012') 
            then 'Owned by K-Tech'
        when (pch.StartDate between '1/1/2013' and '12/31/2016') 
            then 'Owned by Z-Tech'
        else 'Unknown Ownership'
    end
    as [StandardCost]
from Production.ProductCostHistory as pch
order by [StandardCost]

-- Working with NULL
-- COALESCE(val_1, val_2, ..., val_n): returns the first non-null expression from a list of arguments
-- ISNULL(column, replace_value): replaces any NULL in the column with replace_value
-- Option CONCAT_NULL_YIELDS_NULL: when ON, concatenating a null value and a non-null string yields a NULL result.
-- This is ON by default
SET CONCAT_NULL_YIELDS_NULL ON;
GO

DECLARE @ReportName varchar(20) = NULL;
SELECT 'Report Date:' + @ReportName
    AS [ReportHeader];
GO
-- No string will appear in the results, just a NULL
-- (string + NULL = NULL)

SET CONCAT_NULL_YIELDS_NULL OFF;
GO

DECLARE @ReportName varchar(20) = NULL;
SELECT 'Report Date:' + @ReportName
    AS [ReportHeader];
GO
-- Now the string will appear, with nothing appended to the end
-- (string + NULL = string)

-- String Functions
-- ASCII(string): returns ASCII int from leftmost char
-- CHAR(int): returns char from int
-- NCHAR(int): returns unicode char from int
-- UNICODE(string): returns ASCII int from leftmost char
-- FORMAT(input, format [, style]): returns nvarchar
-- LEFT(string, index): returns left part of input string from 0 - index
-- RIGHT(string, index): returns right part of input string from index - LEN(string)
SELECT LEFT(p.LastName, 1) + '####' + RIGHT(p.LastName, 1) AS [Mask]
FROM Person.Person as P

-- LEN(string): take a friggin guess. Excludes trailing blanks
-- DATALENGTH(string): outputs number of bytes from string, also excludes trailing blanks
-- LOWER(string)
-- UPPER(string)
-- LTRIM(string): removes leading blanks
-- RTRIM(string): removes trailing blanks
-- PATINDEX(string, pattern [, start_index]): returns start position of a pattern (string data type) within string
--  Also CHARINDEX but no wildcards
-- REPLACE(string, pattern, replacement):returns string with occurences of pattern replaced with replacement
-- STUFF(string, index, length, stuff_string): Inserts stuff_string into string, replacing chars from index to length
-- SUBSTRING(string, index, length): Returns part of a string
-- REPLICATE(string, n): Repeat string n times
-- REVERSE(string): reverse the string
-- SPACE(n): returns a string of n spaces
-- STR(float [, length [, decimal]]): converts numeric data into non-Unicode string
SELECT p.FirstName + ':' + LTRIM(STR(p.EmailPromotion)) AS [EmailPromotion]
FROM Person.Person as p
-- CONCAT(input, con_1, con_2, ..., con_n): returns input with concatenations
-- QUOTENAME(input [, quote_character]): delimits input, returns a Unicode string that produces a valid SQL Server identifier
DECLARE @ExampleObjectName NVARCHAR(50) = 'Bad Object Name';
SELECT QUOTENAME(@ExampleObjectName);
-- Wraps 'Bad Object Name' in square brackets

-- Analytic Functions (all require OVER([PARTITION BY] ORDER BY))
-- LAG(scalar [, offset] [, default]): Compare values in current row with values in previous row
-- LEAD(scalar [, offset] [, default]): Compare values in current row with values in the following row
-- FIRST_VALUE(scalar): Return the first value in a result set (may or may not be logically partitioned)
-- LAST_VALUE(scalar): Return the last value in a result set (may or may not be logically partitioned)
--  More advanced for LAST_VALUE: RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING

-- CUME_DIST() returns a value such that 0 < value < 1. Represents the number of rows <= current row value / number of rows in result set
--  ie computes the relative position of a specified value in a group of values
-- PERCENT_RANK(): returns a value such that 0 < value < 1. Represents the relative rank of a row within the result set
-- PERCENT_CONT(interpolated): calculates a percentile based on continuous distribution of values.
--  Result is interpolated, so the return value may not actually be in the result set.
-- PERCENTILE_DISC(interpolated): Similar to PERCENT_CONT, but the result will choose a number from the result set.
--  Smallest CUME_DIST value >= the percentile value