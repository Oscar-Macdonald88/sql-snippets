select  top 1 start_time, storage_space_used_mb, reserved_storage_mb,
        [storage usage %] = 100 * (storage_space_used_mb/reserved_storage_mb),
		reserved_storage_mb - storage_space_used_mb AS availablestorage_mb
from master.sys.server_resource_stats
order by start_time desc