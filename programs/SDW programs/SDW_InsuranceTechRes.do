*** Download F6 - Insurance technical reserves
* F6: (Insurance, pension and standardized guarantee schemes of households); 
* F62 (life insurance reserves) + F6M (pension fund reserveS) = F61 (previous, discontinued variable);

foreach ii of global ctrylist {
/*
	getTimeSeries ECB QSA.Q.N.`ii'.W0.S1M.S1.N.A.LE.F6+F62+F6M._Z._Z.XDC._T.S.V.N._T $year_start "" 0 1

	gen var = regexs(0) if(regexm(TSNAME, "F6._Z"))
	replace var = regexs(0) if(regexm(TSNAME, "F62._Z"))	
	replace var = regexs(0) if(regexm(TSNAME, "F6M._Z"))	

	gen var1 = subinstr(var,"._Z","",.)

	drop var
	drop TSNAME
	rename VALUE `ii'_
	reshape wide `ii'_, i(DATE) j(var1) string
	
	rename `ii'_F6  F6_`ii'
	rename `ii'_F62 F62_`ii'
	rename `ii'_F6M F6M_`ii' 
	
	* Generate 'old' variable
	gen F61_`ii' = F62_`ii' + F6M_`ii'
	drop F62_`ii' F6M_`ii'
	label variable F6_`ii' "Insurance technical reserves"
	label variable F61_`ii' "Net equity of households in life insurance reserves and in pension funds reserves"
	
	rename DATE PERIOD_NAME
	sort PERIOD_NAME	
	compress	
	save "$dataoutputPath/InsuranceTechRes_`ii'.dta", replace
*/



	local f_vars "F6 F62 F6M"

	foreach var of local f_vars{

		local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_QSA_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('QSA.Q.N.`ii'.W0.S1M.S1.N.A.LE.`var'._Z._Z.XDC._T.S.V.N._T') AND PERIOD_NAME>='2007'"
		odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear

		rename OBS_VALUE `var'_`ii'

		keep PERIOD_NAME `var'

		sort PERIOD_NAME
		compress

		save "$dataoutputPath/ITR_temp_`var'_`ii'.dta", replace

	}

	use "$dataoutputPath/ITR_temp_F6_`ii'.dta", clear

	merge 1:1 PERIOD_NAME using "$dataoutputPath/ITR_temp_F62_`ii'.dta"
	drop _merge

	merge 1:1 PERIOD_NAME using "$dataoutputPath/ITR_temp_F6M_`ii'.dta"
	drop _merge

	gen F61_`ii' = F62_`ii' + F6M_`ii'
	drop F62_`ii' F6M_`ii'

	label variable F6_`ii' "Insurance technical reserves"
	label variable F61_`ii' "Net equity of households in life insurance reserves and in pension funds reserves"

	sort PERIOD_NAME	
	compress	
	save "$dataoutputPath/InsuranceTechRes_`ii'.dta", replace

	
}

* Combine countries into one file
local country1 `: word 1 of $ctrylist'

use "$dataoutputPath/InsuranceTechRes_`country1'.dta", clear
rm "$dataoutputPath/InsuranceTechRes_`country1'.dta"

local n_countries `: word count $ctrylist'
forval i = 2/`n_countries' {

	local country `: word `i' of $ctrylist'
	
	merge 1:1 PERIOD_NAME using "$dataoutputPath/InsuranceTechRes_`country'.dta"
	drop _merge
	rm "$dataoutputPath/InsuranceTechRes_`country'.dta"
	
}

save "$dataoutputPath/InsuranceTechRes_ALL.dta", replace
