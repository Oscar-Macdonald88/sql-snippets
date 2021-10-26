# How to read the graphical execution plan?

The graphical execution plan should be read from Right to Left:

- Table Scan: Index is missing
- Index Scan: Proper indexes are not used. Determine what order columns should be specified in the index
- BookMark Lookup: Limits the number of columns in the select list
- Filter: Removes any functions from the WHERE clause; may require additional indexes
- Sort: Checks if the data really needs to be sorted, if an index can be used to avoid sorting, and if sorting can be done at the client-side more efficiently?
- DataFlow Arrow (high density): Sometimes, we find few rows as the outcome, but the arrow line density indicates the query/proc processing huge number of rows
- Cost: Easily finds out which table/operation taking much time

From the execution plan, we can find out the bottlenecks and give possible solutions to avoid latency

[Original article](https://intellipaat.com/blog/interview-question/sql-server-interview-questions/#31)