use SSLDBA;
go
begin tran
	update tbl_JobHistDetails
	set Duration_alarm = 600, Auto_stop = 'Y' where Job_name = N'SSL_Weekly_Job';
	update tbl_JobHistDetails
	set Duration_alarm = 200, Auto_stop = 'Y' where Job_name = N'SSL_Monthly_Report';
	update tbl_JobHistDetails
	set Duration_alarm = 7, Auto_stop = 'Y' where Job_name = N'SSL_SendDashboardData';
	update tbl_JobHistDetails
	set Duration_alarm = 600, Auto_stop = 'Y' where Job_name = N'SSL_Optimise_Sunday';
	update tbl_JobHistDetails
	set Duration_alarm = 180, Auto_stop = 'Y' where Job_name = N'SSL_Optimise_GenMasterList';
commit

select * from tbl_JobHistDetails order by Job_name