USE [master]
GO
/****** Object:  Database [OracleMSP]    Script Date: 11/16/2023 4:54:44 PM ******/
CREATE DATABASE [OracleMSP]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'OracleMSP', FILENAME = N'D:\SQLData\OracleMSP.mdf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'OracleMSP_log', FILENAME = N'F:\SQLLogs\OracleMSP_log.ldf' , SIZE = 8192KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
GO
ALTER DATABASE [OracleMSP] SET COMPATIBILITY_LEVEL = 140
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [OracleMSP].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [OracleMSP] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [OracleMSP] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [OracleMSP] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [OracleMSP] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [OracleMSP] SET ARITHABORT OFF 
GO
ALTER DATABASE [OracleMSP] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [OracleMSP] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [OracleMSP] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [OracleMSP] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [OracleMSP] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [OracleMSP] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [OracleMSP] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [OracleMSP] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [OracleMSP] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [OracleMSP] SET  DISABLE_BROKER 
GO
ALTER DATABASE [OracleMSP] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [OracleMSP] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [OracleMSP] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [OracleMSP] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [OracleMSP] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [OracleMSP] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [OracleMSP] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [OracleMSP] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [OracleMSP] SET  MULTI_USER 
GO
ALTER DATABASE [OracleMSP] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [OracleMSP] SET DB_CHAINING OFF 
GO
ALTER DATABASE [OracleMSP] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [OracleMSP] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [OracleMSP] SET DELAYED_DURABILITY = DISABLED 
GO
ALTER DATABASE [OracleMSP] SET QUERY_STORE = OFF
GO
USE [OracleMSP]
GO
/****** Object:  User [ENTERPRISEIT\Jose.Dacostarolim]    Script Date: 11/16/2023 4:54:44 PM ******/
CREATE USER [ENTERPRISEIT\Jose.Dacostarolim] FOR LOGIN [ENTERPRISEIT\Jose.Dacostarolim] WITH DEFAULT_SCHEMA=[dbo]
GO
ALTER ROLE [db_owner] ADD MEMBER [ENTERPRISEIT\Jose.Dacostarolim]
GO
/****** Object:  Schema [msp]    Script Date: 11/16/2023 4:54:44 PM ******/
CREATE SCHEMA [msp]
GO
/****** Object:  Schema [report]    Script Date: 11/16/2023 4:54:44 PM ******/
CREATE SCHEMA [report]
GO
/****** Object:  Schema [source]    Script Date: 11/16/2023 4:54:44 PM ******/
CREATE SCHEMA [source]
GO
/****** Object:  Schema [staging]    Script Date: 11/16/2023 4:54:44 PM ******/
CREATE SCHEMA [staging]
GO
/****** Object:  Schema [trend]    Script Date: 11/16/2023 4:54:44 PM ******/
CREATE SCHEMA [trend]
GO
/****** Object:  UserDefinedFunction [dbo].[udfGetOracleBuild]    Script Date: 11/16/2023 4:54:44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[udfGetOracleBuild] (@PatchName nvarchar(255))
returns nvarchar(255)
as
begin
return substring(@PatchName,PATINDEX('%[0-9.-]%',@PatchName), PatIndex('%[^0-9.-]%', SubString(@PatchName, PatIndex('%[0-9.-]%', @PatchName), len(@PatchName)) + 'X')-1)
end
GO
/****** Object:  Table [source].[OperatingSystem]    Script Date: 11/16/2023 4:54:44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [source].[OperatingSystem](
	[OperatingSystemID] [int] IDENTITY(1,1) NOT NULL,
	[OperatingSystem_name] [nvarchar](254) NOT NULL,
 CONSTRAINT [PK_OperatingSystem] PRIMARY KEY CLUSTERED 
(
	[OperatingSystemID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [CK_OperatingSystem_name] UNIQUE NONCLUSTERED 
(
	[OperatingSystem_name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [source].[OfficialOracleRelease]    Script Date: 11/16/2023 4:54:44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [source].[OfficialOracleRelease](
	[release_id] [int] IDENTITY(1,1) NOT NULL,
	[fullname] [nvarchar](50) NOT NULL,
	[release] [nvarchar](50) NOT NULL,
	[releasedate] [date] NULL,
	[patchingenddate] [date] NOT NULL,
	[extendedsupportend] [date] NULL,
 CONSTRAINT [PK_OfficialOracleRelease] PRIMARY KEY CLUSTERED 
(
	[release_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [source].[OfficialOraclePatches]    Script Date: 11/16/2023 4:54:44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [source].[OfficialOraclePatches](
	[PatchNumber] [int] NOT NULL,
	[PatchName] [nvarchar](254) NOT NULL,
	[PSUBundle] [nvarchar](254) NOT NULL,
	[release_id] [int] NOT NULL,
 CONSTRAINT [PK_OfficialOraclePatches] PRIMARY KEY CLUSTERED 
(
	[PatchNumber] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [source].[OraclePatchCandidates]    Script Date: 11/16/2023 4:54:44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [source].[OraclePatchCandidates](
	[PatchNumber] [int] NOT NULL,
	[OperatingSystemID] [int] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  View [msp].[vOracleRecommendedPatch]    Script Date: 11/16/2023 4:54:44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE view [msp].[vOracleRecommendedPatch] as
(
select os_group.OperatingSystem_name
, os_group.OperatingSystemId
, os_group.fullname
, os_group.PatchName
, os_group.PatchNumber
, [dbo].[udfGetOracleBuild](os_group.PatchName) as PatchLevel
from( select OS.OperatingSystem_name
, OS.OperatingSystemID
, OOR.fullname
, OOP.PatchName
, OOP.PatchNumber
,ROW_NUMBER() OVER(PARTITION BY OS.OperatingSystem_name ORDER BY OPC.PatchNumber desc) as rn
from source.OperatingSystem OS
 join [source].[OraclePatchCandidates] OPC on OPC.OperatingSystemID = OS.OperatingSystemID
 join [source].[OfficialOraclePatches] OOP on OOP.PatchNumber = OPC.PatchNumber
 join [source].[OfficialOracleRelease] OOR on OOR.release_id = OOP.release_id ) as os_group
where rn = 1
)
GO
/****** Object:  Table [msp].[Environment]    Script Date: 11/16/2023 4:54:44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [msp].[Environment](
	[EnvironmentId] [tinyint] IDENTITY(1,1) NOT NULL,
	[EnvironmentName] [nvarchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
 CONSTRAINT [PK_EnvironmentId] PRIMARY KEY CLUSTERED 
(
	[EnvironmentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [msp].[Timezone]    Script Date: 11/16/2023 4:54:44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [msp].[Timezone](
	[TimezoneId] [tinyint] IDENTITY(1,1) NOT NULL,
	[TimezoneName] [nvarchar](10) NOT NULL,
	[TimezoneOffset] [numeric](3, 1) NOT NULL,
 CONSTRAINT [PK_TimezoneID] PRIMARY KEY CLUSTERED 
(
	[TimezoneId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_TimezoneName] UNIQUE NONCLUSTERED 
(
	[TimezoneName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [msp].[Inventory]    Script Date: 11/16/2023 4:54:44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [msp].[Inventory](
	[InstanceId] [uniqueidentifier] NOT NULL,
	[CustomerId] [uniqueidentifier] NOT NULL,
	[InstanceName] [nvarchar](128) NOT NULL,
	[OracleRelease] [int] NOT NULL,
	[OperatingSystemId] [int] NOT NULL,
	[EnvironmentId] [tinyint] NOT NULL,
	[HostId] [uniqueidentifier] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[Is24x7] [bit] NOT NULL,
	[Comment] [nvarchar](max) NULL,
	[LastUpdateDate] [datetime] NOT NULL,
	[LastUpdateUser] [nvarchar](50) NOT NULL,
	[TimezoneId] [tinyint] NOT NULL,
 CONSTRAINT [PK_InstanceId] PRIMARY KEY CLUSTERED 
(
	[InstanceId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [trend].[PatchLevel]    Script Date: 11/16/2023 4:54:44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [trend].[PatchLevel](
	[CustomerId] [uniqueidentifier] NOT NULL,
	[InstanceId] [uniqueidentifier] NOT NULL,
	[PatchNumber] [int] NOT NULL,
	[Collected] [datetime] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [msp].[Customer]    Script Date: 11/16/2023 4:54:44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [msp].[Customer](
	[CustomerId] [uniqueidentifier] NOT NULL,
	[CustomerCode] [nvarchar](10) NOT NULL,
	[CustomerDisplayName] [nvarchar](128) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[Is24x7] [bit] NOT NULL,
	[CXDM] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_CustomerId] PRIMARY KEY CLUSTERED 
(
	[CustomerId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [report].[vPatchLevel]    Script Date: 11/16/2023 4:54:44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [report].[vPatchLevel] AS 
  WITH InventoryCTE AS (
	SELECT
	    c.CustomerId
		,c.CustomerCode
		,i.InstanceId
		,i.InstanceName
	FROM [msp].[Inventory] i
	JOIN [msp].[Customer] c
	ON i.CustomerId = c.CustomerId
	WHERE 1=1
  )
  SELECT 
    CustomerId
	,InstanceId
	,CustomerCode
	,InstanceName
	,( SELECT TOP 1 FIRST_VALUE(PatchNumber) OVER( PARTITION BY InstanceId ORDER BY Collected DESC ) FROM [trend].[PatchLevel] WHERE InstanceId = i.InstanceId ) AS [PatchNumber]
  FROM InventoryCTE i
GO
/****** Object:  View [msp].[vInventory]    Script Date: 11/16/2023 4:54:44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE view [msp].[vInventory]
as
SELECT 
      C.[CustomerId]
	  ,C.[CustomerCode]
	  ,I.[InstanceId]
      ,I.[InstanceName]
	  ,I.[OperatingSystemId]
	  ,O.[OperatingSystem_name]
      ,I.[EnvironmentId]
	  ,E.[EnvironmentName]
      ,I.[IsActive]
      ,I.[Is24x7] as [InstanceIs24x7]
	  ,P.[PatchNumber] as [CurrentPatch]
	  ,R.[PatchNumber] as [RecommendedPatch]
	   ,CASE
		WHEN R.[PatchNumber] > P.[PatchNumber] THEN 'No'
		ELSE 'Yes'
	  END AS [OracleUp-to-date]
      ,I.[Comment]
      ,I.[LastUpdateDate]
      ,I.[LastUpdateUser]
      ,I.[TimezoneId]
	  ,T.[TimezoneName]
	  ,C.[Is24x7] as [CustomerIs24x7]
  FROM [msp].[Inventory] I
  join [msp].[Customer] C on C.CustomerId = I.CustomerId
  join [msp].[Environment] E on E.EnvironmentId = I.EnvironmentId
  join [msp].[Timezone] T on T.TimezoneId = I.TimezoneId
  join [source].[OperatingSystem] O on O.OperatingSystemID = I.OperatingSystemID
  join [msp].[vOracleRecommendedPatch] R on R.OperatingSystemId = I.OperatingSystemID
  join [report].[vPatchLevel] P on P.InstanceId = I.InstanceId
GO
/****** Object:  View [dbo].[vCurrentPatch]    Script Date: 11/16/2023 4:54:44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[vCurrentPatch]
as
WITH InventoryCTE AS (
	SELECT
	    c.CustomerId
		,c.CustomerCode
		,i.InstanceId
		,i.InstanceName
	FROM [msp].[Inventory] i
	JOIN [msp].[Customer] c
	ON i.CustomerId = c.CustomerId
  )
  SELECT 
    CustomerId
	,InstanceId
	,CustomerCode
	,InstanceName
	,(SELECT TOP 1 FIRST_VALUE(PatchNumber) OVER( PARTITION BY InstanceId ORDER BY Collected DESC ) FROM [trend].[PatchLevel] WHERE InstanceId = i.InstanceId ) AS [CurrentPatchNumber]
  FROM InventoryCTE i
GO
/****** Object:  Table [staging].[PatchLevel]    Script Date: 11/16/2023 4:54:44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [staging].[PatchLevel](
	[CLIENT] [nvarchar](15) NULL,
	[DATABASE_NAME] [nvarchar](50) NULL,
	[DATABASE_ROLE] [nvarchar](10) NULL,
	[ORACLE_VERSION] [nvarchar](255) NULL,
	[PATCH_LEVEL] [nvarchar](50) NULL,
	[OPERATING_SYSTEM] [nvarchar](50) NULL,
	[HOSTNAME] [nvarchar](255) NULL,
	[Collected] [datetime] NULL
) ON [PRIMARY]
GO
/****** Object:  View [staging].[vw_PatchLevels]    Script Date: 11/16/2023 4:54:44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [staging].[vw_PatchLevels] as
select CLIENT, DATABASE_NAME, DATABASE_ROLE, ORACLE_VERSION, [1] as PATCH_MAJOR, [2] as PATCH_MINOR, OPERATING_SYSTEM, HOSTNAME, Collected from (
select CLIENT, DATABASE_NAME, DATABASE_ROLE, ORACLE_VERSION, PATCH_LEVEL, OPERATING_SYSTEM, HOSTNAME, Collected, RowN, value from [staging].[PatchLevel] d cross apply (select RowN=Row_Number() over (Order by (SELECT NULL)), value from string_split(d.PATCH_LEVEL, '.')) u) as src
pivot (max(value) for src.RowN in([1],[2])) p
GO
/****** Object:  Table [dbo].[LoadPSUErrors]    Script Date: 11/16/2023 4:54:44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LoadPSUErrors](
	[Flat File Source Error Output Column] [nvarchar](max) NULL,
	[ErrorCode] [int] NULL,
	[ErrorColumn] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [msp].[Host]    Script Date: 11/16/2023 4:54:44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [msp].[Host](
	[HostId] [uniqueidentifier] NOT NULL,
	[CustomerId] [uniqueidentifier] NOT NULL,
	[HostName] [nvarchar](255) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[Comment] [nvarchar](max) NULL,
	[LastUpdateDate] [datetime] NOT NULL,
	[LastUpdateUser] [nvarchar](50) NOT NULL,
	[TimezoneId] [tinyint] NOT NULL,
 CONSTRAINT [PK_HostId] PRIMARY KEY CLUSTERED 
(
	[HostId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [source].[OfficialLatestOracleVersionRecommendation]    Script Date: 11/16/2023 4:54:44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [source].[OfficialLatestOracleVersionRecommendation](
	[PatchNumber] [int] NOT NULL,
	[Patch] [nvarchar](50) NOT NULL,
	[PatchName] [nvarchar](254) NOT NULL,
	[PSUBundle] [nvarchar](254) NOT NULL,
	[release_id] [int] NOT NULL,
 CONSTRAINT [PK_OfficialLatestOracleVersionRecommendation] PRIMARY KEY CLUSTERED 
(
	[PatchNumber] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [staging].[OfficialOraclePatches]    Script Date: 11/16/2023 4:54:44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [staging].[OfficialOraclePatches](
	[PatchNumber] [int] NOT NULL,
	[PatchName] [nvarchar](254) NOT NULL,
	[PSUBundle] [nvarchar](254) NOT NULL,
	[OracleRelease] [nvarchar](50) NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [staging].[OperatingSystem]    Script Date: 11/16/2023 4:54:44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [staging].[OperatingSystem](
	[OperatingSystem_name] [nvarchar](254) NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [staging].[OraclePatchCandidates]    Script Date: 11/16/2023 4:54:44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [staging].[OraclePatchCandidates](
	[PatchNumber] [int] NOT NULL,
	[OperatingSystem_name] [nvarchar](254) NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [msp].[Customer] ADD  DEFAULT (newid()) FOR [CustomerId]
GO
ALTER TABLE [msp].[Customer] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [msp].[Customer] ADD  DEFAULT ((0)) FOR [Is24x7]
GO
ALTER TABLE [msp].[Environment] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [msp].[Host] ADD  DEFAULT (newid()) FOR [HostId]
GO
ALTER TABLE [msp].[Host] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [msp].[Host] ADD  DEFAULT (getdate()) FOR [LastUpdateDate]
GO
ALTER TABLE [msp].[Host] ADD  DEFAULT (suser_sname()) FOR [LastUpdateUser]
GO
ALTER TABLE [msp].[Host] ADD  DEFAULT ((1)) FOR [TimezoneId]
GO
ALTER TABLE [msp].[Inventory] ADD  DEFAULT (newid()) FOR [InstanceId]
GO
ALTER TABLE [msp].[Inventory] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [msp].[Inventory] ADD  DEFAULT ((0)) FOR [Is24x7]
GO
ALTER TABLE [msp].[Inventory] ADD  DEFAULT (getdate()) FOR [LastUpdateDate]
GO
ALTER TABLE [msp].[Inventory] ADD  DEFAULT (suser_sname()) FOR [LastUpdateUser]
GO
ALTER TABLE [msp].[Inventory] ADD  DEFAULT ((1)) FOR [TimezoneId]
GO
ALTER TABLE [msp].[Timezone] ADD  DEFAULT ((0)) FOR [TimezoneOffset]
GO
ALTER TABLE [msp].[Host]  WITH CHECK ADD  CONSTRAINT [FK_Host_CustomerId] FOREIGN KEY([CustomerId])
REFERENCES [msp].[Customer] ([CustomerId])
GO
ALTER TABLE [msp].[Host] CHECK CONSTRAINT [FK_Host_CustomerId]
GO
ALTER TABLE [msp].[Host]  WITH CHECK ADD  CONSTRAINT [FK_Host_TimezoneId] FOREIGN KEY([TimezoneId])
REFERENCES [msp].[Timezone] ([TimezoneId])
GO
ALTER TABLE [msp].[Host] CHECK CONSTRAINT [FK_Host_TimezoneId]
GO
ALTER TABLE [msp].[Inventory]  WITH CHECK ADD  CONSTRAINT [FK_Inventory_CustomerId] FOREIGN KEY([CustomerId])
REFERENCES [msp].[Customer] ([CustomerId])
GO
ALTER TABLE [msp].[Inventory] CHECK CONSTRAINT [FK_Inventory_CustomerId]
GO
ALTER TABLE [msp].[Inventory]  WITH CHECK ADD  CONSTRAINT [FK_Inventory_EnvironmentId] FOREIGN KEY([EnvironmentId])
REFERENCES [msp].[Environment] ([EnvironmentId])
GO
ALTER TABLE [msp].[Inventory] CHECK CONSTRAINT [FK_Inventory_EnvironmentId]
GO
ALTER TABLE [msp].[Inventory]  WITH CHECK ADD  CONSTRAINT [FK_Inventory_HostId] FOREIGN KEY([HostId])
REFERENCES [msp].[Host] ([HostId])
GO
ALTER TABLE [msp].[Inventory] CHECK CONSTRAINT [FK_Inventory_HostId]
GO
ALTER TABLE [msp].[Inventory]  WITH CHECK ADD  CONSTRAINT [FK_Inventory_OperatingSystemId] FOREIGN KEY([OperatingSystemId])
REFERENCES [source].[OperatingSystem] ([OperatingSystemID])
GO
ALTER TABLE [msp].[Inventory] CHECK CONSTRAINT [FK_Inventory_OperatingSystemId]
GO
ALTER TABLE [msp].[Inventory]  WITH CHECK ADD  CONSTRAINT [FK_Inventory_OracleRelease] FOREIGN KEY([OracleRelease])
REFERENCES [source].[OfficialOracleRelease] ([release_id])
GO
ALTER TABLE [msp].[Inventory] CHECK CONSTRAINT [FK_Inventory_OracleRelease]
GO
ALTER TABLE [msp].[Inventory]  WITH CHECK ADD  CONSTRAINT [FK_TimezoneId] FOREIGN KEY([TimezoneId])
REFERENCES [msp].[Timezone] ([TimezoneId])
GO
ALTER TABLE [msp].[Inventory] CHECK CONSTRAINT [FK_TimezoneId]
GO
ALTER TABLE [source].[OfficialLatestOracleVersionRecommendation]  WITH CHECK ADD  CONSTRAINT [FK_OfficialLatestOracleVersionRecommendation_OfficialOracleRelease] FOREIGN KEY([release_id])
REFERENCES [source].[OfficialOracleRelease] ([release_id])
GO
ALTER TABLE [source].[OfficialLatestOracleVersionRecommendation] CHECK CONSTRAINT [FK_OfficialLatestOracleVersionRecommendation_OfficialOracleRelease]
GO
ALTER TABLE [source].[OfficialOraclePatches]  WITH CHECK ADD  CONSTRAINT [FK_OfficialOraclePatches_OfficialOracleRelease] FOREIGN KEY([release_id])
REFERENCES [source].[OfficialOracleRelease] ([release_id])
GO
ALTER TABLE [source].[OfficialOraclePatches] CHECK CONSTRAINT [FK_OfficialOraclePatches_OfficialOracleRelease]
GO
ALTER TABLE [source].[OraclePatchCandidates]  WITH CHECK ADD  CONSTRAINT [FK_OraclePatchCandidates_OfficialOraclePatches] FOREIGN KEY([PatchNumber])
REFERENCES [source].[OfficialOraclePatches] ([PatchNumber])
GO
ALTER TABLE [source].[OraclePatchCandidates] CHECK CONSTRAINT [FK_OraclePatchCandidates_OfficialOraclePatches]
GO
ALTER TABLE [source].[OraclePatchCandidates]  WITH CHECK ADD  CONSTRAINT [FK_OraclePatchCandidates_OperatingSystem] FOREIGN KEY([OperatingSystemID])
REFERENCES [source].[OperatingSystem] ([OperatingSystemID])
GO
ALTER TABLE [source].[OraclePatchCandidates] CHECK CONSTRAINT [FK_OraclePatchCandidates_OperatingSystem]
GO
ALTER TABLE [trend].[PatchLevel]  WITH CHECK ADD  CONSTRAINT [FK_CustomerId_Customer] FOREIGN KEY([CustomerId])
REFERENCES [msp].[Customer] ([CustomerId])
GO
ALTER TABLE [trend].[PatchLevel] CHECK CONSTRAINT [FK_CustomerId_Customer]
GO
ALTER TABLE [trend].[PatchLevel]  WITH CHECK ADD  CONSTRAINT [FK_PatchLevel_OfficialOraclePatches] FOREIGN KEY([PatchNumber])
REFERENCES [source].[OfficialOraclePatches] ([PatchNumber])
GO
ALTER TABLE [trend].[PatchLevel] CHECK CONSTRAINT [FK_PatchLevel_OfficialOraclePatches]
GO
/****** Object:  StoredProcedure [msp].[LoadStageHostData]    Script Date: 11/16/2023 4:54:44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



/* OraclePatchLevel */
CREATE PROCEDURE [msp].[LoadStageHostData]
AS
BEGIN	
	BEGIN TRAN;
	WITH src AS (
		SELECT
			c.CustomerId
			,p.[HOSTNAME] as HostName
		FROM [staging].[PatchLevel] p
		JOIN [msp].[Customer] c 
		ON p.[CLIENT] = c.CustomerCode
	)
	MERGE INTO [msp].[Host] AS tgt USING src
	ON (src.CustomerId = tgt.CustomerId AND src.HostName = tgt.HostName)
	WHEN NOT MATCHED BY TARGET THEN
		INSERT ([CustomerId]
			   ,[HostName]
			   )
		VALUES 
		(src.CustomerId
		,src.HostName);
		COMMIT
END
GO
/****** Object:  StoredProcedure [msp].[LoadStageInventory]    Script Date: 11/16/2023 4:54:44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



/* OraclePatchLevel */
CREATE PROCEDURE [msp].[LoadStageInventory]
AS
BEGIN	
	BEGIN TRAN;
	WITH src AS (
		SELECT
			c.CustomerId
			,p.DATABASE_NAME as InstanceName
			,os.OperatingSystemID
			,e.EnvironmentId
			,[or].release_id as OracleRelease
			,h.HostId
			,CAST(p.[Collected] AS DATETIME) AS Collected
		FROM [staging].[PatchLevel] p
		JOIN [msp].[Customer] c 
		ON p.[CLIENT] = c.CustomerCode
		JOIN [source].[OperatingSystem] os
		on p.OPERATING_SYSTEM = os.OperatingSystem_name
		JOIN [source].[OfficialOracleRelease] [or]
		on p.ORACLE_VERSION = [or].fullname
		JOIN [msp].[Environment] e
		on p.DATABASE_ROLE = e.EnvironmentName
		JOIN [msp].[Host] h
		on h.HostName = p.HOSTNAME

	)
	MERGE INTO [msp].[Inventory] AS tgt USING src
	ON (src.CustomerId = tgt.CustomerId AND src.InstanceName = tgt.InstanceName AND src.EnvironmentId = tgt.EnvironmentId AND src.HostId = tgt.HostId)
	WHEN NOT MATCHED BY TARGET THEN
		INSERT ([CustomerId]
			   ,[InstanceName]
			   ,[OracleRelease]
			   ,[OperatingSystemId]
			   ,[EnvironmentId]
			   ,[HostId]
			   )
		VALUES 
		([src].[CustomerId]
		,[src].[InstanceName]
		,[src].[OracleRelease]
		,[src].[OperatingSystemId]
		,[src].[EnvironmentId]
		,[src].[HostId]);
		COMMIT
END
GO
/****** Object:  StoredProcedure [msp].[LoadStagePatchData]    Script Date: 11/16/2023 4:54:44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/* OraclePatchLevel */
CREATE PROCEDURE [msp].[LoadStagePatchData]
AS
BEGIN	
	BEGIN TRAN;
	WITH src AS (
		SELECT
			c.CustomerId
			,i.InstanceId
			,CAST(p.[Collected] AS DATETIME) AS Collected
			,p.[DATABASE_NAME]
			,p.[PATCH_LEVEL] as PatchNumber
		FROM [staging].[PatchLevel] p
		JOIN [msp].[Customer] c 
		ON p.[CLIENT] = c.CustomerCode
		JOIN [msp].[Inventory] i
		ON p.[DATABASE_NAME] = i.InstanceName AND c.CustomerId = i.CustomerId

	)
	MERGE INTO [trend].[PatchLevel] AS tgt USING src
	ON (src.CustomerId = tgt.CustomerId AND src.InstanceId = tgt.InstanceId AND src.Collected = tgt.Collected AND src.PatchNumber = tgt.PatchNumber)
	WHEN NOT MATCHED BY TARGET THEN
		INSERT ([CustomerId]
			   ,[InstanceId]
			   ,[Collected]
			   ,[PatchNumber]
			   )
		VALUES 
		(src.CustomerId
		,src.InstanceId
		,src.Collected
		,src.PatchNumber);
		COMMIT
END
GO
USE [master]
GO
ALTER DATABASE [OracleMSP] SET  READ_WRITE 
GO
