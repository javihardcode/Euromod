
*** This script illustrates how to impute net income into the HFCS using the 
*** Euromod output files generated by Javi (April 2022)
*** It consists of a single do file but indicates how to separate the two main
*** steps into two separate do files


** Housekeeping

clear all
macro drop _all
set more off
set mem 3000m


** FOLLOW UP

* In some (country/year) Euromod files, the income is not incremented by 10
* For households with multiple members, I need to take the sum of earned and disposable income
* -> Do not get all decimal values, even after rounding.
* --> Cannot match some HFCS observations


********************************************************************************
** DOFILE 1: Generate files for merging (import and edit txt files)

** 0. Open Ends
*  - Find way to put household full names into global and loop over it when combining _ALL.dta files. 
*  -> saves manual adjustment of this combination step

** 1. For each household type, consolidate all year/country txt files into single dta file

*global EuromodPath_in  = "/Users/main/Library/CloudStorage/OneDrive-IstitutoUniversitarioEuropeo/data/Euromod/Simulations_Javi_April02"
*global EuromodPath_out = "/Users/main/Library/CloudStorage/OneDrive-IstitutoUniversitarioEuropeo/data/Euromod/Simulations_Javi_April02/dta_all"
 
global EuromodPath_in  = "D:/microsim/1_0_3/data/euromod/Household_data1"
global EuromodPath_out = "$EuromodPath_in/dta_all"

local counter = 0
foreach hh in "Output Household Type 1" "Output Household Type 2" "Output Household Type 3" {
	local counter = `counter'+1
	
	if `counter' == 1 {
		local hh_name = "hh1"
		capture mkdir "$EuromodPath_out"
		capture mkdir "$EuromodPath_out/`hh_name'"
	}
	else if `counter' == 2 {
		local hh_name = "hh2"
		capture mkdir "$EuromodPath_out/`hh_name'"
	}
	else {
		local hh_name = "hh3"
		capture mkdir "$EuromodPath_out/`hh_name'"
	}
	
	local files : dir "$EuromodPath_in/`hh'" files "*.txt"
	
	foreach file in `files' {
	
		if regexm("`file'", "EUROMOD_Log") {
			continue
		}
	
		import delimited using "$EuromodPath_in/`hh'/`file'", clear
		
		keep ils_origy ils_dispy idhh
		
		if `counter' == 1 {
			gen famtype = "hh1"
		}
		else if `counter' == 2 {
			collapse (sum) ils_origy=ils_origy ils_dispy=ils_dispy, by(idhh)
			gen famtype = "hh2"
		}
		else {
			collapse (sum) ils_origy=ils_origy ils_dispy=ils_dispy, by(idhh)
			gen famtype = "hh3"
		}

		gen inc_gross = round(ils_origy, 10)
		gen inc_net = round(ils_dispy, 10)
	
		keep inc_gross inc_net famtype
	
		local c = substr("`file'",1,2) // di "`c'"
		local y = substr("`file'",4,4) // di "`y'"
	
		gen sa0100 = upper("`c'")
		gen year = "`y'"
		
		local name = substr("`file'",1,11) // di "`name'"
		save "$EuromodPath_out/`hh_name'/`name'", replace
	
	}
	
	local files2 : dir "$EuromodPath_out/`hh_name'" files "*.dta"
	local counter2 = 0

	foreach file2 in `files2' {
	
		local counter2 = `counter2'+1
	
		if `counter2' == 1 {
			local name2 = substr("`file2'",1,15)
			use "$EuromodPath_out/`hh_name'/`name2'", clear
			rm "$EuromodPath_out/`hh_name'/`name2'"
		}
	
		else {
			append using "$EuromodPath_out/`hh_name'/`file2'"
			rm "$EuromodPath_out/`hh_name'/`file2'"
		}
		
	}

	sort sa0100 year inc_gross
	save "$EuromodPath_out/`hh_name'/`hh_name'_ALL.dta", replace

}
*

** 2. Consolidate all year/country household specific dta files into single dta file

local counter = 0
foreach hh in "Output Household Type 1" "Output Household Type 2" "Output Household Type 3" {

	local counter = `counter'+1
	
	if `counter' == 1 {
		local hh_name = "hh1"
		use "$EuromodPath_out/`hh_name'/`hh_name'_ALL.dta", clear
		rm "$EuromodPath_out/`hh_name'/`hh_name'_ALL.dta"
	}
	else if `counter' == 2 {
		local hh_name = "hh2"
		append using "$EuromodPath_out/`hh_name'/`hh_name'_ALL.dta"
		rm "$EuromodPath_out/`hh_name'/`hh_name'_ALL.dta"
	}
	else {
		local hh_name = "hh3"
		append using "$EuromodPath_out/`hh_name'/`hh_name'_ALL.dta"
		rm "$EuromodPath_out/`hh_name'/`hh_name'_ALL.dta"
	}

}
*

save "$EuromodPath_out/net_income_ALL_HHS.dta", replace



********************************************************************************
** DOFILE 2: Illustrate how to merge Euromod net incomes with HFCS files

* Use D1 as example
*use "/Users/main/Library/CloudStorage/OneDrive-IstitutoUniversitarioEuropeo/data/HFCS_update/!HFCS_data/wave2/D1.dta", clear
use  "D:/data/hfcs/wave3/d1.dta",clear 
rename *, lower
* Use employee income as gross income, MONTHLY & rounded to nearest decimal as in Euromod gross income 
gen inc_gross = round(di1100/12, 10)
drop if inc_gross == .

* Use dhhtype to assign household types
gen     famtype = "hh3"
replace famtype = "hh1" if dhhtype == 51 | dhhtype == 52
replace famtype = "hh2" if dhhtype == 9

* Pick example year (can make this country specific using the ref_periods.do file)
gen year = "2017"

* Merge with the Euromod dta file
merge m:m year sa0100 famtype inc_gross using "$EuromodPath_out/net_income_ALL_HHS.dta"
keep if _merge == 3

gen inc_net_annual = inc_net * 12


* Compute di2000_net agregating income components: 

egen di2000_net = rowtotal(inc_net_annual di1200 di1300 di1400 di1500 di1600 di1700 di1800)




* Check how the relship gross and net income looks like: Scatter gross and net income + 45 degree line

foreach c in "ES" "DE"{
foreach t in "hh1" "hh2" "hh3"{
preserve 
keep if sa0100 == "`c'" & famtype == "`t'"
tw (scatter inc_net inc_gross   if inrange(inc_gross,0,3500), msymbol(o) msize(small))|| ///
   (line    inc_gross inc_gross if inrange(inc_gross,0,3500)), title("di1100 `c' `t'") name(`t'_`c',replace) legend(order(1 "" 2 "45-degrees")) ytitle("Net Income") xtitle("Gross Income")
restore
}
}


* Check relship comparing di2000 
foreach c in "DE" "ES"{
foreach t in "hh1" "hh2" "hh3"{
preserve 
keep if sa0100 == "`c'" & famtype == "`t'"
tw (scatter di2000_net di2000   if inrange(di2000,0,200000), msymbol(o) msize(small))|| ///
   (line    di2000 di2000 if inrange(di2000,0,200000)), title("di2000 `c' `t'") name(`t'_`c',replace) legend(order(1 "" 2 "45-degrees")) ytitle("Net Income") xtitle("Gross Income")
restore
}
}



* Check relship comparing di1100 with di








