CREATE TABLE #errorLog (LogDate DATETIME, ProcessInfo VARCHAR(64), [Text] VARCHAR(MAX));

INSERT INTO #errorLog
EXEC sp_readerrorlog -- specify the log number or use nothing for active error log

SELECT * 
FROM #errorLog a
WHERE EXISTS (SELECT * 
              FROM #errorLog b
              WHERE [Text] like '%Severity: 19%'
                AND a.LogDate = b.LogDate
                AND a.ProcessInfo = b.ProcessInfo)
OR EXISTS (SELECT * 
              FROM #errorLog b
              WHERE [Text] like '%Severity: 20%'
                AND a.LogDate = b.LogDate
                AND a.ProcessInfo = b.ProcessInfo)
OR EXISTS (SELECT * 
              FROM #errorLog b
              WHERE [Text] like '%Severity: 21%'
                AND a.LogDate = b.LogDate
                AND a.ProcessInfo = b.ProcessInfo)
ORDER BY a.LogDate DESC

DROP TABLE #errorLog;