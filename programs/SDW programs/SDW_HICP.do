*** Download HICP - Inflation: HICP - Overall index, Monthly Index, Eurostat, Neither seasonally nor working day adjusted; Unit  2015 = 100  

foreach ii of global ctrylist {
/*
	getTimeSeries ECB ICP.M.`ii'.N.000000.4.INX $year_start "" 0 1

	drop TSNAME
	rename VALUE HICP_`ii'
	label variable HICP_`ii' "End of quarter level of HICP"
	rename DATE PERIOD_NAME
	sort PERIOD_NAME	
	compress	
	save "$dataoutputPath/HICP_`ii'.dta", replace
*/

local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_ICP_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('ICP.M.`ii'.N.000000.4.INX') AND PERIOD_NAME>='2007'"
odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
duplicates drop
rename OBS_VALUE HICP_`ii'
label variable HICP_`ii' "End of quarter level of HICP"
compress	
save "$dataoutputPath/HICP_`ii'.dta", replace


}

* Combine countries into one file
local country1 `: word 1 of $ctrylist'

use "$dataoutputPath/HICP_`country1'.dta", clear
rm "$dataoutputPath/HICP_`country1'.dta"

local n_countries `: word count $ctrylist'
forval i = 2/`n_countries' {

	local country `: word `i' of $ctrylist'
	
	merge 1:1 PERIOD_NAME using "$dataoutputPath/HICP_`country'.dta"
	drop _merge
	rm "$dataoutputPath/HICP_`country'.dta"
	
}

* Pick only quarter-end values
gen date_test = monthly(PERIOD_NAME, "YM")
format date_test %tm
gen temp_y= yofd(dofm(date_test))
format temp_y %ty
gen temp_q= qofd(dofm(date_test))
format temp_q %tq
sort temp_q date_test
by temp_q: gen t=_n
keep if t==3
sort temp_y temp_q
list temp_y temp_q
drop t
by temp_y: gen t=_n
gen qind="Q1" if t==1
replace qind="Q2" if t==2
replace qind="Q3" if t==3
replace qind="Q4" if t==4
gen y_str = string(temp_y)
replace PERIOD_NAME = y_str + /*"-" +*/ qind

drop date_test temp_y temp_q t qind y_str

save "$dataoutputPath/HICP_ALL.dta", replace
