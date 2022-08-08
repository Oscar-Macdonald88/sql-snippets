Declare @weekDay Table (
      mask      int
    , maskValue varchar(32)
);

Insert Into @weekDay
Select 1, 'Sunday'  Union All
Select 2, 'Monday'  Union All
Select 4, 'Tuesday'  Union All
Select 8, 'Wednesday'  Union All
Select 16, 'Thursday'  Union All
Select 32, 'Friday'  Union All
Select 64, 'Saturday';

With myCTE
As(
    Select sched.name As 'scheduleName'
        , sched.schedule_id
        , jobsched.job_id
        , Case When sched.freq_type = 1 Then 'Once' 
            When sched.freq_type = 4 
                And sched.freq_interval = 1 
                    Then 'Daily'
            When sched.freq_type = 4 
                Then 'Every ' + Cast(sched.freq_interval As varchar(5)) + ' days'
            When sched.freq_type = 8 Then 
                Replace( Replace( Replace(( 
                    Select maskValue 
                    From @weekDay As x 
                    Where sched.freq_interval & x.mask <> 0 
                    Order By mask For XML Raw)
                , '"/><row maskValue="', ', '), '<row maskValue="', ''), '"/>', '') 
                + Case When sched.freq_recurrence_factor <> 0 
                        And sched.freq_recurrence_factor = 1 
                            Then '; weekly' 
                    When sched.freq_recurrence_factor <> 0 Then '; every ' 
                + Cast(sched.freq_recurrence_factor As varchar(10)) + ' weeks' End
            When sched.freq_type = 16 Then 'On day ' 
                + Cast(sched.freq_interval As varchar(10)) + ' of every '
                + Cast(sched.freq_recurrence_factor As varchar(10)) + ' months' 
            When sched.freq_type = 32 Then 
                Case When sched.freq_relative_interval = 1 Then 'First'
                    When sched.freq_relative_interval = 2 Then 'Second'
                    When sched.freq_relative_interval = 4 Then 'Third'
                    When sched.freq_relative_interval = 8 Then 'Fourth'
                    When sched.freq_relative_interval = 16 Then 'Last'
                End + 
                Case When sched.freq_interval = 1 Then ' Sunday'
                    When sched.freq_interval = 2 Then ' Monday'
                    When sched.freq_interval = 3 Then ' Tuesday'
                    When sched.freq_interval = 4 Then ' Wednesday'
                    When sched.freq_interval = 5 Then ' Thursday'
                    When sched.freq_interval = 6 Then ' Friday'
                    When sched.freq_interval = 7 Then ' Saturday'
                    When sched.freq_interval = 8 Then ' Day'
                    When sched.freq_interval = 9 Then ' Weekday'
                    When sched.freq_interval = 10 Then ' Weekend'
                End
                + Case When sched.freq_recurrence_factor <> 0 
                        And sched.freq_recurrence_factor = 1 Then '; monthly'
                    When sched.freq_recurrence_factor <> 0 Then '; every ' 
                + Cast(sched.freq_recurrence_factor As varchar(10)) + ' months' End
            When sched.freq_type = 64 Then 'StartUp'
            When sched.freq_type = 128 Then 'Idle'
          End As 'frequency'
        , IsNull('Every ' + Cast(sched.freq_subday_interval As varchar(10)) + 
            Case When sched.freq_subday_type = 2 Then ' seconds'
                When sched.freq_subday_type = 4 Then ' minutes'
                When sched.freq_subday_type = 8 Then ' hours'
            End, 'Once') As 'subFrequency'
        , Replicate('0', 6 - Len(sched.active_start_time)) 
            + Cast(sched.active_start_time As varchar(6)) As 'startTime'
        , Replicate('0', 6 - Len(sched.active_end_time)) 
            + Cast(sched.active_end_time As varchar(6)) As 'endTime'
        , Replicate('0', 6 - Len(jobsched.next_run_time)) 
            + Cast(jobsched.next_run_time As varchar(6)) As 'nextRunTime'
        , Cast(jobsched.next_run_date As char(8)) As 'nextRunDate'
    From msdb.dbo.sysschedules As sched
    Join msdb.dbo.sysjobschedules As jobsched
        On sched.schedule_id = jobsched.schedule_id
    Where sched.enabled = 1
)
SELECT
distinct c.Name AS ReportName
, J.name as job_name
, sched.frequency
    , sched.subFrequency
    , SubString(sched.startTime, 1, 2) + ':' 
        + SubString(sched.startTime, 3, 2) + ' - ' 
        + SubString(sched.endTime, 1, 2) + ':' 
        + SubString(sched.endTime, 3, 2) 
        As 'scheduleTime' -- HH:MM
    , SubString(sched.nextRunDate, 1, 4) + '/' 
        + SubString(sched.nextRunDate, 5, 2) + '/' 
        + SubString(sched.nextRunDate, 7, 2) + ' ' 
        + SubString(sched.nextRunTime, 1, 2) + ':' 
        + SubString(sched.nextRunTime, 3, 2) As 'nextRunDate',
Convert(XML,[ExtensionSettings]).value('(//ParameterValue/Value[../Name="TO"])[1]','nvarchar(50)') as [To]
,Convert(XML,[ExtensionSettings]).value('(//ParameterValue/Value[../Name="CC"])[1]','nvarchar(50)') as [CC]
,Convert(XML,[ExtensionSettings]).value('(//ParameterValue/Value[../Name="RenderFormat"])[1]','nvarchar(50)') as [Render Format]
,Convert(XML,[ExtensionSettings]).value('(//ParameterValue/Value[../Name="Subject"])[1]','nvarchar(50)') as [Subject]
,[LastStatus]
,[LastRunTime]
FROM 
 dbo.[Catalog] c
INNER JOIN dbo.[Subscriptions] S ON c.ItemID = S.Report_OID
INNER JOIN dbo.ReportSchedule R ON S.SubscriptionID = R.SubscriptionID
INNER JOIN msdb.dbo.sysjobs J ON Convert(nvarchar(128),R.ScheduleID) = J.name
INNER JOIN myCTE as sched on J.job_id = sched.job_id