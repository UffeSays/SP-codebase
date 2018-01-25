USE [datalake]
GO
/****** Object:  StoredProcedure [dbo].[create_troy_fNCB]    Script Date: 2018-01-25 13:03:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




ALTER PROC [dbo].[create_troy_fNCB] 
AS

-- Laddning av fNCB_all för alla årtal - Fakta för NCB-avräkning
-- Anropa med parameter för vilket år som ska laddas
--
-- Kräver att stored procedures "create_fAPS_tmptables" och "create_fAPS_temptables_indexes" 
-- har körts för att hjälptabellerna "for_dm_*" ska ha genererats
--
-- Typiskt för att ladda ett år körs:
-- * create_troy_tmptables
-- * create_troy_dimtables
-- * create_troy_fAPS
-- * create_troy_fRES
-- * create_tory_fNCB
-- * create_medley_rightsholders


SET NOCOUNT ON
DECLARE @sql nvarchar(max)

IF OBJECT_ID('datamarts.fNCB_all', 'U') IS NOT NULL
DROP table datamarts.fNCB_all

SELECT
	CONVERT(int, 1000000 + mnatnr) AS DistKey,
	mnkate AS Category,
	CONVERT(int, mnipnr) AS IceIPNameKey,
	CONVERT(int, ipi.IPBaseKey) AS IceIPBaseKey,
	CONVERT(int, mnvknr) AS IceWorkKey,
	mnbelp AS NcbAmountDistributed
INTO datamarts.fNCB_all
FROM dinminpf dm
LEFT JOIN datamarts.dIPInfoName ipi ON dm.mnipnr = ipi.IPNameKey
WHERE dm.mnatnr IN (SELECT anatnr FROM dinatnpf WHERE anjbss = '+' AND anjbst IN ('11', '08'))



