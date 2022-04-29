
* Mortgage Simulation Diagnostics: 

* 1. Targeted number vs simulated number: 
* 2. Distribution of new mortgages 

cls 
qui use "$hfcsinputPath/D_compl_MicroSim_$print_ts.dta" , clear
global diagnosticsPath "D:\microsim\results\diagnostics wave 3\Diagnostics Mortgages" 
qui graph drop _all 
global countries "AT BE DE ES IT FR NL"
qui keep if inlist(sa0100, "AT","BE","DE","ES","IT","FR","NL") & im0100 == 1

local varlist = "ihs_new_issued_mort dl1100"
foreach v of local varlist{
qui rename `v' `v'_w2
qui replace `v'_w2 = . if `v'_w2 == 0 
}

qui save "$hfcsinputPath/diagnostics_w2_simul_w3_mort.dta", replace



* 2. Open wave 3 
qui use "D:\data\hfcs\wave3\DP_extended.dta", clear
qui sort sa0100 
qui decode sa0100, gen(sa0100_str)
qui drop sa0100
qui rename sa0100_str sa0100
qui keep if im0100 == 1 & inlist(sa0100,"AT","BE","DE","ES","IT","FR","NL")                             // 

local varlist = "dl2000 doltvratio dl1100"
foreach v of local varlist{
qui rename `v' `v'_w3
qui replace `v'_w3 = . if `v'_w3 == 0 
}

qui append using "$hfcsinputPath/diagnostics_w2_simul_w3_mort.dta"
qui rm           "$hfcsinputPath/diagnostics_w2_simul_w3_mort.dta"









********************************************************************************
* 1. AGGREGATE CHANGE VS TARGETED LOANS
********************************************************************************
preserve 
qui collapse Agg_Loans, by(sa0100)
qui gen delta  = . 
qui gen nabla  = . 
qui gen target = . 
qui gen simul  = . 

foreach c of global countries{
qui replace delta  = Scale_deltaMort_`c'   if sa0100 == "`c'"                   // Aggregate Change from SDW 
qui replace nabla  = Scale_NablaMort_`c'   if sa0100 == "`c'"                   // Nabla 
qui replace target = delta + nabla         if sa0100 == "`c'"
qui replace simul  = Agg_Loans             if sa0100 == "`c'" 
}

* Delta vs Nabla vs Simulation
graph bar delta nabla simul, over(sa0100) legend( row(1) label(1 "SDW Change") label(2 "Repayment Change") label(3 "Simulated Loans")) title("Aggregate Issued Loans") name(Delta_vs_Nabla_simul, replace)
graph export "${diagnosticsPath}\Delta_vs_Nabla_vs_Simul_mort.png", replace

* Target vs Simulation
graph bar target simul, over(sa0100) legend( row(1) label(1 "SDW Target = Nabla + Delta") label(2 "Simulated Loans")) title("Aggregate Issued Loans") note("Target includes the number of new loans that need to be issued, once we account for repayments", size(vsmall)) name(target_vs_simul, replace)
qui graph export "${diagnosticsPath}\Agg_change_vs_targets.png", replace
restore 




********************************************************************************
* 2. SIMULATED LOANS VS WAVE 2 VS WAVE 3 
********************************************************************************
preserve 
qui gen ihs_loan = asinh(loan)
qui gen ihs_dl1100_w3 = asinh(dl1100_w3)
tw (kdensity ihs_new_issued_mort [aw=hw0010] if ihs_new_issued_mort>0) || (kdensity ihs_dl1100_w3 [aw=hw0010]) || (kdensity ihs_loan [aw=hw0010]), legend(row(1) order(1 "Loans W2" 2 "Loans W3" 3 "Loans Simulated W3")) xtitle("ihs value in euros") title("Newly Issued Loans") 
graph export "${diagnosticsPath}\New_loans_data_vs_simul.png", replace

foreach c of global countries{
tw (kdensity ihs_new_issued_mort [aw=hw0010] if ihs_new_issued_mort>0 & sa0100=="`c'") || (kdensity ihs_dl1100_w3 [aw=hw0010] if sa0100=="`c'") || (kdensity ihs_loan [aw=hw0010] if sa0100=="`c'"), legend(row(1) order(1 "Loans W2" 2 "Loans W3" 3 "Loans Simulated W3")) xtitle("ihs value in euros") title(" `c' Newly Issued Loans") name(`c'_data_vs_simul_loans,replace)
graph export "${diagnosticsPath}\New_loans_data_vs_simul_`c'.png", replace
}
restore



********************************************************************************
* 3. AGGREGATE MORTGAGES: W2 VS W3 VS SIMULATED WAVE 3 
********************************************************************************
preserve 
qui drop Agg_* 

qui gen Agg_dl1100_w2    = . 
qui gen Agg_dl1100_w3    = . 
qui gen Agg_dl1100_simul = . 

foreach c of global countries{

************* TOTAL MORTGAGE DEBT WAVE 2 
qui sum dl1100_w2 [aw=hw0010]                       if sa0100 == "`c'" ,d
qui replace Agg_dl1100_w2 = r(sum)                  if sa0100 == "`c'"  

************* TOTAL MORTGAGE DEBT WAVE 3 
qui sum dl1100_w3 [aw=hw0010]                       if sa0100 == "`c'" ,d
qui replace Agg_dl1100_w3 = r(sum)                  if sa0100 == "`c'"  

************* TOTAL MORTGAGE DEBT SIMULATED WAVE 3 
qui sum dl1100_simul [aw=hw0010]                    if sa0100 == "`c'" ,d
qui replace Agg_dl1100_simul = r(sum)               if sa0100 == "`c'"  
}


gr bar Agg_dl1100_w2 Agg_dl1100_w3 Agg_dl1100_simul, over(sa0100) legend(row(1) order(1 "Wave 2" 2 "Wave 3" 3 "Simulated Wave 3")) title("Aggregate mortgage debt")


restore


































