* Compute targets for saving rate
*  Last update: 22-03-2022



* 1. Open Disposable Income Data (B6G) max data: 2021Q3 
use "$dataoutputPath/B6G_ALL.dta", clear 
* Collect scalars from SDW  
expand 2 if PERIOD_NAME == "2021Q3"
replace     PERIOD_NAME = "2021Q4" in 60

foreach c of global ctrylist{
sca Agg_B6G_`c'_base_wave = B6G_`c'[start_q_inc_`c'_n]*1000000*4                // Convert to  millions and to yearly data (approx)
sca Agg_B6G_`c'_simul_wave = B6G_`c'[end_q_inc_`c'_n]*1000000*4                 // Convert to  millions and to yearly data (approx)
}
save "$dataoutputPath/B6G_ALL_temp.dta", replace 



* 2. Open Imputed Rents data (CP042) & convert to quarterly data 
use "$dataoutputPath/CP042_ALL.dta", clear                        
gen year = PERIOD_NAME 
expand 4                                                                        // duplicate the dataset for quarters 
sort PERIOD_NAME
bysort year: gen Q = _n
forval i=2007/2021   {
forval v=1/4{
qui replace PERIOD_NAME = "`i'Q`v'" if year == "`i'" & Q == `v'
}
}

* Now give thE last available obs (2020Q4) to the four quarters of 2021: 
foreach c of global ctrylist{
forval  i = 0/3{
local N = _N -`i'
replace CP042_`c' = CP042_`c'[_N-5] in `N'
}
}

* Now collect scalar on Aggregate Imputed rents 
foreach c of global ctrylist{
sca Agg_CP042_`c'_base_wave = CP042_`c'[start_q_inc_`c'_n]*1000000              // use the cell for 2016!!! and convert to millions NOTE THAT THIS IS YEARLY DATA EVEN THOUGH ITS IN QUARTERLY FORMAT!!!!!
sca Agg_CP042_`c'_simul_wave = CP042_`c'[end_q_inc_`c'_n]*1000000               // use the cell for 2016!!! and convert to millions NOTE THAT THIS IS YEARLY DATA EVEN THOUGH ITS IN QUARTERLY FORMAT!!!!!
}
save "$dataoutputPath/CP042_ALL_temp.dta", replace                       




* 3. Open Personal Final Consumption (P31) 
use "$dataoutputPath/P31_ALL.dta", clear

foreach c of global ctrylist{
sca Agg_P31_`c'_base_wave = P31_`c'[start_q_inc_`c'_n]*1000000*4               // use the cell for 2016!!! and convert to millions 
sca Agg_P31_`c'_simul_wave = P31_`c'[end_q_inc_`c'_n]*1000000*4               // use the cell for 2016!!! and convert to millions 
}
save "$dataoutputPath/P31_ALL_temp.dta", replace


* 4. Open Aggregate Saving rate for comparison 
use "$dataoutputPath/B8G_ALL.dta", clear
foreach c of global ctrylist{
sca Agg_B8G_`c'_base_wave = B8G_`c'[start_q_inc_`c'_n]
sca Agg_B8G_`c'_simul_wave = B8G_`c'[end_q_inc_`c'_n - 1]
}
save "$dataoutputPath/B8G_ALL_temp.dta", replace




foreach c of global ctrylist{
sca target_Saving_rate_base_wave_`c' = 100*(1- ( Agg_P31_`c'_base_wave - Agg_CP042_`c'_base_wave)/Agg_B6G_`c'_base_wave) 
sca target_Saving_rate_simul_wave_`c' = 100*(1- ( Agg_P31_`c'_simul_wave - Agg_CP042_`c'_simul_wave)/Agg_B6G_`c'_simul_wave) 

* Do this to take the average for missing countries (CY,EE,LU,LV,MT,SK)
qui gen Sbase`c' = target_Saving_rate_base_wave_`c'

qui gen Ssimul`c' = target_Saving_rate_simul_wave_`c'

*di "`c' Saving Rate SDW                   2021Q4 : " Agg_B8G_`c'_simul_wave "%"
*di "`c' Saving Rate without Imputed rents 2021Q4 : " Saving_rate_simul_wave_`c' "%"
}


egen average_saving_base_wave = rowmean(Sbase*)
egen average_saving_simul_wave = rowmean(Ssimul*)

foreach c of global ctrylist{
qui replace Sbase`c' = average_saving_base_wave if Sbase`c' == . 
qui replace Ssimul`c' = average_saving_simul_wave if Ssimul`c' == . 


sca target_Agg_S_base_`c'  = Sbase`c'[1]
sca target_Agg_S_simul_`c' = Ssimul`c'[1]

* Now display the target for each country

di "`c' Saving Rate SDW                   Base W : " Agg_B8G_`c'_base_wave "%"
di "`c' Saving Rate without Imputed rents Base W : " target_Agg_S_base_`c' "%"

di "`c' Saving Rate SDW                   2021Q4 : " Agg_B8G_`c'_simul_wave "%"
di "`c' Saving Rate without Imputed rents 2021Q4 : " target_Agg_S_simul_`c' "%"


sca target_Agg_S_base_`c'  = Sbase`c'[1]/100
sca target_Agg_S_simul_`c' = Ssimul`c'[1]/100
}





********************************************************************************
* Ad-Hoc request 24-03-2022: time series 
********************************************************************************
/*
use "$dataoutputPath/B6G_ALL_temp.dta", clear
merge 1:1 PERIOD_NAME using "$dataoutputPath/CP042_ALL_temp.dta"
drop _merge
merge 1:1 PERIOD_NAME using "$dataoutputPath/P31_ALL_temp.dta"
drop _merge 
merge 1:1 PERIOD_NAME using "$dataoutputPath/B8G_ALL_temp.dta"
drop _merge 

encode PERIOD_NAME, gen(date)


* 1. Evolution of Income, Consumption and Imputed Rents 






* Compute our measure of interest rate: 
foreach c of global ctrylist{
qui replace P31_`c' = 1000000*4*P31_`c' 
qui replace CP042_`c' = 1000000*CP042_`c' 
qui replace B6G_`c' = 1000000*4*B6G_`c'

* 
tw (line B6G_`c' date) || (line CP042_`c' date) || (line P31_`c' date) , legend(row(1) order(1 "Income" 2 "Imputed Rents" 3 "Consumption")) title("`c' Aggregate Variables") name(`c'_, replace)
gr export "D:/microsim/results/diagnostics 2020/`c'_agg_vars_in_time.png", replace


qui gen s_norents_`c' =100*(1-(P31_`c' - CP042_`c')/(B6G_`c'))
tw (line s_norents_`c' date) || (line B8G_`c' date), legend(order(1 "Without imputed rents" 2 "With imputed rents")) title(" `c' Aggregate Saving rate") name(`c'_s, replace)
gr export "D:/microsim/results/diagnostics 2020/`c'_agg_saving_rates_in_time.png", replace

}


*/













