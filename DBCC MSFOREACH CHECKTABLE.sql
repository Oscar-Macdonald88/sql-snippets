USE <dbname>;
EXECUTE sp_MSforeachtable 'DBCC CHECKTABLE ([?])';