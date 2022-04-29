*
* Generates charts Aggregate Consumption (Simul & SDW) and Income (Simul & SDW) Wave 2 & 3 
* Javier Ramos Perez (DGR) 19-11-2021 

* 1) Open Aggregate Wage data from SDW (convert to yearly)
* 1.1) Save aggregates as scalars to avoing merge 
* 2) Open simulated Wave 3 
* 2.2) Compute Aggregate Y and C for Wave 2 & 3
* 3) Additionally compute aggregate Saving Rate 


* 1) Open Wage data from SDW: Exctract Aggregate Wages from WagesPC_ALL.dta 
use "$dataoutputPath/WagesPC_ALL.dta", clear                                    // Aggregate WagE SDW 
drop if PERIOD_NAME < "2007Q1"                                                  // Drop before 2007                            
                               
foreach ii of global ctrylist {
 * 1) convert to yearly 
 replace wages_`ii' = 4*wages_`ii'
 
 * 2) Save scalar with the quantity in Wave 2 and Wave 3
 sca Aggregate_Wage_w2_`ii' = wages_`ii'[start_q_inc_`ii'_n] 
 sca Aggregate_Wage_w3_`ii' = wages_`ii'[end_q_inc_`ii'_n]
}



* 2) Open Simulated Wave 3 
*use "$resultPath/D_compl_MicroSim_$print_ts.dta", clear 
use "$hfcsinputPath/D_compl_MicroSim_$print_ts.dta", clear                      // saved locally 

gen agg_di2000_w2 = .                                                           // Income 
gen agg_di2000    = .
gen percap_di2000_w2 = .
gen percap_di2000 = . 
gen growth_agg_di2000 = . 
gen Aggregate_Wage_macro_w2 = . 
gen Aggregate_Wage_macro_w3 = . 

gen agg_di3001_w2 = .                                                           // Consumption
gen agg_di3001_w3 = .
gen percap_di3001_w2 = .
gen percap_di3001_w3 = . 
gen growth_agg_di3001 = . 
gen macro_growth = .
gen agg_s_rate_w2 = . 
gen agg_s_rate_w3 = . 
gen Aggregate_C_macro_w2 = . 
gen Aggregate_C_macro_w3 = . 

* Keep first implicate to compute aggregates:  
keep if im0100 == 1 

foreach ii of global ctrylist {

* Income
replace Aggregate_Wage_macro_w2 = Aggregate_Wage_w2_`ii' if sa0100 == "`ii'"    // Aggregate Wage from SDW 
sum di2000_w2 [w=hw0010]   if sa0100=="`ii'" , d                                
replace agg_di2000_w2 = r(sum)/1000000    if sa0100=="`ii'"                     // Aggregate  Y Wave 2 
replace percap_di2000_w2 = r(sum) / r(sum_w) if sa0100=="`ii'"                  // Per Capita Y Wave 2


replace Aggregate_Wage_macro_w3 = Aggregate_Wage_w3_`ii' if sa0100 == "`ii'"    // Aggregate Wage from SDW 
sum di2000 [w=hw0010]   if sa0100=="`ii'" , d                                
replace agg_di2000 = r(sum)/1000000    if sa0100=="`ii'"                        // Aggregate Y  Wave 3 
replace percap_di2000 = r(sum) / r(sum_w) if sa0100=="`ii'"                     // Per Capita Y Wave 3

replace growth_agg_di2000 = 100 * (agg_di2000-agg_di2000_w2)/agg_di2000_w2 if sa0100 == "`ii'"


* Consumption
replace Aggregate_C_macro_w2 = Aggregate_C_w2_`ii' if sa0100 == "`ii'"          // Aggregate C from SDW 
sum di3001_w2 [w=hw0010]   if sa0100=="`ii'" , d                                
replace agg_di3001_w2 = r(sum)/1000000    if sa0100=="`ii'"                     // Aggregate C Wave 2 Lamarche 2017
replace percap_di3001_w2 = r(sum) / r(sum_w) if sa0100=="`ii'"

replace Aggregate_C_macro_w3 = Aggregate_C_w3_`ii' if sa0100 == "`ii'"          // Aggregate C from SDW 
sum di3001_w3 [w=hw0010]   if sa0100=="`ii'" , d                                
replace agg_di3001_w3 = r(sum)/1000000    if sa0100=="`ii'"                     // Aggregate C Wave 3 Lamarche 2017
replace percap_di3001_w3 = r(sum) / r(sum_w) if sa0100=="`ii'"

replace growth_agg_di3001 = 100 * (agg_di3001_w3-agg_di3001_w2)/agg_di3001_w2 if sa0100 == "`ii'"

* Macrodata on Consumption Growth Rate
replace macro_growth = 100*(P31_growth_`ii'-1) if sa0100 == "`ii'"

* Aggregate Saving Rate 
replace agg_s_rate_w2 = 100*(agg_di2000_w2-agg_di3001_w2)/agg_di2000_w2 if sa0100 == "`ii'"
replace agg_s_rate_w3 = 100*(agg_di2000-agg_di3001_w3)/agg_di2000       if sa0100 == "`ii'"

}



* Now compute charts for Aggregate Income + Aggregate Consumption DE, ES, FR, IT 
local countries "DE ES IT FR"
foreach cc of local countries{

gr bar agg_di2000_w2 Aggregate_Wage_macro_w2 agg_di2000 Aggregate_Wage_macro_w3 if sa0100 == "`cc'", title("`cc'Aggregate Income") legend(label(1 "Income W2") label(2 "SDW Wages W2") label(3 "Simulated Income W3") label(4 "SDW Wages W3")) name(Aggregate_Income, replace)

gr bar agg_di3001_w2 Aggregate_C_macro_w2 agg_di3001_w3 Aggregate_C_macro_w3 if sa0100 == "`cc'", legend(label(1 "Simulated C W2") label(2 "SDW C W2") label(3 "Simulated C W3") label(4 "SDW C W3")) title("`cc' Aggregate Consumption") name(Aggregate_Consumption, replace) 

gr combine Aggregate_Income Aggregate_Consumption, title("`cc' Aggregate Diagnostics")
gr export "P:\ECB business areas\DGR\Databases and Programme files\DGR\Javier Ramos\microsim\1_0_2\diagnostics\diagnostics_cons\Aggregate_Diagnostics_`cc'.png", replace 
}





