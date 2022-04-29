



*
* Some diagnostics 23April2022 
*
* Diagnostics consumption change: 
* The main goal of this script is to understand what is driving the changes in consumption at household level 



global countries = "DE ES FR IT"
global charts    = "D:/microsim/results/diagnostics 23April2022"

use "$hfcsinputPath/D_compl_MicroSim_$print_ts.dta" , clear
keep if im0100 == 1 
keep if inlist(sa0100,"DE","ES", "FR", "IT")





*** Conver scaling factors lambda to variables  lambda_simul_`j'_`ii'


*** Apply formula:  dc_hat = dlambda*c + dc*lambda + dlambda*dc 
qui gen dc      = di3000_simul-di3000
qui gen dlambda = lambda_simul - lambda 
qui gen term1   = dlambda*di3000 
qui gen term2   = dc*lambda 
qui gen term3   = dlambda*dc


qui gen dc_hat = term1 + term2 + term3 

qui gen diff_c =  di3001_simul - di3001 

sum dc_hat diff_c [aw=hw0010],d

foreach c of global countries{
preserve 
keep if sa0100 == "`c'"
qui xtile di2000_simul_net_xtile = di2000_simul_net [aw=hw0010], nq(10)


gr bar term1 term2 term3, stack over(di2000_simul_net_xtile) title("`c' Change in C decomposition") legend(row(1) order(1 "dlambda*c" 2 "dc*lambda" 3 "dlambda*dc")) name(`c',replace) b1title("Income quintiles")

restore

}











