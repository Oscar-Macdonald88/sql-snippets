-- https://sqlkover.com/exporting-environment-variables-out-of-the-ssis-catalog/

SELECT
    v.[name]
   ,v.[type]
   ,v.[value]
   ,Script = 'EXEC [SSISDB].[catalog].[create_environment_variable]
       @variable_name=''' + CONVERT(NVARCHAR(250), v.name) + '''
      ,@sensitive=0
      ,@description=''''
      ,@environment_name=''myenv''
      ,@folder_name=''myfolder''
      ,@value='
             + IIF(v.type = 'String'
                ,N'N''' + CONVERT(NVARCHAR(500), v.value) + ''''
                ,CONVERT(NVARCHAR(500), v.value)
                )
             + '
      ,@data_type=N''' + v.type + ''';
'
FROM    [SSISDB].[catalog].[environments]          e
JOIN [SSISDB].[catalog].[folders]               f ON f.[folder_id]      = e.[folder_id]
JOIN [SSISDB].[catalog].[environment_variables] v ON e.[environment_id] = v.[environment_id]
WHERE   f.[name] = N'FolderName' -- Object Explorer -> Server -> Integration Services Catalogs -> SSIS -> FolderName
    AND e.[name] = N'EnvName'; -- Eg usually one of PROD, DEV, UAT, TEST etc.


/*
You can also set or delete existing variables:
[SSISDB].[catalog].[create_environment_variable]
[SSISDB].[catalog].[delete_environment_variable]
[SSISDB].[catalog].[set_environment_variable_value]
*/