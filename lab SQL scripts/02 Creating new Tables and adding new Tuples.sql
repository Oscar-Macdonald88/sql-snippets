-- Creating a Table
USING [Food]
CREATE TABLE Snack
(
    -- everything inside these parentheses will be a field (column)
    SnackName VARCHAR(50),
    AmountInMg INT,
    Calories INT

)

-- CHAR(10) 'Cat       '
-- this stores exactly 10 characters every time and pads out the rest with spaces (7 in this case)
-- char is useful when using codes that share the same number of characters eg US state codes (CHAR(2)) or country codes (CHAR(3))
-- using VARCHAR in these cases uses extra overhead.

-- VARCHAR(10) 'Cat'
-- this stores up to 10 characters and trims the padding
-- Good for lots of other cases (names, addresses, comment fields)


-- new entries will add records aka tuples (row)
INSERT Snack
SELECT 'Chocolate Raisins', '500', '100'

INSERT Snack
SELECT 'Honeycomb', '200', '20'

SELECT * FROM Snack

-- There are a few ways to insert data. The above example creates a new row from the SELECT statement, and inserts it into the SNACK table
-- The Basic syntax is: INSERT • table value constructor:
INSERT INTO dbo.Snack
VALUES (N'Apple', 100, 10)
-- You can specify the order of the columns by specifying the column list order:
INSERT INTO dbo.Snack (Calories, SnackName, AmountInMg)
VALUES (500, N'Honey Roasted Peanuts', 40)
-- You can also insert data from another table using the SELECT and EXECUTE options

-- the following was generated from SSMS
/* To prevent any potential data loss issues, you should review this script in detail before running it outside the context of the database designer.*/
BEGIN TRANSACTION
SET QUOTED_IDENTIFIER ON
SET ARITHABORT ON
SET NUMERIC_ROUNDABORT OFF
SET CONCAT_NULL_YIELDS_NULL ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
COMMIT
BEGIN TRANSACTION
GO
CREATE TABLE dbo.TableName
	(
	TableName_ID int NOT NULL,
	Name varchar(10) NOT NULL,
	Date datetime NOT NULL
	)  ON [PRIMARY]
GO
ALTER TABLE dbo.TableName ADD CONSTRAINT
	PK_TableName PRIMARY KEY CLUSTERED 
	(
	TableName_ID
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO
ALTER TABLE dbo.TableName SET (LOCK_ESCALATION = TABLE)
GO
COMMIT