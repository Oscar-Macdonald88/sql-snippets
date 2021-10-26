$DBCCPath = ''' + @DAB_Path + ''';
$GlobalErrorFound = $false;
if(Test-Path -Path $DBCCPath)
{
    $DABFiles = Get-ChildItem -Path $DBCCPath''*DBCC_All_DB*.txt'' -Name;
    if($DABFiles.Length -gt 0)
    {
        Write-Host ''Files found:'';
        foreach($DBCCResult in $DABFiles)
        {
            Write-Host $DBCCResult;
            $LocalErrorFound = $false;
            $DBCCOutput = Get-Content -Path $DBCCPath$DBCCResult;
            $DBCCResults = $DBCCOutput "|" Select-String -Pattern ''CHECKDB found'';
            $DBCCErrors = @();
            foreach($row in $DBCCResults)
            {
                if($row.Line "|" Select-String -Pattern ''0 allocation errors and 0'' -Quiet -NotMatch)
                {
                    $DBCCErrors += ,$row.Line;
                    $LocalErrorFound = $true;
                    $GlobalErrorFound = $true;
                }
            }
            $ServerName =  Select-String -Pattern ''\[.*\] '' -InputObject $DBCCOutput[2];
            $EOFFound = $false;
            for($i = $DBCCOutput.Length; $i -ge $DBCCOutput.Length - 2; $i--)
            {
                if($DBCCOutput[$i] "|" Select-String -Pattern ''DBCC execution completed. If DBCC printed error messages, contact your system administrator.'' -Quiet )
                {
                    $EOFFound = $true;
                }
            }
            if( -Not $EOFFound -Or $LocalErrorFound)
            {
                Write-Host ''Errors were found in the ''$DBCCResult'' file'';
                Write-Host $ServerName;
                if( -Not $EOFFound)
                {
                    Write-Host ''End of file not found. This may mean that the DBCC check was prematurely interrupted. Please check the result of DBCC job or error log'';
                }
                if($LocalErrorFound)
                {
                    foreach($DBCCError in $DBCCErrors)
                    {
                        Write-Host $DBCCError;
                    }
                }
                Write-Host `n
            }
        }
        if( -Not $GlobalErrorFound)
        {
            Write-Host ''No errors were found in the DBCC output files'';
        }
    }
    else
    {
        Write-Host ''No DBCC_All_DB.txt files found in '' $DBCCPath ''. Please check your path variable and the names of the files. They should include DBCC_All_DB in the file name and be text files.''
    }
}
else
{
    Write-Host $DBCCPath '' was not found. Please check your path and try again''
}