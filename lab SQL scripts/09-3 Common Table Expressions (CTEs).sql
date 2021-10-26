-- Common Table Expressions
-- A mechanism for defining a subquery that may be used elsewhere in a query (supports recursion)
WITH CTE_year AS
(
    SELECT  YEAR(orderdate) AS orderyear,
            custid
    FROM    Sales.Orders
)
SELECT orderyear, COUNT(Distinct custid) AS cust_count
FROM CTE_year
GROUP BY orderyear;