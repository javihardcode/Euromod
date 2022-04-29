
* Read in from Excel files either short or long-term OECD replacement rates
local RR_OECD "LongTerm"
if "$unempLTreplRatiosIndex" == "0" {
	local RR_OECD "Initial"
}

local OECD_years "2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018"			// Note: have data only until 2015; assume more recent years constant
local n_years : word count `OECD_years'
local row_list = "44 46 46 46 47 47 48 48 48 48 48 48"

forval i = 1/`n_years' {

	local year `: word `i' of `OECD_years''
	local row `: word `i' of `row_list''

	import excel using "$datainputPath/NRR_`RR_OECD'_EN.xlsx", sheet(`year') cellrange(A9:AL`row') clear
	
	drop T
	
	* Replace country names with two letters
	rename A var1
	do "$programPath1/inc_update_RR_OECD_CountryIDs.do"
	rename var1 ctryid
	drop if inlist(ctryid, "OECD", "AEU", "EU")
	
	* Keep only countries of selected wave
	gen idx = 0
	foreach k of global ctrylist {
	replace idx = 1 if ctryid == "`k'"
	}
	drop if idx != 1
	drop idx
		
	ds ctryid, not
	global col_list = "`r(varlist)'" 
	
	* Take means of qualifying and not qualifying families
	local n_v_list `: word count $col_list'
	local n_v_list_half = `n_v_list'/2
	
	forval i = 1/`n_v_list_half' {		

		local var1 = word("$col_list",`i')
		destring `var1', replace 
	
		local ii `i' + `n_v_list_half'
		local var2 = word("$col_list",`ii')
		destring `var2', replace 
		
		local var_name `: word `i' of $col_list'
		
		if inlist("`var_name'", "B","C","D", "H","I","J", "N","O","P"){
		egen `var_name'_0 = rowmean(`var1' `var2')
		}
		
		if !inlist("`var_name'", "B","C","D", "H","I","J", "N","O","P"){
		egen `var_name'_2 = rowmean(`var1' `var2')
		}
		
		drop `var1' `var2'
		
	}
	
	* Reshape variables according to country and number of children
	reshape long B_ C_ D_  E_ F_ G_ H_ I_ J_  K_ L_ M_ N_ O_ P_  Q_ R_ S_ , i(ctryid) j(children)
	
	* Take care of reshape output and change names
	ds ctryid children, not
	global v_list = "`r(varlist)'" 
	
	local n_v_list `: word count $v_list'
	local n_v_list_half = `n_v_list'/2
	
	forval i = 1/`n_v_list_half' {		

		local var1 = word("$v_list",`i')
	
		local ii `i' + `n_v_list_half'
		local var2 = word("$v_list",`ii')

		gen var_`i' = max(`var1',`var2')
		drop `var1' `var2'
	}
		
	* Rename variables to correspond to HFCS family variables
	rename var_1 famstat_s_67 
	rename var_2 famstat_1_67        
	rename var_3 famstat_2_67
	rename var_4 famstat_s_100
	rename var_5 famstat_1_100
	rename var_6 famstat_2_100
	rename var_7 famstat_s_150
	rename var_8 famstat_1_150
	rename var_9 famstat_2_150
	
	* Generate one variable for married families
	gen famstat_m_67 = (famstat_1_67 + famstat_2_67)/2
	drop famstat_1_67  famstat_2_67
	gen famstat_m_100 = (famstat_1_100 + famstat_2_100)/2
	drop famstat_1_100  famstat_2_100
	gen famstat_m_150 = (famstat_1_150 + famstat_2_150)/2
	drop famstat_1_150 famstat_2_150
	
	* Rename some variables
	replace children=1 if children==2
	egen temp = concat(ctryid children)
	encode temp, gen(newid)
	drop temp

	reshape long famstat_m_ famstat_s_, i(newid) j(inc)
	sort ctryid children
	rename famstat_s_ famstat_1 
	rename famstat_m_ famstat_0

	egen temp = concat(newid inc)
	encode temp, gen(newid2)
	reshape long famstat_, i(newid2) j(single)
	rename famstat_ replrate
	drop newid2 newid temp

	aorder
	sort ctryid children single inc
	
	gen date = `year'
	
	save "$dataoutputPath/RR_`RR_OECD'_`year'.dta", replace
		
	
}
	

* Consolidate years into one file
local year1 `: word 1 of `OECD_years''
use "$dataoutputPath/RR_`RR_OECD'_`year1'.dta", clear
rm "$dataoutputPath/RR_`RR_OECD'_`year1'.dta"

forval i = 2/`n_years' {
	local year `: word `i' of `OECD_years''
	append using "$dataoutputPath/RR_`RR_OECD'_`year'.dta"
	rm "$dataoutputPath/RR_`RR_OECD'_`year'.dta"
	}

label variable children "0: no children; 1: 2 children"
label variable inc "3 income categories: 67/100/150 of awg. wage"
label variable replrate "net replacement rate of last wage"
label variable single "1: single person / loan parent; 0: married couple "

* Rename ctryid
rename ctryid sa0100

save "$dataoutputPath/RR_`RR_OECD'.dta", replace

	