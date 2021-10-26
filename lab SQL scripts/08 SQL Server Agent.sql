/*
SQL Server Agent
Basically SQL Server Job Scheduler, including alerting, logging and calendaring.
*/

/* Creating Jobs
SSMS -> Sql Server Agent. Green arrow = enabled. Red square = disabled.
Sql Server Agent -> Jobs (to see jobs)
Rclick Jobs -> new job
Who owns the job determines what the job can do. Best set to sa so only people with access to sa can change it.
Categories are just a way of organizing jobs (sorting by category)
Steps -> New
Type -> T-SQL, PowerShell, Operating system (cmd), Server Integration Services Package (SIS)
Pick database
Enter command
*/