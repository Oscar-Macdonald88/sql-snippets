# README

This script was developed to rebuild indexes for an Azure SQL Database in an Elastic Pool. CW ticket #179842. The Elastic Pool had reached 1TB used space and increasing the DTUs of the Pool to allow for a larger max size was very expensive.

The Database had a lot of page splits, so rebuilding the indexes would save a lot of space, however there wasn't enough room to rebuild the larger indexes, so we decided to rebuild the top 20, starting with the smallest and working our way up, one by one, to the larger indexes.

## Definitions

Azure Database: The server\Azure Database  that has the fragmented indexes on it. Will also hold the `dsl_index_optimisation` table to keep track of the indexes to rebuild and how long they took.
Remote Server: The server that will execute the rebuild commands.

## Steps to deploy

1. Ensure there is an SQL login that can be used to connect to the Azure Database. Requires sufficient permissions to rebuild indexes.
2. Run `dsl_index_optimisation table.sql` on the Azure Database to create the table.
3. Consider doing a test by adding a row to the new `dsl_index_optimisation` in the Azure Database for a very small index, or create a test table with a small index to be used as a test.
4. Create a new linked server on the Remote Server that connects to the Azure Database with these features:
    Linked Server: name_of_Azure_SQL_DB
    Provider: Microsoft OLE DB Provider for SQL Server
    Data source: name_of_Azure_SQL_DB.database.windows.net
    Catalog: the name of the database to connect to
    Under security, add the SQL Agent account for the Remote Server as the Local Logi if using an SQL Agent Job to run the defragging, then set the SQL login as the Remote User and specify the password.MAM-AZ-SQ
    Under "For a login not defined in the list above, connections will" to "Not be made"  
    Under "Server Options" make sure you set RPC and RPC Out to True. WARNING: this is considered insecure so only enable if you are aware of the risks, the client is aware of the risks, and you have mapped specific logins that can use the linked server.
5. Update the `Rebuild indexes.sql` script so that the correct linked server is used.
6. Create a job on the Remote Server. Copy `Rebuild indexes.sql` and paste it in to the command of the job. Schedule the job to run at the appropriate time.
7. Add entries to the new `dsl_index_optimisation` in the Azure Database. Entries are processed based on RowID ascending (1, 2, 3 etc). Best to start with smaller indexes first. Make sure that for HEAP tables, you run the rebuilds for the NON-CLUSTERED INDEXES, and for tables with CLUSTERED INDEXES you only rebuild the CLUSTERED INDEXES.