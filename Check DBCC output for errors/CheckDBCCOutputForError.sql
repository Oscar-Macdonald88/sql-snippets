---------------------------------------------------------------------------------
-- Overview:
-- ---------
-- Reads a provided DBCC_All_DB.txt file and checks for the following:
--  Allocation Errors
--  Consistency Errors
--  DBCC execution completed
--
-- Changes:
-- --------
--
-- Date:		Who:	Details:
-- -----------	----	----------------------------------------------------
-- 06-July-2018 OM      Initial script creation
-- 10-July-2018	OM		Added feedback for error search results
-- 23-Aug-2018	OM		Changed script to run PowerShell command instead of using T-SQL (bulk-load issue)
-- 29-Aug-2018	OM		Added commit to end of transaction. Added output condition if no errors are found.
-- 29-Aug-2018	OM		Added option to check multiple files
-- 11-Sep-2018	OM		Put the @PowerShellCommand variable onto multiple lines, for ease of editing and reviewing.
-- 19-Sep-2018	OM		Added extra functionality - PowerShellCommand now lists all files matching search criteria
---------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- SET Parameters
--------------------------------------------------------------------------------
set nocount on
set arithabort on -- query might experience overflow

begin try
	begin tran

		--------------------------------------------------------------------------------
		-- Declare Variables
		--------------------------------------------------------------------------------
		-- Enter path to file or directory that contains multiple DBCC_All_DB files
		-- for multiple files, make sure each file has 'DBCC_All_DB' somewhere in the file name.
		declare @DAB_Path varchar(255) = 'D:\testDBCC\';
		declare @Server nvarchar(128) = CONVERT(nvarchar(128), ISNULL(SERVERPROPERTY('ServerName'), ''));
		declare @PowerShellCommand varchar(8000) = 'powershell.exe -Command $DBCCPath = ''' + @DAB_Path + ''';';
		set @PowerShellCommand = @PowerShellCommand + '$GlobalErrorFound = $false;';
		set @PowerShellCommand = @PowerShellCommand + 'if(Test-Path -Path $DBCCPath){'
			set @PowerShellCommand = @PowerShellCommand + '$DABFiles = Get-ChildItem -Path $DBCCPath''*DBCC_All_DB*.txt'' -Name;';
			set @PowerShellCommand = @PowerShellCommand + 'if($DABFiles.Length -gt 0){';
				set @PowerShellCommand = @PowerShellCommand + 'Write-Host ''Files found:'';';
				set @PowerShellCommand = @PowerShellCommand + 'foreach($DBCCResult in $DABFiles){';
					set @PowerShellCommand = @PowerShellCommand + 'Write-Host $DBCCResult;';
					set @PowerShellCommand = @PowerShellCommand + '$LocalErrorFound = $false;';
					set @PowerShellCommand = @PowerShellCommand + '$DBCCOutput = Get-Content -Path $DBCCPath$DBCCResult;';
					set @PowerShellCommand = @PowerShellCommand + '$DBCCResults = $DBCCOutput "|" Select-String -Pattern ''CHECKDB found'';';
					set @PowerShellCommand = @PowerShellCommand + '$DBCCErrors = @();';
					set @PowerShellCommand = @PowerShellCommand + 'foreach($row in $DBCCResults){';
						set @PowerShellCommand = @PowerShellCommand + 'if($row.Line "|" Select-String -Pattern ''0 allocation errors and 0'' -Quiet -NotMatch){';
							set @PowerShellCommand = @PowerShellCommand + '$DBCCErrors += ,$row.Line;';
							set @PowerShellCommand = @PowerShellCommand + '$LocalErrorFound = $true;'
							set @PowerShellCommand = @PowerShellCommand + '$GlobalErrorFound = $true;}}';
					set @PowerShellCommand = @PowerShellCommand + '$ServerName =  Select-String -Pattern ''\[.*\] '' -InputObject $DBCCOutput[2];';
					set @PowerShellCommand = @PowerShellCommand + '$EOFFound = $false;';
					set @PowerShellCommand = @PowerShellCommand + 'for($i = $DBCCOutput.Length; $i -ge $DBCCOutput.Length - 2; $i--){';
						set @PowerShellCommand = @PowerShellCommand + 'if($DBCCOutput[$i] "|" Select-String -Pattern ''DBCC execution completed. If DBCC printed error messages, contact your system administrator.'' -Quiet ){';
							set @PowerShellCommand = @PowerShellCommand + '$EOFFound = $true;}}';
					set @PowerShellCommand = @PowerShellCommand + 'if( -Not $EOFFound -Or $LocalErrorFound){';
						set @PowerShellCommand = @PowerShellCommand + 'Write-Host ''Errors were found in the ''$DBCCResult'' file'';'
						set @PowerShellCommand = @PowerShellCommand + 'Write-Host $ServerName;';
						set @PowerShellCommand = @PowerShellCommand + 'if( -Not $EOFFound){';
							set @PowerShellCommand = @PowerShellCommand + 'Write-Host ''End of file not found. This may mean that the DBCC check was prematurely interrupted. Please check the result of DBCC job or error log'';}';
						set @PowerShellCommand = @PowerShellCommand + 'if($LocalErrorFound){';
							set @PowerShellCommand = @PowerShellCommand + 'foreach($DBCCError in $DBCCErrors){';
								set @PowerShellCommand = @PowerShellCommand + 'Write-Host $DBCCError;}}';
						set @PowerShellCommand = @PowerShellCommand + 'Write-Host `n}}';
				set @PowerShellCommand = @PowerShellCommand + 'if( -Not $GlobalErrorFound){';
					set @PowerShellCommand = @PowerShellCommand + 'Write-Host ''No errors were found in the DBCC output files'';}}';
			set @PowerShellCommand = @PowerShellCommand + 'else{';
				set @PowerShellCommand = @PowerShellCommand + 'Write-Host ''No DBCC_All_DB.txt files found in '' $DBCCPath ''. Please check your path variable and the names of the files. They should include DBCC_All_DB in the file name and be text files.'';}}';
		set @PowerShellCommand = @PowerShellCommand + 'else{';
			set @PowerShellCommand = @PowerShellCommand + 'Write-Host $DBCCPath '' was not found. Please check your path and try again''}';;

		--------------------------------------------------------------------------------
		-- Begin
		--------------------------------------------------------------------------------
		--Ensure that DAB_path has been set
		if @DAB_Path = ''
		begin
			print '@DAB_Path is empty. Please enter a value for @DAB_Path';
		end
		else
		begin
			--
			exec master..xp_cmdshell @PowerShellCommand;
		end
	commit
end try

begin catch
	select ERROR_MESSAGE() as 'Try-Catch triggered, rolling back transaction';

	if @@TRANCOUNT > 0
		rollback
end catch
