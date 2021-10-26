--Restart the mirroring endpoints
/*	We have had success in synchronising disconnected mirrored databases 
	by running steps #1 and #2 on both the Primary and Secondary servers. 
	- Failing this, then get them to restart the DR server [full Windows restart, 
	not SQL Server services] and then try running this again.
*/
	-- #1 check endpoint is started
	select * from sys.database_mirroring_endpoints
 
	-- #2 on the primary server stop and start the endpoints, this should fix mirroring
	alter endpoint [mirroring] state = stopped
	alter endpoint [mirroring] state = started
 
	-- Failing then try the following to see if there is a problem
	-- Check the tcp endpoint setting, should be 5022
	select name, port from sys.tcp_endpoints