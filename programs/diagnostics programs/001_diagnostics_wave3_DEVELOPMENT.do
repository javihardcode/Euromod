* 
* Create diagnostics Wave 2, Wave 3 and Simulated Wave 3 
* Reference to OECD chart on hh savings: https://data.oecd.org/hha/household-savings.htm#indicator-chart 

* 1.  Open Wave 2 and Simulated Wave 3:
* 2.  Open Wave 3 
* 3.   Charts 


* Set Path for results: 
*global diagnosticsPath "P:\ECB business areas\DGR\Databases and Programme files\DGR\Javier Ramos\microsim\1_0_2\diagnostics"
global diagnosticsPath "D:\microsim\results\diagnostics wave 3"                                  // use this path for speed at home
graph drop _all 
global countries "DE ES IT FR"


* 1. Open Wave 2 and Simulated Wave 3: 
qui use "$hfcsinputPath/D_compl_MicroSim_$print_ts.dta" , clear
qui keep sa0100 sa0010 im0100 hw0010 di2000 di2000_simul da2100 da2100_simul da1000 da1000_simul dl1000 dl1000_simul dl1100 dl1100_simul dl1200 dl1200_simul dn3001 dn3001_simul dnnla dnnla_simul da3001 da3001_simul savings_flow_w3_simul di3001 di3001_simul LTV doltvratio new_mort
qui keep if im0100 == 1
qui replace dl1000_simul = . if dl1000_simul == 0                                   // 
qui gen wave = 2
local variables = "di2000 da2100 da1000 dl1000 dl1100 dl1200 dn3001 dnnla da3001 doltvratio"
foreach v of local variables{
qui rename `v' `v'_w2
}

qui save "$hfcsinputPath/diagnostics_w2_simul_w3.dta", replace


* 2. Open wave 3 
qui use "D:\data\hfcs\wave3\DP_extended.dta", clear
qui keep if im0100 == 1 
qui sort sa0100
qui decode sa0100, gen(sa0100_str)
qui drop sa0100
qui rename sa0100_str sa0100
qui keep sa0100 hw0010 di2000 da1000 da1110 da2100 dn3001 dl1200 da3001 dl1000 dl1100 dnnla doltvratio
local variables = "di2000 da1000 da1110 da2100 dn3001 dl1200 da3001 dl1000 dl1100 dnnla doltvratio"
foreach v of local variables{
qui rename `v' `v'_w3
}


qui append using "$hfcsinputPath/diagnostics_w2_simul_w3.dta"
qui rm "$hfcsinputPath/diagnostics_w2_simul_w3.dta" 



foreach c of global countries{

* 1. INCOME di2000
preserve 
qui drop if sa0100 != "`c'"
qui gen ihs_di2000_w2    = asinh(di2000_w2)
qui gen ihs_di2000_w3    = asinh(di2000_w3)
qui gen ihs_di2000_simul = asinh(di2000_simul) 
tw (kdensity ihs_di2000_w2 [aw=hw0010] if ihs_di2000_w2>0)||(kdensity ihs_di2000_w3 [aw=hw0010] if ihs_di2000_w3>0)||(kdensity ihs_di2000_simul [aw=hw0010] if ihs_di2000_simul>0), legend(order(1 "Wave 2" 2 "Wave 3" 3 "Simulated Wave 3") row(1)) title("Gross Income: di2000") name(di2000_`c') nodraw
restore


* 2. REAL ASSETS da1000
preserve 
qui drop if sa0100 != "`c'"
qui gen ihs_da1000_w2    = asinh(da1000_w2)
qui gen ihs_da1000_w3    = asinh(da1000_w3)
qui gen ihs_da1000_simul = asinh(da1000_simul) 
tw (kdensity ihs_da1000_w2 [aw=hw0010])||(kdensity ihs_da1000_w3 [aw=hw0010])||(kdensity ihs_da1000_simul [aw=hw0010]), legend(order(1 "Wave 2" 2 "Wave 3" 3 "Simulated Wave 3") row(1)) title("Real Assets: da1000") name(da1000_`c') nodraw
restore

* 3. FINANCIAL ASSETS da2100
preserve 
qui drop if sa0100 != "`c'"
qui gen ihs_da2100_w2    = asinh(da2100_w2)
qui gen ihs_da2100_w3    = asinh(da2100_w3)
qui gen ihs_da2100_simul = asinh(da2100_simul) 
tw (kdensity ihs_da2100_w2 [aw=hw0010])||(kdensity ihs_da2100_w3 [aw=hw0010])||(kdensity ihs_da2100_simul [aw=hw0010]), legend(order(1 "Wave 2" 2 "Wave 3" 3 "Simulated Wave 3") row(1)) title("Financial Assets: da2100") note("Includes savings!!") name(da2100_`c') nodraw
restore

* 4. MORTGAGE DEBT dl1100 
preserve 
drop if sa0100 != "`c'"
qui gen ihs_dl1100_w2    = asinh(dl1100_w2)
qui gen ihs_dl1100_w3    = asinh(dl1100_w3)
qui gen ihs_dl1100_simul = asinh(dl1100_simul) 
tw (kdensity ihs_dl1100_w2 [aw=hw0010])||(kdensity ihs_dl1100_w3 [aw=hw0010])||(kdensity ihs_dl1100_simul [aw=hw0010]), legend(order(1 "Wave 2" 2 "Wave 3" 3 "Simulated Wave 3") row(1)) title("Mortgage Debt: dl1100") name(dl1100_`c') nodraw
restore


* 5. NON-MORTGAGE DEBT dl1200
preserve 
qui drop if sa0100 != "`c'"
qui gen ihs_dl1200_w2    = asinh(dl1200_w2)
qui gen ihs_dl1200_w3    = asinh(dl1200_w3)
qui gen ihs_dl1200_simul = asinh(dl1200_simul) 
tw (kdensity ihs_dl1200_w2 [aw=hw0010])||(kdensity ihs_dl1200_w3 [aw=hw0010])||(kdensity ihs_dl1200_simul [aw=hw0010]), legend(order(1 "Wave 2" 2 "Wave 3" 3 "Simulated Wave 3") row(1)) title("Non-Mortgage Debt: dl1200") note("Includes negative positions from consumption simulation") name(dl1200_`c') nodraw
restore

* 6. Net Assets dn3001
preserve 
qui drop if sa0100 != "`c'"
qui gen ihs_dn3001_w2    = asinh(dn3001_w2)
qui gen ihs_dn3001_w3    = asinh(dn3001_w3)
qui gen ihs_dn3001_simul = asinh(dn3001_simul) 
tw (kdensity ihs_dn3001_w2 [aw=hw0010])||(kdensity ihs_dn3001_w3 [aw=hw0010])||(kdensity ihs_dn3001_simul [aw=hw0010]), legend(order(1 "Wave 2" 2 "Wave 3" 3 "Simulated Wave 3") row(1)) title("Net Assets: dn3001") name(dn3001_`c') nodraw
restore

* 7. Net Liquid Assets dnnla
preserve 
qui drop if sa0100 != "`c'"
qui gen ihs_dnnla_w2    = asinh(dnnla_w2)
qui gen ihs_dnnla_w3    = asinh(dnnla_w3)
qui gen ihs_dnnla_simul = asinh(dnnla_simul) 
tw (kdensity ihs_dnnla_w2 [aw=hw0010])||(kdensity ihs_dnnla_w3 [aw=hw0010])||(kdensity ihs_dnnla_simul [aw=hw0010]), legend(order(1 "Wave 2" 2 "Wave 3" 3 "Simulated Wave 3") row(1)) title("Net Liquid Assets: dnnla") name(dnnla_`c') nodraw
restore

* 8. Consumption di3001
preserve 
qui drop if sa0100 != "`c'"
qui gen ihs_di3001    = asinh(di3001)
qui gen ihs_di3001_simul = asinh(di3001_simul) 
tw (kdensity ihs_di3001 [aw=hw0010])||(kdensity ihs_di3001_simul [aw=hw0010]), legend(order(1 "Wave 2" 2 "Simulated Wave 3") row(1)) title("Consumption: di3001") name(di3001_`c') nodraw
restore

}








********************************************************************************
*  Charts on macroeconomic changes 
********************************************************************************

foreach c of global countries {

* 1. INCOME UPDATE - MACRO SERIES: WagesPC, B2B3, D41, D75_C, Unemployment Target
qui gen WagesPC_growth_`c' = (di1100_simul_growth_`c' - 1)*100
qui gen B2B3_growth_`c'    = (di1200_simul_growth_`c'	- 1)*100
qui gen D41_growth_`c'	   = (di1400_growth_`c' - 1)*100
qui gen D75_C_growth_`c'   = (di1700_growth_`c' - 1)*100
qui gen UTarget_`c' = (Scale_deltaU_T_`c')

gr bar WagesPC_growth_`c' B2B3_growth_`c' D41_growth_`c' D75_C_growth_`c' UTarget_`c', bargap(90) blabel(bar, format(%4.1f)) legend(order(1 "Wages, salaries" 2 "Operating surplus, mixed inc." 3 "Interests" 4 "Misc. Current Transfers" 5 "Unemployment (% pts)")) title("Macro series (change wave 2 to 3, in %)") name(`c'_di2000_macro) nodraw


* 2. REAL ASSETS - MACRO SERIES: RPP, HICP, USOE_D
qui gen RPP_growth_`c'    = (da1110_growth_`c' - 1)*100                         // RPP 
qui gen HICP_growth_`c'   = (da1130_growth_`c' - 1)*100                         // HICP 
qui gen Stock_growth_`c'  = (da1140_growth_`c' - 1)*100                         // Stock 
qui sum new_mort [aw=hw0010] 
qui gen new_mort_share_`c' = r(mean)*100 

gr bar RPP_growth_`c' HICP_growth_`c' Stock_growth_`c' new_mort_share_`c', bargap(90) blabel(bar, format(%4.1f)) legend(order(1 "RPP" 2 "HICP" 3 "Stock Market Index" 4 "New mortgages ") row(2)) title("Macro series (change wave 2 to 3, in %)") name(`c'_da1000_macro) nodraw


* 3. FINANCIAL ASSETS - MACRO SERIES: Stock, ZCB, F6, Aggregate saving rate, household saving rate 
qui gen ZCB_growth_`c'   = (da2103_growth_`c' - 1)*100                          // zero cupon bond 
qui gen F6_growth_`c'    = (da2109_growth_`c' - 1)*100                          

qui sum di2000_simul [aw=hw0010] if sa0100 == "`c'", d                          // Aggregate saving rate 
sca Agg_Income_`c' = r(sum)       
qui sum savings_flow_w3_simul [aw=hw0010] if sa0100 == "`c'",d
sca Agg_Savings_`c' = r(sum)
qui gen saving_rate_`c' = 100*(Agg_Savings_`c' / Agg_Income_`c') if sa0100 == "`c'"

qui gen hh_saving_rate_`c' = savings_flow_w3_simul / di2000_simul if sa0100=="`c'"  // Compute average hh saving rate
qui sum hh_saving_rate_`c' [aw=hw0010] if inrange(hh_saving_rate_`c',-1,1) & sa0100=="`c'",d 
qui gen mean_hh_s_rate_`c' = 100*(r(mean))     

gr bar Stock_growth_`c' ZCB_growth_`c' HICP_growth_`c' saving_rate_`c' mean_hh_s_rate_`c', bargap(90) blabel(bar, format(%4.1f)) legend(order(1 "Stock Market" 2 "ZCB" 3 "Insurance" 4 "Agg. Saving Rate" 5 "HH Saving Rate")) title("") note("Saving rates are cross-sectional rates.") name(`c'_da2100_macro) nodraw


* 4. MORTGAGE DEBT - MACRO SERIES: IntRH_all, LTV, ratio new-to-old mortgages
qui gen IntRH_all_`c'   = (dl1110_growth_`c')                                   // Change in interest pp                            
qui sum LTV [aw=hw0010] if sa0100 == "`c'"                          
qui gen mean_LTV_simul_`c' = r(mean)*100                                        // Average LTV simulation 
qui sum doltvratio_w3   if inrange(doltvratio_w3,0,1) & sa0100 == "`c'"
qui gen mean_LTV_`c' = r(mean)*100                   if sa0100 == "`c'"         // Average LTV data (Wave 3)                 
qui gen ratio_new_old_mortgage_`c' = Scale_Mort_`c'                             // Ratio new to old mortgages


gr bar IntRH_all_`c' mean_LTV_simul_`c' mean_LTV_`c' ratio_new_old_mortgage_`c', bargap(90) blabel(bar, format(%4.1f)) legend(order(1 "Change int." 2 "LTV simul" 3 "LTV data" 4 "New-to-Old Agg.mort") row(2)) title("") name(`c'_dl1000_macro) nodraw


* 5. NON-MORTGAGE DEBT: Agg Saving Rate, household saving rate, P31_Growth  
qui gen P31_growth_`c' = (P31_growth_`c'-1)*100

gr bar saving_rate_`c' mean_hh_s_rate_`c' P31_growth_`c', bargap(90) blabel(bar, format(%4.1f)) legend(order(1 "Agg. S rate" 2 "HH S rate" 3 "Consumption Growth") row(1)) title("") name(`c'_dl1200_macro) nodraw


* 6. NET ASSETS 


* 7. NET LIQUID ASSETS: WagesPC, Agg. Saving rate, HH S rate, P31_Growth, IntRH_all 
gr bar WagesPC_growth_`c' saving_rate_`c' mean_hh_s_rate_`c' P31_growth_`c' IntRH_all_`c', bargap(90) blabel(bar, format(%4.1f)) legend(order(1 "Wages" 2 "Agg. S rate" 3 "HH S rate" 4 "Consumption Growth" 5 "Interests")) title("") name(`c'_dnnla_macro) nodraw


* 8. CONUSMPTION; P31_Growth SDW, C growth data, % people whose consumptio decreases  
qui sum     di3001 [aw=hw0010] if sa0100 == "`c'"                               // Agg.Consumption growth data 
sca     Agg_di3001_`c' = r(sum)
qui sum     di3001_simul [aw=hw0010] if sa0100 == "`c'"                         // Agg.Consumption growth data 
sca     Agg_di3001_simul_`c' = r(sum) 
qui gen Agg_di3001_growt_`c' = 100*(Agg_di3001_simul_`c'-Agg_di3001_`c')/Agg_di3001_`c' if sa0100 == "`c'"

qui gen di3001_decreases_`c' = (di3001_simul < di3001) 
qui sum di3001_decreases_`c' [aw=hw0010] 
qui replace di3001_decreases_`c' = 100*r(mean) if sa0100 == "`c'" 

gr bar P31_growth_`c' Agg_di3001_growt_`c' di3001_decreases_`c', blabel(bar, format(%4.1f)) legend(row(1) order(1 "Agg. C growth SDW" 2 "Agg. C growth data" 3 "% ppl less C")) title("") bargap(90) note("SDW bar is a validity check. Compare SDW to data.") name(`c'_di3001_macro) nodraw

}


********************************************************************************
*             Create the panels 
********************************************************************************

foreach c of global countries{

* PANEL 1/3
gr combine di2000_`c' `c'_di2000_macro da1000_`c' `c'_da1000_macro da2100_`c' `c'_da2100_macro , col(2) row(3) title("`c' Diagnostics Wave 3 1/3") iscale(0.4) imargin(5 5 5 5) 
qui graph export "$diagnosticsPath\ `c'_Diagnostics_Histograms_1.png", replace

* PANEL 2/3
gr combine dl1100_`c' `c'_dl1000_macro dl1200_`c' `c'_dl1200_macro di3001_`c' `c'_di3001_macro, col(2) row(3) title("`c' Diagnostics Wave 3 2/3") iscale(0.4) imargin(5 5 5 5)
qui graph export "$diagnosticsPath\ `c'_Diagnostics_Histograms_2.png", replace


* PANEL 3/3
gr combine dn3001_`c' dnnla_`c' `c'_dnnla_macro, hole(2)  col(2) row(3) title("`c' Diagnostics Wave 3 3/3") iscale(0.4) imargin(5 5 5 5)
qui graph export "$diagnosticsPath\ `c'_Diagnostics_Histograms_3.png", replace

}


















