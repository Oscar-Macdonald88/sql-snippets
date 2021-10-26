-- Creating Views
-- A database object referenced in the same way as a table (table-like objects)
-- You can think of Views as virtual tables
-- Views are useful for obscuring complexity of queries or just to hide from others how your query works
USE [Food];
GO
-- A View is essentially a named SELECT
-- When creating a view, the CREATE VIEW statement must be the ony statement in the batch
CREATE VIEW [vwSnacks]
AS
SELECT * FROM [Snacks]
GO
-- If you want to edit a view, use ALTER
ALTER VIEW [vwSnacks]
AS
SELECT * FROM [Snacks]
WHERE [calories] < 100;
GO

-- Get more info about the View (use 'Output to Text' for best result)
SELECT OBJECT_DEFINITION(OBJECT_ID(N'vwSnacks', N'V'));
GO
-- You can do this just as easily by going to DB -> Views -> Right click View -> Script View as -> CREATE To -> New Query Window

-- To make a View encrypted:
ALTER VIEW vwSnacks
WITH ENCRYPTION
AS
SELECT * FROM [Snacks]
GO
-- Then, trying to script out the view will not work (returns NULL)

-- A View does not persist data, it only holds data when the view is queried, unless you have an indexed view
-- WITH SCHEMABINDING prevents changes to the underlying table (so the View won't be broken)
-- Adding a UNIQUE CLUSTERED INDEX to a view makes it an Indexed View, which persists the data independently.
--  Make sure you're design is correct. An Indexed View may as well be a table in most cases.
-- Enterprise Edition evaluates indexed views (it will use it in other areas of the server). Note: Standard Edition does not do this.
-- INSERT and UPDATE can be used in views, but can only affect one underlying table (not multiple tables)

-- Nested Views:
-- Be careful when calling views within views (nested views) because the logic can get very thick, like class inheritance can in OO systems.
-- Use views sparingly, map it out.

-- More examples of Views:
CREATE VIEW HumanResources.EmployeeList(EmployeeID, FamilyName, GivenName)
AS
SELECT EmployeeID, LastName, FirstName
FROM HumanResources.Employee;