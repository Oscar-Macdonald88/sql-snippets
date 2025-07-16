select tsk.TaskName, tsk.TheCommand, tsk.ScheduleName, sch.NextRun, sch.Enabled, sch.IntervalType, sch.IntervalCount, sch.StartLateSecs
from DBAToolset.dsl.tbl_Task tsk left join DBAToolset.dsl.tbl_Schedule sch on tsk.ScheduleName = sch.ScheduleName
where tsk.TaskName like 'Perform%'
order by [NextRun] desc