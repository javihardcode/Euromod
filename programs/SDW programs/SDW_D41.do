*** Download D41 - Interests
* Total interest paid to households (in millions)
* Quick view for Spain: (https://sdw.ecb.europa.eu/quickview.do?SERIES_KEY=332.QSA.Q.N.ES.W0.S1M.S1.N.D.D41._Z._Z._Z.XDC._T.S.V.N._T) 

* NOTE: Variable is missing for several countries. Use HICP instead.
/*
foreach ii of global ctrylist {
	
	if !inlist("`ii'", "CY", "EE", "HU", "LV", "LU", "MT", "SK") {
	getTimeSeries ECB QSA.Q.N.`ii'.W0.S1M.S1.N.D.D41._Z._Z._Z.XDC._T.S.V.N._T $year_start "" 0 1
	rename DATE PERIOD_NAME
	}
	
	* Countries with missing variable
	if inlist("`ii'", "CY", "EE", "HU", "LV", "LU", "MT", "SK") {
	getTimeSeries ECB ICP.M.`ii'.N.000000.4.INX $year_start "" 0 1
	
	* Transform monthly to quarterly frequency
	gen yq = qofd(dofm(monthly(DATE,"YM"))) 
	format yq %tq
	collapse (mean) VALUE = VALUE, by(yq TSNAME)
	gen yq2 = string(yq, "%tq")
	gen yq3 = upper(yq2)
	gen year = regexs(0) if(regexm(yq3, "[0-9][0-9][0-9][0-9]"))
	gen quarter = regexs(0) if(regexm(yq3, "Q[0-9]"))
	gen PERIOD_NAME = year + "-" + quarter 
	drop yq yq2 yq3 year quarter
	}
		
	drop TSNAME
	rename VALUE D41_`ii'
	label variable D41_`ii' "D41 for hh-sector, credit"
	sort PERIOD_NAME
	compress
	save "$dataoutputPath/D41_`ii'.dta", replace

}
	*/
	
foreach ii of global ctrylist {
	
	if !inlist("`ii'", "CY", "EE", "HU", "LV", "LU", "MT", "SK") {
	
	local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_QSA_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN 		('QSA.Q.N.`ii'.W0.S1M.S1.N.D.D41._Z._Z._Z.XDC._T.S.V.N._T') AND PERIOD_NAME>='2007'"
	odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear

	rename OBS_VALUE D41_`ii'

	sort PERIOD_NAME
	compress

	}
	
	* Countries with missing variable
	if inlist("`ii'", "CY", "EE", "HU", "LV", "LU", "MT", "SK") {
	
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
	
	rename OBS_VALUE D41_`ii'

	sort PERIOD_NAME
	compress
	/*
	* Transform monthly to quarterly frequency
	gen yq = qofd(dofm(monthly(DATE,"YM"))) 
	format yq %tq
	collapse (mean) VALUE = VALUE, by(yq TSNAME)
	gen yq2 = string(yq, "%tq")
	gen yq3 = upper(yq2)
	gen year = regexs(0) if(regexm(yq3, "[0-9][0-9][0-9][0-9]"))
	gen quarter = regexs(0) if(regexm(yq3, "Q[0-9]"))
	gen PERIOD_NAME = year + "-" + quarter 
	drop yq yq2 yq3 year quarter*/
	}
		

	label variable D41_`ii' "D41 for hh-sector, credit"

	save "$dataoutputPath/D41_`ii'.dta", replace

}
	
* Rename variables, reshape into long and save as single dta file
local country1 `: word 1 of $ctrylist'

use "$dataoutputPath/D41_`country1'.dta", clear
rm "$dataoutputPath/D41_`country1'.dta"

local n_countries `: word count $ctrylist'
forval i = 2/`n_countries' {

	local country `: word `i' of $ctrylist'
	
	merge 1:1 PERIOD_NAME using "$dataoutputPath/D41_`country'.dta"
	drop _merge
	rm "$dataoutputPath/D41_`country'.dta"
	
}

save "$dataoutputPath/D41_ALL.dta", replace
