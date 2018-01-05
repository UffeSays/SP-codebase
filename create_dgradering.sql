USE [datalake]
GO
/****** Object:  StoredProcedure [dbo].[create_dgradering]    Script Date: 2018-01-05 16:15:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROC [dbo].[create_dgradering]
AS

IF OBJECT_ID('datamarts.dgradering', 'U') IS NOT NULL
DROP TABLE datamarts.dgradering


-----------------------
-- dDistribution
SELECT CONVERT(int, distributionkey) AS DistKey,
       ICEWORKKEY,
       LOCALATTRIBUTEVALUE, 
       GraderingVidAvrakning,
       LOCALATTRIBUTETYPE
INTO datamarts.dgradering
FROM dbo.dstwla
	

CREATE CLUSTERED INDEX [CI-DistKey] ON [datamarts].[dgradering]
([DistKey] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

