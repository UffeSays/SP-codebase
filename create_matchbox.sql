USE [datalake]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROC [dbo].[create_matchbox]
AS

IF OBJECT_ID('datamarts.fMBhdr', 'U') IS NOT NULL DROP TABLE datamarts.fMBhdr
IF OBJECT_ID('datamarts.dMBart', 'U') IS NOT NULL DROP TABLE datamarts.dMBart
IF OBJECT_ID('datamarts.dMBipi', 'U') IS NOT NULL DROP TABLE datamarts.dMBipi
IF OBJECT_ID('datamarts.dMBipw', 'U') IS NOT NULL DROP TABLE datamarts.dMBipw
IF OBJECT_ID('datamarts.dMBtit', 'U') IS NOT NULL DROP TABLE datamarts.dMBtit
IF OBJECT_ID('datamarts.dMBref', 'U') IS NOT NULL DROP TABLE datamarts.dMBref


-----------------------
-- fMBhdr
SELECT *
INTO datamarts.fMBhdr
FROM dbo.mbhdr  a

-----------------------
-- dMBart
SELECT *
INTO datamarts.dMBart
FROM dbo.mbart  a
	

-----------------------
-- dMBipi
SELECT *
INTO datamarts.dMBipi
FROM dbo.mbipi  a

-----------------------
-- dMBipw
SELECT *
INTO datamarts.dMBipw
FROM dbo.mbipw  a

-----------------------
-- dMBtit
SELECT *
INTO datamarts.dMBtit
FROM dbo.mbtit  a

-----------------------
-- dMBref
SELECT *
INTO datamarts.dMBref
FROM dbo.mbref  a

CREATE CLUSTERED INDEX [CI-workkey] ON [datamarts].[fMBhdr]
([workkey] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

CREATE CLUSTERED INDEX [CI-workKey] ON [datamarts].[dMBart]
([workkey] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

CREATE CLUSTERED INDEX [CI-ipnamekey] ON [datamarts].[dMBipi]
([ipnamekey] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

CREATE CLUSTERED INDEX [CI-workKey] ON [datamarts].[dMBipw]
([workkey] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

CREATE CLUSTERED INDEX [CI-workKey] ON [datamarts].[dMBtit]
([workkey] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

CREATE CLUSTERED INDEX [CI-workKey] ON [datamarts].[dMBref]
([workkey] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

GO