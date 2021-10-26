use DBName
SET NOCOUNT ON
DECLARE @cmdstr varchar(100)
declare  @TempTableData TABLE
 ([Table_Name] varchar(500),
    Row_Count bigint,
    Table_Size varchar(15),
    Data_Space_Used varchar(15),
    Index_Space_Used varchar(15),
    Unused_Space varchar(15) )
SELECT
    @cmdstr = 'sp_msforeachtable ''sp_spaceused ''''?'''''''
INSERT INTO @TempTableData
EXEC(@cmdstr)
DECLARE @totalRows real
SELECT
    @totalRows = SUM(Row_Count)
from
    @TempTableData
DECLARE @totalReserved real
SELECT
    @totalReserved = SUM(CAST(SUBSTRING(Table_Size,1,LEN(Table_Size)-2) as bigint))
from
    @TempTableData
SELECT
    Table_Name [Name],
    Row_Count [Rows],
    STR((Row_Count/@totalRows)*100 ,4 ,2) Row_Percents,
    CAST(SUBSTRING(Table_Size,1,LEN(Table_Size)-2) as bigint) Reserved,
    STR((CAST(SUBSTRING(Table_Size,1,LEN(Table_Size)-2) as real)/@totalReserved)*100 , 4, 2) Reserved_Percents,
    CAST(SUBSTRING(Data_Space_Used,1,LEN(Data_Space_Used)-2) as bigint) Data ,
    CAST(SUBSTRING(Index_Space_Used,1,LEN(Index_Space_Used)-2) as bigint) IndexSize,
    CAST(SUBSTRING(Unused_Space,1,LEN(Unused_Space)-2) as bigint) Unused
FROM
    @TempTableData
where Row_Count > 0
ORDER BY Reserved DESC
