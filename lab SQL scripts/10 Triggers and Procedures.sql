-- Stored Procedures (SP) and Triggers
-- Pretty much the same thing with two big differences:
-- Stored procedure is called by the user, whereas a trigger is called by an event (you can't specifically call a trigger)
-- Triggers are tied to a table, stored procedures aren't.
-- Lecturer's advice: Don't use triggers if you can help it. There is always a way around using them. They impact performance.

USE [Food]
GO
-- Create the TRIGGER
CREATE TRIGGER [CalorieCheck]
    ON [Snack]
    AFTER INSERT
AS
    SET NOCOUNT ON;
    -- if any snack has fewer than 10 calories, set it to 10 calories (no point keeping track of foods with less than 10 calories)
    DECLARE @Calories INT;
    -- SQL has two hidden tables, Inserted and Deleted
    -- You can access these for TRIGGERS
    SET @Calories = (SELECT [Calories] FROM [Inserted]); -- this gets the Calories from the last Snack that was Inserted
    IF @Calories < 10 -- if it was less than 10
    BEGIN
    SET @Calories = 10; -- set it to 10
    UPDATE [S]
    SET [Calories] = @Calories
    FROM [Snack] AS [S]
    INNER JOIN [Inserted] AS [I]
    ON [S].[SnackName] = [I].[SnackName] AND [S].[Calories] = [I].[Calories];
END;
GO

INSERT [Snack]
VALUES ('Rice Cakes', 2, 3);
GO
-- Rice Cakes will have 10 calories, but any tuples with calories < 10 will still have their original calories value

-- Procedures:
CREATE PROC [spCalorieFix]
@SnackName VARCHAR(50),
@AmountInOz INT,
@Calories INT
AS
IF @Calories < 10
    SET @Calories = 10;
INSERT [dbo].[Snack]
VALUES (@SnackName, @AmountInOz, @Calories);

spCalorieFix 'Chocolate Covered Cherries', 10, 1
SELECT * FROM [Snack]

