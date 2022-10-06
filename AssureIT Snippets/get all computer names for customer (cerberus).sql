select distinct
case
    when CHARINDEX('\', InstanceName) > 0 -- Check if there's a backslash in the instance name
    then rtrim(left(InstanceName, CHARINDEX('\', InstanceName) - 1)) -- gets all characters before the backslash
    else InstanceName -- If there's no backslash, just return the server name
end as InstanceName
from SQLMSP.msp.vinventory where customercode='SCEG' and isactive = 1
order by InstanceName