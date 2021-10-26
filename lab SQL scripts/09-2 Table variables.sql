-- Table variables
-- Introduce around SQL 7 (SQL 2000) because temp tables can cause recompilations:
-- Temp tables act like normal tables, and SQL Server produces statistics based on the distribution of data across tables, and as the data in the tables changes, it can trigger a recompilation of the data. Because the recompilation was performed with the temp tables in mind, the recompilation is not optimized and causes performance issues.
-- Table variables are used similarly to temp tables but scoped to the batch, which doesn't produce statistics.
-- Always estimates 1 row, so use only on very small datasets.
DECLARE @tmpProducts table
(
    ProductID INT,
    ProductName VARCHAR(50)
);