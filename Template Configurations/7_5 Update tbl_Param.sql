declare
@CustCode varchar(255)        = ''
, @CustomerName varchar(255)    = ''
, @Domain varchar(255)          = ''
, @ServerMake varchar(255)      = ''
, @ServerModel varchar(255)     = ''
, @SLALevel varchar(255)        = ''
, @SSLTeam varchar(255)         = 'DBATEAM3'

, @SQLData varchar(255)         = ''
, @SQLLogs varchar(255)         = ''
, @SQLDataDumps varchar(255)    = ''
, @SQLLogDumps varchar(255)     = ''
, @SQLReportsDir varchar(255)   = ''
, @DropFolderDir varchar(255)   = ''

-- DON'T FORGET TO UPDATE EXTENSION FLAGS: 24x7, DR, etc!

begin tran
update SSLDBA..tbl_Param
set TextValue = @CustCode 
where Param = 'CustCode'
update SSLDBA..tbl_Param
set TextValue = @CustomerName
where Param = 'CustomerName'
update SSLDBA..tbl_Param
set TextValue = @Domain
where Param = 'DomainName'
update SSLDBA..tbl_Param
set TextValue = @ServerMake
where Param = 'ServerMake'
update SSLDBA..tbl_Param
set TextValue = @ServerModel
where Param = 'ServerModel'
update SSLDBA..tbl_Param
set TextValue = @SLALevel
where Param = 'SLALevel'
update SSLDBA..tbl_Param
set TextValue = @SSLTeam
where Param = 'SSLTeam'
update SSLDBA..tbl_Param
set TextValue = @SQLData
where Param = 'SQLData'
update SSLDBA..tbl_Param
set TextValue = @SQLLogs
where Param = 'SQLLogs'
update SSLDBA..tbl_Param
set TextValue = @SQLDataDumps
where Param = 'SQLDataDumps'
update SSLDBA..tbl_Param
set TextValue = @SQLLogDumps
where Param = 'SQLLogDumps'
update SSLDBA..tbl_Param
set TextValue = @SQLReportsDir
where Param = 'SQLReportsDir'
update SSLDBA..tbl_Param
set TextValue = @DropFolderDir
where Param = 'DropFolderDir'
COMMIT
select * from SSLDBA..tbl_Param
