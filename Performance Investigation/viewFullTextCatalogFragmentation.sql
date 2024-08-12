-- from https://www.sqlshack.com/hands-full-text-search-sql-server/
WITH FragmentationDetails
AS (
	SELECT 
		table_id,
        COUNT(*) AS FragmentsCount,
        CONVERT(DECIMAL(9,2), SUM(data_size/(1024.*1024.))) AS IndexSizeMb,
        CONVERT(DECIMAL(9,2), MAX(data_size/(1024.*1024.))) AS largest_fragment_mb
    FROM sys.fulltext_index_fragments
    GROUP BY table_id
)
SELECT 
	DB_NAME()				AS DatabaseName,
	ftc.fulltext_catalog_id AS CatalogId, 
	ftc.[name]				AS CatalogName, 
	fti.change_tracking_state AS ChangeTrackingState,
    fti.object_id				AS BaseObjectId, 
	QUOTENAME(OBJECT_SCHEMA_NAME(fti.object_id)) + '.' + QUOTENAME(OBJECT_NAME(fti.object_id)) AS BaseObjectName,
	f.IndexSizeMb		    AS IndexSizeMb, 
	f.FragmentsCount    	AS FragmentsCount, 
	f.largest_fragment_mb   AS IndexLargestFragmentMb,
	f.IndexSizeMb - f.largest_fragment_mb AS IndexFragmentationSpaceMb,
    CASE
		WHEN f.IndexSizeMb = 0 THEN 0
		ELSE 
			100.0 * (f.IndexSizeMb - f.largest_fragment_mb) / f.IndexSizeMb
	END AS IndexFragmentationPct
FROM 
	sys.fulltext_catalogs ftc
JOIN 
	sys.fulltext_indexes fti
ON 
	fti.fulltext_catalog_id = ftc.fulltext_catalog_id
JOIN FragmentationDetails f
    ON f.table_id = fti.object_id
;