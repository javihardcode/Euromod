

*
* EUROMOD data preparation employee Income 
*

local counter = 0
foreach hh in "Output Household Type 1" "Output Household Type 2" "Output Household Type 3" {
	local counter = `counter'+1
	
	if `counter' == 1 {
		local hh_name = "hh1"
		capture mkdir "$EuromodPath_out1"
		capture mkdir "$EuromodPath_out1/`hh_name'"
	}
	else if `counter' == 2 {
		local hh_name = "hh2"
		capture mkdir "$EuromodPath_out1/`hh_name'"
	}
	else {
		local hh_name = "hh3"
		capture mkdir "$EuromodPath_out1/`hh_name'"
	}
	
	local files : dir "$EuromodPath_in1/`hh'" files "*.txt"
	
	foreach file in `files' {
	
		if regexm("`file'", "EUROMOD_Log") {
			continue
		}
	
		import delimited using "$EuromodPath_in1/`hh'/`file'", clear
		
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
		save "$EuromodPath_out1/`hh_name'/`name'", replace
	
	}
	
	local files2 : dir "$EuromodPath_out1/`hh_name'" files "*.dta"
	local counter2 = 0

	foreach file2 in `files2' {
	
		local counter2 = `counter2'+1
	
		if `counter2' == 1 {
			local name2 = substr("`file2'",1,15)
			use "$EuromodPath_out1/`hh_name'/`name2'", clear
			rm "$EuromodPath_out1/`hh_name'/`name2'"
		}
	
		else {
			append using "$EuromodPath_out1/`hh_name'/`file2'"
			rm "$EuromodPath_out1/`hh_name'/`file2'"
		}
		
	}

	
	qui replace inc_gross = . if inc_gross <  10 
	qui replace inc_net   = . if inc_gross == . 
	duplicates drop 
	
	sort sa0100 year inc_gross
	save "$EuromodPath_out1/`hh_name'/`hh_name'_ALL.dta", replace

}
*

** 2. Consolidate all year/country household specific dta files into single dta file

local counter = 0
foreach hh in "Output Household Type 1" "Output Household Type 2" "Output Household Type 3" {

	local counter = `counter'+1
	
	if `counter' == 1 {
		local hh_name = "hh1"
		use "$EuromodPath_out1/`hh_name'/`hh_name'_ALL.dta", clear
		rm "$EuromodPath_out1/`hh_name'/`hh_name'_ALL.dta"
	}
	else if `counter' == 2 {
		local hh_name = "hh2"
		append using "$EuromodPath_out1/`hh_name'/`hh_name'_ALL.dta"
		rm "$EuromodPath_out1/`hh_name'/`hh_name'_ALL.dta"
	}
	else {
		local hh_name = "hh3"
		append using "$EuromodPath_out1/`hh_name'/`hh_name'_ALL.dta"
		rm "$EuromodPath_out1/`hh_name'/`hh_name'_ALL.dta"
	}

}
*

save "$EuromodPath_out1/net_income_ALL_HHS.dta", replace

