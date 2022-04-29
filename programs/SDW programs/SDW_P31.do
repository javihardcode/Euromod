*** Download P31 - Private final consumption (in levels at current prices)
* in millions 
* seasonally udjusted (as disposable income)



* MISSING FOR SK. USE SI INSTEAD.

foreach ii of global ctrylist {
/*
	if inlist("`ii'", "SK") getTimeSeries ECB MNA.Q.Y.SI.W0.S1M.S1.D.P31._Z._Z._T.XDC.V.N $year_start "" 0 1
	else getTimeSeries ECB MNA.Q.Y.`ii'.W0.S1M.S1.D.P31._Z._Z._T.XDC.V.N $year_start "" 0 1
 	
	drop TSNAME
 	rename VALUE P31_`ii'
 	rename DATE PERIOD_NAME
 	compress
 	save "$dataoutputPath/P31_`ii'.dta", replace
*/

******************************************************************************************************************
* NOTE 15-11-2021: Original key for P31: MNA.Q.Y.`ii'.W0.S1M.S1.D.P31._Z._Z._T.XDC.V.N
* However, I cannot find it in SDW: https://sdw.ecb.europa.eu/browse.do?node=9683074 
* Instead, I use the key:                MNA.Q.Y.`ii'.W0.S1M.S1.D.P31._Z._Z._T.XDC.LR.N
******************************************************************************************************************
	if inlist("`ii'", "SK") local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_MNA_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('MNA.Q.Y.SI.W0.S1M.S1.D.P31._Z._Z._T.XDC.V.N') AND PERIOD_NAME>='2007'"
	
	else local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_MNA_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('MNA.Q.Y.`ii'.W0.S1M.S1.D.P31._Z._Z._T.XDC.V.N') AND PERIOD_NAME>='2007'"
	
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	
	rename OBS_VALUE P31_`ii'
	
	sort PERIOD_NAME
	compress
	save "$dataoutputPath/P31_`ii'.dta", replace
	
}


* Combine countries into one file
local country1 `: word 1 of $ctrylist'

use "$dataoutputPath/P31_`country1'.dta", clear
rm "$dataoutputPath/P31_`country1'.dta"

local n_countries `: word count $ctrylist'
forval i = 2/`n_countries' {

 	local country `: word `i' of $ctrylist'
	
 	merge 1:1 PERIOD_NAME using "$dataoutputPath/P31_`country'.dta"
 	drop _merge
 	rm "$dataoutputPath/P31_`country'.dta"
	
}

* DROP OBSERVATIONS BEFORE 2007
gen year = substr(PERIOD_NAME,1,4)
destring year, replace
drop if year < 2007 
drop year OBS_DATE PERIOD_FIRST_DATE PERIOD_LAST_DATE SERIES_KEY FORMATTED_OBS_VALUE


 save "$dataoutputPath/P31_ALL.dta", replace                                    // macrodata


** Other Aggregate consumption series

* Final consumption expenditure of households, per capita (growth rate)
* QSA.Q.N.`ii'.W0.S1M.S1.N.A.LE.F6+F62+F6M._Z._Z.XDC._T.S.V.N._T

* Final consumption expenditure of households
* QSA.Q.N.I8.W0.S1M.S1.N.D.P3._Z._Z._Z.XDC._T.S.V.N._T 


* Collective consumption expenditure of Total economy
* QSA.Q.N.I8.W0.S1.S1.N.D.P32._Z._Z._Z.XDC._T.S.V.N._T 


* Individual consumption expenditure of households
* QSA.Q.N.I8.W0.S1M.S1.N.D.P31._Z._Z._Z.XDC._T.S.V.N._T  


* Final consumption expenditure of Total economy 
* QSA.Q.N.I8.W0.S1.S1.N.D.P3._Z._Z._Z.XDC._T.S.V.N._T 

