*
* DIAGNOSTICS CONSUMPTION:
* 


* 1. Append Wave 2









********************************************************************************
* 1. Open data Wave 2 and Simulated Wave 3 + Simul 
********************************************************************************
qui use "D:\data\hfcs\wave3\h1.dta", clear                                          // hh core variables wave 3
qui rename * , lower 
qui save "D:\data\hfcs\wave3\h1_temp.dta", replace

qui use "D:\data\hfcs\wave3\DP_extended.dta", clear                                 // derived variables wave 3
sort sa0100 
decode sa0100, gen(sa0100_str)
qui drop sa0100
qui rename sa0100_str sa0100
keep if im0100 == 1 
merge 1:1 id sa0010 sa0100 using "D:\data\hfcs\wave3\h1_temp.dta"
drop _merge 
rm "D:\data\hfcs\wave3\h1_temp.dta"

 
qui append using "$hfcsinputPath/D_compl_MicroSim_$print_ts.dta"                // append to wave 2 and simulated wave 3
qui keep if im0100 == 1 & inlist(sa0100,"AT","BE","DE","ES","IT","FR","NL")                        
qui replace wave = 2 if wave == . 
global countries "AT BE DE ES IT FR NL"


********************************************************************************
* 2. Describe variable food outside 
********************************************************************************
order sa0100 wave hi0200 docogood di3001 di3001_simul
*br sa0100 wave hi0200 docogood di3001 di3001_simul                              // hi0200 only available for AT in Wave 2 


 



********************************************************************************
* 2. Ratio food-out-home 
********************************************************************************
replace hi0200   = . if hi0200   == 0 
replace docogood = . if docogood == 0 

gen food_to_docogood_w2     = 12*hi0200/docogood if wave == 2                   // only availabel for AT 
gen food_to_docogood_di3001 = 12*hi0200/di3001   if wave == 2                   // only availabel for AT 


gen food_to_docogood_w3     = 12*hi0200/docogood if wave == 3                   // available for most countries (no ES) 


tw (kdensity food_to_docogood_w2 [aw=hw0010] if inrange(food_to_docogood_w2,0,1)) || (kdensity food_to_docogood_di3001 [aw=hw0010] if inrange(food_to_docogood_di3001,0,1)) || (kdensity food_to_docogood_w3 [aw=hw0010] if inrange(food_to_docogood_w3,0,1)), legend(row(1) order(1 "W2 data" 2 "W2 simulated" 3 "W3 data")) title("Share of food outside on total consumption")






































