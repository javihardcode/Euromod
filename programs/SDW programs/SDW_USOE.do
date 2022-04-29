*** Download unquoted shares and other equity (USOE)
/*
foreach ii of global ctrylist {
	
	getTimeSeries ECB QSA.Q.N.`ii'.W0.S1M.S1.N.A.LE.F51M._Z._Z.XDC._T.S.V.N._T $year_start "" 0 1

	drop TSNAME
	rename DATE PERIOD_NAME
	rename VALUE USOE_D_`ii'
	label variable USOE_D_`ii' "Unquoted shares/otehr equity HH-sector, debit (F51M)"
	sort PERIOD_NAME
	compress
	save "$dataoutputPath/USOE_`ii'.dta", replace

}
*/
foreach ii of global ctrylist {
local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_QSA_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('QSA.Q.N.`ii'.W0.S1M.S1.N.A.LE.F51M._Z._Z.XDC._T.S.V.N._T') AND PERIOD_NAME>='2007'"
odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear

rename OBS_VALUE USOE_D_`ii'
label variable USOE_D_`ii' "Unquoted shares/otehr equity HH-sector, debit (F51M)"
sort PERIOD_NAME
compress
save "$dataoutputPath/USOE_`ii'.dta", replace	
}
	
* Rename variables, reshape into long and save as single dta file
local country1 `: word 1 of $ctrylist'

use "$dataoutputPath/USOE_`country1'.dta", clear
rm "$dataoutputPath/USOE_`country1'.dta"

local n_countries `: word count $ctrylist'
forval i = 2/`n_countries' {

	local country `: word `i' of $ctrylist'
	
	merge 1:1 PERIOD_NAME using "$dataoutputPath/USOE_`country'.dta"
	drop _merge
	rm "$dataoutputPath/USOE_`country'.dta"
	
}

save "$dataoutputPath/USOE_ALL.dta", replace
