USE EIT_DBA
GO

-- Run this to show all drive letters on record
select distinct InstanceName as DriveLetters from dbo.CounterDetails where InstanceName like '%:' and len(instancename) = 2

-- Run this to get the history of the space used and total size of the drive
DECLARE @drive varchar(2)= 'H:' --INSERT DRIVE LETTER WITH COLON HERE

SELECT

	distinct left(dat.CounterDateTime, 10)		AS dttm -- get only one entry per day
	,dat.SecondValueA - dat.FirstValueA			AS [used_mb]
	,dat.SecondValueA							AS [total_mb]
FROM
	dbo.CounterData AS dat
	INNER JOIN dbo.CounterDetails AS det
		ON dat.CounterID = det.CounterID
WHERE
	det.ObjectName      = 'LogicalDisk'
AND det.CounterName     = '% Free Space'
AND det.InstanceName    = @drive
AND substring(dat.CounterDateTime, 10, 14) like '%05:00%' -- Get only the 5am entries

