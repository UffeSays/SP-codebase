USE [datalake]
GO
/****** Object:  StoredProcedure [dbo].[create_dimtables]    Script Date: 2017-11-16 14:58:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROC [dbo].[create_dimtables]
AS

IF OBJECT_ID('datamarts.dDistribution', 'U') IS NOT NULL
DROP TABLE datamarts.dDistribution

IF OBJECT_ID('datamarts.dAvräkningsområde', 'U') IS NOT NULL
DROP TABLE datamarts.dAvräkningsområde

IF OBJECT_ID('datamarts.dDistCodeGroup', 'U') IS NOT NULL
DROP TABLE datamarts.dDistCodeGroup

IF OBJECT_ID('datamarts.dDistributionCode', 'U') IS NOT NULL
DROP TABLE datamarts.dDistributionCode

IF OBJECT_ID('datamarts.dProcess', 'U') IS NOT NULL
DROP TABLE datamarts.dProcess

IF OBJECT_ID('datamarts.dSociety', 'U') IS NOT NULL
DROP TABLE datamarts.dSociety

IF OBJECT_ID('datamarts.dCountry', 'U') IS NOT NULL
DROP TABLE datamarts.dCountry

IF OBJECT_ID('datamarts.dWork', 'U') IS NOT NULL
DROP TABLE datamarts.dWork

IF OBJECT_ID('datamarts.dReportRow', 'U') IS NOT NULL
DROP TABLE datamarts.dReportRow

IF OBJECT_ID('datamarts.dIPBaseName', 'U') IS NOT NULL
DROP TABLE datamarts.dIPBaseName

IF OBJECT_ID('datamarts.dIPInfoName', 'U') IS NOT NULL
DROP TABLE datamarts.dIPInfoName

IF OBJECT_ID('datamarts.dCAECode', 'U') IS NOT NULL
DROP TABLE datamarts.dCAECode

IF OBJECT_ID('datamarts.dTypeOfRight', 'U') IS NOT NULL
DROP TABLE datamarts.dTypeOfRight

IF OBJECT_ID('datamarts.dCommissiontype', 'U') IS NOT NULL
DROP TABLE datamarts.dCommissiontype

IF OBJECT_ID('datamarts.dResApprovedForDistribution', 'U') IS NOT NULL
DROP TABLE datamarts.dResApprovedForDistribution

IF OBJECT_ID('datamarts.dResStatus', 'U') IS NOT NULL
DROP TABLE datamarts.dResStatus

-----------------------
-- dDistribution
SELECT CONVERT(int, s.distributionkey) AS DistKey, 
       description AS DistDesc, 
       description + ' (' + CONVERT(varchar, s.distributionkey) + ')' AS DistDescAndKey, 
       description + ' -- ' + CONVERT(varchar, CONVERT(date, s.distributiondate)) + ' (' + CONVERT(varchar, s.distributionkey) + ')' AS DistDescWithDateAndKey, 
       CONVERT(date, distributiondate) AS DistDate,
	   COALESCE(de.DistEventKey, 0) AS DistEventKey,
	   COALESCE(de.DistEventDesc, 'Ej kopplade avräkningar') AS DistEventDesc,
	   DistEventOrderDate
INTO datamarts.dDistribution
FROM (SELECT distributionkey, description, distributiondate FROM vw_dstidn_all) s
LEFT JOIN udd_distribution_to_distributionevent dd ON s.distributionkey = dd.distributionkey
LEFT JOIN udd_distributionevents de ON dd.DistEventKey = de.DistEventKey

CREATE CLUSTERED INDEX [CI-DistKey] ON [datamarts].[dDistribution]
([DistKey] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

 
-----------------------
-- dAvräkningsområde
SELECT ao.aoaoid AS DistAreaCodeKey, ao.aotext AS DistAreaDesc, COALESCE(aog.DistAreaGroupDesc, 'Övriga') AS DistAreaGroupDesc 
INTO datamarts.dAvräkningsområde
FROM gemavopf ao
LEFT OUTER JOIN udd_distareagroup aog ON ao.aoaoid = aog.DistAreaCodeKey

CREATE CLUSTERED INDEX [CI-DistAreaCodeKey] ON [datamarts].[dAvräkningsområde]
([DistAreaCodeKey] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

-----------------------
-- dDistCodeGroup-- Bara en DCG-rad. Finns flera pga processkey och de kan ha olika beskrivning
SELECT CONVERT(int, distributioncodegroup) AS DistCodeGroupKey, 
       MAX(distributioncodegroupdescriptionswe) AS DistCodeGroupDesc 
INTO datamarts.dDistCodeGroup
FROM vw_dstdcg_all
GROUP BY distributioncodegroup 

CREATE CLUSTERED INDEX [CI-DistCodeGroupKey] ON [datamarts].[dDistCodeGroup]
([DistCodeGroupKey] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

-----------------------
-- dDistributionCode
SELECT distributioncode as DistCodeKey, MAX(pdcdescriptionswe) AS DistCodeDesc
INTO datamarts.dDistributionCode
FROM dstpdc_2017
GROUP BY distributioncode 

CREATE CLUSTERED INDEX [CI-DistCodeKey] ON [datamarts].[dDistributionCode]
([DistCodeKey] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

-----------------------
-- dProcess
SELECT 	
	CONVERT(int, processkey) AS ProcessKey, 
	distributionkey AS DistKey, 
	distributionareacode AS DistAreaCodeKey, 
	distributioncodegroup AS DistCodeGroupKey,  
	distributioncodegroupdescriptionswe AS DistCodeGroupDesc, 
	distributioncodegroupfromdate AS DCGFromDate, 
	distributioncodegrouptodate AS DCGToDate,
	distributionphase AS DistPhase, 
	distributionstatus AS DistStatus, 
	distcomment AS DistComment
INTO datamarts.dProcess
FROM (
	SELECT 	processKey, distributionkey, distributionareacode, distributioncodegroup, distributioncodegroupdescriptionswe, distributioncodegroupfromdate,
			distributioncodegrouptodate, distributionphase, distributionstatus, distcomment FROM vw_dstdcg_all
) s

CREATE CLUSTERED INDEX [CI-ProcesKey] ON [datamarts].[dProcess]
([ProcessKey] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

-----------------------
-- dSociety
SELECT f.societycode AS SocietyCode, 
       COALESCE(scakny, f.societycode + ' - Okänt sällskap') AS SocietyName, 
       COALESCE(scland, '--') AS SocietyCountryCode, 
       COALESCE(lnnamn, f.societycode + ' - Okänt sällskap') AS SocietyCountryNameSwe, 
       COALESCE(lnname, f.societycode + ' - Okänt sällskap') AS SocietyCountryNameEng
INTO datamarts.dSociety
FROM
(SELECT distinct societycode FROM 
	(SELECT distinct societycode FROM vw_dstaps_all UNION ALL
	 SELECT distinct helpsocietycode FROM vw_dstaps_all AS societycode UNION ALL
	 SELECT distinct usagereportsocietycode FROM vw_dstaps_all AS societycode) t
) f
LEFT OUTER JOIN
( SELECT scslsk, scakny, scland, lnnamn, lnname FROM gemsocpf_2017 sc 
  INNER JOIN gemlndpf ln ON sc.scland = ln.lnland
) s ON s.SCSLSK = f.societycode

CREATE CLUSTERED INDEX [CI-SocietyCode] ON [datamarts].[dSociety]
([SocietyCode] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

-----------------------
-- dCountry
SELECT COALESCE(lnland, '') AS CountryCode, 
       COALESCE(lnnamn, 'Okänt land') AS CountryNameSwe, 
       COALESCE(lnname, 'Okänt land') AS CountryNameEng
INTO datamarts.dCountry
FROM 
(SELECT DISTINCT countryofuse FROM vw_dstrrw_all) d
left outer join
gemlndpf l on l.lnland = d.countryofuse

CREATE CLUSTERED INDEX [CI-CountryCode] ON [datamarts].[dCountry]
([CountryCode] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

-----------------------
-- dWork
-- Tar namnet från den förekomsten med den senaste DistKey:n
SELECT CONVERT(int, w.IceWorkKey) AS IceWorkKey, 
       w.WorkTitle, 
       w.WorkTitle + ' (' + CAST(w.IceWorkKey as varchar) + ')' AS WorkTitleKeyLatest, 
       Left(w.WorkDuration ,2) * 3600 + substring(w.WorkDuration , 4,2) * 60 + substring(w.WorkDuration , 7,2) AS WorkDurationSec, 
       w.IceWorkKeyOrig AS OriginalWorkIceWorkKey, 
       wt.WorkTitleOriginal AS OriginalWorkTitle, 
       wt.WorkTitleOriginal + ' (' + CAST(w.IceWorkKeyOrig as varchar) + ')' AS OriginalWorkTitleAndKeyLatest
INTO datamarts.dWork
FROM
(
	SELECT IceWorkKey, MAX(distributionkey) as DistKey
    FROM vw_dstwrk_all
    GROUP BY iceworkkey
) s
INNER JOIN (
	SELECT IceWorkKey, distributionkey, Max(worktitle) AS worktitle, MAX(workduration) AS workduration, MAX(IceWorkKeyOrig) AS IceWorkKeyOrig
    FROM vw_dstwrk_all
	GROUP BY iceworkkey, distributionkey
) w 
ON w.DistributionKey = s.DistKey AND w.IceWorkKey = s.IceWorkKey
LEFT OUTER JOIN (
	SELECT distributionkey, iceworkkey, MAX(worktitleoriginal) AS worktitleoriginal FROM vw_dstwot_all GROUP BY distributionkey, iceworkkey
) wt
ON s.DistKey = wt.DistributionKey AND w.IceWorkKeyOrig = wt.IceWorkKey 

CREATE CLUSTERED COLUMNSTORE INDEX [CCI-dWork] ON [datamarts].[dWork] WITH (DROP_EXISTING = OFF, COMPRESSION_DELAY = 0) ON [PRIMARY]

-----------------------
-- dReportRow
-- Tar namn och duration från raden med den högsta processkeyn (senaste)
-- Hämtar rapportsystem (SelectType) från DSTRRW för att inte blanda prodkeys från olika system
SELECT s.ProductionKey, 
       MAX(p.productionname) AS ProductionName, 
       MAX(p.productionname + ' (' + s.ProductionKey + ')') AS ProductionNameAndKey,
       MAX(p.totalmusicduration) AS ProductionMusicDurationSec
INTO datamarts.dReportRow
FROM (
	SELECT rw.selecttype, rp.localprodkey, rp.reportkey, rp.reportrowkey, selecttype + '-' + CAST(localprodkey as varchar) AS ProductionKey, MAX(rp.processkey) AS processkey 
    FROM vw_dstrpw_all rp 
    INNER JOIN vw_dstrrw_all rw ON rp.processkey = rw.processkey AND rp.reportkey = rw.reportkey AND rp.reportrowkey = rw.reportrowkey 
	GROUP BY rw.selecttype, rp.localprodkey, rp.reportkey, rp.reportrowkey
) s
INNER JOIN vw_dstrpw_all p ON p.processkey = s.processkey AND p.localprodkey = s.localprodkey AND p.reportkey = s.reportkey AND p.reportrowkey = s.reportrowkey
WHERE p.distributionkey in (SELECT distributionkey FROM udd_distribution_to_distributionevent)
GROUP BY s.productionkey

-- För att matcha alla aps-rader så lägg till rader med de källor (SelectionType) som har rader med LocalProdKey = 0
INSERT INTO datamarts.dReportRow
SELECT  selectiontype + '-0' AS ProductionKey,
        'Ingen produktion' AS ProductionName, 
        'Ingen produktion' AS ProductionNameAndKey,
		0 AS ProductionMusicDurationSec
FROM (SELECT DISTINCT selectiontype FROM vw_dstaps_all WHERE localprodkey = 0) s

-- Skapa CCI
CREATE CLUSTERED COLUMNSTORE INDEX [CCI-dReportRow] ON [datamarts].[dReportRow] WITH (DROP_EXISTING = OFF, COMPRESSION_DELAY = 0) ON [PRIMARY]


-----------------------
-- dIPBaseName
SELECT CONVERT(int, ib.iceipbasekey) as IPBaseKey, 
       LTRIM(LTRIM(ib.ipbfirstname) + ' ' + LTRIM(ib.ipbname)) AS IPBaseName, 
       LTRIM(LTRIM(ib.ipbfirstname) + ' ' + LTRIM(ib.ipbname)) + ' (' + CAST(ib.iceipbasekey as varchar) + ')' AS IPBaseNameAndKey, 
       CONVERT(date, ib.dateofdeath) AS IPBDateofDeath
INTO datamarts.dIPBaseName
FROM (SELECT iceipbasekey, 
             MAX(distributionkey) AS distributionkey 
      FROM vw_dstipb_all 
      GROUP BY iceipbasekey) s
INNER JOIN vw_dstipb_all ib ON ib.distributionkey = s.distributionkey AND 
                             ib.iceipbasekey = s.iceipbasekey 

-- Skapa CCI
CREATE CLUSTERED COLUMNSTORE INDEX [CCI-dIPBaseName] ON [datamarts].[dIPBaseName] WITH (DROP_EXISTING = OFF, COMPRESSION_DELAY = 0) ON [PRIMARY]

-----------------------
-- dIPInfoName
SELECT CONVERT(int, ii.iceipnamekey) AS IPNameKey, 
       LTRIM(LTRIM(ii.ipifirstname) + ' ' + LTRIM(ii.ipiname)) AS IPInfoName, 
       LTRIM(LTRIM(ii.ipifirstname) + ' ' + LTRIM(ii.ipiname)) + ' (' + CAST(ii.iceipnamekey as varchar) + ')' AS IPInfoNameAndKey, 
       ii.iceipbasekey AS IPBaseKey, LTRIM(LTRIM(ib.ipbfirstname) + ' ' + LTRIM(ib.ipbname)) + ' (' + CAST(ib.iceipbasekey as varchar) + ')' AS IPBaseNameAndKey
INTO datamarts.dIPInfoName
FROM (SELECT iceipnamekey, 
             MAX(distributionkey) AS distributionkey 
      FROM vw_dstipi_all 
      GROUP BY iceipnamekey) s
INNER JOIN vw_dstipi_all ii ON ii.distributionkey = s.distributionkey AND 
                             ii.iceipnamekey = s.iceipnamekey
INNER JOIN vw_dstipb_all ib ON ii.distributionkey = ib.distributionkey AND 
                             ii.iceipbasekey = ib.iceipbasekey 

-- Skapa CCI
CREATE CLUSTERED COLUMNSTORE INDEX [CCI-dIPInfoName] ON [datamarts].[dIPInfoName] WITH (DROP_EXISTING = OFF, COMPRESSION_DELAY = 0) ON [PRIMARY]

-----------------------
-- dCAECode
SELECT CAECode 
INTO datamarts.dCAECode
FROM (SELECT 'A' AS CAECode UNION 
      SELECT 'AD' UNION 
      SELECT 'AR' UNION 
      SELECT 'C' UNION 
      SELECT 'CA' UNION 
      SELECT 'E' UNION 
      SELECT 'SA' UNION 
      SELECT 'SE' UNION 
      SELECT 'SR' UNION 
      SELECT 'TR') s

CREATE CLUSTERED INDEX [CI-CAECode] ON [datamarts].[dCAECode]
([CAECode] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)


-----------------------
-- dTypeOfRight
SELECT TypeOfRight 
INTO datamarts.dTypeOfRight
FROM (SELECT 'PR' AS TypeOfRight UNION 
      SELECT 'MR') s

CREATE CLUSTERED INDEX [CI-TypeOfRight] ON [datamarts].[dTypeOfRight]
([TypeOfRight] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

-----------------------
-- dCommissiontype
SELECT CONVERT(smallint, deductiontype) AS CommissionTypeKey, 
       description AS CommissionType
INTO datamarts.dCommissiontype
FROM dstpdt
WHERE deductiontypecode = 'C'
UNION (SELECT 0, 'Inget kommissionsavdrag')

CREATE CLUSTERED INDEX [CI-CommissionTypeKey] ON [datamarts].[dCommissiontype]
([CommissionTypeKey] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

-----------------------
-- dResApprovedForDistribution
SELECT CONVERT(smallint, ascid) AS ApprovedForDistributionKey, 
       description AS AppForDistDescription 
INTO datamarts.dResApprovedForDistribution
FROM dstasc
WHERE ascid IN (1,2,5,6,7,8,9)

CREATE CLUSTERED INDEX [CI-ApprovedForDistributionKey] ON [datamarts].[dResApprovedForDistribution]
([ApprovedForDistributionKey] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

-----------------------
-- dResStatus
SELECT CONVERT(smallint, resstatus) AS ResStatusKey, 
       resstatusdescriptionswe AS ResStatusDescription
INTO datamarts.dResStatus
FROM udd_resstatus

CREATE CLUSTERED INDEX [CI-ResStatusKey] ON [datamarts].[dResStatus]
([ResStatusKey] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
