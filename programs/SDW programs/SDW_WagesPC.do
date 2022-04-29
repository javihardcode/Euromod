*** Download wage per employee (based on aggregate wages and employment)

* 1) Aggregate wages and salaries
foreach ii of global ctrylist {
/*
	if inlist("`ii'", "FR", "DE", "SK") getTimeSeries ECB MNA.Q.S.`ii'.W2.S1.S1.D.D11._Z._T._Z.EUR.V.N $year_start "" 0 1
	else getTimeSeries ECB MNA.Q.Y.`ii'.W2.S1.S1.D.D11._Z._T._Z.EUR.V.N $year_start "" 0 1
	
	drop TSNAME
	rename VALUE wages_`ii'
	rename DATE PERIOD_NAME */
	
	
	if inlist("`ii'", "FR", "DE", "SK") local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_MNA_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('MNA.Q.S.`ii'.W2.S1.S1.D.D11._Z._T._Z.EUR.V.N') AND PERIOD_NAME>='2007'"
	else local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_MNA_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('MNA.Q.Y.`ii'.W2.S1.S1.D.D11._Z._T._Z.EUR.V.N') AND PERIOD_NAME>='2007'"
	
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear

	rename OBS_VALUE wages_`ii'
	
	
	
	compress
	save "$dataoutputPath/wages_`ii'.dta", replace
	
}

local ctry1 `: word 1 of $ctrylist'
use "$dataoutputPath/wages_`ctry1'.dta", clear
rm "$dataoutputPath/wages_`ctry1'.dta"

local n_countries `: word count $ctrylist'
forval i = 2/`n_countries' {

	local ctry `: word `i' of $ctrylist'
	merge 1:1 PERIOD_NAME using "$dataoutputPath/wages_`ctry'.dta"
	drop _merge
	rm "$dataoutputPath/wages_`ctry'.dta"
	
}

compress
sort PERIOD_NAME
save "$dataoutputPath/wages_ALL.dta", replace

* 2) Aggregate number of employees
foreach ii of global ctrylist {
		
/*	if inlist("`ii'", "FR", "GR", "MT", "PL", "PT", "SK") getTimeSeries ECB ENA.Q.S.`ii'.W2.S1.S1._Z.EMP._Z._T._Z.PS._Z.N $year_start "" 0 1
	else getTimeSeries ECB ENA.Q.Y.`ii'.W2.S1.S1._Z.EMP._Z._T._Z.PS._Z.N $year_start "" 0 1*/
	
	if inlist("`ii'", "FR", "GR", "MT", "PL", "PT", "SK") local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_ENA_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('ENA.Q.S.`ii'.W2.S1.S1._Z.EMP._Z._T._Z.PS._Z.N') AND PERIOD_NAME>='2007'"
	else local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_ENA_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('ENA.Q.Y.`ii'.W2.S1.S1._Z.EMP._Z._T._Z.PS._Z.N') AND PERIOD_NAME>='2007'"
	
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	
	rename OBS_VALUE emp_`ii'
	
	sort PERIOD_NAME
	compress
	save "$dataoutputPath/emp_`ii'.dta", replace
	
}

local ctry1 `: word 1 of $ctrylist'
use "$dataoutputPath/emp_`ctry1'.dta", clear
rm "$dataoutputPath/emp_`ctry1'.dta"

local n_countries `: word count $ctrylist'
forval i = 2/`n_countries' {

	local ctry `: word `i' of $ctrylist'
	merge 1:1 PERIOD_NAME using "$dataoutputPath/emp_`ctry'.dta"
	drop _merge
	rm "$dataoutputPath/emp_`ctry'.dta"
	
}

compress
sort PERIOD_NAME
save "$dataoutputPath/emp_ALL.dta", replace

* Merge and compute wage per employee
use "$dataoutputPath/wages_ALL.dta", clear
merge 1:1 PERIOD_NAME using "$dataoutputPath/emp_ALL.dta"
drop _merge
rm "$dataoutputPath/wages_ALL.dta"
rm "$dataoutputPath/emp_ALL.dta"

foreach ii of global ctrylist {

	gen WagesPC_`ii' = wages_`ii'/emp_`ii'                                
	
	drop emp_`ii'                                                               // dont drop aggregate Wages

}

compress
sort PERIOD_NAME
drop if PERIOD_NAME < "2007Q1"
save "$dataoutputPath/WagesPC_ALL.dta", replace
