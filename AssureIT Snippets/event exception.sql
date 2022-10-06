/*
Sunday -   1 
Monday -   2 
Tuesday -  4 
Wednesday- 8 
Thursday - 16
Friday -   32
Saturday - 64

exclusion is the start/end time of the exclusion window. If the window covers midnight, you'll need to add two exclusions, before and after.
*/
INSERT INTO EIT_DBA.dbo.EIT_monitoring_exclusions_event
(exclusion_code, column_name, exclusion, is_enabled, is_reported, active_weekdays, comments)
VALUES 
(
'HIGH_CPU',
'Event_Time',
'START_HHMM-END_HHMM',
'y', -- Is Enabled
'n', --Is Reported
64,
'OM: DBCCs for INST2 run early on Sunday mornings and use a lot of CPU' --Reason for exclusion
);
GO
SELECT * from EIT_DBA.dbo.EIT_monitoring_exclusions_event