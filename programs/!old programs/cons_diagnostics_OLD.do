* 
* Consumption Diagnostics __ OLD  
* 09-11-2021 Javier Ramos Perez (DGR)

* Charts are saved on P:\ECB business areas\DGR\Databases and Programme files\DGR\Javier Ramos\microsim\1_0_2\diagnostics\diagnostics_cons
* Important Variables: 
* di2000                                                                        // hh income
* di3001_w2                                                                     // estimated chat   Wave2 
* di3001_c_w2                                                                   // estimated chat_c Wave2
* di3001_w3                                                                     // estimated chat   Wave3 
* di3001_c_w3                                                                   // estimated chat_c Wave2 
* ccbar                                                                         // between waves consumption change 
* cbar_c                                                                        // between waves consumption change
* savings                                                                       // simulated wave 3 savings
* savings_c                                                                     // simulated wave 3 savings
* da2100_savings                                                                // implied financial assets + savings
* da2100_savings_c                                                              // implied financial assets + savings

* Additionally, I compute the cross sectional saving rate: Income_Simulated_W3 - Consumption_Simulated_Wave_3 
* savings_w3                                                                     // Gross Savings Simulated Wave 3

*********************************************************************************
adopath + "D:/stata/ado"
set scheme ecb2015

* Open Simulated Data: 
*use "$resultPath/D_compl_MicroSim_$print_ts.dta", clear                         // P:
use "$hfcsinputPath/D_compl_MicroSim_$print_ts.dta", replace                   // save locally 


* Generate cross-sectional savings using the definition;

* Generate gross cross sectional savings: 
gen savings_w3    = di2000 - di3001_w3                                          // WARNING: Issue: 266 observations has negative income with very high (negative) value

********************************************************************************
* Temporal change just to avoid writting everything, label drop savings, and label savings flow as savings
drop savings savings_c 
rename savings_flow_w3 savings 
rename savings_flow_w3_c savings_c
********************************************************************************


********************************************************************************
* Saving Rates
********************************************************************************
* Generate saving rates 
gen saving_rate    = .
gen saving_rate_c  = . 
gen saving_rate_w3 = .    
foreach ctry of global ctrylist {
     replace saving_rate    = savings   /  di2000 if sa0100=="`ctry'"           // pay a lot of attention here !!!!!!!!!!!!
	 replace saving_rate_c  = savings_c /  di2000 if sa0100=="`ctry'"           // pay a lot of attention here !!!!!!!!!!!!
	 replace saving_rate_w3 = savings_w3 / di2000 if sa0100=="`ctry'"           // pay a lot of attention here !!!!!!!!!!!!
	 
} 

* Count Outliers for each saving rate:
bysort sa0100: count if !inrange(saving_rate,   - 1.49, 0.99)
bysort sa0100: count if !inrange(saving_rate_c, - 1.49, 0.99)
bysort sa0100: count if !inrange(saving_rate_w3, -1.49, 0.99)

* Summarize Saving Rates: 
sum saving_rate   [aw=hw0010] if inrange(saving_rate, -1.5, 1)   , d
sum saving_rate_c [aw=hw0010] if inrange(saving_rate_c, -1.5, 1) , d
sum saving_rate_w3 [aw=hw0010] if inrange(saving_rate_w3, -1.5, 1) , d


* Create Aggregate (European) Diagnostics
preserve 
*keep if sa0100 == "ES"
* Figure 1: Saving Rates Histogram:
tw (hist saving_rate if inrange(saving_rate, -1.5,1), color(blue%30))||(hist saving_rate_c if inrange(saving_rate_c, -1.5,1), color(red%30))||(hist saving_rate_w3 if inrange(saving_rate_w3, -1.5,1), color(green%30)) , title("Saving Rate", size(small)) legend(row(1)size(vvsmall) label(1 "Lamarche 2017") label(2 "Crossley 2019") label(3 "Gross s")) note("Data truncated at -1.5 and 1" , size(vsmall)) xtitle("") ytitle("") name(Figure1,replace) 
graph export "P:\ECB business areas\DGR\Databases and Programme files\DGR\Javier Ramos\microsim\1_0_2\diagnostics\diagnostics_cons\s_hist.png", replace 
restore

********************************************************************************
* Aggregate Saving
********************************************************************************
preserve
keep if sa0100 == "ES"
* Lamarche 2017 
sum savings [aw=hw0010], d
gen savingss1 = r(p25)                                                          // p25 
gen savingss2 = r(p50)                                                          // p50
gen savingss3 = r(p75)                                                          // p75
gen savingss4 = r(p90)                                                          // p90 
* Crossley 2019 
sum savings_c [aw=hw0010], d
gen savings_cc1 = r(p25) 
gen savings_cc2 = r(p50)
gen savings_cc3 = r(p75)
gen savings_cc4 = r(p90)
* Gross
sum savings_w3 [aw=hw0010], d
gen savings_ww31 = r(p25) 
gen savings_ww32 = r(p50)
gen savings_ww33 = r(p75)
gen savings_ww34 = r(p90)
* Income 
sum di2000 [aw=hw0010], d
gen di2000_01 = r(p25)                                                          // p25 
gen di2000_02 = r(p50)                                                          // p50
gen di2000_03 = r(p75)                                                          // p75
gen di2000_04 = r(p90)                                                          // p90 

* Generate the figure: 
* Collapse
collapse savingss* savings_cc* savings_ww3* di2000_0* 
* Reshape  
gen idd = 1 
reshape long savingss savings_cc savings_ww3 di2000_0, i(idd) j(percentile_group)     // 1 Lamarche, 2 Crossley, 3 Gross saving rate 

* Figure 2: Bar Aggregate Savings
graph bar savingss savings_cc savings_ww3 di2000_0, over(percentile_group, relabel(1 "p25" 2 "p50" 3 "p75" 4 "p90")) title("Aggregate Savings", size(small)) legend(row(2) size(vvsmall) label(1 "Lamarche 2017") label(2 "Crossley 2019") label(3 "Gross Savings") label(4 "Household Income")) blabel(bar, format(%9.0f) size(vvsmall)) name(Figure2,replace) ylabel(,labsize(vsmall))
graph export "P:\ECB business areas\DGR\Databases and Programme files\DGR\Javier Ramos\microsim\1_0_2\diagnostics\diagnostics_cons\S_bar.png", replace 
restore 

********************************************************************************
* Aggregate Consumption chart 
********************************************************************************

preserve 
keep if sa0100 == "ES"
* Lamarche 2017 
sum di3001_w3 [w=hw0010], d  
gen di3001_ww31 = r(p25)                                                         // p25 
gen di3001_ww32 = r(p50)                                                         // p50
gen di3001_ww33 = r(p75)                                                         // p75
gen di3001_ww34 = r(p90)                                                         // p90 

* Crossley 2019 
sum di3001_c_w3 [w=hw0010], d  
gen di3001_c_ww31 = r(p25)                                                      // p25 
gen di3001_c_ww32 = r(p50)                                                      // p50
gen di3001_c_ww33 = r(p75)                                                      // p75
gen di3001_c_ww34 = r(p90)                                                      // p90 

* Generate the figure: 
collapse di3001_ww3* di3001_c_ww3* 
gen idd = 1 
reshape long di3001_ww3 di3001_c_ww3, i(idd) j(percentile_group)     // 1 Lamarche, 2 Crossley, 3 Gross saving rate 

* Figure 3: Bar Aggregate Consumption  
graph bar di3001_ww3 di3001_c_ww3, over(percentile_group,relabel(1 "p25" 2 "p50" 3 "p75" 4 "p90")) legend(size(vsmall) label(1 "Lamarche 2017") label(2 "Crossley 2019")) title("Aggregate Consumption", size(small)) blabel(bar, format(%9.0f) size(vvsmall)) name(Figure3,replace) ylabel(,labsize(vsmall))
graph export "P:\ECB business areas\DGR\Databases and Programme files\DGR\Javier Ramos\microsim\1_0_2\diagnostics\diagnostics_cons\C_bar.png", replace 
restore 

********************************************************************************
* Scatter Saving Rate vs Job After Shock 
********************************************************************************
preserve 
keep if sa0100 == "ES"
* Figure 4: Whiskers plot Job Probability and Saving Rates 
graph box saving_rate [w=hw0010], over(job_aftershock, label(labsize(*0.5))) noout title("Job Probability and Saving Rates", size(small)) note("Saving Rates from Lamarche 2017", size(vsmall)) name(Figure4,replace) ytitle("")
graph export "P:\ECB business areas\DGR\Databases and Programme files\DGR\Javier Ramos\microsim\1_0_2\diagnostics\diagnostics_cons\s_job_whisker.png", replace 
restore

********************************************************************************
* Financial Assets before and After savings 
********************************************************************************
preserve
keep if sa0100 == "ES" 
* Initial Wealth
sum da2100 [w=hw0010], d  
gen da210001 = r(p25)                                                          // p25 
gen da210002 = r(p50)                                                          // p50
gen da210003 = r(p75)                                                          // p75
gen da210004 = r(p90)                                                          // p90 

* Savings Lamarche 2017 
sum savings [aw=hw0010], d
gen savingss1 = r(p25)                                                          // p25 
gen savingss2 = r(p50)                                                          // p50
gen savingss3 = r(p75)                                                          // p75
gen savingss4 = r(p90)

* Generate the figure: 
* Collapse
collapse da21000* savingss*  
* Reshape  
gen idd = 1 
reshape long da21000 savingss, i(idd) j(percentile_group)     // 1 Lamarche, 2 Crossley, 3 Gross saving rate 

* Figure 5: Bar Financial Assets and Savings  
graph bar da21000 savingss, stack over(percentile_group,relabel(1 "p25" 2 "p50" 3 "p75" 4 "p90")) legend(size(vsmall) label(1 "W2 Financial Wealth") label(2 "Savings")) title("Total Financial Wealth", size(small)) blabel(bar, format(%9.0f) size(vvsmall)) ytitle("") name(Figure5,replace) ylabel(,labsize(vsmall))
graph export "P:\ECB business areas\DGR\Databases and Programme files\DGR\Javier Ramos\microsim\1_0_2\diagnostics\diagnostics_cons\Financial_Assets_savings_bar.png", replace 
restore 

********************************************************************************
* Interesting Numbers: C_growth, Saving Rates 
********************************************************************************
preserve
keep if sa0100 == "ES"

* Consumption growth Rate  
gen growth_c = (P31_growth_ES-1)*100 

* Median Lamarche 2017 saving Rate 
sum saving_rate [aw=hw0010]if inrange(saving_rate, -1.5, 1) ,d
gen median_savingrate = r(mean)*100

* Median Crossley 2019 Saving Rate 
sum saving_rate_c [aw=hw0010] if inrange(saving_rate, -1.5, 1),d
gen median_savingrate_c = r(mean)*100

* Median gross Saving Rate 
sum saving_rate_w3 [aw=hw0010] if inrange(saving_rate, -1.5, 1),d
gen median_savingrate_w3 = r(mean)*100

graph bar growth_c median_savingrate  median_savingrate_c median_savingrate_w3 , legend( size(vvsmall) label(1 "C Growth Rate") label(2 "S Rate Lamarche 2017") label(3 "S Rate Crossley 2019") label(4 "S Rate Gross")) bargap(70) note("") blabel(bar, format(%9.1f)) title("Interesting Numbers", size(small)) name(Figure6,replace)
graph export "P:\ECB business areas\DGR\Databases and Programme files\DGR\Javier Ramos\microsim\1_0_2\diagnostics\diagnostics_cons\Interesting_Numbers.png", replace 

restore 

********************************************************************************
* Combine the six files and save
graph combine Figure1 Figure2 Figure3 Figure4 Figure5 Figure6, title("ES Consumption Diagnostics") row(2)
graph export "P:\ECB business areas\DGR\Databases and Programme files\DGR\Javier Ramos\microsim\1_0_2\diagnostics\diagnostics_cons\EU_Cons_Diagnostics.png", replace 












********************************************************************************
********************************************************************************
********************************************************************************

* Create Country by Country Diagnostics: 

********************************************************************************
********************************************************************************
********************************************************************************

foreach ii of global ctrylist {

preserve 
keep if sa0100 == "`ii'"
* Figure 1: Saving Rates Histogram:
tw (hist saving_rate if inrange(saving_rate, -1.5,1), color(blue%30))||(hist saving_rate_c if inrange(saving_rate_c, -1.5,1), color(red%30))||(hist saving_rate_w3 if inrange(saving_rate_w3, -1.5,1), color(green%30)) , title("Saving Rate", size(small)) legend(row(1)size(vvsmall) label(1 "Lamarche 2017") label(2 "Crossley 2019") label(3 "Gross s")) note("Data truncated at -1.5 and 1" , size(vsmall)) xtitle("") ytitle("") name(Figure1,replace) 
graph export "P:\ECB business areas\DGR\Databases and Programme files\DGR\Javier Ramos\microsim\1_0_2\diagnostics\diagnostics_cons\`ii'_s_hist.png", replace 
restore

********************************************************************************
* Aggregate Saving
********************************************************************************
preserve
keep if sa0100 == "`ii'"
* Lamarche 2017 
sum savings [aw=hw0010], d
gen savingss1 = r(p25)                                                          // p25 
gen savingss2 = r(p50)                                                          // p50
gen savingss3 = r(p75)                                                          // p75
gen savingss4 = r(p90)                                                          // p90 
* Crossley 2019 
sum savings_c [aw=hw0010], d
gen savings_cc1 = r(p25) 
gen savings_cc2 = r(p50)
gen savings_cc3 = r(p75)
gen savings_cc4 = r(p90)
* Gross
sum savings_w3 [aw=hw0010], d
gen savings_ww31 = r(p25) 
gen savings_ww32 = r(p50)
gen savings_ww33 = r(p75)
gen savings_ww34 = r(p90)
* Income 
sum di2000 [aw=hw0010], d
gen di2000_01 = r(p25)                                                          // p25 
gen di2000_02 = r(p50)                                                          // p50
gen di2000_03 = r(p75)                                                          // p75
gen di2000_04 = r(p90)                                                          // p90

* Generate the figure: 
* Collapse
collapse savingss* savings_cc* savings_ww3* di2000_0* 
* Reshape  
gen idd = 1 
reshape long savingss savings_cc savings_ww3 di2000_0, i(idd) j(percentile_group)     // 1 Lamarche, 2 Crossley, 3 Gross saving rate 

* Figure 2: Bar Aggregate Savings
graph bar savingss savings_cc savings_ww3 di2000_0, over(percentile_group, relabel(1 "p25" 2 "p50" 3 "p75" 4 "p90")) title("Aggregate Savings", size(small)) legend(row(1) size(vvsmall) label(1 "Lamarche 2017") label(2 "Crossley 2019") label(3 "Gross Savings") label(4 "Household Income")) blabel(bar, format(%9.0f) size(vvsmall)) name(Figure2,replace) ylabel(,labsize(vsmall))
graph export "P:\ECB business areas\DGR\Databases and Programme files\DGR\Javier Ramos\microsim\1_0_2\diagnostics\diagnostics_cons\`ii'_S_bar.png", replace 
restore 

********************************************************************************
* Aggregate Consumption
********************************************************************************
preserve 
keep if sa0100 == "`ii'"
* Lamarche 2017 
sum di3001_w3 [w=hw0010], d  
gen di3001_ww31 = r(p25)                                                          // p25 
gen di3001_ww32 = r(p50)                                                          // p50
gen di3001_ww33 = r(p75)                                                          // p75
gen di3001_ww34 = r(p90)                                                          // p90 

* Crossley 2019 
sum di3001_c_w3 [w=hw0010], d  
gen di3001_c_ww31 = r(p25)                                                      // p25 
gen di3001_c_ww32 = r(p50)                                                      // p50
gen di3001_c_ww33 = r(p75)                                                      // p75
gen di3001_c_ww34 = r(p90)                                                      // p90 

* Generate the figure: 
* Collapse
collapse di3001_ww3* di3001_c_ww3* 
* Reshape  
gen idd = 1 
reshape long di3001_ww3 di3001_c_ww3, i(idd) j(percentile_group)     // 1 Lamarche, 2 Crossley, 3 Gross saving rate 

* Figure 3: Bar Aggregate Consumption  
graph bar di3001_ww3 di3001_c_ww3, over(percentile_group,relabel(1 "p25" 2 "p50" 3 "p75" 4 "p90")) legend(size(vsmall) label(1 "Lamarche 2017") label(2 "Crossley 2019")) title("Aggregate Consumption", size(small)) blabel(bar, format(%9.0f) size(vvsmall)) name(Figure3,replace) ylabel(,labsize(vsmall))
graph export "P:\ECB business areas\DGR\Databases and Programme files\DGR\Javier Ramos\microsim\1_0_2\diagnostics\diagnostics_cons\`ii'_C_bar.png", replace 
restore 

********************************************************************************
* Scatter Saving Rate vs Job After Shock 
********************************************************************************
preserve 
keep if sa0100 == "`ii'"
* Figure 4: Whiskers plot Job Probability and Saving Rates 
graph box saving_rate [w=hw0010], over(job_aftershock, label(labsize(*0.5))) noout title("Job Probability and Saving Rates", size(small)) note("Saving Rates from Lamarche 2017", size(vsmall)) name(Figure4,replace) ytitle("")
graph export "P:\ECB business areas\DGR\Databases and Programme files\DGR\Javier Ramos\microsim\1_0_2\diagnostics\diagnostics_cons\`ii'_s_job_whisker.png", replace 
restore

********************************************************************************
* Financial Assets before and After savings 
********************************************************************************
preserve
keep if sa0100 == "`ii'" 
* Initial Wealth
sum da2100 [w=hw0010], d  
gen da210001 = r(p25)                                                          // p25 
gen da210002 = r(p50)                                                          // p50
gen da210003 = r(p75)                                                          // p75
gen da210004 = r(p90)                                                          // p90 

* Savings Lamarche 2017 
sum savings [aw=hw0010], d
gen savingss1 = r(p25)                                                          // p25 
gen savingss2 = r(p50)                                                          // p50
gen savingss3 = r(p75)                                                          // p75
gen savingss4 = r(p90)

* Generate the figure: 
* Collapse
collapse da21000* savingss*  
* Reshape  
gen idd = 1 
reshape long da21000 savingss, i(idd) j(percentile_group)     // 1 Lamarche, 2 Crossley, 3 Gross saving rate 

* Figure 5: Bar Financial Assets and Savings  
graph bar da21000 savingss, stack over(percentile_group,relabel(1 "p25" 2 "p50" 3 "p75" 4 "p90")) legend(size(vsmall) label(1 "W2 Financial Wealth") label(2 "Savings")) title("Total Financial Wealth", size(small)) blabel(bar, format(%9.0f) size(vvsmall)) ytitle("") name(Figure5,replace) ylabel(,labsize(vsmall))
graph export "P:\ECB business areas\DGR\Databases and Programme files\DGR\Javier Ramos\microsim\1_0_2\diagnostics\diagnostics_cons\`ii'_Financial_Assets_savings_bar.png", replace 
restore 

********************************************************************************
* Interesting Numbers: C_growth, Saving Rates 
********************************************************************************
preserve
keep if sa0100 == "`ii'"

* Consumption growth Rate, Wages growth rate, Interests   
gen growth_c = (P31_growth_`ii'-1)*100                                          // Consumption growth *******************************************
gen growth_w = (di1100_growth_`ii'-1)*100                                       // Wages growth 
gen growth_financial = (D41_growth_`ii'-1)*100                                  // Financial Income growth 

* Median Lamarche 2017 saving Rate 
sum saving_rate [aw=hw0010]if inrange(saving_rate, -1.5, 1) ,d
gen median_savingrate = r(p50)*100

* Median Crossley 2019 Saving Rate 
sum saving_rate_c [aw=hw0010] if inrange(saving_rate, -1.5, 1),d
gen median_savingrate_c = r(p50)*100

* Median gross Saving Rate 
sum saving_rate_w3 [aw=hw0010] if inrange(saving_rate, -1.5, 1),d
gen median_savingrate_w3 = r(p50)*100

graph bar growth_c growth_w growth_financial median_savingrate  median_savingrate_c median_savingrate_w3 , legend( size(vvsmall) label(1 "C Growth Rate") label(2 "W Growth Rate") label(3 "Financial Inc Growth") label(4 "S Rate Lamarche 2017") label(5 "S Rate Crossley 2019") label(6 "S Rate Gross")) bargap(70) note("") blabel(bar, format(%9.1f)) title("Interesting Numbers", size(small)) name(Figure6,replace)
graph export "P:\ECB business areas\DGR\Databases and Programme files\DGR\Javier Ramos\microsim\1_0_2\diagnostics\diagnostics_cons\`ii'_Interesting_Numbers.png", replace 

restore 

********************************************************************************
* Combine the six files and save
graph combine Figure1 Figure2 Figure3 Figure4 Figure5 Figure6, title("`ii' Consumption Diagnostics") row(2)
graph export "P:\ECB business areas\DGR\Databases and Programme files\DGR\Javier Ramos\microsim\1_0_2\diagnostics\diagnostics_cons\Cons_Diagnostics_`ii'.png", replace 


* Drop gaphs from memory for Next Iteration
graph drop _all 
}





















