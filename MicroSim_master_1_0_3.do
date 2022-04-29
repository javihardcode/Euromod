
global programPath     "$basePath/programs"                                     // baseline programs 
global programPath1    "$basePath/programs/macro update 1 programs"             // program path if macroupdate == 1 
global programPathSDW  "$basePath/programs/SDW programs"                        // programs to download macrodata from SDW 
global dataoutputPath  "$basePath/data/macrodata"                               // macrodata 
global data_HBS         "D:/data/hbs"  
global EuromodPath_in1  = "D:/data/euromod/Household_data1"                     // subfix 1 refers to employee income folder 
global EuromodPath_out1 = "D:/microsim/1_0_3/data/euromod/Household_data1/dta_all"
global EuromodPath_in2  = "D:/data/euromod/Household_data2"                     // subfix2 refers to self employment income folder
global EuromodPath_out2 = "D:/microsim/1_0_3/data/euromod/Household_data2/dta_all"


*** Set reference periods for assets, income, unemployment updates
do "$programPath/000_ref_periods.do"



if "$start_wave" == "1" {
global datainputPath "$basePath/data/input_w1"
}
if "$start_wave" == "2" {
global datainputPath "$basePath/data/input_w2"
}
if "$start_wave" == "3" {
global datainputPath "$basePath/data/input_w3"                                  // (replacement rates) P:/microsim-copy/1_0_2_dev/data/input_w2
}



* ==============================================================================	  
*                             SIMULATION PROGRAMS 
* ==============================================================================	  




* ==============================================================================	  
*** I Income/Unemployment Simulation 
* ==============================================================================	  

if "$unempSimulIncomeIndex" == "1" {
	
	if "$macroupdate" == "1" {
	

	     do "$programPath1/inc_update_RR.do"                                    // OECD Replacement Rates (short or long term)

	     do "$programPath1/inc_update_utarget.do"                               // Target Unemployment Rates

	     do "$programPath1/inc_update_seprob.do"                                // Compute unemployment probabilities

	     do "$programPath1/EUROMOD_dataprep1.do"                                // Consolidate EUROMOD data 
	     do "$programPath1/EUROMOD_dataprep2.do"
      }
 
	if "$macroupdate" == "0" {
	
	     do "$programPath/0011_inc_update_macro_noupdate.do"
	  }
	     do "$programPath/0012_inc_update_simul.do"                             // Conduct unemployment simulation
	     do "$programPath/0013_inc_update_merge.do"	                            // Merge results into HFCS and save combined file
}

	  
	  
	  
	  
* ==============================================================================	  
*** II Assets and liabilities update
* ==============================================================================	  

if "$macroupdate" == "1" {
	do "$programPath1/asset_update_macrodata.do"                                // Download data if chosen                              
}
do "$programPath/0021_asset_update.do"                                          // Update assets and liabilities




* ==============================================================================
* III Consumption Simulation and update 
* ==============================================================================

if "$macroupdate" == "1" {
    do "$programPathSDW/SDW_CP042.do"                                           // download imputed rents from consumption 
    do "$programPathSDW/SDW_B6G.do"                                             // download aggregate household disposable income 
    do "$programPathSDW/SDW_B8G.do"                                             // download aggregate household saving rate  
    do "$programPathSDW/SDW_P31.do"                                             // download private final consumption in levels 
}	

do "$programPath/0031_cons_imputation_Wave_base_DEVELOPMENT.do"                 // impute consumption from HBS to base wave 
do "$programPath/0032_cons_imputation_Wave_simul.do"                            // impute consumption from HBS to final wave 
do "$programPath/0033_cons_saving_target.do"                                    // temporal script: substracts imputed rents from aggregate saving rate 
do "$programPath/0034_cons_savings_calibration.do"                              // temporal script: calibrates lambda_1 to lambda_5 in order to match 


* ---------- some diagnostics 
*Diagnostics consumption simulation == 1 { 
* do comparing distribution HBS-HFCS
* do comparing how the lambdas_i distort coonsumption at household level.  
*}






* ==============================================================================
*** IV Mortgage Simulation 
* ==============================================================================

do "$programPath/0041_mort_update_target.do"                                    // Set aggregate targets	
do "$programPath/0042_mort_update_simul.do"                                     // Conduct simulation
do "$programPath/0043_mort_update_merge.do"                                     // Recompute variables and Merge results        
		
*}





* ==============================================================================
*** V. COMPARING TWO NON-WAVES QUARTERS
* ==============================================================================


do "$programPath/0051_Comparing_quarters.do"

















































