*
* Diagnostics on New debt services: 
* 1. Open Wave 2 and Simulated Wave 3
* 2. Merge with Wave 3 


* Set Path for results: 
*global diagnosticsPath "P:\ECB business areas\DGR\Databases and Programme files\DGR\Javier Ramos\microsim\1_0_2\diagnostics"
global diagnosticsPath "D:\microsim\results\diagnostics wave 3\Diagnostics Debt Services"                                  // use this path for speed at home
graph drop _all 
global countries "AT BE DE ES IT FR NL"




* 1. Open Wave 2 and Simulated Wave 3: 
use "$hfcsinputPath/D_compl_MicroSim_$print_ts.dta" , clear
keep sa0100 sa0010 im0100 hw0010 dl2000 dl2000_simul LTV doltvratio ihs_new_issued_mort
keep if im0100 == 1 & inlist(sa0100,"AT","BE","DE","ES","IT","FR","NL")                             // 
qui gen wave = 2
local variables = "dl2000 doltvratio"
foreach v of local variables{
qui rename `v' `v'_w2
qui replace `v'_w2 = . if `v'_w2 == 0 
}
replace dl2000_simul = . if dl2000_simul == 0 
save "$hfcsinputPath/diagnostics_w2_simul_w3_ds.dta", replace


* 2. Open wave 3 
use "D:\data\hfcs\wave3\DP_extended.dta", clear
keep sa0100 sa0010 im0100 hw0010 dl2000 doltvratio
sort sa0100 
decode sa0100, gen(sa0100_str)
drop sa0100
rename sa0100_str sa0100
keep if im0100 == 1 & inlist(sa0100,"AT","BE","DE","ES","IT","FR","NL")                             // 
local variables = "dl2000 doltvratio"
foreach v of local variables{
qui rename `v' `v'_w3
qui replace `v'_w3 = . if `v'_w3 == 0 
}

append using "$hfcsinputPath/diagnostics_w2_simul_w3_ds.dta"
rm           "$hfcsinputPath/diagnostics_w2_simul_w3_ds.dta"





********************************************************************************
* Figure 1) Compare Aggregate dl2000 with Aggregate dl2000_simul
********************************************************************************                                                                           
gen Agg_dl2000_w2    = . 
gen Agg_dl2000_w3    = . 
gen Agg_dl2000_simul = . 
foreach ii of global ctrylist{
qui sum         dl2000_w2 [aw=hw0010]     if sa0100 == "`ii'",d
qui replace Agg_dl2000_w2 = r(sum)        if sa0100 == "`ii'"                             // no divide by 5, just implicate 1 

qui         sum dl2000_w3 [aw=hw0010]     if sa0100 == "`ii'", d 
qui replace Agg_dl2000_w3 = r(sum)        if sa0100 == "`ii'"

qui sum         dl2000_simul [aw=hw0010]  if sa0100 == "`ii'",d
qui replace Agg_dl2000_simul = r(sum)     if sa0100 == "`ii'"
}

gr bar Agg_dl2000_w2 Agg_dl2000_w3 Agg_dl2000_simul, over(sa0100) legend(row(1) order(1 "dl2000 w2" 2 "dl2000 w3" 3 "dl2000 simul w3")) title("Aggregate Debt Services")
gr export "D:\microsim\results\diagnostics wave 3\Diagnostics Debt Services\Agg_dl2000_VS_Agg_dl2000_simul.png", replace



********************************************************************************
* Figure 2) Distribution of debt services
********************************************************************************
preserve 
foreach ii of global countries{
tw (kdensity dl2000_w2 [aw=hw0010] if sa0100 == "`ii'" & inrange(dl2000_w2,50,3000)) || (kdensity dl2000_w3 [aw=hw0010] if sa0100 == "`ii'" & inrange(dl2000_w3,50,3000)) || (kdensity dl2000_simul [aw=hw0010] if sa0100 == "`ii'" & inrange(dl2000_simul,50,3000)) , legend(row(1) order(1 "dl2000 w2" 2 "dl2000 w3" 3 "dl2000 simul w3")) title("`ii' Distribution of Debt Services") name(`ii'_distribution_debt_serv, replace) xtitle("Debt Services in EUR") note("Range: 50-3000 EUR. Aproxx 80% of total sample")
gr export "D:\microsim\results\diagnostics wave 3\Diagnostics Debt Services\Distribution_debt_services_`ii'.png", replace

}
restore







********************************************************************************
* 3. LOAN-TO-VALUE RATIO DISTRIBUTION 
********************************************************************************
* 1. Only for those whose mortgage was contracted close in time 
* 2. A lot of cross-country variation and patterns. 
* 3. Need to think about how to assign people their correct LTV distribution. 



foreach c of global countries{
tw (kdensity doltvratio_w2 [aw=hw0010] if inrange(doltvratio_w2,0,1) & ihs_new_issued_mort >0 & sa0100 == "`c'") || (kdensity LTV [aw=hw0010] if inrange(LTV,0,1) & sa0100 == "`c'"), legend(row(1) order(1 "Wave 2 data" 2 "Simul Wave 3")) title("`c' Loan-to-Value") name(`c'_LTV, replace)
gr export "D:\microsim\results\diagnostics wave 3\Diagnostics Debt Services\LTV_distribution_`c'.png", replace
}




















