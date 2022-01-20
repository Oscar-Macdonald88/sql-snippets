use SQLMSP;
GO
select InstanceName, e.EnvironmentName, i.IsActive, i.Is24x7, i.Comment, i.LastUpdateDate from msp.Inventory i
join msp.Customer c on i.CustomerId = c.CustomerId
join msp.Environment e on e.EnvironmentId = i.EnvironmentId
where c.CustomerCode = 'TDHB' -- update this
--  and e.EnvironmentName = 'P'
and i.IsActive = 1
order by InstanceName