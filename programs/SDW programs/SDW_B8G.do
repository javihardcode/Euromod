
* Download Aggregate saving rates from SDW: (https://sdw.ecb.europa.eu/browse.do?node=9689710)
* B8G, Qarterly, financial and non financial sector accounts

* CY,EE,LU,LV, MT and SK missing, 
* SK and LV replaced by SI
* LU by NL 
* CY by GR 
* MT by IT 

foreach ii of global ctrylist {

if inlist("`ii'", "SK", "LV","EE") local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_QSA_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('QSA.Q.N.SI.W0.S1M.S1._Z.B.B8G._Z._Z._Z.XDC_R_B6GA_CY._T.S.V.C4._T') AND PERIOD_NAME>='2007'"

else if inlist("`ii'", "LU") local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_QSA_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('QSA.Q.N.NL.W0.S1M.S1._Z.B.B8G._Z._Z._Z.XDC_R_B6GA_CY._T.S.V.C4._T') AND PERIOD_NAME>='2007'"

else if inlist("`ii'", "CY") local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_QSA_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('QSA.Q.N.GR.W0.S1M.S1._Z.B.B8G._Z._Z._Z.XDC_R_B6GA_CY._T.S.V.C4._T') AND PERIOD_NAME>='2007'"

else if inlist("`ii'", "MT") local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_QSA_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('QSA.Q.N.IT.W0.S1M.S1._Z.B.B8G._Z._Z._Z.XDC_R_B6GA_CY._T.S.V.C4._T') AND PERIOD_NAME>='2007'"


else local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_QSA_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('QSA.Q.N.`ii'.W0.S1M.S1._Z.B.B8G._Z._Z._Z.XDC_R_B6GA_CY._T.S.V.C4._T') AND PERIOD_NAME>='2007'"


odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear

rename OBS_VALUE B8G_`ii'
	
	sort PERIOD_NAME
	compress
	save "$dataoutputPath/B8G_`ii'.dta", replace
	
}


* Combine countries into one file 
local country1 `: word 1 of $ctrylist'

qui use "$dataoutputPath/B8G_`country1'.dta", clear
qui rm "$dataoutputPath/B8G_`country1'.dta"

local n_countries `: word count $ctrylist'
forval i = 2/`n_countries' {

 	local country `: word `i' of $ctrylist'
	
qui 	merge 1:1 PERIOD_NAME using "$dataoutputPath/B8G_`country'.dta"
qui 	drop _merge
qui 	rm "$dataoutputPath/B8G_`country'.dta"
	
}


* DROP OBSERVATIONS BEFORE 2007
qui gen year = substr(PERIOD_NAME,1,4)
qui destring year, replace
qui drop if year < 2007 
qui drop year OBS_DATE PERIOD_FIRST_DATE PERIOD_LAST_DATE SERIES_KEY FORMATTED_OBS_VALUE


qui save "$dataoutputPath/B8G_ALL.dta", replace                                    // macrodata















