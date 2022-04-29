*** Download the macro data for the asset update and impute missing values

global macro_vars "B2B3 BondYields CurrencyDeposits D41 D75 InsuranceTechRes HICP IntRates RPP Stock USOE WagesPC"

* 1) Download data
foreach ii of global macro_vars {
	do "$programPathSDW/SDW_`ii'"
}

* Merge into one file
local var1 `: word 1 of $macro_vars'
use "$dataoutputPath/`var1'_ALL.dta", clear
*rm "$dataoutputPath/`var1'_ALL.dta"

local n_vars `: word count $macro_vars'
forval i = 2/`n_vars' {
	local var `: word `i' of $macro_vars'
	merge 1:1 PERIOD_NAME using "$dataoutputPath/`var'_ALL.dta"
	drop _merge
	*rm "$dataoutputPath/`var'_ALL.dta"
}

compress
sort PERIOD_NAME
save "$dataoutputPath/raw_asset_macro_data_ALL.dta", replace

*NEW ------- DROP OBSERVATIONS BEFORE 2007

gen year = substr(PERIOD_NAME,1,4)
destring year, replace
drop if year < 2007 
drop year OBS_DATE PERIOD_FIRST_DATE PERIOD_LAST_DATE SERIES_KEY FORMATTED_OBS_VALUE

* 2) Impute missing values

* Compute missing obs
ds PERIOD_NAME, not
global varlist_all = "`r(varlist)'"
egen var_miss_before = rowmiss($varlist_all)
egen var_miss_before_av = mean(var_miss_before)

* a) Inter- and extrapolate missing quarters (begin, in-between, end) 
* Except for variables with lots of missings: IntR_M_MT IntR_L_GR IntRH_all_LV IntR_L_MT

generate q = _n

if "$start_wave" == "1" {
ds PERIOD_NAME IntR_M_MT IntR_L_GR IntR_L_MT var_miss_before var_miss_before_av, not
}

if "$start_wave" == "2" {
ds PERIOD_NAME IntR_M_MT IntR_L_GR IntRH_all_LV IntR_L_MT var_miss_before var_miss_before_av, not
}

global varlist_impute = "`r(varlist)'"

foreach ii of global varlist_impute {
	ipolate `ii' q, gen(`ii'_imputed) epolate
	drop `ii'
	rename `ii'_imputed `ii'
}

* b) Take care of special cases

* 1) WAVE 1 countries

* Interest rates for Malta: IntR_L_MT and IntR_M_MT
* IntR_M_MT = 75* of IntRH_all_MT
replace IntR_L_MT = 0.75*IntRH_all_MT
* IntR_L_MT = average of IntRC_all_MT and IntR_S_MT
egen IntR_M_MT_temp = rowmean(IntRC_all_MT IntR_S_MT)
replace IntR_M_MT = IntR_M_MT_temp
drop IntR_M_MT_temp

* Interest rate for Greece: IntR_L_GR
* gen  = average of IntR_S_GR and IntR_M_GR
egen IntR_L_GR_temp = rowmean(IntR_S_GR IntR_M_GR)
replace IntR_L_GR = IntR_L_GR_temp
drop IntR_L_GR_temp

* 2) WAVE 2 countries

if "$start_wave" == "2" {
* Interest rate for Latvia: IntRH_all_LV
* IntRH_all_LV = 75* of IntR_L_LV
replace IntRH_all_LV = 0.75*IntR_L_LV
}

* Compute missing obs
ds PERIOD_NAME q var_miss_before var_miss_before_av, not
global varlist_all = "`r(varlist)'"
egen var_miss_after = rowmiss($varlist_all)
egen var_miss_after_av = mean(var_miss_after)

* Print some summary info
levelsof PERIOD_NAME, local(periods)
local all_quarters `: word count `periods''
global n_quarter `: word 1 of `periods''
global N_quarter `: word `all_quarters' of `periods''
di "Between $n_quarter to $N_quarter, the average number of variables missing per quarter is " as result var_miss_before_av[1]
di "After imputation, the average number of variables missing per quarter is now " as result var_miss_after_av[1]

drop q var_miss_before var_miss_before_av var_miss_after var_miss_after_av

compress
sort PERIOD_NAME
save "$dataoutputPath/asset_macro_data_ALL.dta", replace
*rm "$dataoutputPath/raw_asset_macro_data_ALL.dta"
clear
