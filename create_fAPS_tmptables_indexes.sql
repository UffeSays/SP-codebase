USE [datalake]
GO
/****** Object:  StoredProcedure [dbo].[create_fAPS_tmptables_indexes]    Script Date: 2018-01-12 15:48:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




ALTER PROC [dbo].[create_fAPS_tmptables_indexes] @pmYear nvarchar(4)
					 
AS

-- Skapar index på hjälptabellerna "for_dm_*" för vidare laddning av fAPS_<årtal> och fRES_<årtal>
-- Anropa med parameter för vilket år som ska laddas
-- 
-- Kräver att create_fAPS_tmptables har körts
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

-- Index for for_dm_dstdcg
CREATE NONCLUSTERED INDEX [NCI-ProcessKey] ON tmp.for_dm_dstdcg_' + @pmYear + ' (processkey ASC)
INCLUDE (distributionareacode) 
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)


-- Index for for_dm_dstrrw
CREATE CLUSTERED INDEX [CI-ProcessKeyReportKey] ON tmp.for_dm_dstrrw_' + @pmYear + ' (processkey ASC, reportkey ASC, reportrowkey ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

-- Index for for_dm_dstrmw
CREATE CLUSTERED INDEX [CI-ProcessKeyReportKeyWorkkey] ON tmp.for_dm_dstrmw_' + @pmYear + ' (processkey ASC, reportkey ASC, reportrowkey ASC, workkey ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

-- Index for for_dm_dstwla
CREATE UNIQUE CLUSTERED INDEX [CI-IceWorkKey] ON [tmp].[for_dm_dstwla] ([ICEWORKKEY] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

'

EXECUTE sp_executesql @sql
