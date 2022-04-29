
*** 1) Download and adjust sectoral employment data
/*
foreach ii of global ctrylist {
		
	getTimeSeries ECB ENA.Q.N.`ii'.W2.S1.S1._Z.EMP._Z.A+BTE+C+F+GTI+J+K+L+M_N+OTQ+RTU+_T._Z.PS._Z.N $year_start "" 0 1

	split TSNAME, p(".EMP.")
	gen var1 = regexs(0) if(regexm(TSNAME2, "(A)|(BTE)|(C)|(F)|(GTI)|(J)|(K)|(L)")) // Need to split because regexm only accepts few inputs in ()
	replace var1 = regexs(0) if(regexm(TSNAME2, "(M_N)|(OTQ)|(RTU)|(_T)"))
	drop TSNAME TSNAME1 TSNAME2

	rename VALUE EMPL_
	reshape wide EMPL_, i(DATE) j(var1) string
	*ren Employment* *
	
	* Special cases: BE, PT, ES
	* BE: C (manufacturing) is missing -> use only BTE and see end of this file for further adjustments

	* ES: HFCS does not follow official NACE categories but only subset
	* w1: Merged categories: DE, HJ, L-N
	
	* PT: HFCS does not follow official NACE categories but only subset in 
	* w1: Merged categories: B-E, L-N, R-U
	* w2: Merged categories: B-E, L-N, R-U
	
	gen ctryid = "`ii'"
	
	if ctryid != "BE" {
	* Construct derived variable: BDE = BTE - C = B+C+D+E - C = B+D+E
	gen EMPL_BDE = EMPL_BTE - EMPL_C
	drop EMPL_BTE
	}	
	
	else if ctryid == "BE" {
	gen EMPL_C = .
	gen EMPL_BDE = EMPL_BTE
	drop EMPL_BTE
	}
	
	rename DATE date
	sort date
	compress
	save "$dataoutputPath/Employment_`ii'.dta", replace
	
}

*/
foreach ii of global ctrylist {

global sec_vars "A BTE C F GTI J K L M_N OTQ RTU _T"

foreach var of global sec_vars{
local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_ENA_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('ENA.Q.N.`ii'.W2.S1.S1._Z.EMP._Z.`var'._Z.PS._Z.N') AND PERIOD_NAME>='2007'"
odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear

rename OBS_VALUE EMPL_`var'
*label variable USOE_D_`ii' "Unquoted shares/otehr equity HH-sector, debit (F51M)"
sort PERIOD_NAME
compress
save "$dataoutputPath/Employment_`var'_`ii'.dta", replace
}


local sector `: word 1 of $sec_vars'
use "$dataoutputPath/Employment_`sector'_`ii'.dta", clear
rm "$dataoutputPath/Employment_`sector'_`ii'.dta"

local n_sectors `: word count $sec_vars'
forval i = 2/`n_sectors' {

	local sector `: word `i' of $sec_vars'

	merge 1:1 PERIOD_NAME using "$dataoutputPath/Employment_`sector'_`ii'.dta"
	drop _merge
	rm "$dataoutputPath/Employment_`sector'_`ii'.dta"
}

save "$dataoutputPath/Employment_`ii'.dta", replace

}

ds EMPL_*
global var_list = "`r(varlist)'"

* Append country files into one (Changes in new version: create country ID)
local ctry1 `: word 1 of $ctrylist'
use "$dataoutputPath/Employment_`ctry1'.dta", clear
gen ctryid = "`ctry1'"
*rm "$dataoutputPath/Employment_`ctry1'.dta"

local n_countries `: word count $ctrylist'
forval i = 2/`n_countries' {

	local country `: word `i' of $ctrylist'

	append using "$dataoutputPath/Employment_`country'.dta"
	replace ctryid = "`country'" if ctryid == ""
	*rm "$dataoutputPath/Employment_`country'.dta"
}

compress

*sort ctryid date
sort ctryid PERIOD_NAME
gen year = substr(PERIOD_NAME,1,4)
destring year, replace
drop if year < 2007 
drop year OBS_DATE PERIOD_FIRST_DATE PERIOD_LAST_DATE SERIES_KEY FORMATTED_OBS_VALUE

*save "$dataoutputPath/Employees_Sect_ALL_N.dta", replace


*** 2) Set values of start and target quarters.

*gen ref_date = quarterly(date, "YQ")
gen ref_date = quarterly(PERIOD_NAME, "YQ")

local sec_list = "$var_list"

forval i = 1/$n_countries {

	local ctry `: word `i' of $ctrylist'

	foreach ij of local sec_list {
	
	preserve
	
	gen temp1 = quarterly(start_q_u_`ctry', "YQ")
	gen temp2 = quarterly(end_q_u_`ctry', "YQ")
	
	keep if ctryid == "`ctry'" & (ref_date == temp1 | ref_date == temp2)
	
	sca G_`ctry'_`ij' = `ij'[2]/`ij'[1]
	sca W_`ctry'_`ij' = `ij'[2]/EMPL__T[2]

	drop temp1 temp2
	
	restore
		
	}

}

/*
gen ref_date = quarterly(PERIOD_NAME, "YQ")

local sec_list = "$var_list"

forval i = 1/$n_countries {

	local ctry `: word `i' of $ctrylist'

	foreach ij of local sec_list {
	
	preserve
	
	keep if ctryid == "`ctry'"
	
	*gen temp1 = quarterly(start_q_u_`ctry', "YQ")
	*gen temp2 = quarterly(end_q_u_`ctry', "YQ")
	
	egen temp1 = min(ref_date)
	egen temp2 = max(ref_date)
	
	
	/*keep if ctryid == "`ctry'" & (ref_date == temp1 | ref_date == temp2)*/
	keep if (ref_date == temp1 | ref_date == temp2)
	
	sca G_`ctry'_`ij' = `ij'[2]/`ij'[1]
	sca W_`ctry'_`ij' = `ij'[2]/EMPL__T[2]

	*drop temp1 temp2
	
	restore
		
	}

}
*/
* Make scalars into variables

keep ctryid
duplicates drop ctryid, force

preserve

clear

set obs 1

local sec_list = "$var_list"

forval i = 1/$n_countries {

	local ctry `: word `i' of $ctrylist'
	
	foreach ij of local sec_list {
	
	sca ushock_`ctry'_`ij' = G_`ctry'_`ij' - G_`ctry'_EMPL__T

	gen ushock`ctry'_`ij' = .
	replace ushock`ctry'_`ij' = ushock_`ctry'_`ij' 

	}
}

*

save "$dataoutputPath/shocks_secs.dta", replace

restore

merge 1:1 _n using "$dataoutputPath/shocks_secs.dta"
rm "$dataoutputPath/shocks_secs.dta"
drop _merge
reshape long ushock, i(ctryid) j(sect, string)

drop ctryid
split sect, p("_EMPL_")
drop sect
rename sect1 sa0100
rename sect2 sect

* drop if sect == "EMPL__T"
drop if sect == "_T"

* replace Gtransf_EMPL_C = Gtransf_EMPL_BDE if ctryid=="BE"
replace ushock = ushock[_n-1] if (sa0100 == "BE" & ushock == .)

drop if ushock == .
sort sa0100 sect
order sa0100 sect ushock

save "$dataoutputPath/Ushock_sect.dta", replace

