use SSLDBA;
go
begin tran
	update tbl_JobHistDetails
	set DurationAlarm = 600, AutoStop = 'Y' where JobName = N'SSL_Weekly_Job';
	update tbl_JobHistDetails
	set DurationAlarm = 200, AutoStop = 'Y' where JobName = N'SSL_Monthly_Report';
	update tbl_JobHistDetails
	set DurationAlarm = 7, AutoStop = 'Y' where JobName = N'SSL_SendDashboardData';
	update tbl_JobHistDetails
	set DurationAlarm = 600, AutoStop = 'Y' where JobName = N'SSL_Optimise_Sunday';
	update tbl_JobHistDetails
	set DurationAlarm = 180, AutoStop = 'Y' where JobName = N'SSL_Optimise_GenMasterList';
commit

select * from tbl_JobHistDetails order by JobName