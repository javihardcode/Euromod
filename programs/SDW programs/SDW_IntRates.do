* Construction

*** Download Interest rates (long, medium, short) for consumption and house purchase

* OUTPUT VARIABLES
// label variable IntR_L_ "Rate for Loans > 10 years"
// label variable IntR_M_ "Rate for Loans 1><5 years"
// label variable IntR_S_ "Rate for Loans <1 year"
// label variable IntRH_all_ "Rate for all Housing loans (weighted)"
// label variable IntRC_all_ "Rate for all Consump loans (weighted)"

/*
* 1) House purchase interest rates: IntR_P and IntR_AM 
foreach ii of global ctrylist {

	if !inlist("`ii'", "HU","PL") {
	getTimeSeries ECB MIR.M.`ii'.B.A2C.P+AM.R.A.2250.EUR.N $year_start "" 0 1

	* Convert monthly to quarterly frequency by taking averages over months
	gen yq = qofd(dofm(monthly(DATE,"YM"))) 
	format yq %tq
	collapse (mean) VALUE = VALUE, by(yq TSNAME)
	gen yq2 = string(yq, "%tq")
	gen yq3 = upper(yq2)
	gen year = regexs(0) if(regexm(yq3, "[0-9][0-9][0-9][0-9]"))
	gen quarter = regexs(0) if(regexm(yq3, "Q[0-9]"))
	gen DATE = year + "-" + quarter 
	drop yq yq2 yq3 year quarter
	
	* Separate into two variables
	gen var = regexs(0) if(regexm(TSNAME, "A2C.AM"))
	replace var = regexs(0) if(regexm(TSNAME, "A2C.P"))	
	gen var1 = subinstr(var,".","_",.)
	gen var2 = subinstr(var1,"A2C","",.)

	drop var var1
	drop TSNAME
	rename VALUE `ii'
	reshape wide `ii', i(DATE) j(var2) string
	
	rename `ii'_AM IntRH_all_`ii'
	label variable IntRH_all_`ii' "Rate for all Housing Loans (weighted)"
	
	rename `ii'_P IntR_L_`ii' 
	label variable IntR_L_`ii' "Rate for Housing Loans > 10 years"
		
	rename DATE PERIOD_NAME
	sort PERIOD_NAME	
	compress	
	save "$dataoutputPath/IntHP_`ii'.dta", replace
	}
	
	* Countries with missing variable: HU
	if inlist("`ii'", "HU") {
	getTimeSeries ECB MIR.M.`ii'.B.A2C.P+A.R.A.2250.HUF.N $year_start "" 0 1

	* Convert monthly to quarterly frequency by taking averages over months
	gen yq = qofd(dofm(monthly(DATE,"YM"))) 
	format yq %tq
	collapse (mean) VALUE = VALUE, by(yq TSNAME)
	gen yq2 = string(yq, "%tq")
	gen yq3 = upper(yq2)
	gen year = regexs(0) if(regexm(yq3, "[0-9][0-9][0-9][0-9]"))
	gen quarter = regexs(0) if(regexm(yq3, "Q[0-9]"))
	gen DATE = year + "-" + quarter 
	drop yq yq2 yq3 year quarter
	
	* Separate into two variables
	gen var = regexs(0) if(regexm(TSNAME, "A2C.A"))
	replace var = regexs(0) if(regexm(TSNAME, "A2C.P"))	
	gen var1 = subinstr(var,".","_",.)
	gen var2 = subinstr(var1,"A2C","",.)

	drop var var1
	drop TSNAME
	rename VALUE `ii'
	reshape wide `ii', i(DATE) j(var2) string
	
	rename `ii'_A IntRH_all_`ii'
	label variable IntRH_all_`ii' "Rate for all Housing Loans"
	
	rename `ii'_P IntR_L_`ii' 
	label variable IntR_L_`ii' "Rate for Housing Loans > 10 years"
		
	rename DATE PERIOD_NAME
	sort PERIOD_NAME	
	compress	
	save "$dataoutputPath/IntHP_`ii'.dta", replace
	}
	
	* Countries with missing variable: PL
	if inlist("`ii'", "PL") {
	getTimeSeries ECB MIR.M.`ii'.B.A2C.P+A.R.A.2250.PLN.N $year_start "" 0 1

	* Convert monthly to quarterly frequency by taking averages over months
	gen yq = qofd(dofm(monthly(DATE,"YM"))) 
	format yq %tq
	collapse (mean) VALUE = VALUE, by(yq TSNAME)
	gen yq2 = string(yq, "%tq")
	gen yq3 = upper(yq2)
	gen year = regexs(0) if(regexm(yq3, "[0-9][0-9][0-9][0-9]"))
	gen quarter = regexs(0) if(regexm(yq3, "Q[0-9]"))
	gen DATE = year + "-" + quarter 
	drop yq yq2 yq3 year quarter
	
	* Separate into two variables
	gen var = regexs(0) if(regexm(TSNAME, "A2C.A"))
	replace var = regexs(0) if(regexm(TSNAME, "A2C.P"))	
	gen var1 = subinstr(var,".","_",.)
	gen var2 = subinstr(var1,"A2C","",.)

	drop var var1
	drop TSNAME
	rename VALUE `ii'
	reshape wide `ii', i(DATE) j(var2) string
	
	rename `ii'_A IntRH_all_`ii'
	label variable IntRH_all_`ii' "Rate for all Housing Loans"
	
	rename `ii'_P IntR_L_`ii' 
	label variable IntR_L_`ii' "Rate for Housing Loans > 10 years"
		
	rename DATE PERIOD_NAME
	sort PERIOD_NAME	
	compress	
	save "$dataoutputPath/IntHP_`ii'.dta", replace
	}
	
}

* Combine countries into one file
local country1 `: word 1 of $ctrylist'

use "$dataoutputPath/IntHP_`country1'.dta", clear
rm "$dataoutputPath/IntHP_`country1'.dta"

local n_countries `: word count $ctrylist'
forval i = 2/`n_countries' {

	local country `: word `i' of $ctrylist'
	
	merge 1:1 PERIOD_NAME using "$dataoutputPath/IntHP_`country'.dta"
	drop _merge
	rm "$dataoutputPath/IntHP_`country'.dta"
	
}

save "$dataoutputPath/IntHP_ALL.dta", replace


* 2) Consumption interest rate: IntR_I, IntR_F and IntR_A
foreach ii of global ctrylist {

	if !inlist("`ii'", "HU","PL") {
	getTimeSeries ECB MIR.M.`ii'.B.A2B.I+F+A.R.A.2250.EUR.N $year_start "" 0 1

	* Convert monthly to quarterly frequency by taking averages over months
	gen yq = qofd(dofm(monthly(DATE,"YM"))) 
	format yq %tq
	collapse (mean) VALUE = VALUE, by(yq TSNAME)
	gen yq2 = string(yq, "%tq")
	gen yq3 = upper(yq2)
	gen year = regexs(0) if(regexm(yq3, "[0-9][0-9][0-9][0-9]"))
	gen quarter = regexs(0) if(regexm(yq3, "Q[0-9]"))
	gen DATE = year + "-" + quarter 
	drop yq yq2 yq3 year quarter
	
	* Separate into two variables
	gen var = regexs(0) if(regexm(TSNAME, "A2B.I"))
	replace var = regexs(0) if(regexm(TSNAME, "A2B.F"))	
	replace var = regexs(0) if(regexm(TSNAME, "A2B.A"))	
	gen var1 = subinstr(var,".","_",.)
	gen var2 = subinstr(var1,"A2B","",.)

	drop var var1
	drop TSNAME
	rename VALUE `ii'
	reshape wide `ii', i(DATE) j(var2) string
	
	rename `ii'_A IntRC_all_`ii'
	label variable IntRC_all_`ii' "Rate for all Consumption Loans (weighted)"
	
	rename `ii'_F IntR_S_`ii' 
	label variable IntR_S_`ii' "Rate for Consumption Loans <1 year"
	
	rename `ii'_I IntR_M_`ii' 
	label variable IntR_M_`ii' "Rate for Consumption Loans 1><5 years"
	
	rename DATE PERIOD_NAME
	sort PERIOD_NAME	
	compress	
	save "$dataoutputPath/IntC_`ii'.dta", replace
	}
	
	* Countries with missing variable: HU
	if inlist("`ii'", "HU") {
	getTimeSeries ECB MIR.M.`ii'.B.A2B.I+F+A.R.A.2250.HUF.N $year_start "" 0 1

	* Convert monthly to quarterly frequency by taking averages over months
	gen yq = qofd(dofm(monthly(DATE,"YM"))) 
	format yq %tq
	collapse (mean) VALUE = VALUE, by(yq TSNAME)
	gen yq2 = string(yq, "%tq")
	gen yq3 = upper(yq2)
	gen year = regexs(0) if(regexm(yq3, "[0-9][0-9][0-9][0-9]"))
	gen quarter = regexs(0) if(regexm(yq3, "Q[0-9]"))
	gen DATE = year + "-" + quarter 
	drop yq yq2 yq3 year quarter
	
	* Separate into two variables
	gen var = regexs(0) if(regexm(TSNAME, "A2B.I"))
	replace var = regexs(0) if(regexm(TSNAME, "A2B.F"))	
	replace var = regexs(0) if(regexm(TSNAME, "A2B.A"))	
	gen var1 = subinstr(var,".","_",.)
	gen var2 = subinstr(var1,"A2B","",.)

	drop var var1
	drop TSNAME
	rename VALUE `ii'
	reshape wide `ii', i(DATE) j(var2) string
	
	rename `ii'_A IntRC_all_`ii'
	label variable IntRC_all_`ii' "Rate for all Consumption Loans (weighted)"
	
	rename `ii'_F IntR_S_`ii' 
	label variable IntR_S_`ii' "Rate for Consumption Loans <1 year"
	
	rename `ii'_I IntR_M_`ii' 
	label variable IntR_M_`ii' "Rate for Consumption Loans 1><5 years"
	
	rename DATE PERIOD_NAME
	sort PERIOD_NAME	
	compress	
	save "$dataoutputPath/IntC_`ii'.dta", replace
	}
	
	* Countries with missing variable: PL
	if inlist("`ii'", "PL") {
	getTimeSeries ECB MIR.M.`ii'.B.A2B.I+F+A.R.A.2250.PLN.N $year_start "" 0 1

	* Convert monthly to quarterly frequency by taking averages over months
	gen yq = qofd(dofm(monthly(DATE,"YM"))) 
	format yq %tq
	collapse (mean) VALUE = VALUE, by(yq TSNAME)
	gen yq2 = string(yq, "%tq")
	gen yq3 = upper(yq2)
	gen year = regexs(0) if(regexm(yq3, "[0-9][0-9][0-9][0-9]"))
	gen quarter = regexs(0) if(regexm(yq3, "Q[0-9]"))
	gen DATE = year + "-" + quarter 
	drop yq yq2 yq3 year quarter
	
	* Separate into two variables
	gen var = regexs(0) if(regexm(TSNAME, "A2B.I"))
	replace var = regexs(0) if(regexm(TSNAME, "A2B.F"))	
	replace var = regexs(0) if(regexm(TSNAME, "A2B.A"))	
	gen var1 = subinstr(var,".","_",.)
	gen var2 = subinstr(var1,"A2B","",.)

	drop var var1
	drop TSNAME
	rename VALUE `ii'
	reshape wide `ii', i(DATE) j(var2) string
	
	rename `ii'_A IntRC_all_`ii'
	label variable IntRC_all_`ii' "Rate for all Consumption Loans (weighted)"
	
	rename `ii'_F IntR_S_`ii' 
	label variable IntR_S_`ii' "Rate for Consumption Loans <1 year"
	
	rename `ii'_I IntR_M_`ii' 
	label variable IntR_M_`ii' "Rate for Consumption Loans 1><5 years"
	
	rename DATE PERIOD_NAME
	sort PERIOD_NAME	
	compress	
	save "$dataoutputPath/IntC_`ii'.dta", replace
	}
	
}
*/

* 1) House purchase interest rates: IntR_P and IntR_AM 
foreach ii of global ctrylist {

	local int_vars "IntRH_all IntR_L"
	
	foreach var of local int_vars {

	if !inlist("`ii'", "HU","PL") {
	*getTimeSeries ECB MIR.M.`ii'.B.A2C.P+AM.R.A.2250.EUR.N $year_start "" 0 1
	if inlist("`var'", "IntRH_all"){
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_MIR_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('MIR.M.`ii'.B.A2C.AM.R.A.2250.EUR.N') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}
	if inlist("`var'", "IntR_L"){
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_MIR_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('MIR.M.`ii'.B.A2C.P.R.A.2250.EUR.N') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}
	* Convert monthly to quarterly frequency by taking averages over months
	gen yq = qofd(dofm(monthly(PERIOD_NAME,"YM"))) 
	format yq %tq
	collapse (mean) OBS_VALUE = OBS_VALUE, by(yq /*TSNAME*/)
	gen yq2 = string(yq, "%tq")
	gen yq3 = upper(yq2)
	gen year = regexs(0) if(regexm(yq3, "[0-9][0-9][0-9][0-9]"))
	gen quarter = regexs(0) if(regexm(yq3, "Q[0-9]"))
	gen PERIOD_NAME = year + /*"-" +*/ quarter 
	drop yq yq2 yq3 year quarter
	
	/** Separate into two variables
	gen var = regexs(0) if(regexm(TSNAME, "A2C.AM"))
	replace var = regexs(0) if(regexm(TSNAME, "A2C.P"))	
	gen var1 = subinstr(var,".","_",.)
	gen var2 = subinstr(var1,"A2C","",.)

	drop var var1
	drop TSNAME
	rename VALUE `ii'
	reshape wide `ii', i(DATE) j(var2) string*/
	if inlist("`var'", "IntRH_all"){
	rename OBS_VALUE IntRH_all_`ii'
	label variable IntRH_all_`ii' "Rate for all Housing Loans (weighted)"
	}
	if inlist("`var'", "IntR_L"){
	rename OBS_VALUE IntR_L_`ii' 
	label variable IntR_L_`ii' "Rate for Housing Loans > 10 years"
	}	
	*rename DATE PERIOD_NAME
	sort PERIOD_NAME	
	compress	
	save "$dataoutputPath/IntHP_`var'_`ii'.dta", replace
	}
	
	* Countries with missing variable: HU
	if inlist("`ii'", "HU") {
	*getTimeSeries ECB MIR.M.`ii'.B.A2C.P+A.R.A.2250.HUF.N $year_start "" 0 1

	if inlist("`var'", "IntRH_all"){
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_MIR_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('MIR.M.`ii'.B.A2C.A.R.A.2250.HUF.N') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}
	if inlist("`var'", "IntR_L"){
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_MIR_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('MIR.M.`ii'.B.A2C.P.R.A.2250.HUF.N') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}
	* Convert monthly to quarterly frequency by taking averages over months
	gen yq = qofd(dofm(monthly(PERIOD_NAME,"YM"))) 
	format yq %tq
	collapse (mean) OBS_VALUE = OBS_VALUE, by(yq /*TSNAME*/)
	gen yq2 = string(yq, "%tq")
	gen yq3 = upper(yq2)
	gen year = regexs(0) if(regexm(yq3, "[0-9][0-9][0-9][0-9]"))
	gen quarter = regexs(0) if(regexm(yq3, "Q[0-9]"))
	gen PERIOD_NAME = year + /*"-" +*/ quarter 
	drop yq yq2 yq3 year quarter
	
	/** Separate into two variables
	gen var = regexs(0) if(regexm(TSNAME, "A2C.AM"))
	replace var = regexs(0) if(regexm(TSNAME, "A2C.P"))	
	gen var1 = subinstr(var,".","_",.)
	gen var2 = subinstr(var1,"A2C","",.)

	drop var var1
	drop TSNAME
	rename VALUE `ii'
	reshape wide `ii', i(DATE) j(var2) string*/
	if inlist("`var'", "IntRH_all"){
	rename OBS_VALUE IntRH_all_`ii'
	label variable IntRH_all_`ii' "Rate for all Housing Loans (weighted)"
	}
	if inlist("`var'", "IntR_L"){
	rename OBS_VALUE IntR_L_`ii' 
	label variable IntR_L_`ii' "Rate for Housing Loans > 10 years"
	}	
	*rename DATE PERIOD_NAME
	sort PERIOD_NAME	
	compress	
	save "$dataoutputPath/IntHP_`var'_`ii'.dta", replace
	}
	
	* Countries with missing variable: PL
	if inlist("`ii'", "PL") {
	*getTimeSeries ECB MIR.M.`ii'.B.A2C.P+A.R.A.2250.PLN.N $year_start "" 0 1

	if inlist("`var'", "IntRH_all"){
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_MIR_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('MIR.M.`ii'.B.A2C.A.R.A.2250.PLN.N') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}
	if inlist("`var'", "IntR_L"){
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_MIR_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('MIR.M.`ii'.B.A2C.P.R.A.2250.PLN.N') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}
	* Convert monthly to quarterly frequency by taking averages over months
	gen yq = qofd(dofm(monthly(PERIOD_NAME,"YM"))) 
	format yq %tq
	collapse (mean) OBS_VALUE = OBS_VALUE, by(yq /*TSNAME*/)
	gen yq2 = string(yq, "%tq")
	gen yq3 = upper(yq2)
	gen year = regexs(0) if(regexm(yq3, "[0-9][0-9][0-9][0-9]"))
	gen quarter = regexs(0) if(regexm(yq3, "Q[0-9]"))
	gen PERIOD_NAME = year + /*"-" +*/ quarter 
	drop yq yq2 yq3 year quarter
	
	/** Separate into two variables
	gen var = regexs(0) if(regexm(TSNAME, "A2C.AM"))
	replace var = regexs(0) if(regexm(TSNAME, "A2C.P"))	
	gen var1 = subinstr(var,".","_",.)
	gen var2 = subinstr(var1,"A2C","",.)

	drop var var1
	drop TSNAME
	rename VALUE `ii'
	reshape wide `ii', i(DATE) j(var2) string*/
	if inlist("`var'", "IntRH_all"){
	rename OBS_VALUE IntRH_all_`ii'
	label variable IntRH_all_`ii' "Rate for all Housing Loans (weighted)"
	}
	if inlist("`var'", "IntR_L"){
	rename OBS_VALUE IntR_L_`ii' 
	label variable IntR_L_`ii' "Rate for Housing Loans > 10 years"
	}	
	*rename DATE PERIOD_NAME
	sort PERIOD_NAME	
	compress	
	save "$dataoutputPath/IntHP_`var'_`ii'.dta", replace
	}
	}
	
	use "$dataoutputPath/IntHP_IntRH_all_`ii'.dta", clear
	merge 1:1 PERIOD_NAME using "$dataoutputPath/IntHP_IntR_L_`ii'.dta"
	drop _merge
	save "$dataoutputPath/IntHP_`ii'", replace
	rm "$dataoutputPath/IntHP_IntRH_all_`ii'.dta"
	rm "$dataoutputPath/IntHP_IntR_L_`ii'.dta"
	
}

* Combine countries into one file
local country1 `: word 1 of $ctrylist'

use "$dataoutputPath/IntHP_`country1'.dta", clear
rm "$dataoutputPath/IntHP_`country1'.dta"

local n_countries `: word count $ctrylist'
forval i = 2/`n_countries' {

	local country `: word `i' of $ctrylist'
	
	merge 1:1 PERIOD_NAME using "$dataoutputPath/IntHP_`country'.dta"
	drop _merge
	rm "$dataoutputPath/IntHP_`country'.dta"
	
}

save "$dataoutputPath/IntHP_ALL.dta", replace


* 2) Consumption interest rate: IntR_I, IntR_F and IntR_A
foreach ii of global ctrylist {

	local int_vars "IntRC_all IntR_S IntR_M"
	
	foreach var of local int_vars {

	if !inlist("`ii'", "HU","PL") {
	*getTimeSeries ECB MIR.M.`ii'.B.A2C.P+AM.R.A.2250.EUR.N $year_start "" 0 1
	if inlist("`var'", "IntRC_all"){
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_MIR_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('MIR.M.`ii'.B.A2B.A.R.A.2250.EUR.N') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}
	if inlist("`var'", "IntR_S"){
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_MIR_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('MIR.M.`ii'.B.A2B.F.R.A.2250.EUR.N') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}
	if inlist("`var'", "IntR_M"){
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_MIR_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('MIR.M.`ii'.B.A2B.I.R.A.2250.EUR.N') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}
	* Convert monthly to quarterly frequency by taking averages over months
	gen yq = qofd(dofm(monthly(PERIOD_NAME,"YM"))) 
	format yq %tq
	collapse (mean) OBS_VALUE = OBS_VALUE, by(yq /*TSNAME*/)
	gen yq2 = string(yq, "%tq")
	gen yq3 = upper(yq2)
	gen year = regexs(0) if(regexm(yq3, "[0-9][0-9][0-9][0-9]"))
	gen quarter = regexs(0) if(regexm(yq3, "Q[0-9]"))
	gen PERIOD_NAME = year + /*"-" +*/ quarter 
	drop yq yq2 yq3 year quarter
	
	/** Separate into two variables
	gen var = regexs(0) if(regexm(TSNAME, "A2C.AM"))
	replace var = regexs(0) if(regexm(TSNAME, "A2C.P"))	
	gen var1 = subinstr(var,".","_",.)
	gen var2 = subinstr(var1,"A2C","",.)

	drop var var1
	drop TSNAME
	rename VALUE `ii'
	reshape wide `ii', i(DATE) j(var2) string*/

	if inlist("`var'", "IntRC_all"){	
	rename OBS_VALUE IntRC_all_`ii'
	label variable IntRC_all_`ii' "Rate for all Consumption Loans (weighted)"
	}
	if inlist("`var'", "IntR_S"){
	rename OBS_VALUE IntR_S_`ii' 
	label variable IntR_S_`ii' "Rate for Consumption Loans <1 year"
	}
	if inlist("`var'", "IntR_M"){
	rename OBS_VALUE IntR_M_`ii' 
	label variable IntR_M_`ii' "Rate for Consumption Loans 1><5 years"
	}
	*rename DATE PERIOD_NAME
	sort PERIOD_NAME	
	compress	
	save "$dataoutputPath/IntC_`var'_`ii'.dta", replace
	}
	
	* Countries with missing variable: HU
	if inlist("`ii'", "HU") {
	*getTimeSeries ECB MIR.M.`ii'.B.A2B.I+F+A.R.A.2250.HUF.N $year_start "" 0 1

	if inlist("`var'", "IntRC_all"){
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_MIR_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('MIR.M.`ii'.B.A2B.A.R.A.2250.HUF.N') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}
	if inlist("`var'", "IntR_S"){
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_MIR_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('MIR.M.`ii'.B.A2B.F.R.A.2250.HUF.N') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}
	if inlist("`var'", "IntR_M"){
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_MIR_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('MIR.M.`ii'.B.A2B.I.R.A.2250.HUF.N') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}
	* Convert monthly to quarterly frequency by taking averages over months
	gen yq = qofd(dofm(monthly(PERIOD_NAME,"YM"))) 
	format yq %tq
	collapse (mean) OBS_VALUE = OBS_VALUE, by(yq /*TSNAME*/)
	gen yq2 = string(yq, "%tq")
	gen yq3 = upper(yq2)
	gen year = regexs(0) if(regexm(yq3, "[0-9][0-9][0-9][0-9]"))
	gen quarter = regexs(0) if(regexm(yq3, "Q[0-9]"))
	gen PERIOD_NAME = year + /*"-" +*/ quarter 
	drop yq yq2 yq3 year quarter
	
	/** Separate into two variables
	gen var = regexs(0) if(regexm(TSNAME, "A2C.AM"))
	replace var = regexs(0) if(regexm(TSNAME, "A2C.P"))	
	gen var1 = subinstr(var,".","_",.)
	gen var2 = subinstr(var1,"A2C","",.)

	drop var var1
	drop TSNAME
	rename VALUE `ii'
	reshape wide `ii', i(DATE) j(var2) string*/
	if inlist("`var'", "IntRC_all"){	
	rename OBS_VALUE IntRC_all_`ii'
	label variable IntRC_all_`ii' "Rate for all Consumption Loans (weighted)"
	}
	if inlist("`var'", "IntR_S"){
	rename OBS_VALUE IntR_S_`ii' 
	label variable IntR_S_`ii' "Rate for Consumption Loans <1 year"
	}
	if inlist("`var'", "IntR_M"){
	rename OBS_VALUE IntR_M_`ii' 
	label variable IntR_M_`ii' "Rate for Consumption Loans 1><5 years"
	}
	*rename DATE PERIOD_NAME
	sort PERIOD_NAME	
	compress	
	save "$dataoutputPath/IntC_`var'_`ii'.dta", replace
	}
	
	* Countries with missing variable: PL
	if inlist("`ii'", "PL") {
	*getTimeSeries ECB MIR.M.`ii'.B.A2B.I+F+A.R.A.2250.PLN.N $year_start "" 0 1

	if inlist("`var'", "IntRC_all"){
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_MIR_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('MIR.M.`ii'.B.A2B.A.R.A.2250.PLN.N') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}
	if inlist("`var'", "IntR_S"){
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_MIR_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('MIR.M.`ii'.B.A2B.F.R.A.2250.PLN.N') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}
	if inlist("`var'", "IntR_M"){
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_MIR_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('MIR.M.`ii'.B.A2B.I.R.A.2250.PLN.N') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear
	}
	* Convert monthly to quarterly frequency by taking averages over months
	gen yq = qofd(dofm(monthly(PERIOD_NAME,"YM"))) 
	format yq %tq
	collapse (mean) OBS_VALUE = OBS_VALUE, by(yq /*TSNAME*/)
	gen yq2 = string(yq, "%tq")
	gen yq3 = upper(yq2)
	gen year = regexs(0) if(regexm(yq3, "[0-9][0-9][0-9][0-9]"))
	gen quarter = regexs(0) if(regexm(yq3, "Q[0-9]"))
	gen PERIOD_NAME = year + /*"-" +*/ quarter 
	drop yq yq2 yq3 year quarter
	
	/** Separate into two variables
	gen var = regexs(0) if(regexm(TSNAME, "A2C.AM"))
	replace var = regexs(0) if(regexm(TSNAME, "A2C.P"))	
	gen var1 = subinstr(var,".","_",.)
	gen var2 = subinstr(var1,"A2C","",.)

	drop var var1
	drop TSNAME
	rename VALUE `ii'
	reshape wide `ii', i(DATE) j(var2) string*/
	if inlist("`var'", "IntRC_all"){	
	rename OBS_VALUE IntRC_all_`ii'
	label variable IntRC_all_`ii' "Rate for all Consumption Loans (weighted)"
	}
	if inlist("`var'", "IntR_S"){
	rename OBS_VALUE IntR_S_`ii' 
	label variable IntR_S_`ii' "Rate for Consumption Loans <1 year"
	}
	if inlist("`var'", "IntR_M"){
	rename OBS_VALUE IntR_M_`ii' 
	label variable IntR_M_`ii' "Rate for Consumption Loans 1><5 years"
	}	
	*rename DATE PERIOD_NAME
	sort PERIOD_NAME	
	compress	
	save "$dataoutputPath/IntC_`var'_`ii'.dta", replace
	}
	}
	
	use "$dataoutputPath/IntC_IntRC_all_`ii'.dta", clear
	merge 1:1 PERIOD_NAME using "$dataoutputPath/IntC_IntR_S_`ii'.dta"
	drop _merge
	merge 1:1 PERIOD_NAME using "$dataoutputPath/IntC_IntR_M_`ii'.dta"
	drop _merge
	save "$dataoutputPath/IntC_`ii'", replace
	rm "$dataoutputPath/IntC_IntRC_all_`ii'.dta"
	rm "$dataoutputPath/IntC_IntR_S_`ii'.dta"
	rm "$dataoutputPath/IntC_IntR_M_`ii'.dta"
	
}




* Combine countries into one file
local country1 `: word 1 of $ctrylist'

use "$dataoutputPath/IntC_`country1'.dta", clear
rm "$dataoutputPath/IntC_`country1'.dta"

local n_countries `: word count $ctrylist'
forval i = 2/`n_countries' {

	local country `: word `i' of $ctrylist'
	
	merge 1:1 PERIOD_NAME using "$dataoutputPath/IntC_`country'.dta"
	drop _merge
	rm "$dataoutputPath/IntC_`country'.dta"
	
}

save "$dataoutputPath/IntC_ALL.dta", replace


* Merge datasets
merge 1:1 PERIOD_NAME using "$dataoutputPath/IntHP_ALL.dta"
drop _merge
save "$dataoutputPath/IntRates_ALL.dta", replace

rm "$dataoutputPath/IntC_ALL.dta"
rm "$dataoutputPath/IntHP_ALL.dta"


// * Impute missing values - NEEDS TO BE COMPLETED
//
// * Imputation for NL
// * Data before 2009Q4 missing for consumption loans
// encode PERIOD_NAME, gen(time)
// sort time
// gen ind=(IntRC_all_NL[_n-1]==. & _n>1)
// replace ind=0 if IntRC_all_NL==.
// gen temp=IntRC_all_NL/IntRH_all_NL if ind==1
// egen C_H_ratio=mean(temp)
// replace IntRC_all_NL=C_H_ratio*IntRH_all_NL if  IntRC_all_NL==.
// drop time ind C_H_ratio temp
//
// * Imputation for MT
// * data for 2013Q2 and 2013Q3 missing: mean of Q1 and Q4
// gen tempQ1=IntRC_all_MT if PERIOD_NAME=="2013-Q1"
// gen tempQ4=IntRC_all_MT if PERIOD_NAME=="2013-Q4"
// egen tempmeanQ1=mean(tempQ1)
// egen tempmeanQ4=mean(tempQ4)
// gen temp_imputed=(tempmeanQ1+tempmeanQ4)/2
// replace IntRC_all_MT=temp_imputed if IntRC_all_MT==. &  PERIOD_NAME=="2013-Q2"
// replace IntRC_all_MT=temp_imputed if IntRC_all_MT==. &  PERIOD_NAME=="2013-Q3"
// drop temp*
//
// * data for 2010Q13missing: mean of Q2-Q4
// gen tempQ2=IntRC_all_MT if PERIOD_NAME=="2012Q2"
// gen tempQ4=IntRC_all_MT if PERIOD_NAME=="2012Q4"
// egen tempmeanQ2=mean(tempQ2)
// egen tempmeanQ4=mean(tempQ4)
// gen temp_imputed=(tempmeanQ2+tempmeanQ4)/2
// replace IntRC_all_MT=temp_imputed if IntRC_all_MT==. &  PERIOD_NAME=="2010Q3"
// drop temp*
//
// * data for 2009Q1-2010Q1 missing
// gen temp=IntRC_all_CY/IntR_S_CY if PERIOD_NAME=="2010Q1"
// egen C_S_ratio=mean(temp)
// replace IntRC_all_CY=C_S_ratio*IntR_S_CY if IntRC_all_CY==.
// drop C_S_ratio temp



