*
* Download CP042 Imputed rents of consumption: 
* Missing for CY, EE, LU, LV, MT, SK. 
* Unit: millions EUROS  
* This data is yearly. 

foreach ii of global ctrylist {

local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_E05_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('E05.A.N.`ii'.W2.S14.S1.D.P31._Z._Z.CP042.EUR.V.N') AND PERIOD_NAME>='2007'"
odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear

rename OBS_VALUE CP042_`ii'

sort PERIOD_NAME
compress

save "$dataoutputPath/CP042_`ii'.dta", replace
}

* Combine countries into one file
local country1 `: word 1 of $ctrylist'
use "$dataoutputPath/CP042_`country1'.dta", clear
rm "$dataoutputPath/CP042_`country1'.dta"

local n_countries `: word count $ctrylist'
forval i = 2/`n_countries' {

	local country `: word `i' of $ctrylist'
	
	merge 1:1 PERIOD_NAME using "$dataoutputPath/CP042_`country'.dta"
	drop _merge
	sort PERIOD_NAME
	rm "$dataoutputPath/CP042_`country'.dta"
	
}

save "$dataoutputPath/CP042_ALL.dta", replace



























