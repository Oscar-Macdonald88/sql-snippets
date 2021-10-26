-- Managing Transactions

-- A revision of ACID
-- Atomicity
--      Each transaction is "all or nothing". If one fails, all transactions are rolled back.
-- Consistency
--      Any transaction will bring the database from one state to another.
-- Isolation
--      If a set of concurrent (simultaneous) transactions would result in a system state, the same state would be achieved 
--      if the set was executed sequentially (one after another)
-- Durability
--      Once a transaction is committed, it will remain so. This includes events such as power loss, crashes, errors. 
--      The transaction result is persistant (stored in non-volatile memory).

-- A transaction is a task or group of tasks that define *a unit of work*
-- Individual data modification statements are automatically treated as standalone transactions (implicit transactions)
-- User transactions can be managed with BEGIN / COMMIT / ROLLBACK TRANSACTION statements (explicit transactions)

-- Implicit Transactions will commit each statement before starting the next
USE SSL_Quiz_Database;
GO

BEGIN TRY
    INSERT INTO dbo.tbl_Questions
        SELECT 'What does ACID stand for?'
    INSERT INTO dbo.tbl_Answers
        VALUES
            ('Atomicity, Consistency, Isolation, Durability'),
            ('Authority, Centralized, Individual, Density'),
            ('Atomic, Concurrent, Isolated, Durable'),
            ('Altered, Checked, Improved, Drafted')
    INSERT INTO dbo.tbl_QuestionAnswerSelection
        VALUES
            (3, 9, 1, 'Briefly explained, these refer to the indivisibility of a set of transactions, state transition of the database, undifferentiated transaction processes, and persistant storage of committed transactions'),
            (3, 10, 1, 'While authorization might be a part of database security, none of these terms have anything to do with ACID'),
            (3, 11, 1, 'Atomic, Isolated and Durable are close, and Concurrency is certainly a factor involved, but none of these terms are abbreviations for the letters in ACID'),
            (3, 12, 1, 'These terms might appear in different version control systems, but these have nothing to do with Microsoft SQL Server and ACID terms');
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS ErrNum, ERROR_MESSAGE() AS ErrMsg;
END CATCH;
-- This will print 547: The INSERT statement conflicted with the FOREIGN KEY constraint "FK_tbl_Questions". The conflict occurred in database "SSL_Quiz_Database", table "dbo.tbl_Questions", column 'question_ID'.
-- There will be a partial success (which ruined my database and, when I tried to fix it, I made it worse so I had to drop everything in my tables. Fortunately it wasn't much so no big whoop, maybe 5 mins of my life)

-- Explicit Transactions will put the transaction into memory and will only become persistent when COMMIT is reached
-- There can't be any batch separators (GO) in a TRY / CATCH
BEGIN TRY
    BEGIN TRAN -- shorthand for TRANSACTION
        INSERT INTO dbo.tbl_Questions
            VALUES ('What does ACID stand for?')
        INSERT INTO dbo.tbl_Answers
            VALUES
                ('Atomicity, Consistency, Isolation, Durability'),
                ('Authority, Centralized, Individual, Density'),
                ('Atomic, Contained, Isolated, Durable'),
                ('Altered, Checked, Improved, Drafted')
        INSERT INTO dbo.tbl_QuestionAnswerSelection
            VALUES
                (3, 9, 1, 'Briefly explained, these refer to the indivisibility of a set of transactions, state transition of the database, undifferentiated transaction processes, and persistant storage of committed transactions'),
                (3, 10, 1, 'While authorization might be a part of database security, none of these terms have anything to do with ACID'),
                (3, 11, 1, 'Atomic, Isolated and Durable are close, but Contained is not correct'),
                (3, 12, 1, 'These terms might appear in different version control systems, but these have nothing to do with ACID');
    COMMIT TRAN
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS ErrNum, ERROR_MESSAGE() AS ErrMsg;
    ROLLBACK TRAN -- rollback if there was an error
END CATCH;

-- Managing Concurrency
-- The ability for multiple processes to access the same data at the same time
-- Two approaches to effective management:
--  Pessimistic Concurrency:
--      . The default and traditional concurrency model for SS
--      . Assumes that different processes will try to read and write to the same data simultaneously
--          - Uses locks to prevent conflicts
--  Optimistic Concurrency (SS 2005)
--      . As the date suggests, it is a more modern concurrency model
--      . Assumes that it is unlikely that readers and writers will be in conflict
--          - Doesn't use locks
--          - Uses snapshot-based isolation levels which use row versioning in lieu of locking

-- Potential Concurrency Issues
--  Concurrency anomalies (note, there are scenarios where these might actually occur as desired data aka they are not always unwanted, so it is difficult to tell whether they are intentional or not.)
--      . Lost Updates
--      . Dirty Reads
--      . Non-Repeatable
--          - Hypothetical comparison: 
--          A pessimistic shop manager wants to calculate the earnings of the day before closing time at 5pm so he starts counting the
--          money in each till at 4.30. He begins counting from till 1 and works his way sequentially to till 4.
--          The problem is that the tills were in use while he was counting, so by the time he started counting from till 2
--          the money in till 1 had changed. He now has a value that is 'non-repeatable', that is: if he had (rather rudely) closed
--          the tills to everyone but himself at 4.30 and then opened them again when he was finished and recorded the value, he would 
--          always have the same (repeatable) value in the records. He would be able to say 'at 4.30 on this day there was x amount in 
--          all the tills.' If he had waited till the shop had closed at 5 before counting the money, he would have a different value 
--          than the one he had at 4.30, but he would be able to repeat that value at any point in time. But because he was lazy and
--          hadn't locked the till, he now has a value that cannot be reproduced.
--      . Phantom Rows / Phantoms


-- Isolation Levels are used to control whether or not you want these anomalies to be introduced into the application.
-- Levels go from least to most isolated
--  Read Uncommitted: Best concurrency but allows dirty reads, non-repeatable reads and phantoms. Doesn't lock data while reading.
--      Doesn't wait for uncommitted transactions to complete before reading
--  Read Committed (default): allows non-repeatable reads and phantoms.
--      Waits for transactions to commit / rollback before reading 
--   Repeatable Read: Allows phantoms
--      Holds locks for the duration of a transaction.
--   Serializable: serializes access to data. No anomalies.
--      Holds locks for the duration of a transaction AND key range locks for rows that don't even exist yet. No new rows can be created while key range is locked. Damaging to concurrency (Only one process can access the data at a time)

-- Optimistic Isolation Level: Snapshot
-- Uses row versions rather than locks. Stores in version_storer (tempdb)
-- If someone wants to read from the table, they will get the row version from version_storer rather than from the table itself 
-- Prevents all anomalies but update conflicts can occur which will cause a transaction rollback

-- Locking
-- Implement the isolation level

-- Two main locking modes:
-- Shared /SH (read)
--  Compatible with other Shared locks (anyone can read the data at the same time)
-- Exclusive / EX (write)
--  Incompatible with any other lock

-- Other locks:
-- Update (used to prevent deadlocks)
--  when a process needs to read data before updating it.
-- Intent (used to indicate that locks are present at a lower level of granularity)
--  A shared lock on a row will also create an intent shared lock on the page and table that it belongs to. 

-- Locking Problems
-- Blocking Locks:
--  Processes wait for access to resources, the larger the data and the more processes then the longer transactions can take.
-- Deadlocks
--  Two processes each hold a lock on one resource while waiting for the other to unlock
--  Automatically detected and resolved, but the cheapest transaction must rollback (deadlock victim)
--  When deadlocks are  a problem:
--      When something changes and several deadlocks in a day start to occur.
--      When a pattern can be seen eg regular deadlocks at certain times because of time triggered, opposite-woring processes.
--  Trace flags 1204 and/or 1222 can be used to diagnose deadlock information
DBCC TRACEON(1222, -1)  -- Introduced in SS 2005, enables the trace flag for all sessions on error 1222 on all sessions (-1)
--  You can also start sql server from the command line with parameter -T <traceflag#> to trace on that flag
--  Note: 1205 is the error when a process is chosen as the deadlock victim.

USE AdventureWorks
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ; -- changes from default Read Committed
GO

-- Within Repeatable Read, the shared lock will be held throughout the transaction
BEGIN TRAN
SELECT * FROM Person.Person
WHERE LastName = 'Macdonald'

SELECT  request_session_id AS Session,
        resource_database_id AS DBID,
        resource_type,
        resource_description,
        request_type,
        request_mode,
        request_status
FROM sys.dm_tran_locks
ORDER BY [session]

-- Run this in another window
USE AdventureWorks
UPDATE Person.Person
SET Title = 'DBAGod'
WHERE LastName = 'Macdonald'
-- It will timeout at 5 seconds

-- show who is waiting for what
SELECT  session_id,
        wait_duration_ms,
        wait_type,
        blocking_session_id,
        resource_description
FROM sys.dm_os_waiting_tasks
WHERE session_id > 50

ROLLBACK TRAN

-- To view deadlock graph (useful tool):
-- Setup SS profiler (?) -> Connect to server -> Set 'Use the template' to Blank -> Events Selection -> Locks -> Deadlock Graph -> Run
