
** Compute implied savings

* Load consumption data
use "$dataoutputPath/di3001_deltaw1w2sim.dta", clear

* Merge income data
merge 1:1 sa0100 sa0010 id using "$dataoutputPath/di2000_deltaw1w2sim.dta"
keep if _merge == 3
drop _merge

* Generate implied savings
gen impl_savings = di2000_deltaw1w2sim - di3001_deltaw1w2sim

* Save
save "$dataoutputPath/impl_savings.dta", replace


** Add to (simulated) deposits

* Load simulated wave 2 data
use "$resultPath/D_compl_MicroSim_$print_ts.dta", clear

merge 1:1 sa0100 sa0010 id using "$dataoutputPath/impl_savings.dta"
keep if _merge == 3
drop _merge

* Add to implied savings to financial assets
gen da2100_incl_impl_savings = da2100 + impl_savings

drop da2100

rename da2100_incl_impl_savings da2100


** Save back into simulated wave 2

save "$resultPath/D_compl_MicroSim_$print_ts.dta", replace
