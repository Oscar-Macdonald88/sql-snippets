-- Stage 9 - Queries

-- a) All queries are written in T-SQL
SELECT  Msg 
FROM    tbl_EmailMessage;
GO

-- c)
SELECT  Msg, 
        Subject 
FROM    tbl_EmailMessage 
WHERE   Priority = 'Low';
GO

-- d)
SELECT  em.Msg, 
        em.Subject 
FROM    tbl_EmailMessage AS em 
        INNER JOIN tbl_EmailDistribution AS ed 
        ON em.Msg = ed.Msg 
WHERE   em.Priority = 'Low' 
        AND ed.Operator = 'SQL Services Gold';
GO

-- e)
SELECT  em.Msg, 
        em.Subject 
FROM    tbl_EmailMessage AS em 
        INNER JOIN tbl_EmailDistribution AS ed 
        ON em.Msg = ed.Msg 
WHERE   em.Priority = 'Low' 
        AND ed.Operator = 'SQL Services Gold'
ORDER BY em.Msg DESC;
GO

-- f)
SELECT  em.Msg, 
        COUNT(em.Priority) AS "Messages per priority"
FROM    tbl_EmailMessage AS em 
        INNER JOIN tbl_EmailDistribution AS ed 
        ON em.Msg = ed.Msg
GROUP BY em.Msg, em.Priority
ORDER BY em.Msg DESC;
GO

-- g)
INSERT INTO tbl_EmailMessage
VALUES ('Ima Message', 'README', 'Hahaha you read me', 'High', NULL, 'N', NULL, NULL, 0, 0, 'N', NULL, 'N')
GO

INSERT INTO tbl_EmailDistribution
VALUES ('Ima Message', 'SQL Services Gold', 'N', 'N', 'N', NULL, 'N')
GO

-- f)
BEGIN TRAN
UPDATE tbl_EmailMessage
SET Priority = 'High'
WHERE [Msg] = 'Ima Message'
COMMIT;
GO