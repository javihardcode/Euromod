*** Download 10yr sovereign bond yields

* Non Euro Area countries as world performance benchmark
global NONEA_ctrylist = "US UK JP"
global all_ctrylist $ctrylist $NONEA_ctrylist
/*
foreach ii of global all_ctrylist {

	if !inlist("`ii'", "EE","HU","PL", "US","UK","JP") {
	getTimeSeries ECB IRS.Q.`ii'.L.L40.CI.0000.EUR.N.Z $year_start "" 0 1
	}

	if "`ii'" == "EE" {
	getTimeSeries ECB MIR.M.EE.B.A2C.AM.R.A.2250.EUR.N $year_start "" 0 1
	
	* Convert monthly to quarterly frequency by taking averages over months
	gen yq = qofd(dofm(monthly(DATE,"YM"))) 
	format yq %tq
	collapse (mean) VALUE = VALUE, by(yq TSNAME)
	gen yq2 = string(yq, "%tq")
	gen yq3 = upper(yq2)
	gen year = regexs(0) if(regexm(yq3, "[0-9][0-9][0-9][0-9]"))
	gen quarter = regexs(0) if(regexm(yq3, "Q[0-9]"))
	gen DATE = year + "-" + quarter 
	drop yq yq2 yq3 year quarter
	}
	
	if "`ii'" == "HU" {
	getTimeSeries ECB IRS.Q.HU.L.L40.CI.0000.HUF.N.Z $year_start "" 0 1
	}
	if "`ii'" == "PL" {
	getTimeSeries ECB IRS.Q.PL.L.L40.CI.0000.PLN.N.Z $year_start "" 0 1
	}
		
	if "`ii'" == "US" {
	getTimeSeries ECB FM.Q.US.USD.BL.BB.USGG10Y.HSTA $year_start "" 0 1
	}
	if "`ii'" == "UK" {
	getTimeSeries ECB FM.Q.GB.GBP.RT.BB.GB10YT_RR.YLDA $year_start "" 0 1
	}
	if "`ii'" == "JP" {
	getTimeSeries ECB FM.Q.JP.JPY.RT.BB.JP10YT_RR.YLDA $year_start "" 0 1
	}
	
	drop TSNAME
	rename VALUE Yield10yr_`ii'
	rename DATE PERIOD_NAME
	sort PERIOD_NAME
	compress
	save "$dataoutputPath/Yield10yr_`ii'.dta", replace	
}
*/

foreach ii of global all_ctrylist {

	if !inlist("`ii'", "EE","HU","PL", "US","UK","JP") {
	*getTimeSeries ECB IRS.Q.`ii'.L.L40.CI.0000.EUR.N.Z $year_start "" 0 1
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_IRS_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('IRS.Q.`ii'.L.L40.CI.0000.EUR.N.Z') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}

	if "`ii'" == "EE" {
	*getTimeSeries ECB MIR.M.EE.B.A2C.AM.R.A.2250.EUR.N $year_start "" 0 1
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_MIR_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('MIR.M.EE.B.A2C.AM.R.A.2250.EUR.N') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	
	* Convert monthly to quarterly frequency by taking averages over months
	gen yq = qofd(dofm(monthly(PERIOD_NAME,"YM"))) 
	format yq %tq
	collapse (mean) OBS_VALUE = OBS_VALUE, by(yq /*TSNAME*/)
	gen yq2 = string(yq, "%tq")
	gen yq3 = upper(yq2)
	gen year = regexs(0) if(regexm(yq3, "[0-9][0-9][0-9][0-9]"))
	gen quarter = regexs(0) if(regexm(yq3, "Q[0-9]"))
	gen PERIOD_NAME = year + /*"-" +*/ quarter 
	drop yq yq2 yq3 year quarter
	}
	
	if "`ii'" == "HU" {
	*getTimeSeries ECB IRS.Q.HU.L.L40.CI.0000.HUF.N.Z $year_start "" 0 1
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_IRS_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('IRS.Q.HU.L.L40.CI.0000.HUF.N.Z') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}
	if "`ii'" == "PL" {
	*getTimeSeries ECB IRS.Q.PL.L.L40.CI.0000.PLN.N.Z $year_start "" 0 1
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_IRS_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('IRS.Q.PL.L.L40.CI.0000.PLN.N.Z') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}
		
	if "`ii'" == "US" {
	*getTimeSeries ECB FM.Q.US.USD.BL.BB.USGG10Y.HSTA $year_start "" 0 1
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_FM_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('FM.Q.US.USD.BL.BB.USGG10Y.HSTA') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}
	if "`ii'" == "UK" {
	*getTimeSeries ECB FM.Q.GB.GBP.RT.BB.GB10YT_RR.YLDA $year_start "" 0 1
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_FM_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('FM.Q.GB.GBP.RT.BB.GB10YT_RR.YLDA') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}
	if "`ii'" == "JP" {
	*getTimeSeries ECB FM.Q.JP.JPY.RT.BB.JP10YT_RR.YLDA $year_start "" 0 1
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_FM_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('FM.Q.JP.JPY.RT.BB.JP10YT_RR.YLDA') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}
	
	*drop TSNAME
	rename OBS_VALUE Yield10yr_`ii'
	*rename DATE PERIOD_NAME
	sort PERIOD_NAME
	compress
	save "$dataoutputPath/Yield10yr_`ii'.dta", replace	
}

*** Combine countries into one file

local country1 `: word 1 of $all_ctrylist'
use "$dataoutputPath/Yield10yr_`country1'.dta", clear
label variable Yield10yr_`country1' "Long-term interest rate for convergence purposes"
* Compute zero coupon bond
gen ZCB_`country1' = 100/((1+Yield10yr_`country1'/100)^10)
label variable ZCB_`country1' "Zero coupon bond, face value=100"
rm "$dataoutputPath/Yield10yr_`country1'.dta"

local n_countries `: word count $all_ctrylist'
forval i = 2/`n_countries' {

	local country `: word `i' of $all_ctrylist'
	
	merge PERIOD_NAME using "$dataoutputPath/Yield10yr_`country'.dta"
	drop _merge
	sort PERIOD_NAME
	label variable Yield10yr_`country' "Long-term interest rate for convergence purposes"
	
	* Compute zero coupon bond
	gen ZCB_`country' = 100/((1+Yield10yr_`country'/100)^10)
	label variable ZCB_`country' "Zero coupon bond, face value=100"
	
	rm "$dataoutputPath/Yield10yr_`country'.dta"
	
}

save "$dataoutputPath/BondYields_ALL.dta", replace

