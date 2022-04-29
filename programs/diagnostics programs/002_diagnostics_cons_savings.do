* 
* 
* Diagnostics for Consumption-Savings  
* 1. Aggregate saving rate SDW vs Simulated Wave 3 
* 2. Aggregate C SDW W2 VS Imputed consumption Wave 2 
* 3. Distribution of saving rates at household level 
* 4. Average consumption, income and savings against the income distirbution. 

* Open Simulated Data: 
use "$hfcsinputPath/D_compl_MicroSim_$print_ts.dta", replace                    
keep if im0100 == 1 & inlist(sa0100,"DE","ES","IT","FR")                             // 
global countries "DE ES IT FR"

********************************************************************************	
* 1. AGG. SAVING RATE: Wave 2 (targeted SDW) & Simulated Wave 3 (targeted SDW)
********************************************************************************
drop Agg_*
global vars "di2000 di3001 S_rate"
foreach v of global vars{
qui gen Agg_`v'       = . 
qui gen Agg_`v'_simul = . 
}
foreach ii of global countries {
 
 * 1.  Wave 2 
global vars "di2000 di3001" 
foreach v of global vars{
qui sum         `v' [aw=hw0010] if sa0100 == "`ii'"
qui replace Agg_`v' = r(sum)    if sa0100 == "`ii'" 
}
*qui sum         dl2000 [aw=hw0010] if sa0100 == "`ii'"
*qui replace Agg_dl2000 = 12*r(sum)    if sa0100 == "`ii'"

* Aggregate saving rate wave 2 
qui replace Agg_S_rate = 100*(Agg_di2000-Agg_di3001)/Agg_di2000 if sa0100 == "`ii'"


 * Simulated Wave 3 
global vars "di2000_simul di3001_simul" 
foreach v of global vars{
qui sum         `v' [aw=hw0010]             if sa0100 == "`ii'" 
qui replace Agg_`v' = r(sum)                if sa0100 == "`ii'" 
}
*qui sum         dl2000_simul [aw=hw0010]    if sa0100 == "`ii'"
*qui replace Agg_dl2000_simul = 12*r(sum)    if sa0100 == "`ii'"



* Aggregate saving rate Simulated wave 3 
qui replace Agg_S_rate_simul = 100*(Agg_di2000_simul-Agg_di3001_simul)/Agg_di2000_simul if sa0100 == "`ii'"

}

graph bar Agg_S_rate  Agg_S_rate_simul, over(sa0100) legend(order(1 "Wave 2" 2 "Simul Wave 3")) title("Aggregate Saving Rate (targeted with SDW)") blabel(bar, format(%9.1f)) name(Aggregate_s, replace)
gr export "D:\microsim\results\diagnostics wave 3\Diagnostics Consumption\Agg_S_rate_Simul_VS_Agg_S_rate_Target.png", replace


********************************************************************************	
* Figure 2) aggregate Consumption HFCS W2 vs Aggregate imputed Consumption W2: 
********************************************************************************
gen Agg_docogood   = . 
gen Agg_di3001_SDW = . 
foreach ii of global countries {
* 1) 
qui sum di3001 [aw=hw0010]              if sa0100 == "`ii'", d 
qui replace Agg_di3001 = r(sum)     if sa0100 == "`ii'"

* 2) 
qui sum docogood [aw=hw0010]            if sa0100 == "`ii'", d 
qui replace Agg_docogood = r(sum)   if sa0100 == "`ii'"

* 3) Lastly, use Aggregate Consumption from SDW (saved as scalar)
qui replace Agg_di3001_SDW = 1000000*Aggregate_C_w2_`ii' if sa0100 == "`ii'"
qui replace Agg_di3001_SDW = Agg_di3001_SDW/1000000 if sa0100 == "HU" | sa0100 == "PL"

}
gr bar Agg_di3001 Agg_di3001_SDW Agg_docogood, over(sa0100) legend(order(1 "di3001 (w2)" 2 "SDW (w2)" 3 "docogood (w2)") row(1)) title("Aggregate Consumption") 
gr export "D:\microsim\results\diagnostics wave 3\Diagnostics Consumption\Agg_di3001_VS_Agg_docogood_w2.png", replace 




*******************************************************************************************	
* Figure(s) 3) Distribution of saving rates using Simulated Consumption on wave 3 and Wave 2 consumption
*******************************************************************************************

preserve 
qui gen saving_rate_w2 = 1-docogood / di2000                                    // saving rate Wave 2 
qui gen saving_rate_w3 = savings_flow_w3_simul / di2000_simul                   // saving rate Simulated Wave 3

qui keep if inrange(saving_rate_w2, -1, 1) & inrange(saving_rate_w3, -1, 1)     // around 2.000/37.000 obs deleted   
bysort sa0100: sum saving_rate_w3 [aw=hw0010],d 

foreach ii of global countries {
tw (kdensity saving_rate_w2 [aw=hw0010] if inrange(saving_rate_w2, -1, 1) & sa0100=="`ii'") || (kdensity saving_rate_w3 [aw=hw0010] if inrange(saving_rate_w3, -1, 1) & sa0100=="`ii'"), legend(order(1 "HFCS (w2)" 2 "Simulation (simul w3)")) title("`ii' Household Saving Rate") xtitle("saving rate") note("Range:-1,1: 95% of total sample") name(`ii'_savings_distribution, replace) 
qui gr export "D:\microsim\results\diagnostics wave 3\Diagnostics Consumption\ histogram_saving_rate_`ii'.png", replace 
}
restore



********************************************************************************
* Figure 4) Saving rates percentiles in euros 
* This chart is useful to answer the following question: 
* High saving rates are driven by income relatively higuer than consumption, 
* or consumption relatively lower than income? 
********************************************************************************
qui gen saving_rate_w2 = docogood / di2000                     
qui gen saving_rate_w3 = savings_flow_w3_simul / di2000_simul 

foreach c of global countries{
qui xtile s_xtile_`c' = saving_rate_w3 [aw=hw0010] if sa0100=="`c'", nq(10)
sort s_xtile_`c' 
order s_xtile_`c' savings_flow_w3_simul
}
qui egen s_xtile = rowtotal(s_xtile_*)
qui drop if s_xtile == 0 

bysort sa0100 s_xtile: egen average_savings_ptile = wtmean(savings_flow_w3_simul) , weight(hw0010)
bysort sa0100 s_xtile: egen average_di2000_simul_ptile = wtmean(di2000_simul) , weight(hw0010)
bysort sa0100 s_xtile: egen average_di3001_simul_ptile = wtmean(di3001_simul)  , weight(hw0010)


foreach c of global countries{
qui replace average_savings_ptile      = average_savings_ptile/1000      if sa0100 == "`c'"
qui replace average_di3001_simul_ptile = average_di3001_simul_ptile/1000 if sa0100 == "`c'"
qui replace average_di2000_simul_ptile = average_di2000_simul_ptile/1000 if sa0100 == "`c'"

gr bar average_savings_ptile average_di3001_simul_ptile average_di2000_simul_ptile if sa0100=="`c'", over(s_xtile,) blabel(bar,format(%9.0f)) title("`c' Y,C & S over savings rate distribution ") ytitle("Thousand Euros") b1title("HH saving rates deciles") legend(order(1 "Savings" 2 "Consumption" 3 "Income") row(1)) note("average EUR within each decile") name(`c'_savings_consumption_income , replace)
gr export "D:\microsim\results\diagnostics wave 3\Diagnostics Consumption\ Savings_Income_Consumption_vs_savingsrates_`c'.png", replace 
}


********************************************************************************
* Figure 5) Composition of aggregate Income, Consumption and debt services
* The goal of this picture is to show what party has increased/decreased more 
* in aggregate terms to drive changes in the aggregate saving rate. 
********************************************************************************
qui drop Agg_*
qui gen Agg_di2000           = .                                                        // Aggregate Income 
qui gen Agg_di2000_simul     = .               
qui gen Agg_di3001_neg       = .                                                        // Aggregate consumption 
qui gen Agg_di3001_simul_neg = . 
*gen Agg_dl2000_neg       = .                                                        // Aggregate debt 
*gen Agg_dl2000_simul_neg = . 

foreach c of global countries{
* Wave 2 
qui sum di2000 [aw=hw0010]                     if sa0100 == "`c'", d
qui replace Agg_di2000 = r(sum)                if sa0100 == "`c'" 

qui sum di3001 [aw=hw0010]                     if sa0100 == "`c'", d
qui replace Agg_di3001_neg = -r(sum)           if sa0100 == "`c'"

*qui sum dl2000 [aw=hw0010]                     if sa0100 == "`c'", d           
*qui replace Agg_dl2000_neg = -r(sum)*12        if sa0100 == "`c'"               // multiply by 12 months 


* Simulated Wave 3 
qui sum di2000_simul [aw=hw0010]               if sa0100 == "`c'", d
qui replace Agg_di2000_simul = r(sum)          if sa0100 == "`c'"

qui sum di3001_simul [aw=hw0010]               if sa0100 == "`c'",d
qui replace Agg_di3001_simul_neg = -r(sum)     if sa0100 == "`c'"

*qui sum dl2000_simul [aw=hw0010]               if sa0100 == "`c'",d
*qui replace Agg_dl2000_simul_neg = -r(sum)*12  if sa0100 == "`c'"               // multiply by 12 months
}

* Collapse and reshape to create the final figure
preserve 
collapse Agg_di2000 Agg_di3001_neg Agg_di2000_simul Agg_di3001_simul_neg , by(sa0100)

* Change names to reshape: 
rename Agg_di2000           Agg_di20001
rename Agg_di2000_simul     Agg_di20002
rename Agg_di3001_neg       Agg_di30011
rename Agg_di3001_simul_neg Agg_di30012
*rename Agg_dl2000_neg       Agg_dl20001
*rename Agg_dl2000_simul_neg Agg_dl20002

reshape long Agg_di2000 Agg_di3001, i(sa0100)                        // reshape 
label define _j 1 "W2" 2 "Simul W3"
label values _j _j
gr bar Agg_di2000 Agg_di3001, over(_j, label(labsize(*0.5))) over(sa0100) stack legend(row(1) order(1 "Income" 2 "Consumption")) ytitle("EUR") title("Composition of Agg Saving Rate") name(comp_s, replace)
gr export "D:\microsim\results\diagnostics wave 3\Diagnostics Consumption\Composition_Agg_saving_rate_by_country.png", replace
restore



********************************************************************************
*  FIGURE 6. Joint distribution of savings and Income 
********************************************************************************

foreach c of global countries{
preserve
keep if sa0100 == "`c'"

xtile di2000_simul_xtile = di2000_simul [pw=hw0010], n(10)
gen  savings_flow_w3_simul2 = savings_flow_w3_simul  

collapse (median) savings_flow_w3_simul2 di3001_simul di2000_simul [aw=hw0010], by(di2000_simul_xtile)

gr bar savings_flow_w3_simul di3001_simul di2000_simul, over(di2000_simul_xtile) legend(row(1) order(1 "Savings" 2 "Consumption" 3 "Income")) title(" `c' 1-year savings along income distribution") b1title("Income deciles") name(`c'_inc_c, replace)
gr export "D:/microsim/results/diagnostics wave 3/Diagnostics Consumption/savings_income_distribution_`c'.png", replace
restore 
}



********************************************************************************
*  FIGURE 7. Joing Distribution of cbar and ybar 
********************************************************************************
foreach c of global countries{
preserve
keep if sa0100 == "`c'"

tw (kdensity ybar [aw=hw0010] if inrange(ybar,-2000,2000)) || (kdensity cbar [aw=hw0010] if inrange(cbar,-2000,2000)), legend(row(1) order(1 "ybar" 2 "cbar")) title("`c' 2014-2017 average change")

gr export "D:/microsim/results/diagnostics wave 3/Diagnostics Consumption/cbar_ybar_distributions_`c'.png", replace
restore 

}











