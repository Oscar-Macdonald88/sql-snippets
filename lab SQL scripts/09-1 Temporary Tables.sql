-- Temporary Tables
-- Hold temp result sets within a user's session.
-- Created in tempdb and deleted automatically.
-- when SS restarts, tempdb is effectively recreated.
CREATE TABLE #tmpProducts -- the hash defines the table as a locally scoped temp table (for the current user executing in the current session)
-- Note: ## would create a global temp table, where any session is able to reference the table.
(
    ProductID INT,
    ProductName VARCHAR(50)
);
