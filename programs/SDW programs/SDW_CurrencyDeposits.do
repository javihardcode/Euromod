* UNDER CONSTRUCTION

*** Download F2, F21, F2M - Currency and Deposits
* F2 currency and deposits
* F21 Currency
* F2M Deposits 
* Example of F2 for Spain: (https://sdw.ecb.europa.eu/quickview.do?SERIES_KEY=332.QSA.Q.N.ES.W0.S1M.S1.N.A.LE.F2.T._Z.XDC._T.S.V.N._T)
* Example of F2M for Spain: (https://sdw.ecb.europa.eu/quickview.do?SERIES_KEY=332.QSA.Q.N.ES.W0.S1M.S1.N.A.LE.F2M.T._Z.XDC._T.S.V.N._T)


/*
foreach ii of global ctrylist {
	
	getTimeSeries ECB QSA.Q.N.`ii'.W0.S1M.S1.N.A.LE.F2+F21+F2M.T._Z.XDC._T.S.V.N._T $year_start "" 0 1
	
	gen var = regexs(0) if(regexm(TSNAME, "F2M"))
	replace var = regexs(0) if(regexm(TSNAME, "F21"))
	replace var = "F2" if var != "F2M" & var != "F21"
	
	drop TSNAME
	rename VALUE `ii'_
	reshape wide `ii'_, i(DATE) j(var) string
	
	rename `ii'_F2	F2_`ii'
	rename `ii'_F21	F21_`ii'
	rename `ii'_F2M F2M_`ii'
	
	label variable F2_`ii' "Currency and Deposits"
	label variable F21_`ii' "Currency"
	label variable F2M_`ii' "Deposits"
	rename DATE PERIOD_NAME
	sort PERIOD_NAME	
	compress	
	save "$dataoutputPath/CD_temp_`ii'.dta", replace
	
}
*/
foreach ii of global ctrylist {

local f_vars "F2 F21 F2M"

foreach var of local f_vars{

local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_QSA_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('QSA.Q.N.`ii'.W0.S1M.S1.N.A.LE.`var'.T._Z.XDC._T.S.V.N._T') AND PERIOD_NAME>='2007'"
odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear

rename OBS_VALUE `var'_`ii'

keep PERIOD_NAME `var'

sort PERIOD_NAME
compress

save "$dataoutputPath/CD_temp_`var'_`ii'.dta", replace

}

use "$dataoutputPath/CD_temp_F2_`ii'.dta", clear

merge 1:1 PERIOD_NAME using "$dataoutputPath/CD_temp_F21_`ii'.dta"
drop _merge

merge 1:1 PERIOD_NAME using "$dataoutputPath/CD_temp_F2M_`ii'.dta"
drop _merge

label variable F2_`ii' "Currency and Deposits"
label variable F21_`ii' "Currency"
label variable F2M_`ii' "Deposits"



save "$dataoutputPath/CD_temp_`ii'.dta", replace
}

* Rename variables, reshape into long and save as single dta file
local country1 `: word 1 of $ctrylist'

use "$dataoutputPath/CD_temp_`country1'.dta", clear
rm "$dataoutputPath/CD_temp_`country1'.dta"

local n_countries `: word count $ctrylist'
forval i = 2/`n_countries' {

	local country `: word `i' of $ctrylist'
	
	merge 1:1 PERIOD_NAME using "$dataoutputPath/CD_temp_`country'.dta"
	drop _merge
	rm "$dataoutputPath/CD_temp_`country'.dta"
	
}

save "$dataoutputPath/CurrencyDeposits_ALL.dta", replace
