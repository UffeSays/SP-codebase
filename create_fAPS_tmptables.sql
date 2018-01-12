USE [datalake]
GO
/****** Object:  StoredProcedure [dbo].[create_fAPS_tmptables]    Script Date: 2017-11-16 15:00:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROC [dbo].[create_fAPS_tmptables] @pmYear nvarchar(4)
					 
AS

-- Skapar hjälptabellerna "for_dm_*" för vidare laddning av fAPS_<årtal> och fRES_<årtal>
-- Anropa med parameter för vilket år som ska laddas
--
-- Typiskt för att ladda ett år körs:
-- * create_dimtables
-- * create_fAPS_tmptables
-- * create_fAPS_temptables_indexes
-- * create_fAPS_facts
-- * createfRES_facts


SET NOCOUNT ON
DECLARE @sql nvarchar(max)

SET @sql = N'

-- Drop existing temp-tables
IF OBJECT_ID(''tmp.for_dm_commission_by_processkey_' + @pmYear + ''', ''U'') IS NOT NULL
DROP table tmp.for_dm_commission_by_processkey_' + @pmYear + '

IF OBJECT_ID(''tmp.for_dm_deduct_by_processkey_tor_' + @pmYear + ''', ''U'') IS NOT NULL
DROP table tmp.for_dm_deduct_by_processkey_tor_' + @pmYear + '

IF OBJECT_ID(''tmp.for_dm_report_processkey_' + @pmYear + ''', ''U'') IS NOT NULL
DROP table tmp.for_dm_report_processkey_' + @pmYear + '

IF OBJECT_ID(''tmp.for_dm_dstdcg_' + @pmYear + ''', ''U'') IS NOT NULL
DROP table tmp.for_dm_dstdcg_' + @pmYear + '

IF OBJECT_ID(''tmp.for_dm_dstrrw_' + @pmYear + ''', ''U'') IS NOT NULL
DROP table tmp.for_dm_dstrrw_' + @pmYear + '

IF OBJECT_ID(''tmp.for_dm_dstrmw_' + @pmYear + ''', ''U'') IS NOT NULL
DROP table tmp.for_dm_dstrmw_' + @pmYear + '


-- Hämtar faktor för att multiplicera fram kommission
SELECT processkey, 
       MAX(CAST(COMMISSIONPERCENT as decimal(22,10)) / (100.0 - commissionpercent)) as comfact, 
       MAX(commtype) AS commtype, MAX(commissionpercent) as commissionpercent  
INTO tmp.for_dm_commission_by_processkey_' + @pmYear + ' 
FROM dstdam_' + @pmYear + '
GROUP BY processkey


-- Hämtar avdrag per processkey och typeofuse
SELECT dbt.processkey, 
       dbt.typeofright, 
       dedamstip, 
       dedammem, 
       dedamother, 
       CAST(dedamstip as decimal(26,10))/dedamsum AS dedamstipshare, 
       CAST(dedammem as decimal(26,10))/dedamsum AS dedammemshare, 
       CAST(dedamother as decimal(26,10))/dedamsum AS dedamothershare
INTO tmp.for_dm_deduct_by_processkey_tor_' + @pmYear + '
FROM (
	SELECT processkey, typeofright, SUM(dedamstip) AS dedamstip, SUM(dedammem) AS dedammem, SUM(dedamother) AS dedamother 
	FROM (
		SELECT processkey, typeofright, deducttype, 
		CASE WHEN deducttype = 3 THEN SUM(deductamount) ELSE 0 END AS dedamstip, CASE WHEN deducttype = 4 THEN SUM(deductamount) ELSE 0 END AS dedammem, CASE WHEN not deducttype in (3,4) THEN SUM(deductamount) ELSE 0 END AS dedamother
 		FROM dstded_' + @pmYear + ' GROUP BY processkey, typeofright, deducttype
	) ded GROUP BY processkey, typeofright
) dbt
INNER JOIN (
	SELECT processkey, typeofright, SUM(deductamount) AS dedamsum 
	FROM dstded_' + @pmYear + ' GROUP BY processkey, typeofright
) dedsum ON dedsum.processkey = dbt.processkey AND dedsum.typeofright = dbt.typeofright
WHERE dedamsum <> 0 


-- Skapa temptabell för att översätta processkey till reportprocesskeys
SELECT dcg.processkey, 
       CASE WHEN dan.selectedprocesskey is null THEN dcg.processkey ELSE dan.selectedprocesskey END AS ReportProcessKey
INTO tmp.for_dm_report_processkey_' + @pmYear + ' 
FROM dstdcg_' + @pmYear + ' dcg 
LEFT OUTER JOIN dstdan_' + @pmYear + ' dan ON dcg.processkey = dan.selectionkey


-- Skapa tabell med processkeys och distarea för de processkeys som gått igenom (D7 och +)
SELECT processkey, distributionareacode
INTO tmp.for_dm_dstdcg_' + @pmYear + '
FROM dstdcg_' + @pmYear + '
WHERE distributionphase = ' + '''D7''' + ' AND distributionstatus = ' + '''+''' + '


-- Hämta ut aktuella rader från alla års dstrrw (pga analogier) för laddning till aktuell dm_aps 
-- Beror av att for_dm_report_processkey laddats
SELECT processkey, reportkey, reportrowkey, countryofuse, dateofuse 
INTO tmp.for_dm_dstrrw_' + @pmYear + '
FROM vw_dstrrw_all 
WHERE processkey in (SELECT DISTINCT ReportProcessKey FROM tmp.for_dm_report_processkey_' + @pmYear + ' )


-- Hämta ut aktuella rader från alla års dstrmw (pga analogier) för laddning till aktuell dm_aps 
-- Beror av att for_dm_report_processkey laddats
SELECT processkey, reportkey, reportrowkey, workkey, duration
INTO tmp.for_dm_dstrmw_' + @pmYear + '
FROM vw_dstrmw_all 
WHERE processkey in (SELECT DISTINCT ReportProcessKey FROM tmp.for_dm_report_processkey_' + @pmYear + ')
'

EXECUTE sp_executesql @sql