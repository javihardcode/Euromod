*
* Charts for presentation with Oreste 
* last update 04-04-2022
*

qui use "$hfcsinputPath/D_compl_MicroSim_$print_ts.dta" , clear 
global countries = "DE ES IT FR"
keep if inlist(sa0100,"DE","ES","IT","FR")
keep if im0100 == 1 


********************************************************************************
*  Figure 1 and 2. Income by deciles 
********************************************************************************
foreach c of global countries{
preserve 
qui keep if sa0100 == "`c'"
qui xtile di2000_simul_xtile = di2000_simul [pw=hw0010], n(10)

qui collapse (median) di2000 di2000_simul dnnla dnnla_simul [aw=hw0010], by(di2000_simul_xtile)

gr bar di2000 di2000_simul, over(di2000_simul_xtile) title(" `c' 1-Year income by deciles") legend(row(1) order(1 "2017Q*" 2 "2021Q4")) ytitle("Euros")
qui gr export "D:/microsim/results/diagnostics oreste/income_by_deciles_`c'.png", replace

gr bar dnnla dnnla_simul, over(di2000_simul_xtile) title(" `c' Liq. assets by income deciles") legend(row(1) order(1 "2017Q*" 2 "2021Q4")) ytitle("Euros")
qui gr export "D:/microsim/results/diagnostics oreste/liquidAssets_by_deciles_`c'.png", replace

restore 
}



********************************************************************************
*  Figure. Level of savings by income deciles 
********************************************************************************
foreach c of global countries{
preserve 
qui keep if sa0100 == "`c'"
qui xtile di2000_simul_xtile = di2000_simul [pw=hw0010], n(10)

gen savings_base = di2000_net - di3001 
gen savings_simul22 = di2000_net_simul - di3001_simul

qui collapse (median) savings_base savings_simul22 [aw=hw0010], by(di2000_simul_xtile)

gr bar savings_base savings_simul22, over(di2000_simul_xtile) title(" `c' 1-Year savings by income deciles")   ytitle("Euros") legend(row(1) order(1 "2017Q**" 2 "2021Q4"))
qui gr export "D:/microsim/results/diagnostics oreste/savings_by_deciles_`c'.png", replace
restore 
}


********************************************************************************
*  Figure. Real Assets by Income decile 
********************************************************************************
foreach c of global countries{
preserve 
qui keep if sa0100 == "`c'"
qui xtile di2000_simul_xtile = di2000_simul [pw=hw0010], n(10)

qui collapse (median) da1000 da1000_simul [aw=hw0010], by(di2000_simul_xtile)

gr bar da1000 da1000_simul, over(di2000_simul_xtile) title(" `c' 1-Year real assets by income deciles") legend(row(1) order(1 "2017Q*" 2 "2021Q4")) ytitle("Euros")
qui gr export "D:/microsim/results/diagnostics oreste/real_assets_by_deciles_`c'.png", replace
restore 
}



********************************************************************************
*  Figure. Deposits-to-income
********************************************************************************
foreach c of global countries{
preserve 
qui keep if sa0100 == "`c'"
qui xtile di2000_simul_xtile = di2000_simul [pw=hw0010], n(10)

qui collapse (median) da2101 savings_simul di2000 di2000_simul [aw=hw0010], by(di2000_simul_xtile)

gen dep_to_inc       = da2101 / di2000 
gen dep_to_inc_simul = savings_simul / di2000_simul 

gr bar dep_to_inc dep_to_inc_simul , over(di2000_simul_xtile) title(" `c' deposits to income") legend(row(1) order(1 "2017Q*" 2 "2021Q4")) ytitle("Euros")
qui gr export "D:/microsim/results/diagnostics oreste/deposits_to_income_by_deciles_`c'.png", replace
restore 
}


********************************************************************************
*  Figure. Household total wealth  
********************************************************************************
foreach c of global countries{
preserve 
qui keep if sa0100 == "`c'"
qui xtile di2000_simul_xtile = di2000_simul [pw=hw0010], n(10)

qui collapse (median) dn3001 dn3001_simul [aw=hw0010], by(di2000_simul_xtile)

gr bar dn3001 dn3001_simul , over(di2000_simul_xtile) title(" `c' net worth by income deciles") legend(row(1) order(1 "2017Q*" 2 "2021Q4")) ytitle("Euros")
qui gr export "D:/microsim/results/diagnostics oreste/net_worth_by_deciles_`c'.png", replace
restore 
}


********************************************************************************
*  Figure. Distribution of saving rates   
********************************************************************************
foreach c of global countries{
preserve 
qui keep if sa0100 == "`c'"
qui xtile di2000_simul_xtile = di2000_simul [pw=hw0010], n(10)
gen saving_rate  =100*savings_flow_w3_simul / di2000_simul 

qui collapse (median) saving_rate [aw=hw0010], by(di2000_simul_xtile)

gr bar saving_rate , over(di2000_simul_xtile) title(" `c' saving rates by income deciles") ytitle("Euros")
qui gr export "D:/microsim/results/diagnostics oreste/saving_rates_by_deciles_`c'.png", replace
restore 
}



********************************************************************************
*  Figure. net liquid wealth over wealth distribution 
********************************************************************************
foreach c of global countries{
preserve 
qui keep if sa0100 == "`c'"
qui xtile dnnla_simul_xtile = dnnla_simul [pw=hw0010], n(10)

qui collapse (median) dnnla dnnla_simul [aw=hw0010], by(dnnla_simul_xtile)

gr bar dnnla dnnla_simul, over(dnnla_simul_xtile) title(" `c' Liq. assets by income deciles") legend(row(1) order(1 "2017Q*" 2 "2021Q4")) ytitle("Euros")
qui gr export "D:/microsim/results/diagnostics oreste/liquidAssets_by_wealthdeciles_`c'.png", replace

restore 
}











********************************************************************************
*  Figure. Ybar and cbar  
********************************************************************************
foreach c of global countries{
preserve 
qui keep if sa0100 == "`c'"


tw (hist ybar if inrange(ybar,-2000,2000), color(blue%20)) || (hist cbar if inrange(cbar,-2000,2000), color(red%20)), legend(row(1) order(1 "Income" 2 "Consumption")) title(" `c' average change 2021-2017")

*gr bar ybar cbar, over(di2000_simul_xtile) title(" `c' 1-Year real assets by income deciles") legend(row(1) order(1 "2017Q*" 2 "2021Q4")) ytitle("Euros")
*qui gr export "D:/microsim/results/diagnostics oreste/real_assets_by_deciles_`c'.png", replace
restore 
}







********************************************************************************
*  Figure xx1. Income Consumption and Savings along INCOME DISTRIBUTION 
********************************************************************************
foreach c of global countries{
preserve
qui keep if sa0100 == "`c'"

qui xtile di2000_simul_xtile = di2000_simul [pw=hw0010], n(10)

qui collapse (median) savings_flow_w3_simul di2000_simul di3001_simul [aw=hw0010], by(di2000_simul_xtile)

gr bar savings_flow_w3_simul di3001_simul di2000_simul, over(di2000_simul_xtile) legend(row(1) order(3 "Income" 2 "Consumption" 1 "Savings")) title(" `c' 1-year along the income distribution") ytitle("Euros")
qui gr export "D:/microsim/results/diagnostics oreste/savings_income_distribution_`c'.png", replace
restore 
}


********************************************************************************
*  Figure xx2. Income Consumption and Savings along WEALTH DISTRIBUTION 
********************************************************************************
foreach c of global countries{
preserve
qui keep if sa0100 == "`c'"

qui xtile dn3001_simul_xtile = dn3001_simul [pw=hw0010], n(10)
qui replace dl2000_simul     = 12*dl2000_simul                                      // convert to year frequency 

qui collapse (median) savings_flow_w3_simul di2000_simul di3001_simul dl2000_simul [aw=hw0010], by(dn3001_simul_xtile)

gr bar dl2000_simul savings_flow_w3_simul di3001_simul di2000_simul, over(dn3001_simul_xtile) legend(row(2) order(4 "Income" 3 "Consumption" 2 "Savings" 1 "Debt Services")) title(" `c' 1-year along the wealth distribution") ytitle("Euros")
qui gr export "D:/microsim/results/diagnostics oreste/savings_wealth_distribution_`c'.png", replace
restore 
}























