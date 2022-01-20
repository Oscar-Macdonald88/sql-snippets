USE EIT_DBA
SELECT TOP (1000)
	[dttm],
	[d_name],
	[FileId],
    [ReadLatency] =
        CASE WHEN [NumberReads] = 0
            THEN 0 ELSE ([IoStallReadMS] / [NumberReads]) END,
    [WriteLatency] =
        CASE WHEN [NumberWrites] = 0
            THEN 0 ELSE ([IoStallWriteMS] / [NumberWrites]) END,
    [Latency] =
        CASE WHEN ([NumberReads] = 0 AND [NumberWrites] = 0)
            THEN 0 ELSE ([IoStallMS] / ([NumberReads] + [NumberWrites])) END,
    --avg bytes per IOP
    [AvgBPerRead] =
        CASE WHEN [NumberReads] = 0
            THEN 0 ELSE ([BytesRead] / [NumberReads]) END,
    [AvgBPerWrite] =
        CASE WHEN [IoStallWriteMS] = 0
            THEN 0 ELSE ([BytesWritten] / [NumberWrites]) END,
    [AvgBPerTransfer] =
        CASE WHEN ([NumberReads] = 0 AND [NumberWrites] = 0)
            THEN 0 ELSE
                (([BytesRead] + [BytesWritten]) /
                ([NumberReads] + [NumberWrites])) END
  FROM [EIT_DBA].[dbo].[EIT_trend_database_io]
  where d_name = 'HEB'
  and FileId = 1
  and dttm > '2022/01/01'