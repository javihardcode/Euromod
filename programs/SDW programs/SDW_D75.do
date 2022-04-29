*** Download D75 - Miscellaneous Current Transfers; C: Credits; D: Debits
* NOTE: Variable is missing for several countries. Use HICP instead.

foreach ii of global ctrylist {

	if !inlist("`ii'", "CY", "EE", "HU", "LV", "LU", "MT", "PL", "SK", "ES") {
	/*getTimeSeries ECB QSA.Q.N.`ii'.W0.S1M.S1.N.D+C.D75._Z._Z._Z.XDC._T.S.V.N._T $year_start "" 0 1
	
	gen var = regexs(0) if(regexm(TSNAME, "D.D75"))
	replace var = regexs(0) if(regexm(TSNAME, "C.D75"))	
	gen var1 = subinstr(var,".","_",.)

	drop var
	drop TSNAME
	rename VALUE `ii'_
	reshape wide `ii'_, i(DATE) j(var1) string
	
	rename `ii'_C_D75 D75_C_`ii'
	rename `ii'_D_D75 D75_D_`ii'*/
	local D75_vars "C D"
	foreach var of local D75_vars{
	
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_QSA_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN 		('QSA.Q.N.`ii'.W0.S1M.S1.N.`var'.D75._Z._Z._Z.XDC._T.S.V.N._T') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	
	
	rename OBS_VALUE D75_`var'_`ii'
	sort PERIOD_NAME	
	compress	
	save "$dataoutputPath/D75_`var'_`ii'.dta", replace
	}
	
	merge 1:1 PERIOD_NAME using "$dataoutputPath/D75_C_`ii'.dta"
	drop _merge
	
	
	label variable D75_C_`ii' "D75 for hh-sector, credit"
	label variable D75_D_`ii' "D75 for hh-sector, debit"
	
	save "$dataoutputPath/D75_`ii'.dta", replace
	
	}

	* Countries with missing variable
	if inlist("`ii'", "CY", "EE", "HU", "LV", "LU", "MT", "PL", "SK", "ES") {
	
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_ICP_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('ICP.M.`ii'.N.000000.4.INX') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	
	* Transform monthly to quarterly frequency
	gen yq = qofd(dofm(monthly(PERIOD_NAME,"YM"))) 
	format yq %tq
	collapse (mean) OBS_VALUE = OBS_VALUE, by(yq /*TSNAME*/)
	gen yq2 = string(yq, "%tq")
	gen yq3 = upper(yq2)
	gen year = regexs(0) if(regexm(yq3, "[0-9][0-9][0-9][0-9]"))
	gen quarter = regexs(0) if(regexm(yq3, "Q[0-9]"))
	gen PERIOD_NAME = year + /*"-" +*/ quarter 
	drop yq yq2 yq3 year quarter
	
	rename OBS_VALUE D75_C_`ii'
	gen D75_D_`ii' = D75_C_`ii'

	*rename VALUE D75_C_`ii'
	label variable D75_C_`ii' "D75 for hh-sector, credit"
	*gen D75_D_`ii' = D75_C_`ii'
	label variable D75_D_`ii' "D75 for hh-sector, debit"
	sort PERIOD_NAME	
	compress	
	save "$dataoutputPath/D75_`ii'.dta", replace
	}
	
}

* Combine countries into one file
local country1 `: word 1 of $ctrylist'

use "$dataoutputPath/D75_`country1'.dta", clear
rm "$dataoutputPath/D75_`country1'.dta"

local n_countries `: word count $ctrylist'
forval i = 2/`n_countries' {

	local country `: word `i' of $ctrylist'
	
	merge 1:1 PERIOD_NAME using "$dataoutputPath/D75_`country'.dta"
	drop _merge
	rm "$dataoutputPath/D75_`country'.dta"
	
}

save "$dataoutputPath/D75_ALL.dta", replace
