USE [datalake]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROC [dbo].[create_matchbox]
AS

IF OBJECT_ID('datamarts.fMatchBoxHeader', 'U') IS NOT NULL DROP TABLE datamarts.fMatchBoxHeader
IF OBJECT_ID('datamarts.dMatchBoxArtist', 'U') IS NOT NULL DROP TABLE datamarts.dMatchBoxArtist
IF OBJECT_ID('datamarts.dMatchBoxIPInfo', 'U') IS NOT NULL DROP TABLE datamarts.dMatchBoxIPInfo
IF OBJECT_ID('datamarts.dMatchBoxIPBase', 'U') IS NOT NULL DROP TABLE datamarts.dMatchBoxIPBase
IF OBJECT_ID('datamarts.dMatchBoxTitle', 'U') IS NOT NULL DROP TABLE datamarts.dMatchBoxTitle
IF OBJECT_ID('datamarts.dMatchBoxReference', 'U') IS NOT NULL DROP TABLE datamarts.dMatchBoxReference


-----------------------
-- fMBhdr
SELECT *
INTO datamarts.fMatchBoxHeader
FROM dbo.mbhdr  a

-----------------------
-- dMBart
SELECT *
INTO datamarts.dMatchBoxArtist
FROM dbo.mbart  a
	

-----------------------
-- dMBipi
SELECT *
INTO datamarts.dMatchBoxIPInfo
FROM dbo.mbipi  a

-----------------------
-- dMBipw
SELECT *
INTO datamarts.dMatchBoxIPBase
FROM dbo.mbipw  a

-----------------------
-- dMBtit
SELECT *
INTO datamarts.dMatchBoxTitle
FROM dbo.mbtit  a

-----------------------
-- dMBref
SELECT *
INTO datamarts.dMatchBoxReference
FROM dbo.mbref  a

CREATE CLUSTERED INDEX [CI-workkey] ON [datamarts].[fMatchBoxHeader]
([workkey] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

CREATE CLUSTERED INDEX [CI-workKey] ON [datamarts].[dMatchBoxArtist]
([workkey] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

CREATE CLUSTERED INDEX [CI-ipnamekey] ON [datamarts].[dMatchBoxIPInfo]
([ipnamekey] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

CREATE CLUSTERED INDEX [CI-workKey] ON [datamarts].[dMatchBoxIPBase]
([workkey] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

CREATE CLUSTERED INDEX [CI-workKey] ON [datamarts].[dMatchBoxTitle]
([workkey] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

CREATE CLUSTERED INDEX [CI-workKey] ON [datamarts].[dMatchBoxReference]
([workkey] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

GO