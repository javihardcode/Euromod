
*              **********************************
*                SECTORIAL UNEMPLOYMENT SHOCKS
*              **********************************

* Last update: 09-03-2022 
* Javier Ramos Perez DG/R

*               LIST OF CONTENTS 








* 1. Scalars for agg. unemployment change
* 2. Scalar for sector-specific unemployment change 
* 3. Set values of start and target quarters 




*******************************************************************************
* 1.    Create scalars for change in aggregate employment
*******************************************************************************
qui use "$dataoutputPath/UnemplT.dta", clear                                    // saved on macrodata 
qui drop if date < "2007Q1"
*** 2) Set values of start and target quarters
qui gen ref_date = quarterly(date, "YQ")
local u_varlist= "T M F"
forval i = 1/$n_countries {
 local ctry `: word `i' of $ctrylist'
foreach ij of local u_varlist {
 preserve	
 qui	gen start_date = quarterly(start_q_u_`ctry', "YQ")
 qui	gen end_date   = quarterly(end_q_u_`ctry', "YQ")
	
 qui	keep if ctryid == "`ctry'" & (ref_date == start_date | ref_date == end_date)
 sca ScaleF_U`ij'_`ctry' = U`ij'[2]/U`ij'[1]
 sca Scale_deltaU_`ij'_`ctry' = U`ij'[2] - U`ij'[1]
 qui	drop start_date end_date
 restore
}
}

* Transform scalars to variables in one dataset and save
qui keep ctryid
qui duplicates drop ctryid, force

qui gen ScaleF_UT = .
qui gen ScaleF_UM = .
qui gen ScaleF_UF = .

forval i = 1/$n_countries {
 local ctry `: word `i' of $ctrylist'
 qui	replace ScaleF_UT = ScaleF_UT_`ctry' in `i'
 qui	replace ScaleF_UM = ScaleF_UM_`ctry' in `i'
 qui	replace ScaleF_UF = ScaleF_UF_`ctry' in `i'
}

qui rename ctryid sa0100
qui compress
qui save "$dataoutputPath/UnemplT_Target.dta", replace                              // saved on macrodata 



*******************************************************************************
* 2.     Create scalars for change in sector specific employment
*******************************************************************************

local ctry1 `: word 1 of $ctrylist'
qui use "$dataoutputPath/Employment_`ctry1'.dta", clear                 
qui gen ctryid = "`ctry1'"
local n_countries `: word count $ctrylist'
forval i = 2/`n_countries' {
local country `: word `i' of $ctrylist'
qui	append using "$dataoutputPath/Employment_`country'.dta"
qui	replace ctryid = "`country'" if ctryid == ""
}
compress
ds EMPL_*
global var_list = "`r(varlist)'"

*sort ctryid date
qui sort ctryid PERIOD_NAME
qui gen year = substr(PERIOD_NAME,1,4)
qui destring year, replace
qui drop if year < 2007 
qui drop year OBS_DATE PERIOD_FIRST_DATE PERIOD_LAST_DATE SERIES_KEY FORMATTED_OBS_VALUE

qui save "$dataoutputPath/Employment_sect_ALL'.dta", replace



*******************************************************************************
* 3.   Set values for target quarters 
*******************************************************************************

qui gen ref_date = quarterly(PERIOD_NAME, "YQ")
local sec_list = "$var_list"
forval i = 1/$n_countries {
 local ctry `: word `i' of $ctrylist'
foreach ij of local sec_list {	
 preserve
 qui	gen temp1 = quarterly(start_q_u_`ctry', "YQ")
 qui	gen temp2 = quarterly(end_q_u_`ctry', "YQ")
 qui	keep if ctryid == "`ctry'" & (ref_date == temp1 | ref_date == temp2)
 sca G_`ctry'_`ij' = `ij'[2]/`ij'[1]
 sca W_`ctry'_`ij' = `ij'[2]/EMPL__T[2]
 qui	drop temp1 temp2
 restore
}
}

* Convert scalars to variables 
qui keep ctryid
qui duplicates drop ctryid, force

preserve
clear
set obs 1
local sec_list = "$var_list"
forval i = 1/$n_countries {
 local ctry `: word `i' of $ctrylist'
foreach ij of local sec_list {
 sca ushock_`ctry'_`ij' = G_`ctry'_`ij' - G_`ctry'_EMPL__T
 qui	gen ushock`ctry'_`ij' = .
 qui	replace ushock`ctry'_`ij' = ushock_`ctry'_`ij' 
}
}
qui save "$dataoutputPath/shocks_secs.dta", replace
restore


qui merge 1:1 _n using "$dataoutputPath/shocks_secs.dta"
qui rm "$dataoutputPath/shocks_secs.dta"
qui drop _merge
qui reshape long ushock, i(ctryid) j(sect, string)

qui drop ctryid
qui split sect, p("_EMPL_")
qui drop sect
qui rename sect1 sa0100
qui rename sect2 sect

qui drop if sect == "_T"

qui replace ushock = ushock[_n-1] if (sa0100 == "BE" & ushock == .)

qui drop if ushock == .
qui sort sa0100 sect
qui order sa0100 sect ushock
qui save "$dataoutputPath/Ushock_sect_$UpdateTo.dta", replace                                 

