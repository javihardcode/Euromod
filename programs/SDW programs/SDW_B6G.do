*
* Download B6G Gross Disposable Income 
* Missing for CY, EE, LU, LV, MT, SK. 
* Unit millions EUROS 

foreach ii of global ctrylist {

local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_QSA_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('QSA.Q.N.`ii'.W0.S1M.S1._Z.B.B6G._Z._Z._Z.XDC._T.S.V.N._T') AND PERIOD_NAME>='2007'"

odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear

rename OBS_VALUE B6G_`ii'
	
	sort PERIOD_NAME
	compress
	save "$dataoutputPath/B6G_`ii'.dta", replace
}


* Combine countries into one file
local country1 `: word 1 of $ctrylist'

use "$dataoutputPath/B6G_`country1'.dta", clear
rm "$dataoutputPath/B6G_`country1'.dta"

local n_countries `: word count $ctrylist'
forval i = 2/`n_countries' {

 	local country `: word `i' of $ctrylist'
	
 	merge 1:1 PERIOD_NAME using "$dataoutputPath/B6G_`country'.dta"
 	drop _merge
 	rm "$dataoutputPath/B6G_`country'.dta"
}

save "$dataoutputPath/B6G_ALL.dta", replace
