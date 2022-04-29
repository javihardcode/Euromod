
* Consumption Diagnostics NEW  
* Last update: 31-01-2022
* Javier Ramos Perez

* Open Simulated Data: 
*use "$resultPath/D_compl_MicroSim_$print_ts.dta", clear                        // P:
use "$hfcsinputPath/D_compl_MicroSim_$print_ts.dta", replace                    // save locally 

																																							 
* Figure 1) Aggregate Saving Rate: from SDW (target) vs on Simulated Wave 3
gen Agg_di2000_simul = . 
gen Agg_di3001_simul = . 
gen Agg_S_rate_simul = . 
gen Agg_S_target     = . 
foreach ii of global ctrylist {

* Aggregate Income Simulated Wave 3
 qui sum di2000_simul [aw=hw0010] if sa0100=="`ii'" , d 
 replace Agg_di2000_simul = r(sum) / 5   if sa0100=="`ii'"                      // divide by 5 
 
* Agregate Consumption Simulated wave 3 
 qui sum di3001_simul [aw=hw0010] if sa0100=="`ii'", d   
 replace Agg_di3001_simul = r(sum) / 5 if sa0100 =="`ii'"

* Aggregate Saving Rate Simulated Wave 3: 
  
 replace Agg_S_rate_simul = 100*(Agg_di2000_simul - Agg_di3001_simul)/Agg_di2000_simul if sa0100=="`ii'"

* Now replace the target: 
replace Agg_S_target = 100* saving_target_`ii'  if sa0100 == "`ii'"

}

graph bar Agg_S_rate_simul Agg_S_target, over(sa0100) title("") legend(label(1 "Simul Wave 3 Agg. Savings") label(2 "SDW Wave 2 Agg. Savings")) note("Need to add new liabilities from mortgage simulation!!") name(Aggregate_s, replace)













																 