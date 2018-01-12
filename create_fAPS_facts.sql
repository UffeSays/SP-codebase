USE [datalake]
GO
/****** Object:  StoredProcedure [dbo].[create_fAPS_facts]    Script Date: 2018-01-12 15:43:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





ALTER PROC [dbo].[create_fAPS_facts] @pmYear nvarchar(4)
AS

-- Laddning av fAPS_<årtal> - Fakta för avräkningar
-- Anropa med parameter för vilket år som ska laddas
--
-- Kräver att stored procedures "create_fAPS_tmptables" och "create_fAPS_temptables_indexes" 
-- har körts för att hjälptabellerna "for_dm_*" ska ha genererats
--
-- Typiskt för att ladda ett år körs:
-- * create_dimtables
-- * create_fAPS_tmptables
-- * create_fAPS_tmptables_indexes
-- * create_fAPS_facts
-- * createfRES_facts



SET NOCOUNT ON
DECLARE @sql nvarchar(max)

SET @sql = N'
IF OBJECT_ID(''datamarts.fAPS_' + @pmYear + ''', ''U'') IS NOT NULL
DROP table datamarts.fAPS_' + @pmYear + '


-- Själva fAPS tabellen
SELECT	
	CONVERT(int, aps.distributionkey) AS DistKey,
	dcg.distributionareacode AS DistAreaCodeKey,
	CONVERT(int, aps.distributioncodegroupcode) AS DistCodeGroupKey,
	aps.distributioncode AS DistCodeKey,
	CONVERT(int, aps.processkey) AS ProcessKey,
	CONVERT(int, aps.reportkey) AS ReportKey, 
	CONVERT(int, aps.reportrowkey) AS ReportRowKey,
	CONVERT(int, aps.iceworkkey) AS IceWorkKey,
	CONVERT(int, aps.iceipbasekey) AS IceIPBaseKey,
	CONVERT(int, aps.iceipnamekey) AS IceIPNameKey,
	CONVERT(smallint, aps.commisiontype) AS CommissionTypeKey,
	aps.societycode AS SocietyCode,
	aps.usagereportsocietycode AS UsageReportSocietyCode,
	aps.helpsocietycode AS HelpSocietyCode,
	aps.selectiontype + ''-'' + CONVERT(varchar, aps.localprodkey) AS ProductionKey,
	rrw.countryofuse AS CountryOfUseCode,
	aps.caecode AS CAECode,
	aps.typeofright AS TypeOfRight,
	aps.workkey AS WorkKey,
	CONVERT(int, aps.usagekey) AS UsageKey,
	CONVERT(int, aps.CAR) AS CAR,
	CONVERT(date, CASE WHEN Year(rrw.dateofuse) < 1990 THEN null ELSE rrw.dateofuse END) AS DateOfUse,
	aps.currency AS CurrencyCode, 
	CONVERT(int, aps.numberofuses) AS NumberOfUsesByWork,
	CONVERT(int, rmw.duration) AS DurationSecByWork,
	aps.shareprc AS SharePrc,
	cbp.comfact * (aps.amount + aps.deductamount)  + (aps.amount + aps.deductamount) AS AmountToDistribute, 
	cbp.comfact * (aps.amount + aps.deductamount) AS CommissionAmount, 
	cbp.commissionpercent AS CommissionPercent,
	aps.amount + aps.deductamount AS AmountAfterCommission, 
	aps.deductamount AS DeductAmountTot, 
	COALESCE(aps.deductamount * dbpt.dedamstipshare, 0) AS DeductAmountStip, 
	COALESCE(aps.deductamount * dbpt.dedammemshare, 0) AS DeductAmountMem, 
	COALESCE(aps.deductamount * dbpt.dedamothershare, 0) AS DeductAmountOther,
	aps.amount AS AmountDistributed
INTO datamarts.fAPS_' + @pmYear + '
FROM dbo.dstaps_' + @pmYear + ' aps
INNER JOIN tmp.for_dm_dstdcg_' + @pmYear + ' dcg ON aps.processkey = dcg.processkey
INNER JOIN tmp.for_dm_commission_by_processkey_' + @pmYear + ' cbp ON aps.processkey = cbp.processkey 
INNER JOIN tmp.for_dm_report_processkey_' + @pmYear + ' rpk ON aps.processkey = rpk.processkey
INNER JOIN tmp.for_dm_dstrrw_' + @pmYear + ' rrw ON rpk.reportprocesskey = rrw.processkey AND aps.reportkey = rrw.reportkey AND aps.reportrowkey = rrw.reportrowkey
INNER JOIN tmp.for_dm_dstrmw_' + @pmYear + ' rmw ON rpk.reportprocesskey = rmw.processkey AND aps.reportkey = rmw.reportkey AND aps.reportrowkey = rmw.reportrowkey AND aps.workkey = rmw.workkey
LEFT OUTER JOIN tmp.for_dm_deduct_by_processkey_tor_' + @pmYear + ' dbpt ON aps.processkey = dbpt.processkey AND aps.typeofright = dbpt.typeofright

CREATE CLUSTERED COLUMNSTORE INDEX ccs_Index ON datamarts.fAPS_' + @pmYear + '
CREATE NONCLUSTERED INDEX [NCI-DateOfUse] ON datamarts.fAPS_' + @pmYear + ' (DateOfUse ASC)
'

EXECUTE sp_executesql @sql
