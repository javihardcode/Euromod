
* Mortgage Simulation Diagnostics: 

* 1) Targeted number vs simulated number: 
* 2) Distirbution of newly issued mortgages 

cls 
use "$hfcsoutputPath/mort_simul_compl.dta", clear
global mort_dig = "P:\ECB business areas\DGR\Databases and Programme files\DGR\Javier Ramos\microsim\1_0_2\diagnostics\diagnostics_mort"


* 1) Aggegate change vs target  
preserve 
collapse Agg_Loans, by(sa0100)
gen delta  = . 
gen nabla  = . 
gen target = . 
gen simul  = . 

foreach c of global ctrylist{
replace delta  = Scale_deltaMort_`c'   if sa0100 == "`c'"                     // Aggregate Change from SDW 
replace nabla  = Scale_NablaMort_`c'   if sa0100 == "`c'"                       // Nabla 
replace target = delta + nabla         if sa0100 == "`c'"
replace simul  = Agg_Loans             if sa0100 == "`c'" 
}

* Delta vs Nabla vs Simulation
graph bar delta nabla simul, over(sa0100) legend( row(1) label(1 "SDW Change") label(2 "Repayment Change") label(3 "Simulated Loans")) title("")
graph export "${mort_dig}\Delta_vs_Nabla_vs_Simul_mort.png", replace

* Target vs Simulation
graph bar target simul, over(sa0100) legend( row(1) label(1 "Target") label(2 "Simulated Loans")) title("") note("Target includes the number of new loans that need to be issued, once we account for repayments", size(vsmall))
graph export "${mort_dig}\Agg_change_vs_targets.png", replace
restore 

* 2) Simulated loans: 
bysort sa0100: sum loan [aw=hw0010], d 
gen ihs_loan = asinh(loan)

preserve 
drop if inlist(sa0100, "GR")
tw (kdensity ihs_loan [aw=hw0010]) || (kdensity ihs_new_issued_mort [aw=hw0010] if ihs_new_issued_mort > 0), legend(label(1 "Simulated Loans") label(2 "Data Loans")) xtitle("ihs value in euros")
graph export "${mort_dig}\new_vs_simul_loans_allEU.png", replace
restore

* Hist for each country 
foreach c of global ctrylist{
if !inlist("`c'","GR"){
tw (hist ihs_loan if sa0100 =="`c'", bcolor(blue%20)) || (hist ihs_new_issued_mort if ihs_new_issued_mort > 0 & sa0100 =="`c'", bcolor(red%20)), legend(label(1 "Simulated Loans") label(2 "Data Loans")) xtitle("ihs value in euros") name("`c'", replace) title("`c' Loans")
*graph export "${mort_dig}\new_vs_simul_loans_`c'.png", replace
}
}


* Probabiliy-Mortgage 
scatter ihs_loan mort_prob_hat if afford == 1, by(sa0100)   
graph export "${mort_dig}\prob_hat_vs_mort_hat.png", replace


tw (hist ihs_mort_hat if inrange(ihs_mort_hat,5,20) , bcolor(red%20)) || (hist ihs_new_issued_mort if inrange(ihs_new_issued_mort,5,20), bcolor(blue%20)), legend(label(1 "Prediction") label(2 "Data"))








