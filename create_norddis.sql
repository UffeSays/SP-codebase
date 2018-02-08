USE [datalake]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROC [dbo].[create_norddis]
AS

IF OBJECT_ID('datamarts.fNorddisAPS', 'U') IS NOT NULL DROP TABLE datamarts.fNorddisAPS
IF OBJECT_ID('datamarts.dNorddisDistribution', 'U') IS NOT NULL DROP TABLE datamarts.dNorddisDistribution
IF OBJECT_ID('datamarts.dNorddisDistribitionCode', 'U') IS NOT NULL DROP TABLE datamarts.dNorddisDistribitionCode


-----------------------
-- fNorddisAPS
SELECT *
INTO datamarts.fNorddisAPS
FROM dbo.dinmippf

-----------------------
-- dNorddisDistribution
SELECT DISTRIBUTIONKEY AS DistKey,
       DISTRIBUTIONCODEGROUPDESCRIPTIONSWE AS DistDesc, 
       DISTRIBUTIONCODEGROUPDESCRIPTIONSWE + ' (' + CONVERT(varchar, DISTRIBUTIONKEY) + ')' AS DistDescAndKey, 
       DISTRIBUTIONCODEGROUPDESCRIPTIONSWE + ' -- ' + COALESCE(CONVERT(varchar, (CONVERT(date, CONVERT(varchar, DISTRIBUTIONDATE)))), '<Saknar datum>') + ' (' + CONVERT(varchar, DISTRIBUTIONKEY) + ')' AS DistDescWithDateAndKey, 
       CONVERT(date, CONVERT(varchar, DISTRIBUTIONDATE)) AS DistDate
INTO datamarts.dNorddisDistribution
FROM dbo.fdisvb


CREATE CLUSTERED INDEX [CI-workkey] ON [datamarts].[fNorddisAPS]
([workkey] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

CREATE CLUSTERED INDEX [CI-workKey] ON [datamarts].[dNorddisDistribition]
([workkey] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)


GO
