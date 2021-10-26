/* Transaction Logs and Recovery Models
Recovery Model defines how the Transaction Log works
The transaction log:
- keeps track of all DB changes
- Allows for rollback and rollforward of transactions (xacts)
All changes are written to the log first before being committed (write-ahead logging) (atomic)

Recovery Models
- Simple Recovery
    - No log backups, only page allocations are logged
    - Full backup only

- Bulk logged recovery
    - Logs and differentials, but no Point in Time (PiT)

- Full recovery
    - Adds PiT

Point in Time means you can recover up to a point in time (this time on this day)
*/
