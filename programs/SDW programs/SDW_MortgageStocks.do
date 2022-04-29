*** Download and adjust mortgage stock data
* 08-12-2021 Javier Ramos 
* Working on last version
* Link to ES example (https://sdw.ecb.europa.eu/quickview.do?SERIES_KEY=117.BSI.M.ES.N.A.A22.A.1.U2.2250.Z01.E)
* in millions of €

foreach ii of global ctrylist {

    /*
	getTimeSeries ECB BSI.M.`ii'.N.A.A22.A.1.U2.2250.Z01.E $year_start "" 0 1
	
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
	gen ctryid = "`ii'"
	
	drop TSNAME
	rename VALUE Mort_stock
	rename DATE PERIOD_NAME
	sort PERIOD_NAME
	compress
	save "$dataoutputPath/Mort_stock_`ii'.dta", replace	
    */
	
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_BSI_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN  ('BSI.M.`ii'.N.A.A22.A.1.U2.2250.Z01.E') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	
  * Convert monthly to quarterly frequency by taking averages over months
	gen yq = qofd(dofm(monthly(PERIOD_NAME,"YM"))) 
	format yq %tq
	collapse (mean) OBS_VALUE = OBS_VALUE, by(yq /*TSNAME*/)
	gen yq2 = string(yq, "%tq")
	gen yq3 = upper(yq2)
	gen year = regexs(0) if(regexm(yq3, "[0-9][0-9][0-9][0-9]"))
	gen quarter = regexs(0) if(regexm(yq3, "Q[0-9]"))
	gen DATE = year + "-" + quarter 
	drop yq yq2 yq3 year quarter
	gen ctryid = "`ii'"
	
  * drop TSNAME
	rename OBS_VALUE Mort_stock
	rename DATE PERIOD_NAME
	sort PERIOD_NAME
	compress
	save "$dataoutputPath/Mort_stock_`ii'.dta", replace
	

}


local country1 `: word 1 of $ctrylist'

use "$dataoutputPath/Mort_stock_`country1'.dta", clear
rm "$dataoutputPath/Mort_stock_`country1'.dta"

local n_countries `: word count $ctrylist'
forval i = 2/`n_countries' {

	local country `: word `i' of $ctrylist'
	
	append using "$dataoutputPath/Mort_stock_`country'.dta"
	rm "$dataoutputPath/Mort_stock_`country'.dta"
	
}
* Drop before 2007:
drop if PERIOD_NAME < "2007-Q1"
save "$dataoutputPath/Mort_stock_ALL.dta", replace	
