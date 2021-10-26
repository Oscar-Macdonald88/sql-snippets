$DBCCPath = 'D:\testDBCC\';
# Make sure the path exists
if(Test-Path -Path $DBCCPath)
{
    # Find all files that include 'DBCC_All_DB' in the file name and put them into a list.
    $DABFiles = Get-ChildItem -Path $DBCCPath '*DBCC_All_DB*.txt' -Name;
    # Used as feedback if no errors were found.
    $GlobalErrorFound = $false;
    # go through each file found and check the contents
    if($DABFiles.Length -gt 0)
    {
        Write-Host 'Files found:'
        foreach($DBCCResult in $DABFiles)
        {
            Write-Host $DBCCResult;
            $LocalErrorFound = $false;
            # adds the filename to the path for the full path, and reads the contents
            $DBCCOutput = Get-Content -Path $DBCCPath$DBCCResult;
            # Search for 'CHECKDB found' lines in the results
            $DBCCResults = $DBCCOutput | Select-String -Pattern 'CHECKDB found';
            $DBCCErrors = @(); # create an empty list
            foreach($row in $DBCCResults)
            {
                # if the string doesn't match '0 allocation errors and 0' then there were allocation or consistency errors.
                if($row.Line | Select-String -Pattern '0 allocation errors and 0' -Quiet -NotMatch)
                {
                    $DBCCErrors += ,$row.Line; #append the text of the row to the error list.
                    $LocalErrorFound = $true;
                    $GlobalErrorFound = $true;
                }
            }

            # server name is found on index 2.
            $ServerName =  Select-String -Pattern '\[.*\] ' -InputObject $DBCCOutput[2];


            # make sure the end of the file includes the execution confirmed message.
            # most of the time the last line is \n, so we need to check the last two lines
            $EOFFound = $false;
            for($i = $DBCCOutput.Length; $i -ge $DBCCOutput.Length - 2; $i--)
            {
                if($DBCCOutput[$i] | Select-String -Pattern 'DBCC execution completed. If DBCC printed error messages, contact your system administrator.' -Quiet )
                {
                    $EOFFound = $true;
                }
            }

            # Show any errors if they have been found
            if( -Not $EOFFound -Or $LocalErrorFound)
            {
                Write-Host 'Errors were found in the '$DBCCResult' file';
                Write-Host $ServerName;
                if( -Not $EOFFound)
                {
                    Write-Host 'End of file not found. This may mean that the DBCC check was prematurely interrupted. Please check the result of DBCC job or error log';
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
            Write-Host 'No errors were found in the DBCC output files';
        }
    }
    else
    {
        Write-Host 'No DBCC_All_DB.txt files found in ' $DBCCPath '. Please check your path variable and the names of the files. They should include DBCC_All_DB in the file name and be text files.'
    }
}
else
{
    Write-Host $DBCCPath ' was not found. Please check your path and try again'
}
