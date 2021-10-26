SELECT MessageTypeID
FROM SSLPerfMaster..tbl_CounterData
WHERE ServerID = 943 --update this, get ID by querying tbl_Server
GROUP BY MessageTypeID