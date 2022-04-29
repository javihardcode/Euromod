


* Adjusting the consumption distribution 


qui use "$hfcsinputPath/D_compl_MicroSim_$print_ts.dta", clear 

keep if inlist(sa0100, "DE","ES","FR","IT")
keep if im0100 == 1 
global countries "DE ES FR IT"

global results "D:/microsim/results/diagnostics 2020"



* 1. Saving rates: base wave, before and after udjustment 
gen srate_pr_base = 100*(di2000_net - di3000)/di2000_net  
gen srate_af_base = 100*(di2000_net - di3001)/di2000_net

foreach c of global countries{   
preserve 
keep if sa0100 == "`c'"     
tw (kdensity srate_pr_base [aw=hw0010] if inrange(srate_pr_base,-100,100)) ///
   (kdensity srate_af_base [aw=hw0010] if inrange(srate_af_base,-100,100)), legend(order(1 "Pre-adjustment" 2 "After-udjustment")) title("`c' base wave (HFCS 2017)") xsc(r(-100 100)) xtitle("Saving Rate") name(`c'1, replace)
   gr export "${results}/01_saving_rates_base_wave_`c'.png"   
   restore
}



* 2. Saving rates: simulated wave, before and after udjustment 
gen srate_pr_simu = 100*(di2000_net_simul - di3000_simul)/di2000_net_simul  
gen srate_af_simu = 100*(di2000_net_simul - di3001_simul)/di2000_net

foreach c of global countries{   
preserve 
keep if sa0100 == "`c'"     
tw (kdensity srate_pr_simu [aw=hw0010] if inrange(srate_pr_simu,-100,100)) ///
   (kdensity srate_af_simu [aw=hw0010] if inrange(srate_af_simu,-100,100)), legend(order(1 "Pre-adjustment" 2 "After-udjustment")) title("`c' simulated wave (2021Q4)") xsc(r(-100 100)) xtitle("Saving Rate") name(`c'2, replace)
   gr export "${results}/02_saving_rates_simul_wave_`c'.png", replace   
   restore
}



* 3. scatter saving rates (after udjustment): who have seen their saving rates increased? 

foreach c of global countries{   
preserve 
keep if sa0100 == "`c'"  
keep if inrange(srate_af_base,-100,100)
keep if inrange(srate_af_simu,-100,100)

tw (scatter srate_af_base srate_af_simu, msize(0.001in)) /// 
   (function y = x , range(-100 100) lwidth(vthin)), legend(order(1 "" 2 "45degree line")) title("`c' Saving rates") ytitle("HFCS 2017") xtitle("2021Q4") name(`c'3, replace)
   gr export "${results}/03_scatter_saving_rates_`c'.png", replace   

restore
}



* 4. saving rates along income distribution 

foreach c of global countries{   
preserve 
keep if sa0100 == "`c'"  
keep if inrange(srate_af_base,-100,100)
keep if inrange(srate_af_simu,-100,100)
drop if di2000_net_simul < 0 

qui xtile di2000_net_simul_xtile = di2000_net_simul [aw=hw0010], nq(5)

collapse (mean) srate_af_base srate_af_simu [aw=hw0010], by(di2000_net_simul_xtile)

gr bar srate_af_base srate_af_simu , over(di2000_net_simul_xtile) legend(order(1 "HFCS 2017" 2 "2021Q4")) title(" `c' Saving rates by income") note("Net Income, ") name(`c'4, replace)
gr export "${results}/04_saving_rates_income_deciles_`c'.png", replace      
restore
}



* 5. scatter: increase in come vs increase in consumption 
gen dy = 100*(di2000_net_simul / di2000_net - 1) 
gen dc = 100*(di3001_simul     / di3001 - 1) 

foreach c of global countries{   
preserve 
keep if sa0100 == "`c'"  
keep if inrange(dy,-50,50)
keep if inrange(dc,-50,50)

tw (scatter dy dc, msize(vtiny)) ///
   (function y=x, range(-50 50) lwidth(vthin)) , legend(order(1 "" 2 "45degree line")) name(`c'5, replace) title("`c' Change in Income vs Change in Consumption") ytitle("Change in Income") xtitle("Change in consumption")
gr export "${results}/05_scatter_dy_dc_`c'.png", replace   
restore
}


* 6. scatter: increase in come vs increase in consumption but for income quintiles
foreach c of global countries{   
preserve 
keep if sa0100 == "`c'"  
qui xtile di2000_net_simul_xtile = di2000_net_simul [aw=hw0010], nq(5)
keep if inrange(dy,-50,50)
keep if inrange(dc,-50,50)

tw (scatter dy dc, msize(vtiny)) ///
   (function y=x, range(-50 50)) , by(di2000_net_simul_xtile) legend(order(1 "" 2 "45degree line")) name(`c'5, replace) title("`c' Change in Income vs Change in Consumption") ytitle("Change in Income") xtitle("Change in consumption")
gr export "${results}/06_scatter_dy_dc_incomedist_`c'.png", replace   
restore
}






















