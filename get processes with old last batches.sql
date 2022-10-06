declare @minutes int = 30

if exists (
    select top (1) 1
    from sys.sysprocesses
    where datediff(minute, last_batch, getdate()) > @minutes
        and spid > 51
) begin
DECLARE @SERVERNAME nvarchar(255);
select @SERVERNAME = SERVERPROPERTY('servername');
DECLARE @tableHTML  NVARCHAR(MAX) ; 
SET @tableHTML = 
    N'<H1>The following SPIDs on ' + @SERVERNAME + ' have a last batch that was older than 30 minutes. Please review</H1>'+
    N'<table border="1">' +
    N'<tr><th>spid</th>' +  
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
    N'<th>hostname</th>' +
    N'<th>program_name</th>' +
    N'<th>cmd</th>' +
    N'<th>nt_username</th>' +
    N'<th>login_time</th>' +
    N'<th>st.tex</th></tr>' +
    CAST ( ( SELECT
                    td = ISNULL(spid, 0),       '',
                    td = ISNULL(blocked, 0),       '',
                    td = ISNULL(waittime, 0),       '',
                    td = ISNULL(lastwaittype, ''),       '',
                    td = ISNULL(waitresource, ''),       '',
                    td = ISNULL(db_name(p.dbid), ''),       '',
                    td = ISNULL(cpu, 0),       '',
                    td = ISNULL(physical_io, 0),       '',
                    td = ISNULL(memusage, 0),       '',
                    td = login_time,       '',
                    td = last_batch,       '',
                    td = ISNULL(open_tran, 0),       '',
                    td = ISNULL(status, ''),       '',
                    td = ISNULL(SUSER_SNAME(sid), ''),       '',
                    td = ISNULL(hostname, ''),       '',
                    td = ISNULL(program_name, ''),       '',
                    td = ISNULL(cmd, ''),       '',
                    td = ISNULL(nt_username, ''),       '',
                    td = login_time,       '',
                    td = ISNULL(st.text, '')
                    from sys.sysprocesses p
                        CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS st
                    where datediff(minute, last_batch, getdate()) > @minutes
                        and spid > 51
              FOR XML PATH('tr'), TYPE   
    ) AS NVARCHAR(MAX) ) +  
    N'</table>' ; 
EXEC msdb.dbo.sp_send_dbmail
    @profile_name = 'EIT_Maintenance',  
    @recipients = 'oscar.macdonald@servian.com',  
    @body = @tableHTML,
    @body_format = 'HTML',
    @execute_query_database = 'master',
    @subject = @SERVERNAME + ': Queries with the last batch older than 30 minutes'
end

