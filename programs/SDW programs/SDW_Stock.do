* Download Stock Price Indices

* Non Euro Area countries as world performance benchmark
global NONEA_ctrylist = "US UK JP"
global all_ctrylist $ctrylist $NONEA_ctrylist
/*
foreach ii of global all_ctrylist {
	
	if "`ii'" == "AT" {
	getTimeSeries ECB FM.Q.AT.EUR.DS.EI.ATXINDX.HSTE $year_start "" 0 1
	}
	if "`ii'" == "BE" {
	getTimeSeries ECB FM.Q.BE.EUR.DS.EI.BGBEL20.HSTE $year_start "" 0 1
	}	
	if "`ii'" == "CY" {
	getTimeSeries ECB FM.Q.CY.EUR.DS.EI.CYPMAPM.HSTE $year_start "" 0 1
	}
	if "`ii'" == "EE" {
	getTimeSeries ECB FM.Q.EE.EEK.DS.EI.ESTALSE.HSTE $year_start "" 0 1
	}
	if "`ii'" == "FI" {
	getTimeSeries ECB FM.Q.FI.EUR.DS.EI.HEXINDX.HSTE $year_start "" 0 1
	}
	if "`ii'" == "FR" {
	getTimeSeries ECB FM.Q.FR.EUR.DS.EI.FRCAC40.HSTE $year_start "" 0 1
	}	
	if "`ii'" == "DE" {
	getTimeSeries ECB FM.Q.DE.EUR.DS.EI.DAXINDX.HSTE $year_start "" 0 1
	}
	if "`ii'" == "GR" {
	getTimeSeries ECB FM.Q.GR.EUR.DS.EI.GRAGENL.HSTE $year_start "" 0 1
	}
	if "`ii'" == "HU" {
	getTimeSeries ECB FM.Q.HU.HUF.DS.EI.BUXINDX.HSTE $year_start "" 0 1
	}
	if "`ii'" == "IE" {
	getTimeSeries ECB FM.Q.IE.EUR.DS.EI.ISEQUIT.HSTE $year_start "" 0 1
	}	
	if "`ii'" == "IT" {
	getTimeSeries ECB FM.Q.IT.EUR.DS.EI.S_PMIBX.HSTE $year_start "" 0 1
	}
	if "`ii'" == "LV" {
	getTimeSeries ECB FM.Q.LV.EUR.DS.EI.RIGSEIN.HSTE $year_start "" 0 1
	}
	if "`ii'" == "LU" {
	getTimeSeries ECB FM.Q.LU.EUR.DS.EI.LUXGENI.HSTE $year_start "" 0 1
	}
	if "`ii'" == "MT" {
	getTimeSeries ECB FM.Q.MT.EUR.BL.EI.MALTEX.HSTE $year_start "" 0 1
	}	
	if "`ii'" == "NL" {
	getTimeSeries ECB FM.Q.NL.EUR.DS.EI.AMSTEOE.HSTE $year_start "" 0 1
	}
	if "`ii'" == "PL" {
	getTimeSeries ECB FM.Q.PL.PLN.DS.EI.POLWIGI.HSTE $year_start "" 0 1
	}
	if "`ii'" == "PT" {
	getTimeSeries ECB FM.Q.PT.EUR.DS.EI.POPSIGN.HSTE $year_start "" 0 1
	}
	if "`ii'" == "SK" {
	getTimeSeries ECB FM.Q.SK.EUR.DS.EI.SXSAX12.HSTE $year_start "" 0 1
	}	
	if "`ii'" == "SI" {
	getTimeSeries ECB FM.Q.SI.EUR.DS.EI.TOTMKSJ.HSTE $year_start "" 0 1
	}
	if "`ii'" == "ES" {
	getTimeSeries ECB FM.Q.ES.EUR.DS.EI.IBEX35I.HSTE $year_start "" 0 1
	}
	
	if "`ii'" == "UK" {
	getTimeSeries ECB FM.Q.GB.EUR.DS.EI.WIUTDKL.HSTE $year_start "" 0 1
	}	
	if "`ii'" == "US" {
	getTimeSeries ECB FM.Q.U2.EUR.DS.EI.DJSTOXX.HSTE $year_start "" 0 1
	}
	if "`ii'" == "JP" {
	getTimeSeries ECB FM.Q.JP.EUR.DS.EI.WIJPANL.HSTE $year_start "" 0 1
	}

	drop TSNAME
	rename VALUE Stock_`ii'
	label variable Stock_`ii' "Country specific stock price index"
	rename DATE PERIOD_NAME
	sort PERIOD_NAME
	compress
	save "$dataoutputPath/Stock_`ii'.dta", replace	
	
}
*/
foreach ii of global all_ctrylist {
	
	if "`ii'" == "AT" {
	*getTimeSeries ECB FM.Q.AT.EUR.DS.EI.ATXINDX.HSTE $year_start "" 0 1
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_FM_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('FM.Q.AT.EUR.DS.EI.ATXINDX.HSTE') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}
	if "`ii'" == "BE" {
	*getTimeSeries ECB FM.Q.BE.EUR.DS.EI.BGBEL20.HSTE $year_start "" 0 1
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_FM_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('FM.Q.BE.EUR.DS.EI.BGBEL20.HSTE') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}	
	if "`ii'" == "CY" {
	*getTimeSeries ECB FM.Q.CY.EUR.DS.EI.CYPMAPM.HSTE $year_start "" 0 1
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_FM_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('FM.Q.CY.EUR.DS.EI.CYPMAPM.HSTE') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}
	if "`ii'" == "EE" {
	*getTimeSeries ECB FM.Q.EE.EEK.DS.EI.ESTALSE.HSTE $year_start "" 0 1
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_FM_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('FM.Q.EE.EEK.DS.EI.ESTALSE.HSTE') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}
	if "`ii'" == "FI" {
	*getTimeSeries ECB FM.Q.FI.EUR.DS.EI.HEXINDX.HSTE $year_start "" 0 1
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_FM_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('FM.Q.FI.EUR.DS.EI.HEXINDX.HSTE') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}
	if "`ii'" == "FR" {
	*getTimeSeries ECB FM.Q.FR.EUR.DS.EI.FRCAC40.HSTE $year_start "" 0 1
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_FM_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('FM.Q.FR.EUR.DS.EI.FRCAC40.HSTE') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}	
	if "`ii'" == "DE" {
	*getTimeSeries ECB FM.Q.DE.EUR.DS.EI.DAXINDX.HSTE $year_start "" 0 1
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_FM_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('FM.Q.DE.EUR.DS.EI.DAXINDX.HSTE') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}
	if "`ii'" == "GR" {
	*getTimeSeries ECB FM.Q.GR.EUR.DS.EI.GRAGENL.HSTE $year_start "" 0 1
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_FM_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('FM.Q.GR.EUR.DS.EI.GRAGENL.HSTE') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}
	if "`ii'" == "HU" {
	*getTimeSeries ECB FM.Q.HU.HUF.DS.EI.BUXINDX.HSTE $year_start "" 0 1
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_FM_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('FM.Q.HU.HUF.DS.EI.BUXINDX.HSTE') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}
	if "`ii'" == "IE" {
	*getTimeSeries ECB FM.Q.IE.EUR.DS.EI.ISEQUIT.HSTE $year_start "" 0 1
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_FM_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('FM.Q.IE.EUR.DS.EI.ISEQUIT.HSTE') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}	
	if "`ii'" == "IT" {
	*getTimeSeries ECB FM.Q.IT.EUR.DS.EI.S_PMIBX.HSTE $year_start "" 0 1
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_FM_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('FM.Q.IT.EUR.DS.EI.S_PMIBX.HSTE') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}
	if "`ii'" == "LV" {
	*getTimeSeries ECB FM.Q.LV.EUR.DS.EI.RIGSEIN.HSTE $year_start "" 0 1
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_FM_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('FM.Q.LV.EUR.DS.EI.RIGSEIN.HSTE') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}
	if "`ii'" == "LU" {
	*getTimeSeries ECB FM.Q.LU.EUR.DS.EI.LUXGENI.HSTE $year_start "" 0 1
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_FM_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('FM.Q.LU.EUR.DS.EI.LUXGENI.HSTE') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}
	if "`ii'" == "MT" {
	*getTimeSeries ECB FM.Q.MT.EUR.BL.EI.MALTEX.HSTE $year_start "" 0 1
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_FM_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('FM.Q.MT.EUR.BL.EI.MALTEX.HSTE') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}	
	if "`ii'" == "NL" {
	*getTimeSeries ECB FM.Q.NL.EUR.DS.EI.AMSTEOE.HSTE $year_start "" 0 1
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_FM_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('FM.Q.NL.EUR.DS.EI.AMSTEOE.HSTE') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}
	if "`ii'" == "PL" {
	*getTimeSeries ECB FM.Q.PL.PLN.DS.EI.POLWIGI.HSTE $year_start "" 0 1
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_FM_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('FM.Q.PL.PLN.DS.EI.POLWIGI.HSTE') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}
	if "`ii'" == "PT" {
	*getTimeSeries ECB FM.Q.PT.EUR.DS.EI.POPSIGN.HSTE $year_start "" 0 1
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_FM_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('FM.Q.PT.EUR.DS.EI.POPSIGN.HSTE') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}
	if "`ii'" == "SK" {
	*getTimeSeries ECB FM.Q.SK.EUR.DS.EI.SXSAX12.HSTE $year_start "" 0 1
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_FM_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('FM.Q.SK.EUR.DS.EI.SXSAX12.HSTE') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}	
	if "`ii'" == "SI" {
	*getTimeSeries ECB FM.Q.SI.EUR.DS.EI.TOTMKSJ.HSTE $year_start "" 0 1
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_FM_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('FM.Q.SI.EUR.DS.EI.TOTMKSJ.HSTE') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}
	if "`ii'" == "ES" {
	*getTimeSeries ECB FM.Q.ES.EUR.DS.EI.IBEX35I.HSTE $year_start "" 0 1
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_FM_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('FM.Q.ES.EUR.DS.EI.IBEX35I.HSTE') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}
	
	if "`ii'" == "UK" {
	*getTimeSeries ECB FM.Q.GB.EUR.DS.EI.WIUTDKL.HSTE $year_start "" 0 1
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_FM_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('FM.Q.GB.EUR.DS.EI.WIUTDKL.HSTE') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}	
	if "`ii'" == "US" {
	*getTimeSeries ECB FM.Q.U2.EUR.DS.EI.DJSTOXX.HSTE $year_start "" 0 1
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_FM_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('FM.Q.U2.EUR.DS.EI.DJSTOXX.HSTE') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}
	if "`ii'" == "JP" {
	*getTimeSeries ECB FM.Q.JP.EUR.DS.EI.WIJPANL.HSTE $year_start "" 0 1
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_FM_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('FM.Q.JP.EUR.DS.EI.WIJPANL.HSTE') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}

	*drop TSNAME
	rename OBS_VALUE Stock_`ii'
	label variable Stock_`ii' "Country specific stock price index"
	*rename DATE PERIOD_NAME
	sort PERIOD_NAME
	compress
	save "$dataoutputPath/Stock_`ii'.dta", replace	
	
}



* Combine countries into one file
local country1 `: word 1 of $all_ctrylist'

use "$dataoutputPath/Stock_`country1'.dta", clear
rm "$dataoutputPath/Stock_`country1'.dta"

local n_countries `: word count $all_ctrylist'
forval i = 2/`n_countries' {

	local country `: word `i' of $all_ctrylist'
	
	merge 1:1 PERIOD_NAME using "$dataoutputPath/Stock_`country'.dta"
	drop _merge
	rm "$dataoutputPath/Stock_`country'.dta"
	
}

save "$dataoutputPath/Stock_ALL.dta", replace
