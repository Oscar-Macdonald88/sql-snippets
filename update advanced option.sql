

DECLARE @ShowAdvancedOptionsWasEnabled BIT;
DECLARE @AdvancedOptionName nvarchar(255) = '' -- replace with the option you want like 'optimize for ad hoc workloads'
select name, value FROM sys.configurations
where name in (@AdvancedOptionName,'show advanced options')
if (select CASE WHEN CAST(value AS INT) = 1 THEN 1 ELSE 0 END FROM sys.configurations
where name = @AdvancedOptionName) = 0
begin

    -- Check current state of 'show advanced options'
    SELECT @ShowAdvancedOptionsWasEnabled = CASE WHEN CAST(value AS INT) = 1 THEN 1 ELSE 0 END
    FROM sys.configurations
    WHERE name = 'show advanced options';

    -- If not enabled, enable it
    IF @ShowAdvancedOptionsWasEnabled = 0
    BEGIN
        EXEC sp_configure 'show advanced options', 1;
        RECONFIGURE;
    END

    -- Enable the advanced feature
    EXEC sp_configure @AdvancedOptionName, 1;
    RECONFIGURE;

    -- If 'show advanced options' was originally disabled, revert it
    IF @ShowAdvancedOptionsWasEnabled = 0
    BEGIN
        EXEC sp_configure 'show advanced options', 0;
        RECONFIGURE;
    END
end
select name, value FROM sys.configurations
where name in (@AdvancedOptionName,'show advanced options')