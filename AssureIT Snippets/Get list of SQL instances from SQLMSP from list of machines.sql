WITH cte
AS (
    SELECT CASE 
            WHEN instancename LIKE '%\%'
                THEN left(instancename, charindex('/', instancename) - 1)
            ELSE instancename
            END AS machinename,
        instancename,
        IsActive
    FROM msp.vInventory
    )
SELECT *
FROM cte
WHERE InstanceName IN () -- put in list of machine names.