
* Consumption update Wave 2 to Wave 3:
*  Last update: 01-01-2022
* 1. Compute growth rate btw base wave & target wave (no longuer used)
* 2. Scale Chat to match saving rate from SDW 
* 3) Scale simulated consumption Wave 2 
* 4) Calculate linear change in Chat over years


* 1) For each country, compute aggregage consumption growth rate btw w1 and w2

* Load consumption growth rates
qui use "$dataoutputPath/P31_ALL.dta", clear                                        // open macrodata

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
* 2. SCALE CONSUMPTION TO MATCH AGGREGATE SAVING RATES

/*
************************************************************************************************************************************************************************************************
qui use "$dataoutputPath/B8G_ALL.dta", clear                                    // open data to take targets 
* Collect targets 
foreach ii of global ctrylist {
sca B8G_`ii'_s = B8G_`ii'[start_q_ass_`ii'_n]                                   // Negative for CY and GR 
di "`ii' Target Saving Initial Wave :" B8G_`ii'_s "%"
sca saving_target_`ii'_w2 = B8G_`ii'_s / 100                                    // Convert to 0-1 

sca B8G_`ii'_s = B8G_`ii'[end_q_ass_`ii'_n]                                     // Negative for CY and GR 
di "`ii' Target Saving Simulated Wave :" B8G_`ii'_s "%"
sca saving_target_`ii'_w3 = B8G_`ii'_s / 100                                    // Convert to 0-1 
}
************************************************************************************************************************************************************************************************
*/









* Open Chat_ALL1.dta and merge with Wave 2 to obtain data on income and payments: 
qui use "$hfcsinputPath/Chat_ALL1.dta", clear
qui merge 1:1 sa0100 sa0010 id using "$hfcsinputPath/d_complete.dta"            // 100% matched: HR & LT unmatched
qui keep sa0010 sa0100 im0100 id di3001 di3001_c di2000 dl2000 hw0010 hi0200               // Keep total Income, Consumption and debt payments 

* Now merge with di3001_simul from cons_imputation_simul_w3.do: 
 merge 1:1 sa0100 sa0010 id using "$hfcsinputPath/Chat_ALL1_wave_simul.dta"     // 100% matched: HR & LT unmatched
qui keep sa0010 sa0100 im0100 id di3001 di3001_simul di3001_c di3001_c_simul di2000 di2000_simul dl2000 hw0010 hi0200 // Keep total Income, Consumption and debt payments 
 
 

* Calculate Aggregate Income, Consumption and Debt payments by hh: 
qui gen Agg_di2000         = . 
qui gen Agg_di2000_simul   = . 
qui gen Agg_di3001   = . 
qui gen Agg_di3001_c = . 
qui gen Agg_di3001_simul   = . 
qui gen Agg_di3001_c_simul = . 
qui gen lambda_w2       = .
qui gen lambda_c_w2     = .
qui gen lambda_w3       = .
qui gen lambda_c_w3     = .
qui gen di3001_hbs       = .                                                    // keep initial di3001 
qui gen di3001_hbs_simul = .                                                    // keep initial di3001_simul 
foreach ii of global ctrylist{


*************** SECTION 1 Re-scale consumption Wave 2 ************************** 
*  1. Aggregate Income Base wave 
  qui sum         di2000 [aw=hw0010]   if sa0100=="`ii'", d
  qui replace Agg_di2000 = r(sum)/5    if sa0100=="`ii'"
  sca Sca_Agg_di2000_`ii' = r(sum)/5                                             // Collect scalar for diagnostics 
	  
	  
*  3. Aggregate Simulated consumption base wave 
  qui sum         di3001 [aw=hw0010]     if sa0100=="`ii'", d
  qui replace Agg_di3001 = r(sum)/5      if sa0100=="`ii'"   
  qui sum         di3001_c [aw=hw0010]   if sa0100=="`ii'", d
  qui replace Agg_di3001_c = r(sum)/5    if sa0100=="`ii'"
	  
*  4. Scaling factor: lambda
  qui replace lambda_w2   = ((1-target_Agg_S_base_`ii')*Agg_di2000)/Agg_di3001     if sa0100=="`ii'"
  qui replace lambda_c_w2 = ((1-target_Agg_S_base_`ii')*Agg_di2000)/Agg_di3001_c   if sa0100=="`ii'"

*  5. Use lambda to rescale consumption (Wave 2 and simul Wave 3!!)
   qui replace di3001_hbs     = di3001                         if sa0100=="`ii'" // keep track of initial consumption predicted by the HBS 
   qui replace di3001         = lambda_w2*di3001               if sa0100=="`ii'" // rescale conusmption Wave 2
   qui replace di3001_c       = lambda_c_w2*di3001_c           if sa0100=="`ii'"    

*  6. How far is the aggregate saving rate from target? 
   qui sum di3001 [aw=hw0010] if sa0100=="`ii'", d                              // Compute Aggregate New Consumption 
   sca Sca_Agg_Scaled_di3001_`ii'_w2 = r(sum)/5 	                            // Collect scalar 
   sca Sca_targeted_Agg_s_`ii'_w2 = (Sca_Agg_di2000_`ii' - Sca_Agg_Scaled_di3001_`ii'_w2 ) / Sca_Agg_di2000_`ii' 
   di "`ii'  Base Wave Agg. Saving rate: TARGET SDW = " Agg_B8G_`ii'_base_wave  "   TARGET FINAL = " target_Agg_S_base_`ii' ",   RESULT = " Sca_targeted_Agg_s_`ii'_w2	 	  


*************** SECTION 2 re-scale consumption from Simulated Wave ********************* 
  *  1. Aggregate Income Simulated Wave
  qui sum         di2000_simul [aw=hw0010]   if sa0100=="`ii'", d
  qui replace Agg_di2000_simul = r(sum)/5    if sa0100=="`ii'"
  sca Sca_Agg_di2000_simul_`ii' = r(sum)/5                                      // Collect scalar for diagnostics 

  *  2. Aggregate Simulated consumption Wave 2
  qui sum         di3001_simul [aw=hw0010]     if sa0100=="`ii'", d
  qui replace Agg_di3001_simul = r(sum)/5      if sa0100=="`ii'"   
  qui sum         di3001_c_simul [aw=hw0010]   if sa0100=="`ii'", d
  qui replace Agg_di3001_c_simul = r(sum)/5    if sa0100=="`ii'"

  *  3. Scaling factor: lambda
  qui replace lambda_w3   = ((1-target_Agg_S_simul_`ii')*Agg_di2000_simul)/Agg_di3001_simul     if sa0100=="`ii'"
  qui replace lambda_c_w3 = ((1-target_Agg_S_simul_`ii')*Agg_di2000_simul)/Agg_di3001_c_simul   if sa0100=="`ii'"
  
*  4. Use lambda to rescale consumption (Wave 2 and simul Wave 3!!)
   qui replace di3001_hbs_simul     = di3001_simul             if sa0100=="`ii'"  // keep track of initial consumption predicted by the HBS.  
   qui replace di3001_simul   = lambda_w3*di3001_simul         if sa0100=="`ii'"  // Re scale Consumption simul Wave 3 using lambda_w2 
   qui replace di3001_c_simul = lambda_c_w3*di3001_c_simul     if sa0100=="`ii'"      
    
*  5. How far is the aggregate saving rate from target? 
   qui sum di3001_simul [aw=hw0010] if sa0100=="`ii'", d                        // Compute Aggregate New Consumption 
   sca Sca_Agg_Scaled_di3001_simul_`ii' = r(sum)/5 	                                // Collect scalar 
   sca Sca_targeted_Agg_s_`ii'_w3 = (Sca_Agg_di2000_simul_`ii' - Sca_Agg_Scaled_di3001_simul_`ii' ) / Sca_Agg_di2000_simul_`ii' 
   di "`ii' Simul Wave Agg. Saving rate: TARGET SDW = " Agg_B8G_`ii'_simul_wave "   TARGET FINAL = " target_Agg_S_simul_`ii' ",   RESULT = " Sca_targeted_Agg_s_`ii'_w3	 	   
}


** Save results 
*save "P:/ECB business areas/DGR/Databases and Programme files/DGR/Javier Ramos/microsim/1_0_2/data/output/Chat_ALL.dta", replace                //  Save results
qui save "$hfcsinputPath/Chat_ALL2.dta", replace
qui merge 1:1 sa0100 sa0010 id using "$hfcsinputPath/D_compl_MicroSim_$print_ts.dta" // 100% matched
qui drop _merge


* 3) Compute linear year over year consumption change between waves

qui gen cbar   = .
qui gen cbar_c = .
foreach ctry of global ctrylist {
 qui	replace cbar   = (di3001_simul - di3001)/sim_Y_inc_`ctry'       if sa0100 == "`ctry'"
 qui    replace cbar_c = (di3001_c_simul - di3001_c)/sim_Y_inc_`ctry'   if sa0100 == "`ctry'"
}


* save result
qui save "$hfcsinputPath/di3001_base_simul.dta", replace                                // Save local hfcs wave 2
















