-- Filtered Indexes
-- Use a WHERE clause to limit the rows that the index includes
-- Only works on nonclustered index
CREATE NONCLUSTERED INDEX ncEmpAddress
ON HR.Address
(
    AddressLine1,
    AddressLine2
)
WHERE City = 'New York'

-- Benefits
--  Faster response times
--  Smaller storage requirement
--  Faster rebuild operations

-- Shares some similarities with Indexed Views
