SET NOCOUNT ON
DECLARE @cmdstr varchar(100)
declare  @TempTable TABLE
 ([Table_Name] varchar(500),
    Row_Count bigint,
    Table_Size varchar(15),
    Data_Space_Used varchar(15),
    Index_Space_Used varchar(15),
    Unused_Space varchar(15) )
SELECT @cmdstr = 'sp_MSforeachtable ''sp_spaceused ''''?'''''''
INSERT INTO @TempTable
EXEC(@cmdstr)
DECLARE @totalRows real
SELECT @totalRows = SUM(Row_Count)
from @TempTable
DECLARE @totalReserved real
SELECT @totalReserved = SUM(CAST(SUBSTRING(Table_Size,1,LEN(Table_Size)-2) as bigint))
from @TempTable
SELECT
    Table_Name [Name],
    Row_Count [Rows],
    STR((Row_Count/@totalRows)*100 ,4 ,2) Row_Percents,
    CAST(SUBSTRING(Table_Size,1,LEN(Table_Size)-2) as bigint)/1024.0/1024.0 as 'Reserved GB',
    STR((CAST(SUBSTRING(Table_Size,1,LEN(Table_Size)-2) as real)/@totalReserved)*100 , 4, 2) Reserved_Percents,
    CAST(SUBSTRING(Data_Space_Used,1,LEN(Data_Space_Used)-2) as bigint)/1024.0/1024.0 as 'Data GB' ,
    CAST(SUBSTRING(Index_Space_Used,1,LEN(Index_Space_Used)-2) as bigint)/1024.0/1024.0 as 'IndexSize GB',
    CAST(SUBSTRING(Unused_Space,1,LEN(Unused_Space)-2) as bigint)/1024.0 as 'Unused MB'
FROM @TempTable
where Row_Count > 0
ORDER BY 4 DESC
