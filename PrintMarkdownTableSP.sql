CREATE PROC dbo.up_PrintMarkdownTable
    @Query NVARCHAR(500)
AS
BEGIN
    -- Enter queries here (can return multiple result sets)
    CREATE TABLE tmp_QueryToMarkdown 
    INSERT tmp_QueryToMarkdown (EXEC sp_executesql @Query);
    GO
END;
GO