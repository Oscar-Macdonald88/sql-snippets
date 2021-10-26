-- Synonyms
-- Great way to obscure tables from users
-- Good way to get around business problems and save excessivbe coding
-- access original 'Food' database from Food2
USE Food2
SELECT * FROM Food.dbo.Snack; -- selects data from a different database

-- If you want users to access some data from a different database, you could use a View
-- Can also be handled with a Synonym
CREATE SYNONYM sySnack
FOR Food.dbo.Snack

select * from sySnack;

-- A common use for synonyms is for accessing archive tables
-- Simply change the name of the database to the name of the archived database