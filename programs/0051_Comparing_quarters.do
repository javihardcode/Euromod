*
*
*  This script compares two non-wave simulated quarters 




**** 1. Set the two quarters we want to merge 
global quarter1 = "2019Q2"
global quarter2 = "2020Q2"


**** 2. Open data 
use  "D:/data/hfcs/wave3/D_compl_MicroSim_$quarter1.dta" , clear                // Open First Quarter  
gen      Quarter = "$quarter1"
append using "D:/data/hfcs/wave3/D_compl_MicroSim_$quarter2.dta"                // Append with second Quarter
replace  Quarter = "$quarter2" if missing(Quarter)




**** 3. Keep country, implicates..... etc 
keep if inlist(sa0100,"DE","ES","FR","IT")                                               
keep if im0100 == 1  





**** 4. Compare Income, Consumption and savings: 
preserve 
collapse (p50) di2000 di2000_simul di3001_simul savings_flow_w3_simul [aw=hw0010], by(Quarter sa0100)
sort sa0100

gen diff_DE = di2000_simul - di2000  if sa0100 == "DE"
gen diff_ES = di2000_simul - di2000  if sa0100 == "ES"


gr bar di2000_simul di3001_simul savings_flow_w3_simul, over(Quarter) over(sa0100) legend(row(1) order(1 "Income" 2 "Consumption" 3 "Savings")) ytitle("EUR") note("Medians")
restore



**** 5. Compare dnnla_simul 
preserve 
collapse (p50) dn3001_simul [aw=hw0010], by(Quarter sa0100)
sort sa0100


gr bar dn3001_simul, over(Quarter) over(sa0100) legend(row(1) order(1 "Net liquid assets")) ytitle("EUR") note("Medians")
restore





***** Compare saving rates 
preserve 
gen srate_simul = 1 - di3001_simul / di2000_simul_net 
gen srate22     = savings_flow_w3_simul / di2000_simul_net

keep if inrange(srate_simul,-1,1)
keep if inrange(srate22,-1,1)



* 
gen     xxtile = . 
replace xxtile = di2000_simul_net_xtile_DE if sa0100 == "DE"
replace xxtile = di2000_simul_net_xtile_ES if sa0100 == "ES"
replace xxtile = di2000_simul_net_xtile_FR if sa0100 == "FR"
replace xxtile = di2000_simul_net_xtile_IT if sa0100 == "IT"


collapse (median) srate_simul srate22 [aw=hw0010], by(Quarter sa0100 xxtile)

gr bar srate_simul , over(Quarter) over(xxtile) over(sa0100) name(xx,replace)
gr bar srate22     , over(Quarter) over(xxtile) over(sa0100) name(yy,replace)

restore 
























