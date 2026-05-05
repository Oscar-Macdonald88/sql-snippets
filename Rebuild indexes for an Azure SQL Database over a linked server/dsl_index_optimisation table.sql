DROP TABLE IF EXISTS [dbo].[dsl_index_optimisation]
GO

CREATE TABLE [dbo].[dsl_index_optimisation](
	[RowID] [int] IDENTITY(1,1) NOT NULL,
	[DatabaseName] [varchar](50) NOT NULL,
	[SchemaName] [varchar](50) NOT NULL,
	[TableName] [varchar](50) NOT NULL,
	[IndexName] [varchar](50) NOT NULL,
	[StartDate] [datetime] NULL,
	[EndDate] [datetime] NULL,
	[Success] [bit] NULL,
    [DBFreeSpaceMB] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[RowID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 10, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

