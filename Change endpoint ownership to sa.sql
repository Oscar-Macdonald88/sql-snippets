USE master; 
 
SELECT SUSER_NAME(principal_id) AS endpoint_owner ,name AS endpoint_name 
FROM sys.database_mirroring_endpoints; 
 
--Check and record any permissions. (you will need to add this back) 
SELECT EPS.name, SPS.STATE, CONVERT(nvarchar(38), SUSER_NAME(SPS.grantor_principal_id))AS [GRANTED BY], SPS.TYPE AS PERMISSION, CONVERT(nvarchar(46),SUSER_NAME(SPS.grantee_principal_id))AS [GRANTED TO] 
FROM sys.server_permissions SPS , sys.endpoints EPS WHERE SPS.major_id = EPS.endpoint_id AND name = 'Hadr_endpoint'
ORDER BY Permission,[GRANTED BY], [GRANTED TO]; 

--- now make the change.
BEGIN TRAN USE master; 
 
ALTER AUTHORIZATION ON ENDPOINT::Hadr_endpoint TO sa; 
 
GRANT CONNECT ON ENDPOINT::Hadr_endpoint TO [yourdomain\username]; -- update this
 
COMMIT
-- AG Group Ownership (2017)
SELECT ar.replica_server_name
    ,ag.name AS ag_name
    ,ar.owner_sid
    ,sp.name
FROM sys.availability_replicas ar
LEFT JOIN sys.server_principals sp
    ON sp.sid = ar.owner_sid 
INNER JOIN sys.availability_groups ag
    ON ag.group_id = ar.group_id
-- change ownership   
ALTER AUTHORIZATION ON AVAILABILITY GROUP::[AG-group-name] TO sa; -- update this