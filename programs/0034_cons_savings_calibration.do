* Consumption update base wave to targeted wave:



* 1) For each country, compute aggregage consumption growth rate btw w1 and w2

* Load consumption growth rates
qui use "$dataoutputPath/P31_ALL.dta", clear                                    

* For each country, compute aggregage consumption growth rate btw w1 and w2
foreach ctry of global ctrylist {
 sca P31_growth_`ctry' = P31_`ctry'[end_q_ass_`ctry'_n]/P31_`ctry'[start_q_ass_`ctry'_n]
 di "Agg. Consumption Growth Rate `ctry':"  100*(P31_growth_`ctry' -1)  "%"
 * 1) Rewrite to year frequency
 qui replace P31_`ctry' = 4*P31_`ctry'
 * 2) Save scalar with the quantity in Wave 2 and Wave 3
 sca Aggregate_C_w2_`ctry' = P31_`ctry'[start_q_ass_`ctry'_n]                         
 sca Aggregate_C_w3_`ctry' = P31_`ctry'[end_q_ass_`ctry'_n]
}


********************************************************************************
* 2.1: compute ratio D41/F2M quarter by quarter to obtain r* in each quarter
* 2.2 Compute r* as scalars  
********************************************************************************
qui use PERIOD_NAME D41* using "$basePath/data/macrodata/asset_macro_data_ALL.dta", clear

* Merge with Currency and Deposits data
qui merge 1:1 PERIOD_NAME using "$basePath/data/macrodata/CurrencyDeposits_ALL.dta", keepusing(PERIOD_NAME F2M_*)
qui drop if _merge !=3
qui drop _merge
* 3.2 Interest on deposits                                          
foreach c of global ctrylist { 
qui gen deposit_return_`c' =  D41_`c' / F2M_`c'
sca deposit_return_`c' = 100*(D41_`c' / F2M_`c')                                // Returns on deposits computed from aggregate data. 
di "Agg. Deposits returns `c':" deposit_return_`c' "%"
}

* Create the quarterly return for each country: 
foreach c of global ctrylist { 
forval t = 1/`=sim_q_ass_`c'_n' {
sca r_`c'_`t' = deposit_return_`c'[start_q_ass_`c'_n + `t' -1]                  // Returns in each simulated quarter
di "Agg. return `c' in Q`t'" 100* r_`c'_`t' "%"
}
}



********************************************************************************
* 3. CALIBRATE THE MODEL 
********************************************************************************

* Open Chat_ALL1.dta and merge with Wave 2 to obtain data on income and payments: 
qui use "$hfcsinputPath/Chat_ALL1.dta", clear
merge 1:1 sa0100 sa0010 id using "$hfcsinputPath/d_complete.dta"            // 100% matched: HR & LT unmatched
qui keep sa0010 sa0100 im0100 id di3000 di3000_c di2000 dl2000 di2000_net hw0010 hi0200    // Keep total Income, Consumption and debt payments 

* Now merge with di3001_simul from cons_imputation_simul_w3.do: 
merge 1:1 sa0100 sa0010 id using "$hfcsinputPath/Chat_ALL1_wave_simul.dta"     // 100% matched: HR & LT unmatched
qui keep sa0010 sa0100 im0100 id di3000 di3000_simul di3000_c di3000_c_simul di2000 di2000_net di2000_simul di2000_simul_net  dl2000 hw0010 hi0200 // Keep total Income, Consumption and debt payments 
qui sort sa0100 

qui gen di3001       = . 
qui gen di3001_simul = .
qui gen lambda       = . 
qui gen lambda_simul = . 
 foreach ii of global ctrylist{

 **************  Calibrate C distribution Baseline wave    ****************************

* 1. compute consumption & net-income deciles for di3001 and country 
qui xtile di3000_xtile_`ii'     = di3000     [aw=hw0010] if sa0100 == "`ii'", nq($numqj)

if "$UseIncDist" == "1" {
qui xtile di2000_net_xtile_`ii' = di2000_net [aw=hw0010] if sa0100 == "`ii'", nq($numqk) 
}

if "$UseIncDist" == "0" {
qui gen di2000_net_xtile_`ii' = 1                    if sa0100 == "`ii'"
}


* 2. compute agg di3001 for each deciles (cons & income) and country 
forval k = 1/$numqk{
forval j = 1/$numqj{
qui sum di3000 [aw=hw0010] if di3000_xtile_`ii' == `j' & di2000_net_xtile_`ii' == `k' & sa0100 == "`ii'",d     // agg cons across quintiles 
sca Agg_di3000_xtile_`k'_`j'_`ii' = r(sum)/5                                        // divide by 5 for implicates 
}
}

* 3. compute agg di2000 for each country 
qui sum di2000_net [aw=hw0010] if sa0100 == "`ii'",d 
sca Agg_di2000_`ii' = r(sum)/5                                                  // divide by 5 for implicates 

* 4. compute scaliung factors: lambda_1 to lambda_10
forval k = 1/$numqk{ 
forval j = 1/$numqj{
sca lambda_`k'_`j'_`ii' = (1-target_Agg_S_base_`ii')*Share`k'`j'_hbs_`ii'*Agg_di2000_`ii' / Agg_di3000_xtile_`k'_`j'_`ii' 
di "`ii' Baseline Wave lambda for Income `k' & Consumption `j' = " lambda_`k'_`j'_`ii' 
} 
}
 
* 5. replace di3000 by lambda*di3001
forval k = 1/$numqk{ 
forval j = 1/$numqj{
qui replace lambda = lambda_`k'_`j'_`ii'        if di3000_xtile_`ii' == `j' & di2000_net_xtile_`ii' == `k' & sa0100 == "`ii'"      
qui replace di3001 = lambda_`k'_`j'_`ii'*di3000 if di3000_xtile_`ii' == `j' & di2000_net_xtile_`ii' == `k' & sa0100 == "`ii'"
} 
} 


* 6. make sure we hit the target (aggregate saving rate)
qui sum di3001 [aw=hw0010] if sa0100=="`ii'", d                                 // Compute Aggregate New Consumption 
sca Agg_Scaled_di3001_`ii'_base = r(sum)/5 	                                    // Collect scalar 
sca Sca_targeted_Agg_s_`ii'_base = (Agg_di2000_`ii' - Agg_Scaled_di3001_`ii'_base ) / Agg_di2000_`ii' 

*di "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"   
*di "`ii'  Base Wave Agg. Saving rate: TARGET SDW = " Agg_B8G_`ii'_base_wave  "   TARGET FINAL = " target_Agg_S_base_`ii' ",   RESULT = " Sca_targeted_Agg_s_`ii'_base	 	  
*di "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"   



 **************  Calibrate Simulated wave    ****************************

* 1. compute income deciles for di3000 and country 
qui xtile di3000_simul_xtile_`ii'     = di3000_simul     [aw=hw0010] if sa0100 == "`ii'", nq($numqj)

if "$UseIncDist" == "1" {
qui xtile di2000_simul_net_xtile_`ii' = di2000_simul_net [aw=hw0010] if sa0100 == "`ii'", nq($numqk)
}
 
if "$UseIncDist" == "0" {
qui gen di2000_simul_net_xtile_`ii' = 1                              if sa0100 == "`ii'"
} 
 
 
* 2. compute agg di3000 for each deciles and country
forval k = 1/$numqk{ 
forval j = 1/$numqj{
qui sum di3000_simul [aw=hw0010] if di3000_simul_xtile_`ii' == `j' & di2000_simul_net_xtile_`ii' == `k' & sa0100 == "`ii'",d                        // agg cons across quintiles 
sca Agg_di3000_simul_xtile_`k'_`j'_`ii' = r(sum)/5                                  // divide by 5 for implicates 
}
}


* 3. compute agg di2000_simul_net for each country 
qui sum di2000_simul_net [aw=hw0010] if sa0100 == "`ii'",d 
sca Agg_di2000_simul_net_`ii' = r(sum)/5                                        // divide by 5 for implicates 

* 4. compute scaling factors: lambda_1 to lambda_10
forval k = 1/$numqk{
forval j = 1/$numqj{
sca lambda_simul_`k'_`j'_`ii' = (1-target_Agg_S_simul_`ii')*Share`k'`j'_hbs_`ii'*Agg_di2000_simul_net_`ii' / Agg_di3000_simul_xtile_`k'_`j'_`ii' 
*di "`ii' Simulated Wave lambda for Income decile `k' and consumption decile `j' = " lambda_simul_`k'_`j'_`ii' 
} 
} 
* 5. replace di3001_simul by lambda*di3001 
forval k = 1/$numqk{
forval j = 1/$numqj{
qui replace lambda_simul = lambda_simul_`k'_`j'_`ii'              if di3000_simul_xtile_`ii' == `j' & di2000_simul_net_xtile_`ii' == `k' & sa0100 == "`ii'"
qui replace di3001_simul = lambda_simul_`k'_`j'_`ii'*di3000_simul if di3000_simul_xtile_`ii' == `j' & di2000_simul_net_xtile_`ii' == `k' & sa0100 == "`ii'"
} 
}


* 6. make sure we hit the target (aggregate saving rate)
qui sum di3001_simul [aw=hw0010] if sa0100=="`ii'", d                           // Compute Aggregate New Consumption 
sca Agg_Scaled_di3001_simul_`ii' = r(sum)/5 	                                // Collect scalar 
sca Sca_targeted_Agg_s_`ii'_simul = (Agg_di2000_simul_net_`ii' - Agg_Scaled_di3001_simul_`ii' ) / Agg_di2000_simul_net_`ii' 

*di "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"   
*di "`ii'  Base Wave Agg. Saving rate: TARGET SDW = " Agg_B8G_`ii'_simul_wave  "   TARGET FINAL = " target_Agg_S_simul_`ii' ",   RESULT = " Sca_targeted_Agg_s_`ii'_simul	 	  
*di "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"   

}



** merge & Save results 
qui merge m:m sa0100 sa0010 id using "$hfcsinputPath/D_compl_MicroSim_$UpdateTo.dta" // 100% matched
qui drop _merge





********************************************************************************
* 4. Compute savings on simulated wave 
********************************************************************************
  
qui gen cbar   = .
qui gen cbar_c = .
qui gen ybar   = . 
qui gen savings_simul           = 0 
qui gen savings_c_simul         = 0 
qui gen savings_flow_w3_simul   = 0
qui gen savings_flow_w3_c_simul = 0 
foreach ctry of global ctrylist {
    qui	replace cbar   = (di3001_simul - di3001)/sim_Y_inc_`ctry'        if sa0100 == "`ctry'"
    *qui replace cbar_c = (di3001_c_simul - di3001_c)/sim_Y_inc_`ctry'   if sa0100 == "`ctry'"
    qui	replace ybar   = (di2000_simul_net - di2000_net)/sim_Y_inc_`ctry' if sa0100 == "`ctry'" // linear change btw waves
	
	* Compute cumulative term
	local N_tmp 0
	di "Computing Savings (accumulated & flow) `ctry'"
	forvalues i=1/`=sim_Y_inc_`ctry'' {
	local N_tmp `N_tmp' + `i'
}
 sca Y_cum_`ctry' = `N_tmp'

qui replace savings_simul           = sim_Y_inc_`ctry' * (di2000_simul_net - di3001_simul)   + Y_cum_`ctry'*(ybar - cbar)   if sa0100 == "`ctry'"	
qui replace savings_flow_w3_simul   = (di2000_simul_net - di3001_simul)   + (ybar - cbar)    if sa0100 == "`ctry'"
}


********************************************************************************
* 6. RECOMPUTE BALANCED-SHEET
* 1. Positive savings (+ interests) goes to deposits 
* 2. Negative savings substract assets in this order: 
*    1. deposits (da2101)     
*    2. shares   (da2105)
*    3. bonds    (da2103)
*    4. funds    (da2102)
*    5. mang. ac (da2106)
*    6. priv.bus (da2104)
********************************************************************************

* 1. Positive savings (+ interests) goes to deposits 

* Compute compounded interest on quarterly savings: 
qui gen positive_savings_q   = 0 
qui gen positive_savings_c_q = 0
qui gen savings_plus_interests   = 0 
qui gen savings_plus_interests_c = 0 
foreach c of global ctrylist { 

qui replace positive_savings_q   = savings_simul   / sim_q_ass_`c'_n if sa0100=="`c'" & savings_simul > 0 // Implied savings in each simulated quarter (flow)
qui replace positive_savings_c_q = savings_c_simul / sim_q_ass_`c'_n if sa0100=="`c'" & savings_c_simul > 0
qui replace savings_plus_interests   = (positive_savings_q)*(1+r_`c'_1)     if sa0100 == "`c'"
qui replace savings_plus_interests_c = (positive_savings_c_q)*(1+r_`c'_1)   if sa0100 == "`c'"

forval t = 2/`=sim_q_ass_`c'_n' {
qui replace savings_plus_interests   = (savings_plus_interests + positive_savings_q)*(1+r_`c'_`t')     if sa0100 == "`c'" // Add the aggregate interest to each quarter 
qui replace savings_plus_interests_c = (savings_plus_interests_c + positive_savings_c_q)*(1+r_`c'_`t') if sa0100 == "`c'"
}
}


* positive savings + interests to deposits (da2101) 
qui egen da2101_simul = rowtotal(da2101 savings_plus_interests) 


* 2. Negative savings liquidate deposits, shares bonds, funds....
qui gen neg_savings = savings_simul   if savings_simul < 0    

* Liquidate deposits (da2101_simul) 
qui egen  temp1   = rowtotal(da2101_simul neg_savings)  
replace da2101_simul = temp1
replace da2101_simul = . if temp1 <0 
replace temp1 = . if temp1 >= 0 

* Liquidate shares (da2105_simul)
qui egen temp2 = rowtotal(da2105_simul temp1)
replace da2105_simul = temp2 
replace da2105_simul = .    if temp2 < 0 
replace temp2 = . if temp2 >=1 

* Liquidate Bonds (da2103_simul)
qui egen temp3 = rowtotal(da2103_simul temp2)
replace da2103_simul = temp3 
replace da2103_simul = .    if temp3 < 0 
replace temp3 = . if temp3 >=1 

* Liquidate Funds (da2102_simul)
qui egen temp4 = rowtotal(da2102_simul temp3)
replace da2102_simul = temp4 
replace da2102_simul = .    if temp4 < 0 
replace temp4 = . if temp4 >=1 


* Liquidate managed accounts (da2106)
qui egen temp5 = rowtotal(da2106 temp4)
qui gen da2106_simul = temp5 
replace da2106_simul = .    if temp5 < 0 
replace temp5 = . if temp5 >=1 


* Liquidate priv. business liq wealth (da2104_simul)
qui egen temp6 = rowtotal(da2104_simul temp5)
replace da2104_simul = temp6 
replace da2104_simul = .    if temp6 < 0 
replace temp6 = . if temp6 >=1 

* Remaining neg-savings to overdrafted account  
qui replace temp6 = -temp6                                                      // convert the difference after substracting assets to positive 
qui egen    dl1210_simul = rowtotal(dl1210 temp6) 
qui replace dl1210_simul = . if dl1210_simul >= 0 


* Add negative savings_simul to non-mortgage debt dl1200_amort 
qui egen    dl1200_simul    =    rowtotal(dl1200_amort temp6)
qui replace dl1200_simul    = . if dl1200_simul == 0 
qui drop dl1200_amort_minus 
qui gen  dl1200_amort_minus = -dl1200_simul 

* Add remaining neg-savings to outstanding total debt dl1000_amort 
qui egen       dl1000_simul = rowtotal(dl1100_amort dl1200_simul)
qui replace    dl1000_simul = . if dl1000_simul == 0 

drop temp* 


* 3. Recompute liquid assets 
qui rename dnnla_simul dnnla_simul_temp11
qui egen dnnla_simul = rowtotal(da2101_simul da2102_simul da2103_simul da2104_simul da2105_simul da2106_simul dl1200_amort_minus)

* save result
qui save "$hfcsinputPath/D_compl_MicroSim_$UpdateTo.dta", replace               










/*
***** quick analysis 
gen srate       = 1-di3001       / di2000_net
gen srate_simul = 1-di3001_simul / di2000_simul_net



sum srate       [aw=hw0010] if inrange(srate,-1,1) & sa0100 == "ES",d
sum srate_simul [aw=hw0010] if inrange(srate_simul,-1,1) & sa0100 == "ES",d


preserve 
keep if im0100 == 1 
tw (hist srate_simul [fw=round(hw0010)] if inrange(srate_simul,-1,1) & sa0100 == "DE", color(black%40)) || ///
   (hist srate_simul [fw=round(hw0010)] if inrange(srate_simul,-1,1) & sa0100 == "ES", color(blue%40)) || ///
   (hist srate_simul [fw=round(hw0010)] if inrange(srate_simul,-1,1) & sa0100 == "FR", color(green%40)) || /// 
   (hist srate_simul [fw=round(hw0010)] if inrange(srate_simul,-1,1) & sa0100 == "IT", color(red%40)) /// 
   , legend(row(2) order(1 "DE" 2 "ES" 3 "FR" 4 "IT"))
restore 
*/ 















