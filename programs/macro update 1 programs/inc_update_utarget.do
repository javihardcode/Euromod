
*** 1) Download and adjust unemployment data
/*
* Download monthly unemployment rates of: males and females (RTT000); males (RTM000); females (RTF000) 
foreach ii of global ctrylist {
			
	getTimeSeries ECB STS.M.`ii'.S.UNEH.RTF000+RTM000+RTT000.4.000 $year_start "" 0 1
	
	rename VALUE U
	gen var1 = regexs(0) if(regexm(TSNAME, "(RTF)|(RTM)|(RTT)"))
	gen var2 = substr(var1, 3, .)
	drop TSNAME var1
	reshape wide U, i(DATE) j(var2) string
	gen ctryid = "`ii'"
	rename DATE PERIOD_NAME
	sort PERIOD_NAME
	compress

	save "$dataoutputPath/UnemplT_`ii'.dta", replace
			
}
*/

foreach ii of global ctrylist {

global unemp_rates "T F M"

foreach var of global unemp_rates{
local qry "select  OBS_DATE, null period_first_date, null period_last_date, period_name, a.SERIES_KEY, a.OBS_VALUE, a.FORMATTED_OBS_VALUE FROM ESDB_PUB.V_LFSI_OBS_PIVOT_NICE  a WHERE  SERIES_KEY IN ('LFSI.M.`ii'.S.UNEHRT.TOTAL0.15_74.`var'') AND PERIOD_NAME>='2007'"
odbc load, exec("`qry'") dsn("SDW64") user("pub") password("pub") clear

rename OBS_VALUE U`var'

sort PERIOD_NAME
compress
save "$dataoutputPath/UnemplT_`var'_`ii'.dta", replace
}


local unemp `: word 1 of $unemp_rates'
use "$dataoutputPath/UnemplT_`unemp'_`ii'.dta", clear
rm "$dataoutputPath/UnemplT_`unemp'_`ii'.dta"

local n_unemp `: word count $unemp_rates'
forval i = 2/`n_unemp' {

	local rate `: word `i' of $unemp_rates'

	merge 1:1 PERIOD_NAME using "$dataoutputPath/UnemplT_`rate'_`ii'.dta"
	drop _merge
	rm "$dataoutputPath/UnemplT_`rate'_`ii'.dta"
}

gen ctryid = "`ii'"

save "$dataoutputPath/UnemplT_`ii'.dta", replace

}



* Rename variables, reshape into long and save as single dta file
local country1 `: word 1 of $ctrylist'

use "$dataoutputPath/UnemplT_`country1'.dta", clear
*rm "$dataoutputPath/UnemplT_`country1'.dta"

local n_countries `: word count $ctrylist'
forval i = 2/`n_countries' {

	local country `: word `i' of $ctrylist'
	
	append using "$dataoutputPath/UnemplT_`country'.dta"
	*rm "$dataoutputPath/UnemplT_`country'.dta"
	
}

* Pick only quarter-end values
gen date_test = monthly(PERIOD_NAME, "YM")
format date_test %tm

gen temp_y= yofd(dofm(date_test))
format temp_y %ty
gen temp_q= qofd(dofm(date_test))
format temp_q %tq

sort ctryid temp_q date_test
by ctryid temp_q: gen t=_n
keep if t==3

sort ctryid temp_y temp_q
drop t
by ctryid temp_y: gen t=_n
gen qind="Q1" if t==1
replace qind="Q2" if t==2
replace qind="Q3" if t==3
replace qind="Q4" if t==4

gen y_str = string(temp_y)

replace PERIOD_NAME = y_str + qind
rename PERIOD_NAME date

* Rename/Label variables 
label variable UF "Unemployment rate F, TOTAL"
label variable UM "Unemployment rate M, TOTAL"
label variable UT "Unemployment rate T, TOTAL"

* Select only relevant time series and save
keep date U* ctryid
compress
sort ctryid date
save "$dataoutputPath/UnemplT.dta", replace


*** 2) Set values of start and target quarters

gen ref_date = quarterly(date, "YQ")

local u_varlist= "T M F"

forval i = 1/$n_countries {

	local ctry `: word `i' of $ctrylist'

	foreach ij of local u_varlist {
	
	preserve
	
	gen start_date = quarterly(start_q_u_`ctry', "YQ")
	gen end_date   = quarterly(end_q_u_`ctry', "YQ")
	
	keep if ctryid == "`ctry'" & (ref_date == start_date | ref_date == end_date)
	sca ScaleF_U`ij'_`ctry' = U`ij'[2]/U`ij'[1]
	sca Scale_deltaU_`ij'_`ctry' = U`ij'[2] - U`ij'[1]
	
	drop start_date end_date
	
	restore
		
	}

}

* Transform scalars to variables in one dataset and save

keep ctryid
duplicates drop ctryid, force

gen ScaleF_UT = .
gen ScaleF_UM = .
gen ScaleF_UF = .

forval i = 1/$n_countries {

	local ctry `: word `i' of $ctrylist'
	
	replace ScaleF_UT = ScaleF_UT_`ctry' in `i'
	replace ScaleF_UM = ScaleF_UM_`ctry' in `i'
	replace ScaleF_UF = ScaleF_UF_`ctry' in `i'
    
	* Two Adjustments f
}

rename ctryid sa0100

compress
save "$dataoutputPath/UnemplT_Target.dta", replace
