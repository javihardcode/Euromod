*
* Aggregate Consumption: Simulated Wave 3, SDW, and HFCS Wave 3 
* Javier Ramos Perez (DGR) 19-11-2021 

* 1) Open simulated Wave 3
* 2) Compute Aggregate consumption (Simul and SDW Wave 3)
* 3) Collapse C simul and SDW
* 4) OPen HFCS Wave 3 (just one implicate)
* 5) Aggregate reported C by country 
* 6)Merge and put the three Aggregate Comsumption together in a chart 

* 1) Open simulated Wave 3
use "$hfcsinputPath/D_compl_MicroSim_$print_ts.dta", clear                   // save locally 
*use "$resultPath/D_compl_MicroSim_$print_ts.dta", clear                         // P:

* 2) Compute Aggregate Consumption
gen Aggregate_C_macro_w3 = . 
gen agg_di3001_w3        = . 

keep if im0100 == 1 
foreach ii of global ctrylist {

* SDW 
replace Aggregate_C_macro_w3 = Aggregate_C_w3_`ii' if sa0100 == "`ii'"          // Aggregate C from SDW 

* Simulated Wave 3
sum di3001_simul [w=hw0010]   if sa0100=="`ii'" , d                                
replace agg_di3001_w3 = r(sum)/1000000    if sa0100=="`ii'"                     // Aggregate C Wave 3 Lamarche 2017

}

* 3) Collapse Aggregate consumption: SDW, Simulated Wave 3
collapse Aggregate_C_macro_w3 agg_di3001_w3, by(sa0100)
save "$hfcsinputPath/Aggregate_C_SDW_Simul_W3.dta", replace                     // Saved locally


* 4) Open HFCS Wave 3 hh 
use "D:\data\hfcs\wave3\h1.dta", replace                                        // saved locally 
keep ID SA0100 IM0100 HI0100 HI0200 HI0210 HI0220 HW0010 
rename *, lower  
egen c_hfcs_wave3 = rowtotal(hi0100 hi0200 hi0210 hi0220) 
replace c_hfcs_wave3 = 12*c_hfcs_wave3

* 5) Generate Aggregate Consumption by country using HFCS data 
gen Aggregate_C_HFCS_W3 = . 
foreach ii of global ctrylist {
 sum c_hfcs_wave3 [w=hw0010] if sa0100=="`ii'", d 
 replace Aggregate_C_HFCS_W3 = r(sum)/1000000 if sa0100 == "`ii'"
 
}

collapse Aggregate_C_HFCS_W3, by(sa0100)

* 6) Merge and put the three together
merge 1:1 sa0100 using "$hfcsinputPath/Aggregate_C_SDW_Simul_W3.dta"
keep if _merge == 3

local countries "DE ES IT FR"
foreach cc of local countries{
gr bar agg_di3001_w3 Aggregate_C_macro_w3 Aggregate_C_HFCS_W3 if sa0100=="`cc'", legend(row(1) label(1 "Simulated Wave 3") label(2 "SDW Wave 3") label(3 "HFCS Wave 3")) title("`cc' Aggregate Consumption (in millions)")

graph export "P:\ECB business areas\DGR\Databases and Programme files\DGR\Javier Ramos\microsim\1_0_2\diagnostics\diagnostics_cons\Aggregate_Consumption_SDW_SIMUL_HFCS_WAVE3_`cc'.png", replace 

}












