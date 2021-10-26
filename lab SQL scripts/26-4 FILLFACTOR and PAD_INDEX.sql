-- FILLFACTOR and PAD_INDEX
-- when creating / altering a table, you have the option to set these variables.
ALTER TABLE SchemaName.TableName
ADD CONSTRAINT PK_TableName_IDName
PRIMARY KEY CLUSTERED
(
    IDName ASC
) WITH (PAD_INDEX = ON, FILLFACTOR = 70);
GO

-- FILLFACTOR leaves space in index leaf-level pages for new data to avoid page splits if it might be needed.
-- It does prevent page splits, but storage space (and therefore performance) isn't optimized.
-- PAD_INDEX uses the value specified in FILLFACTOR for the intermediate pages of the index
