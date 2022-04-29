





foreach ii of global ctrylist {
local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_MNA_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('MNA.Q.Y.`ii'.W2.S1.S1.B.B2A3G._Z._T._Z.EUR.V.N') AND PERIOD_NAME>='2007'"
odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear

rename OBS_VALUE B2B3_`ii'

sort PERIOD_NAME
compress

save "$dataoutputPath/B2B3_`ii'_sa.dta", replace	
}

* Combine countries into one file
local country1 `: word 1 of $ctrylist'
use "$dataoutputPath/B2B3_`country1'_sa.dta", clear
rm "$dataoutputPath/B2B3_`country1'_sa.dta"

local n_countries `: word count $ctrylist'
forval i = 2/`n_countries' {

	local country `: word `i' of $ctrylist'
	
	merge 1:1 PERIOD_NAME using "$dataoutputPath/B2B3_`country'_sa.dta"
	drop _merge
	sort PERIOD_NAME
	label variable B2B3_`country' "B2+B3: Gross Operating Surplus and Mixed Income"
	rm "$dataoutputPath/B2B3_`country'_sa.dta"
	
}

save "$dataoutputPath/B2B3_ALL_sa.dta", replace
