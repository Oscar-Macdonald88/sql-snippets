declare @minutes integer;
declare @databaseName NVARCHAR(255);
set @minutes = 30; --default
set @databaseName = 'sds1234' -- make sure to set this before deploying

if exists (select top 1 1 from sys.sysprocesses
where spid > 51
    and status <> 'sleeping'
    and db_name(dbid) = @databaseName
    and DATEDIFF(minute, last_batch, getdate()) > @minutes)
BEGIN
    DECLARE @tableHTML  NVARCHAR(MAX) ;
    DECLARE @serverName NVARCHAR(255);


    SELECT @serverName = @@servername
    
    SET @tableHTML =  
        N'<H1>The following SPIDs on ' + @serverName + ' have a last batch that was older than ' + convert(nvarchar, @minutes) + ' minutes. Please review.</H1>' +
        N'<H2>The purpose of this email is to prevent an outage to SDS. If you are receiving then there is a possibility that a report is being generated against the online database server. Check if all of the gaming machines can still use SDS; if there is an outage please call the Servian on-call DBA or review the below connections to the server and raise an emergency request to restart the offending SDS application.</H2>' +
        N'<table border="1">' +  
        N'<tr>' + 
        N'<th>SPID</th>' +
        N'<th>blocked</th>' + 
        N'<th>waittime</th>' + 
        N'<th>lastwaittype</th>' + 
        N'<th>waitresource</th>' + 
        N'<th>dbname</th>' + 
        N'<th>cpu</th>' + 
        N'<th>physical_io</th>' + 
        N'<th>memusage</th>' + 
        N'<th>login_time</th>' + 
        N'<th>last_batch</th>' + 
        N'<th>open_tran</th>' + 
        N'<th>status</th>' + 
        N'<th>username</th>' +
        N'<th>domainusername</th>' +  
        N'<th>hostname</th>' +
        N'<th>hostprocess</th>' + 
        N'<th>program_name</th>' + 
        N'<th>cmd</th>' + 
        N'<th>st.tex</th>' + 
        N'</tr>' +
        CAST ( ( SELECT 
            td = ISNULL(p.spid, ''),'',
            td = ISNULL(p.blocked, ''),'',
            td = ISNULL(p.waittime, ''),'',
            td = ISNULL(p.lastwaittype, ''),'',
            td = ISNULL(p.waitresource, ''),'',
            td = ISNULL(db_name(p.dbid), ''),'',
            td = ISNULL(p.cpu, ''),'',
            td = ISNULL(p.physical_io, ''),'',
            td = ISNULL(p.memusage, ''),'',
            td = ISNULL(p.login_time, ''),'',
            td = ISNULL(p.last_batch, ''),'',
            td = ISNULL(p.open_tran, ''),'',
            td = ISNULL(p.STATUS, ''),'',
            td = ISNULL(suser_sname(p.sid), ''),'',
            td = ISNULL(p.nt_username, ''),'',
            td = ISNULL(p.hostname, ''),'',
            td = ISNULL(p.hostprocess, ''),'',
            td = ISNULL(p.program_name, ''),'',
            td = ISNULL(p.cmd, ''),'',
            td = ISNULL(t.TEXT, ''),''
        FROM sys.sysprocesses p
        cross apply sys.dm_exec_sql_text(p.sql_handle) t
        where p.spid > 51
        and p.status <> 'sleeping'
        and db_name(p.dbid) = @databaseName
        and DATEDIFF(minute, p.last_batch, getdate()) >= @minutes
                FOR XML PATH('tr'), TYPE   
        ) AS NVARCHAR(MAX) ) +  
        N'</table>' ;  

    declare @fullSubject nvarchar(255)= @servername + ': Queries with the last batch older than 30 minutes'
    EXEC msdb.dbo.sp_send_dbmail @recipients='oscar.macdonald@servian.com',
        @profile_name = 'EIT_Maintenance',
        @subject = @fullSubject,  
        @body = @tableHTML,  
        @body_format = 'HTML' ;
END