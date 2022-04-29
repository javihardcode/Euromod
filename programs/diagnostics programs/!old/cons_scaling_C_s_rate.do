*
* Saving Rates (Lamarche 2017) Scaling Consumption (Simul C = SDW) 
* Javier Ramos Perez (DGR) 19-11-2021 
* Without scaling C: High saving rates 
*         scaling C: Low  saving rates 

* 1) Open Simulated Wave 3
* 2) Generate Saving rates 
* 2.1) Aggregate C simulated and SDW Wave 2 & 3 
* 2.2) Re-scale C using "scale_c_w2" Wave 2 & 3
* 2.3) Compute saving rates 
* 3) Distribution of saving rates DE, ES, IT, FR

adopath + "D:/stata/ado"
set scheme ecb2015


* 1) Open Simulated Data: 
*use "$resultPath/D_compl_MicroSim_$print_ts.dta", clear                         // P:
use "$hfcsinputPath/D_compl_MicroSim_$print_ts.dta", replace                   // saved locally 

* 2) Saving Rates
* 2.1) Re-scale consumption
gen agg_di3001_w2 = .
gen agg_di3001_w3 = .
gen Aggregate_C_macro_w2 = . 
gen Aggregate_C_macro_w3 = .
gen scale_c_w2 = .
gen scale_c_w3 = . 
gen s_rate_w2 = . 
gen s_rate_w3 = . 
* Keep the first implicate to compute aggregates:  
keep if im0100 == 1   
foreach ii of global ctrylist {

* Consumption Wave 2 
* 1) Aggregate di3001_w2 
sum di3001_w2 [w=hw0010]                  if sa0100=="`ii'" , d                                
replace agg_di3001_w2 = r(sum)/1000000    if sa0100=="`ii'"                     // Aggregate C Wave 2 in millions
* 2) Aggregate C SDW W2
replace Aggregate_C_macro_w2 = Aggregate_C_w2_`ii' if sa0100 == "`ii'"          // Aggregate C from SDW in millions 
* 3) Compute scaling factor
replace scale_c_w2 = Aggregate_C_macro_w2 / agg_di3001_w2    if sa0100 == "`ii'"
* 4) Rescale consumption
replace di3001_w2 = scale_c_w2 * di3001_w2   if sa0100 == "`ii'"
* 5) Compute saving rate: 
replace s_rate_w2 = (di2000_w2-di3001_w2)/di2000_w2 if sa0100 == "`ii'"

* Consumption Wave 3 
* 1) Aggregate di3001_w3 
sum di3001_w3 [w=hw0010]                  if sa0100=="`ii'" , d                                
replace agg_di3001_w3 = r(sum)/1000000    if sa0100=="`ii'"                     // Aggregate C Wave 2
* 2) Aggregate C SDW W2
replace Aggregate_C_macro_w3 = Aggregate_C_w3_`ii' if sa0100 == "`ii'"          // Aggregate C from SDW 
* 3) Compute sacling factor
replace scale_c_w3 = Aggregate_C_macro_w3 / agg_di3001_w3    if sa0100 == "`ii'"
* 4) Rescale consumption
replace di3001_w3 = scale_c_w3 * di3001_w3                   if sa0100 == "`ii'"
* 5) Compute saving rate: 
replace s_rate_w3 = (di2000-di3001_w3)/di2000    if sa0100 == "`ii'"


} 

* Histogram Saving Rates 
local countries "DE ES IT FR"
foreach ii of local countries{
tw (hist s_rate_w2 if sa0100 == "`ii'" & inrange(s_rate_w2, -1.5,1), color(blue%30)) || (hist s_rate_w3 if sa0100 == "`ii'" & inrange(s_rate_w3, -1.5,1), color(green%30)), legend(label(1 "Wave 2") label(2 "Wave 3")) title("`ii' Distribution of Saving Rates")
graph export "P:\ECB business areas\DGR\Databases and Programme files\DGR\Javier Ramos\microsim\1_0_2\diagnostics\diagnostics_cons\saving_rates_scaled_`ii'.png", replace
}








