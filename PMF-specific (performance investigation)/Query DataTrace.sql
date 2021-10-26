-- SSLMDW.ssl.DataTrace hasw some useful details on expensive queries, great for up-to-date details on expensive queries
select duration/1000/1000 as 'Duration Sec', * from SSLMDW.ssl.DataTrace
where 1 = 1
and StartTime > '20 Aug 2019 17:00' and StartTime < '20 Aug 2019 21:00'
order by Reads DESC