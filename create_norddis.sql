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
IF OBJECT_ID('datamarts.dNorddisProcess', 'U') IS NOT NULL DROP TABLE datamarts.dNorddisProcess


-----------------------
-- fNorddisAPS
SELECT 	distributionkey AS DistKey,
    	distributionareacode AS DistAreaCodeKey,
    	null AS DistCodeGroupKey,
    	distributioncode AS DistCodeKey,
    	processkey AS ProcessKey,
    	reportkey AS ReportKey, 
    	reportrowkey AS ReportRowKey,
    	iceworkkey AS IceWorkKey,
    	iceipbasekey AS IceIPBaseKey,
    	iceipnamekey AS IceIPNameKey,
    	null AS CommissionTypeKey,
    	societycode AS SocietyCode,
    	usagereportsocietycode AS UsageReportSocietyCode,
    	null AS HelpSocietyCode,
    	null AS ProductionKey,
    	null AS CountryOfUseCode,
    	caecode AS CAECode,
    	null AS TypeOfRight,
    	null AS WorkKey,
    	usagekey AS UsageKey,
    	null AS CAR,
    	null AS DateOfUse,
    	null AS CurrencyCode, 
    	numberofuses AS NumberOfUsesByWork,
    	workduration AS DurationSecByWork,
    	shareprc AS SharePrc,
    	mandateid AS MandateID,
    	null AS AmountToDistribute, 
    	null AS CommissionAmount, 
    	null AS CommissionPercent,
    	null AS AmountAfterComission, 
    	null AS DeductAmountTot, 
    	null AS DeductAmountStip, 
    	null AS DeductAmountMem, 
    	null AS DeductAmountOther,
    	amount AS AmountDistributed
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


-----------------------
-- dNorddisProcess
SELECT 	
	CONVERT(int, processkey) AS ProcessKey, 
	distributionkey AS DistKey, 
	null AS DistAreaCodeKey, 
	null AS DistCodeGroupKey,  
	distributioncodegroupdescriptionswe AS DistCodeGroupDesc, 
	distributioncodegroupfromdate AS DCGFromDate, 
	distributioncodegrouptodate AS DCGToDate,
	distributionphase AS DistPhase, 
	distributionstatus AS DistStatus,
	null AS DistComment
INTO datamarts.dNorddisProcess
FROM dbo.fdisvg


CREATE CLUSTERED INDEX [CI-workkey] ON [datamarts].[fNorddisAPS]
([workkey] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

CREATE CLUSTERED INDEX [CI-DistKey] ON [datamarts].[dNorddisDistribution]
([DistKey] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

CREATE CLUSTERED INDEX [CI-DistKey] ON [datamarts].[dNorddisProcess]
([DistKey] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)


