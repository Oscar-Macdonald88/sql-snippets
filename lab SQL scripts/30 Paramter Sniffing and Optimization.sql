-- Parameter Sniffing and Performance
-- Execution plans can be expensive to create, so generally we want to re-use them as much as possible (DRY)
-- If your data has an uneven distribution (lumpy data) it can cause problems with plan reuse
-- Lumpy data: where, in a single table, you have few values of one type of data but lots of occurences of a different type.
-- Eg If you had a table with 500 entries for 'Red' objects, 499 entries for 'Blue' objects, and 1 entry with 'White', the 
--  GetProductsAndModelsByColor procedure (29) will not be as efficient for 'White' objects

-- Options for resolving
--  CREATE PROCEDURE SchemaName.NewProcedure WITH RECOMPILE
--      This is a bit of a broad approach
--  EXEC Schemaname.ProcedureName WITH RECOMPILE
--      Similar to modifying the stored procedure itself
--  OPTION (OPTIMIZE FOR)
--      Tell the optimizer which value to design the execution plan for (eg 'White')

-- Look at the execution plan to see how the procedure is optimized
DBCC FREEPROCCACHE; -- Use this if you don't want the procedure plan to be reused.
GO
EXEC Production.GetProductsAndModelsByColor 'White'
GO
EXEC Production.GetProductsAndModelsByColor 'Red'
GO
-- The procedure will be optimized for the 'White' value, and if there are few White objects it means that when it is run again it won't be optimized for Red values, taking up precious resources.

EXEC Production.GetProductsAndModelsByColor 'Red' WITH RECOMPILE;
GO

-- Use Recompile option for individual statements
ALTER PROC Production.GetProductsAndModelsByColor
    @Color nvarchar(15)
AS
BEGIN
    SELECT  p.ProductID,
            p.Name,
            p.Size,
            p.ListPrice
    FROM Production.Product AS p
    WHERE (p.Color = @Color) OR (p.Color IS NULL AND @Color IS NULL) -- here is the extra functionality to deal with NULLs
    ORDER BY p.ProductID;

    SELECT  p.ProductID,
            pm.ProductModelID,
            pm.Name AS ModelName
    FROM Production.Product AS p
    INNER JOIN Production.ProductModel AS pm
    ON p.ProductModelID = pm.ProductModelID
    WHERE (p.Color = @Color) OR (p.Color IS NULL AND @Color IS NULL)-- here is the extra functionality to deal with NULLs
    ORDER BY p.ProductID, pm.ProductModelID
    OPTION (RECOMPILE); -- statement-level recompile just for this part of the procedure
END;
GO

-- Option 3, use OPTIMIZE FOR
-- Rather than recompiling individual statements, only optimize on certain values
ALTER PROC Production.GetProductsAndModelsByColor
    @Color nvarchar(15)
AS
BEGIN
    SELECT  p.ProductID,
            p.Name,
            p.Size,
            p.ListPrice
    FROM Production.Product AS p
    WHERE (p.Color = @Color) OR (p.Color IS NULL AND @Color IS NULL) -- here is the extra functionality to deal with NULLs
    ORDER BY p.ProductID;

    SELECT  p.ProductID,
            pm.ProductModelID,
            pm.Name AS ModelName
    FROM Production.Product AS p
    INNER JOIN Production.ProductModel AS pm
    ON p.ProductModelID = pm.ProductModelID
    WHERE (p.Color = @Color) OR (p.Color IS NULL AND @Color IS NULL)-- here is the extra functionality to deal with NULLs
    ORDER BY p.ProductID, pm.ProductModelID
    OPTION (OPTIMIZE FOR (@Color = 'Red'));
END;
GO