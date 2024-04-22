USE [SQLMSP]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [msp].[ReassignInventoryContact]
	@CustomerCode nvarchar(10)
	,@OldContactName nvarchar(128)
	,@NewContactName nvarchar(128)
	,@ForceRemove bit = 0
AS
BEGIN
	DECLARE @CustomerId uniqueidentifier;
	DECLARE @InstanceId uniqueidentifier;
	DECLARE @OldContactId uniqueidentifier;
	DECLARE @NewContactId uniqueidentifier;
	DECLARE @CustomerContactTypeId int;
	DECLARE @ErrorMsg nvarchar(MAX) = NULL;
	DECLARE @URL nvarchar(131) = 'See https://servian.atlassian.net/wiki/spaces/EIT/pages/111659810817/Process+-+Updating+Customer+Contacts+on+CERBERUS for details.'

	SELECT @CustomerContactTypeId = CustomerContactTypeId
	FROM msp.CustomerContactType
	WHERE 1=1
		AND CustomerContactType = 'LEGACY-DEACTIVATED';


	/* Check if the customer exists */
	IF NOT EXISTS (SELECT *
	FROM msp.Customer
	WHERE CustomerCode = @CustomerCode)
	BEGIN
		SET @ErrorMsg = 'Error: CustomerCode = ' + @CustomerCode + ' does not exist. ' + @URL;
		THROW 50000, @ErrorMsg, 1
		RETURN;
	END;
	ELSE
	BEGIN
		SELECT @CustomerId = CustomerId
		FROM msp.Customer
		WHERE CustomerCode = @CustomerCode;
	END;

	/* Check if the old contact exists */
	IF NOT EXISTS (SELECT *
	FROM msp.CustomerContact
	WHERE CustomerId = @CustomerId AND ContactName = @OldContactName)
	BEGIN
		SET @ErrorMsg = 'Error: CustomerCode = ' + @CustomerCode + ', ContactName = ' + @OldContactName + ' does not exist. ' + @URL;
		THROW 50000, @ErrorMsg, 1
		RETURN;
	END;
	ELSE
	BEGIN
		SELECT @OldContactId = ContactId
		FROM msp.CustomerContact
		WHERE CustomerId = @CustomerId
			and ContactName = @OldContactName;
	END;

	/* Check if the new contact exists */
	IF NOT EXISTS (SELECT *
	FROM msp.CustomerContact
	WHERE CustomerId = @CustomerId AND ContactName = @NewContactName)
	BEGIN
		SET @ErrorMsg = 'Error: CustomerCode = ' + @CustomerCode + ', ContactName = ' + @NewContactName + ' does not exist. ' + @URL;
		THROW 50000, @ErrorMsg, 1
		RETURN;
	END;
	ELSE
	BEGIN
		SELECT @NewContactId = ContactId
		FROM msp.CustomerContact
		WHERE CustomerId = @CustomerId
			and ContactName = @NewContactName;
	END;

	/* Check if the new contact already maps to the inventory */
	IF NOT EXISTS (
		SELECT *
		FROM msp.InventoryContactMap
		WHERE CustomerId = @CustomerId
			AND InstanceId = @InstanceId
			AND ContactId = @NewContactId
			AND CustomerContactTypeId = @CustomerContactTypeId
		) AND @ForceRemove = 1
	BEGIN
		BEGIN TRY
		
			/* Set the new contact to match the old contact */
			drop table if exists #ReassignTable
			 select
			[InventoryContactMapId]
			, [CustomerCode]
			, [InstanceName]
			, [ContactName]
			, [CustomerContactTypeId]
			INTO #ReassignTable
			FROM [SQLMSP].[msp].[vInventoryContactMap]
			WHERE [ContactId] = @OldContactId;
			DECLARE @RowCount INT = (SELECT COUNT(*) FROM #ReassignTable); 
			DECLARE @ReassignedInstanceName nvarchar(128);
			DECLARE @ContactName nvarchar(128);
			DECLARE @ReassignCustomerContactTypeId int;
			WHILE @RowCount > 0 
			BEGIN
				SELECT @ReassignedInstanceName=[InstanceName], @ReassignCustomerContactTypeId=[CustomerContactTypeId]
				FROM #ReassignTable
				ORDER BY [InventoryContactMapId] DESC OFFSET @RowCount - 1 ROWS FETCH NEXT 1 ROWS ONLY;
				select @CustomerCode, @ReassignedInstanceName, @NewContactName, @ReassignCustomerContactTypeId
				SET @RowCount -= 1;
			END
			/*Once complete, remove the old contact from all instances */
			select @CustomerCode, @OldContactName, @ForceRemove
		END TRY
		BEGIN CATCH
			THROW;
		END CATCH;
	END;
	ELSE
	BEGIN
		SET @ErrorMsg = 'Error: Contact = ' + @ContactName + ' already mapped to instances try again with another ContactTypeId or update invidiual instances with [msp].[UpdateMapInventoryContact]. ' + @URL;
		THROW 50000, @ErrorMsg, 1
		RETURN;
	END;

END;

/*
SELECT * FROM msp.vInventoryContact WHERE CustomerCode = 'Servian'

EXEC msp.AddCustomerContact @CustomerCode = 'Servian'
	, @ContactName = 'Kevin Ha'
	, @ContactEmail = 'kevin.ha@servian.com'
	, @ContactPhone = '+64273536387'
	, @ContactJobTitle = 'Team Leader'
	, @Comments = 'SQL Team Lead, test entry.'
	, @IsActive = 1
	, @IsDefaultContact = 1;

EXEC msp.DeactivateCustomerContact @CustomerCode = 'Servian';
	, @ContactName = 'Kevin Ha'

UPDATE [SQLMSP].[msp].[CustomerContact]
SET IsActive = 1
WHERE ContactId = 'FBE3776F-43FC-49E3-97EC-ADB787B534BA';

EXEC [msp].[AddInventoryContact] @CustomerCode = 'Servian'
	, @InstanceName = 'HYDRAA'
	, @ContactName = 'Kevin Ha'
	, @CustomerContactTypeId = 1;

EXEC [msp].[UpdateInventoryContact] 
	@CustomerCode = 'Servian'
	, @InstanceName = 'HYDRA'
	, @ContactName = 'Kevin Ha'
	, @CustomerContactTypeId = 1
	--, @ForceUpdate = 1;

EXEC [msp].[AddInventoryContactAllInstances] 
	@CustomerCode = 'Servian'
	, @ContactName = 'Kevin Ha'
	, @CustomerContactTypeId = 1
	--, @ForceAdd = 1;

EXEC [msp].[UpdateInventoryContactAllInstances] 
	@CustomerCode = 'Servian'
	, @ContactName = 'Kevin Ha'
	, @CustomerContactTypeId = 1
	--, @ForceUpdate = 1;

EXEC [msp].[RemoveInventoryContact] 
	@CustomerCode = 'Servian'
	, @InstanceName = 'HYDRA'
	, @ContactName = 'Kevin Ha'
	, @ForceRemove = 1
*/
GO


