
*                  ************************
*                  INCOME SIMULATION MERGE 
*                  ************************

* Last update: 09-03-2022 
* Javier Ramos Perez DG/R

*               LIST Of CONTENTS 

* 1. Open D-files  
* 2. Open Income Simulation data  
* 3. Merge all in one  
* 4. Udjust total income at household level




********************************************************************************
* 1.  load D Files and create D_complete.dta
********************************************************************************

qui use "$hfcsoutputPath//D1.dta", clear
forval i = 2/5{
qui append using "$hfcsoutputPath/D`i'.dta"
}
qui rename *, lower
qui drop if inlist(sa0100, "E1", "I1")
sort id

if "$start_wave" == "1"  {
qui gen dnnlaratio = dnnla/di2000									            // Net liquid assets as a fraction of annual gross income
qui replace dnnlaratio = dnnla/(1) if di2000<=0
}
qui save "$hfcsoutputPath/D_complete.dta", replace                               // save locally 




********************************************************************************
* 2.  Load Income Simulation Data 
********************************************************************************
qui use "$hfcsinputPath/u_simul_results_$UpdateTo.dta", clear                                 




********************************************************************************
* 3.  Merge D-compl with Income Simulation
********************************************************************************
qui merge m:1 id using "$hfcsoutputPath/D_complete.dta"                             // 100%       
qui drop _merge
qui keep if ra0100 == 1                                                             // keep RP to go to hh level 



********************************************************************************
* 4. Udjust total income at household level
********************************************************************************
qui egen di_orig =       rowtotal(di1100 di1200 di1610)                             //  
qui egen di_simul = rowtotal(di1100_simul di1200_simul di1610_simul)                // 
qui gen di2000_simul = di2000-di_orig+di_simul                                      // 
qui save "$hfcsinputPath/D_compl_incsimul_$UpdateTo.dta", replace                             // 





















