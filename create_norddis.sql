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
SELECT 	mip.distributionkey AS DistKey,
    	mip.distributionareacode AS DistAreaCodeKey,
    	null AS DistCodeGroupKey,
    	mip.distributioncode AS DistCodeKey,
    	mip.processkey AS ProcessKey,
    	mip.reportkey AS ReportKey, 
    	mip.reportrowkey AS ReportRowKey,
    	ref.workkey AS IceWorkKey,
    	mip.iceipbasekey AS IceIPBaseKey,
    	mip.iceipnamekey AS IceIPNameKey,
    	null AS CommissionTypeKey,
    	mip.societycode AS SocietyCode,
    	mip.usagereportsocietycode AS UsageReportSocietyCode,
    	null AS HelpSocietyCode,
    	null AS ProductionKey,
    	null AS CountryOfUseCode,
    	mip.caecode AS CAECode,
    	null AS TypeOfRight,
    	mip.workkey AS WorkKey,
    	mip.usagekey AS UsageKey,
    	null AS CAR,
    	null AS DateOfUse,
    	null AS CurrencyCode, 
    	mip.numberofuses AS NumberOfUsesByWork,
    	mip.workduration AS DurationSecByWork,
    	mip.shareprc AS SharePrc,
    	mip.mandateid AS MandateID,
    	null AS AmountToDistribute, 
    	null AS CommissionAmount, 
    	null AS CommissionPercent,
    	null AS AmountAfterComission, 
    	null AS DeductAmountTot, 
    	null AS DeductAmountStip, 
    	null AS DeductAmountMem, 
    	null AS DeductAmountOther,
    	mip.amount AS AmountDistributed
INTO datamarts.fNorddisAPS
FROM dbo.dinmippf mip
     left join (SELECT a.*
            FROM tmp.mbref a
            LEFT OUTER JOIN tmp.mbref b ON a.reference = b.reference AND a.refseqnbr < b.refseqnbr
            WHERE a.reftype='NDREF' and 
			      b.reference IS NULL) ref on RIGHT('0000000000'+CAST(mip.workkey AS VARCHAR(9)),9) = ref.reference
 


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



CREATE CLUSTERED COLUMNSTORE INDEX ccs_Index ON datamarts.fNorddisAPS

CREATE CLUSTERED INDEX [CI-DistKey] ON [datamarts].[dNorddisDistribution]
([DistKey] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

CREATE CLUSTERED INDEX [CI-DistKey] ON [datamarts].[dNorddisProcess]
([DistKey] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
