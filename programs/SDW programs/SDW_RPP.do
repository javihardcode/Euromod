* Download Residential Property Prices
*** mix of different measures for different countries (dwellings vs flats, source)
/*
foreach ii of global ctrylist {
/*
	if !inlist("`ii'", "AT","GR","IT","PT") {
	getTimeSeries ECB RPP.Q.`ii'.N.TD.00.4.00 $year_start "" 0 1
	}
	
	if "`ii'" == "AT" {
	getTimeSeries ECB RPP.Q.AT.N.TD.00.3.00 $year_start "" 0 1
	}
	if "`ii'" == "GR" {
	getTimeSeries ECB RPP.Q.GR.N.TF.00.3.00 $year_start "" 0 1
	}	
	if "`ii'" == "IT" {
	getTimeSeries ECB RPP.Q.IT.N.TD.00.2.00 $year_start "" 0 1
	}
	if "`ii'" == "PT" {
	getTimeSeries ECB RPP.Q.PT.N.TD.00.5.00 $year_start "" 0 1
	}

	drop TSNAME
	rename VALUE RPP_`ii'
	rename DATE PERIOD_NAME
	sort PERIOD_NAME
	compress
	save "$dataoutputPath/RPP_`ii'.dta", replace	
*/

if !inlist("`ii'", "AT","GR","IT","PT") {
local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_RPP_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('RPP.Q.`ii'.N.TD.00.4.00')"
odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}
if "`ii'" == "AT" {
local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_RPP_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('RPP.Q.AT.N.TD.00.3.00')"
odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear	
	}
	if "`ii'" == "GR" {
local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_RPP_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('RPP.Q.GR.N.TF.00.3.00')"
odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear	
	}	
	if "`ii'" == "IT" {
local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_RPP_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('RPP.Q.IT.N.TD.00.2.00')"
odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear	
	}
	if "`ii'" == "PT" {
local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_RPP_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('RPP.Q.PT.N.TD.00.5.00')"
odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear	
	}

rename OBS_VALUE RPP_`ii'

sort PERIOD_NAME
compress

save "$dataoutputPath/RPP_`ii'.dta", replace	

}
*/

* There is a new series on RPP

foreach ii of global ctrylist {

/*
if !inlist("`ii'", "AT","GR","IT","PT") {
local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_RPP_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('RPP.Q.`ii'.N.TD.00.4.00')"

odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}
*/	
	
if "`ii'" == "AT" {
local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_RESR_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('RESR.Q.AT._T.N._TR.TVAL.4F0.TB.N.IX') AND PERIOD_NAME>='2007'"
odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear	
	}
	
if "`ii'" == "BE" {
local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_RESR_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('RESR.Q.BE._T.N.XTR.TVAL.BE2.TB.N.IX') AND PERIOD_NAME>='2007'"
odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear	
	}
	
if "`ii'" == "CY" {
local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_RESR_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('RESR.Q.CY._T.N._TR.TVAL.CY2.TB.N.IX') AND PERIOD_NAME>='2007'"
odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear	
	}
	
if "`ii'" == "DE" {
local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_RESR_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('RESR.Q.DE._T.N._TR.TVAL.DE2.TB.N.IX') AND PERIOD_NAME>='2007'"
odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear	
	}
	
if "`ii'" == "EE" {
local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_RESR_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('RESR.Q.EE._T.N._TR.TVAL.EE1.TB.N.IX') AND PERIOD_NAME>='2007'"
odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear	
	}

if "`ii'" == "ES" {
local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_RESR_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('RESR.Q.ES._T.N._TR.TVAL.5B0.TB.N.IX') AND PERIOD_NAME>='2007'"
odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear	
	}
	
if "`ii'" == "FI" {
local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_RESR_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('RESR.Q.FI._T.N._TR.TVAL.4D0.TB.N.IX') AND PERIOD_NAME>='2007'" 
odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear	
	}

if "`ii'" == "FR" {
local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_RESR_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('RESR.Q.FR._T.N.XTR.TVAL.FR1.TB.N.IX') AND PERIOD_NAME>='2007'"
odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear	
	}

if "`ii'" == "GR" {
local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_RESR_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('RESR.Q.GR._T.N.RTF.TVAL.4F0.TB.N.IX') AND PERIOD_NAME>='2007'"
odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear	
	}
	
if "`ii'" == "HU" {
local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_RESR_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('RESR.Q.HU._T.N._TR.TVAL.4D0.TB.N.IX') AND PERIOD_NAME>='2007'"
odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear	
	}

if "`ii'" == "IE" {
local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_RESR_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('RESR.Q.IE._T.N._TR.TVAL.4D0.TB.N.IX') AND PERIOD_NAME>='2007'"
odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear	
	}
	
if "`ii'" == "IT" {
local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_RESR_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('RESR.Q.IT._T.N._TR.TVAL.IT2.TB.N.IX') AND PERIOD_NAME>='2007'"
odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear	
	}

if "`ii'" == "LU" {
local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_RESR_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('RESR.Q.LU._T.N._TR.TVAL.4D0.TB.N.IX') AND PERIOD_NAME>='2007'"
odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear	
	}

if "`ii'" == "LV" {
local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_RESR_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('RESR.Q.LV._T.N._TR.TVAL.LV1.TB.N.IX') AND PERIOD_NAME>='2007'"
odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear	
	}

if "`ii'" == "MT" {
local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_RESR_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('RESR.Q.MT._T.N._TR.TVAL.MT1.TB.N.IX') AND PERIOD_NAME>='2007'"
odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear	
	}

if "`ii'" == "NL" {
local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_RESR_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('RESR.Q.NL._T.N._TR.TVAL.4D0.TB.N.IX') AND PERIOD_NAME>='2007'"
odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear	
	}

if "`ii'" == "PT" {
local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_RESR_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('RESR.Q.PT._T.N._TR.TVAL.4D0.TB.N.IX') AND PERIOD_NAME>='2007'"
odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear	
	}

if "`ii'" == "PL" {
local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_RPP_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('RPP.Q.PL.N.TD.00.4.00') AND PERIOD_NAME>='2007'"
odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear	
	}

if "`ii'" == "SI" {
local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_RESR_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('RESR.Q.SI._T.N._TR.TVAL.SI1.TB.N.IX') AND PERIOD_NAME>='2007'"
odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear	
	}

if "`ii'" == "SK" {
local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_RESR_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('RESR.Q.SK._T.N.XTR.TVAL.SK2.TB.N.IX') AND PERIOD_NAME>='2007'"
odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear	
	}

if "`ii'" == "LT" {
local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_RESR_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('what') AND PERIOD_NAME>='2007'"
odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear	
	}

if "`ii'" == "HR" {
local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_RESR_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('what') AND PERIOD_NAME>='2007'"
odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear	
	}


/*
	if "`ii'" == "GR" {
local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_RPP_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('RPP.Q.GR.N.TF.00.3.00')"
odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear	
	}	
	if "`ii'" == "IT" {
local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_RPP_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('RPP.Q.IT.N.TD.00.2.00')"
odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear	
	}
	if "`ii'" == "PT" {
local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_RPP_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('RPP.Q.PT.N.TD.00.5.00')"
odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear	
	}
*/
rename OBS_VALUE RPP_`ii'

sort PERIOD_NAME
compress

save "$dataoutputPath/RPP_`ii'.dta", replace	

}
/*
* Combine countries into one file
local country1 `: word 1 of $ctrylist'

use "$dataoutputPath/RPP_`country1'.dta", clear
rm "$dataoutputPath/RPP_`country1'.dta"

local n_countries `: word count $ctrylist'
forval i = 2/`n_countries' {

	local country `: word `i' of $ctrylist'
	
	merge 1:1 PERIOD_NAME using "$dataoutputPath/RPP_`country'.dta"
	drop _merge
	rm "$dataoutputPath/RPP_`country'.dta"
	
}

save "$dataoutputPath/RPP_ALL.dta", replace
*/
* Combine countries into one file
local country1 `: word 1 of $ctrylist'

use "$dataoutputPath/RPP_`country1'.dta", clear
rm "$dataoutputPath/RPP_`country1'.dta"

local n_countries `: word count $ctrylist'
forval i = 2/`n_countries' {

	local country `: word `i' of $ctrylist'
	
	merge 1:1 PERIOD_NAME using "$dataoutputPath/RPP_`country'.dta"
	drop _merge
	rm "$dataoutputPath/RPP_`country'.dta"
	
}

save "$dataoutputPath/RPP_ALL.dta", replace
