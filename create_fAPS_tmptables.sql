USE [datalake]
GO
/****** Object:  StoredProcedure [dbo].[create_fAPS_tmptables]    Script Date: 2018-01-19 12:43:12 ******/
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
-- * create_fRES_facts
-- * create:fNCB_facts


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
-- Kör dynamisk SQL byggd ovan
EXECUTE sp_executesql @sql

-----------------------------------------------

-- Tmp-tabell för gradering men som inte behöver årtal
IF OBJECT_ID('tmp.for_dm_dstwla', 'U') IS NOT NULL
DROP TABLE tmp.for_dm_dstwla 

SELECT
	w.DISTRIBUTIONKEY, 
	w.ICEWORKKEY, 
	-- Alla graderingar utom b-e tolkas som a i TROY-beräkningen (det kan finnas null, -, P och annat i fältet)
	-- Fram till och med minst distkey 1198 så har dessutom graderingar b-e skrivna med versaler tolkats som 'a' i TROY-avräkningen eftersom jämförelsen varit case sensitive
	-- När Gustav ordnar så att beräkningen inte är case sensitive så behöver vi få koll på från vilken distkey och hantera det nedan så att vi får ut rätt gradering
	-- i fältet GraderingSenasteSomAvräkning, dvs den gradering som poängberäkningen utgick från
	CASE WHEN LOCALATTRIBUTEVALUE COLLATE SQL_Latin1_General_CP1_CS_AS IN ('b', 'c', 'd', 'e') THEN LOCALATTRIBUTEVALUE ELSE 'a' END AS GraderingSenasteSomAvräkning, 
	agr.nrg AS GraderingAntalUnikaSomRegistrerat,
	(
		select distinct localattributevalue + ';' 
		from dstwla gl
		where gl.iceworkkey = w.ICEWORKKEY
		for xml path('')
	) GraderingarListaUnikaSomRegistrerat
into tmp.for_dm_dstwla
FROM dstwla w 
INNER JOIN
(
	select iceworkkey, max(distributionkey) as maxdk, count(distinct LOCALATTRIBUTEVALUE) as nrg
	from dstwla
	group by ICEWORKKEY
) agr
ON w.DISTRIBUTIONKEY = agr.maxdk AND w.ICEWORKKEY = agr.ICEWORKKEY
WHERE w.LOCALATTRIBUTETYPE = 2

-----------------------------------------------

-- Tmp-tabell för behandlat Medleydata för upphovspersoner och förlag (berikar dIPBase i martladdning) 
	
IF OBJECT_ID('tmp.for_dm_medley_for_dIpBase', 'U') IS NOT NULL
DROP TABLE tmp.for_dm_medley_for_dIpBase;

WITH mdl AS (
	SELECT mdlpf.*, SONAMN, AULAND, ASORT,ASPONR, PNKOMU, PNLAN
	FROM mdlmdlpf mdlpf
	LEFT OUTER JOIN (SELECT * FROM mdlstopf) orsakskod ON MDMDST=SOMDST AND MDSOKD=SOSOKD
	LEFT OUTER JOIN (SELECT ASMDNR, ASORT, ASPONR FROM mdladspf JOIN mdladrpf ON ASMDNR=ADMDNR AND ASADNR=ADADNR WHERE ADADTP='01') svenskadr ON MDMDNR=ASMDNR
	LEFT OUTER JOIN (SELECT AUMDNR, AULAND FROM mdladupf JOIN mdladrpf ON AUMDNR=ADMDNR AND AUADNR=ADADNR WHERE ADADTP='01') utladr ON MDMDNR=AUMDNR
	LEFT OUTER JOIN (SELECT PNPONR, PNKOMU, PNLAN FROM gempnrpf) komu ON ASPONR = PNPONR
	WHERE MDMDTY IN ('01', '02') -- Upphovsperson och förlag
) 
SELECT  
	MDMDNR AS MdlMedlemsnr, 
	CASE MDMDTY WHEN '01' THEN 'Upphovsperson' WHEN '02' THEN 'Förlag' END AS MdlMedlemstyp,
	CASE MDMDTY 
		WHEN '01' THEN MDNAMN + ', ' + MDFNMR 
		WHEN '02' THEN MDNAMN + CASE WHEN MDFNMN <> MDNAMN THEN COALESCE(', ' + MDFNMN, '') ELSE '' END
	END AS MdlNamn,
	CASE MDMDTY 
		WHEN '01' THEN CASE WHEN MDOPNR = 0 THEN null ELSE CONVERT(date, SUBSTRING(CONVERT(VARCHAR, MDOPNR), 1, 4) + '-' + SUBSTRING(CONVERT(VARCHAR, MDOPNR), 5, 2) + '-' + SUBSTRING(CONVERT(VARCHAR, MDOPNR), 7, 2)) END 
		WHEN '02' THEN NULL
	END AS MdlFödelseDatum, 
	CASE MDMDTY WHEN '01' THEN MDMEDB WHEN '02' THEN NULL END AS MdlFolkbokföringLand,	
	CASE MDMDTY 
		WHEN '01' THEN NULL
		WHEN '02' THEN CASE WHEN MDOPNR <= 9999999999 THEN SUBSTRING(CONVERT(varchar, MDOPNR), 1, 6) + '-' + SUBSTRING(CONVERT(varchar, MDOPNR), 7, 4) ELSE SUBSTRING(CONVERT(varchar, MDOPNR), 1, 8) + '-' + SUBSTRING(CONVERT(varchar, MDOPNR), 9, 4) END 
	END AS MdlOrganisationsnr,
	CRTDTE AS MdlUppläggningsdatum,
	MDAFDT AS MdlAnslutenFrånDatum,
	MDATDT AS MdlAnslutTillDatum, 
	CASE WHEN MDAUDT = 0 THEN 'Ej avliden/upphört' ELSE 'Avliden/upphört' END AS MdlAvlidenUpphört,
	MDAUDT AS MdlAvlidenUpphörtDatum,
	CASE WHEN MDMDST = 0 THEN '0 - Registrerad' WHEN MDMDST = 1 THEN '1 - Ansluten' WHEN MDMDST = 9 THEN '9 - Inaktiv' ELSE 'Okänd status (' + MDMDST + ')' END AS MdlStatus,
	MDSTDT AS MdlStatusDatum, 
	MDSOKD + ' - ' + SONAMN AS MdlStatusOrsak,
	MDSODT AS MdlStatusOrsaksdatum, 
	CASE WHEN MDSTAV = 0 THEN '0 - Ej påbörjat avslut' WHEN MDSTAV = 1 THEN '1 - Påbörjat avslut' WHEN MDSTAV = 2 THEN '2 - Ärende skapat' WHEN MDSTAV = 3 THEN '3 - Slutfört' ELSE 'Okänt värde (' + MDSTAV + ')' END AS MdlStatusAvslut,
	CASE WHEN MDKNKD = 0 THEN '0 - Okänd' WHEN MDKNKD = 1 THEN '1 - Kvinna' WHEN MDKNKD = 2 THEN '2 - Man' ELSE 'Okänt värde (' + MDKNKD + ')' END AS MdlKön,  
	MDSPKD AS MdlSpråkKod, 
	CASE WHEN MDSBYT = 0 THEN '0 - Nej' WHEN MDSBYT = 1 THEN '1 - Ja' ELSE 'Okänt värde (' + MDSBYT + ')' END AS MdlSällskapsbyteTillstim,
	CASE WHEN MDSTOP = 0 THEN '0 - Nej' WHEN MDSTOP = 1 THEN '1 - Ja' ELSE 'Okänt värde (' + MDSTOP + ')' END AS MdlStoppadUtbetalning,
	CASE WHEN ASORT <> '' THEN 'SE' ELSE AULAND END AS MdlLandKod, 
	ASORT AS MdlSvenskOrt,
	ASPONR AS MdlPostNr,
	PNKOMU AS MdlKommun,
	PNLAN AS MdlLän
INTO tmp.for_dm_medley_for_dIpBase
FROM mdl





