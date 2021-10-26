# Performance capabilities

## Memory, CPU, and I/O capacities

- Azure SQL Database can support up to 128 vCores, 4 TB memory, and a 4 TB database size.
- The Hyperscale deployment option supports up to 100 TB of database size.
- Azure SQL Managed Instance can support up to 80 vCores, 400 GB memory, and an 8 TB database size.
- The number of vCores and the service tier also affects other resource capacities, such as maximum transaction log rates, IOPS, I/O latency, and memory.
- Windows job objects are used to support certain resource limits, such as memory. Use **sys.dm_os_job_object** to find true capacities for your deployment.

## Indexes

- All index types are supported in Azure SQL
- Columnstore indexes are available in almost all service tiers.

## In-memory OLTP

- Memory-optimized tables are only available in Business Critical tiers.
- The memory-optimized FILEGROUP is pre-created in Azure SQL Database and SQL Managed Instance when a database is created (even for general purpose tiers).
- The amount of memory for memory-optimized tables is a percentage of the vCore dependent memory limit.

## Partitions

Partitions are supported for Azure SQL Database and SQL Managed Instance., but you can only use filegroups with partitions with SQL Managed Instance

## SQL Server 2019 performance enhancements

tempdb metadata optimization isn't yet available for Azure SQL.

## Intelligent performance

Learn more later.