
global programPath "$basePath/programs"
global dataoutputPath "/Users/main/OneDrive - Istituto Universitario Europeo/data/HFCS_update/1_0_2/data/output"
	*global dataoutputPath "$basePath/data/output"

* Set reference periods for assets, income, unemployment updates
do "$programPath/ref_periods.do"

if "$start_wave" == "1" {
global datainputPath "/Users/main/OneDrive - Istituto Universitario Europeo/data/HFCS_update/1_0_2/data/input_w1"
	*global datainputPath "$basePath/data/input_w1"
}
if "$start_wave" == "2" {
global datainputPath "/Users/main/OneDrive - Istituto Universitario Europeo/data/HFCS_update/1_0_2/data/input_w2"
	*global datainputPath "$basePath/data/input_w2"
}

* Clear timers
timer clear

timer on 4
*** I Income Simulation 

* If chosen, run unemployment simulation
if "$unempSimulIncomeIndex" == "1" {
	
	timer on 3
	* 1) Download data if chosen
	if "$macroupdate" == "1" {
	
	* a) OECD Replacement Rates (short or long term)
	do "$programPath/inc_update_RR.do"
	
	* b) Target Unemployment Rates and sectoral unemployment probabilities
	if "$unempadjustment" == "0" {
		do "$programPath/inc_update_utarget.do"
		do "$programPath/inc_update_seprob.do"
	}
	
	else {
		do "$programPath/inc_update_utarget_sa.do"
		do "$programPath/inc_update_seprob_sa.do"
	
	}	
	timer off 3
	
	}
	
	* 2) Conduct simulation
	timer on 1
	do "$programPath/inc_update_simul.do"
	
	* 3) Merge results into HFCS and save combined file
	do "$programPath/inc_update_merge.do"
	timer off 1
}


*** II Assets and liabilities update

* 1) Download data if chosen

if "$macroupdate" == "1" {
	timer on 3
	do "$programPath/asset_update_macrodata.do"
	timer off 3
}

* 2) Update assets and liabilities
timer on 2
do "$programPath/asset_update.do" 
timer off 2

timer off 4

*** Collect timers
timer list
if "$unempSimulIncomeIndex" == "0" {
	global time_inc_sim = 0
}
if "$unempSimulIncomeIndex" == "1" {
	global time_inc_sim = round(r(t1)/60,.01)
}
global time_ass_upd = round(r(t2)/60,.01)
if "$macroupdate" == "0" {
	global time_macro_d = 0
}
if "$macroupdate" == "1" {
	global time_macro_d = round(r(t3)/60,.01)
}
global time_total = round(r(t4)/60,.01)


*** Save results 
save "$resultPath/D_compl_MicroSim_$print_ts.dta", replace


*** Create and save summary file of the update
do "$programPath/summary.do"


*** Create diagnostics of the update

if "$start_wave" == "1" & "$UpdateTo" == "wave2" {
	do "$programPath/diagnostics_wave2.do"
	do "$programPath/diagnostics_wave2_EA.do"
}

if "$start_wave" == "2" & "$UpdateTo" == "wave3" {
	do "$programPath/diagnostics_wave3_prelim.do"
//	do "$programPath/diagnostics_wave3.do"			USE ONCE COMPLETE w3 D_COMPL AVAILABLE
	do "$programPath/diagnostics_wave3_EA_prelim.do"
// 	do "$programPath/diagnostics_wave3_EA.do"		USE ONCE COMPLETE w3 D_COMPL AVAILABLE
}


*** Close program
log close log_MicroSim
translate "$resultPath/log_MicroSim.smcl" "$resultPath/log_MicroSim.pdf"

rm "$resultPath/log_MicroSim.smcl"

di("Program finished. Results are in the target folder.")


