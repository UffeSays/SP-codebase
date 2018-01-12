USE [datalake]
GO
/****** Object:  StoredProcedure [dbo].[create_fRES_facts]    Script Date: 2018-01-12 15:49:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROC [dbo].[create_fRES_facts] @pmYear nvarchar(4)
AS

-- Laddning av fRES_<årtal> - Fakta för reserveringar
-- Anropa med parameter för vilket år som ska laddas
--
-- Kräver att stored procedures "create_fAPS_tmptables" och "create_fAPS_temptables_indexes" 
-- har körts för att hjälptabellerna "for_dm_*" ska ha genererats
--
-- Typiskt för att ladda ett år körs:
-- * create_dimtables
-- * create_fAPS_tmptables
-- * create_fAPS_temptables_indexes
-- * create_fAPS_facts
-- * create_fRES_facts


SET NOCOUNT ON
DECLARE @sql nvarchar(max)

SET @sql = N'
IF OBJECT_ID(''datamarts.fRES_' + @pmYear + ''', ''U'') IS NOT NULL
DROP table datamarts.fRES_' + @pmYear + '

-- Själva fRES tabellen
SELECT 
	CONVERT(int, res.distributionkey) AS DistKey,
	dcg.distributionareacode AS DistAreaCodeKey,
	CONVERT(int, res.distributioncodegroupcode) AS DistCodeGroupKey,
	res.distributioncode AS DistCodeKey,
	CONVERT(int, res.processkey) AS ProcessKey,
	CONVERT(int, res.reportkey) AS ReportKey, 
	CONVERT(int, res.reportrowkey) AS ReportRowKey,
	CONVERT(int, res.iceworkkey) AS IceWorkKey,
	CONVERT(smallint, cbp.commtype) AS CommissionTypeKey,
	rrw.countryofuse AS CountryOfUseCode,
	CONVERT(smallint, res.approvedfordistribution) AS ApprovedForDistributionKey, 
	CONVERT(smallint, res.resstatus) AS ResStatusKey, 
	res.workkey AS WorkKey,
	CONVERT(int, res.usagekey) AS UsageKey, 
	CONVERT(date, CASE WHEN Year(rrw.dateofuse) < 1990 THEN null ELSE rrw.dateofuse END) AS DateOfUse,
	CONVERT(date, CASE WHEN res.settledtimestp = ''0001-01-01'' THEN null ELSE res.settledtimestp END) AS SettledDate,
	res.reservedshare AS ReservedSharePrc,
	cbp.comfact * res.reservedamount + res.reservedamount AS AmountToReserve, 
	cbp.comfact * res.reservedamount  AS CommissionAmount, 
	cbp.commissionpercent AS CommissionPercent,
	res.reservedamount AS AmountReserved
INTO datamarts.fRES_' + @pmYear + '
FROM dbo.dstres_' + @pmYear + ' res	
INNER JOIN tmp.for_dm_commission_by_processkey_' + @pmYear + ' cbp ON res.processkey = cbp.processkey
INNER JOIN tmp.for_dm_dstdcg_' + @pmYear + ' dcg ON res.processkey = dcg.processkey
INNER JOIN tmp.for_dm_report_processkey_' + @pmYear + ' rpk ON res.processkey = rpk.processkey
INNER JOIN tmp.for_dm_dstrrw_' + @pmYear + ' rrw ON rpk.reportprocesskey = rrw.processkey AND res.reportkey = rrw.reportkey AND res.reportrowkey = rrw.reportrowkey
WHERE approvedfordistribution IN (0,1,2,5,6,7,8,9) -- Bara det som är severity RES

CREATE CLUSTERED COLUMNSTORE INDEX CCI_fRES ON datamarts.fRES_' + @pmYear + '
CREATE NONCLUSTERED INDEX [NCI-DateOfUse] ON datamarts.fRES_' + @pmYear + ' (DateOfUse ASC)
CREATE NONCLUSTERED INDEX [NCI-SettledDate] ON datamarts.fRES_' + @pmYear + ' (SettledDate ASC)

'

EXECUTE sp_executesql @sql
