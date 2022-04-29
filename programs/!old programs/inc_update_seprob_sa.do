
*** 1) Download and adjust sectoral employment data

foreach ii of global ctrylist {
	
	if inlist("`ii'", "FR","GR","MT","PT","SK","PL") {
	getTimeSeries ECB ENA.Q.S.`ii'.W2.S1.S1._Z.EMP._Z.A+BTE+C+F+GTI+J+K+L+M_N+OTQ+RTU+_T._Z.PS._Z.N $year_start "" 0 1
	}
	
	else {
	getTimeSeries ECB ENA.Q.Y.`ii'.W2.S1.S1._Z.EMP._Z.A+BTE+C+F+GTI+J+K+L+M_N+OTQ+RTU+_T._Z.PS._Z.N $year_start "" 0 1
	}
	
	split TSNAME, p(".EMP.")
	gen var1 = regexs(0) if(regexm(TSNAME2, "(A)|(BTE)|(C)|(F)|(GTI)|(J)|(K)|(L)")) // Need to split because regexm only accepts few inputs in ()
	replace var1 = regexs(0) if(regexm(TSNAME2, "(M_N)|(OTQ)|(RTU)|(_T)"))
	drop TSNAME TSNAME1 TSNAME2

	rename VALUE EMPL_
	reshape wide EMPL_, i(DATE) j(var1) string
	
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

ds EMPL_*
global var_list = "`r(varlist)'"

* Append country files into one
local ctry1 `: word 1 of $ctrylist'
use "$dataoutputPath/Employment_`ctry1'.dta", clear
rm "$dataoutputPath/Employment_`ctry1'.dta"

local n_countries `: word count $ctrylist'
forval i = 2/`n_countries' {

	local country `: word `i' of $ctrylist'

	append using "$dataoutputPath/Employment_`country'.dta"
	rm "$dataoutputPath/Employment_`country'.dta"
}

compress
sort ctryid date
save "$dataoutputPath/Employees_Sect_ALL_N.dta", replace


*** 2) Set values of start and target quarters.

gen ref_date = quarterly(date, "YQ")

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

