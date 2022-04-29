* 
* This script computes savings minus imputed rents: 
* 

* This do file compute aggregate saving rates discounting imputed rents. 



* 1. Open Disposable Income Data (B6G)
use "$dataoutputPath/B6G_ALL.dta", clear 
* Collect scalars from SDW  
foreach c of global ctrylist{
sca Agg_B6G_`c' = B6G_`c'[start_q_inc_`c'_n]*1000000*4                           // Convert to  millions and to yearly data (approx)
}


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

* Now give tha last available obs (2020Q4) to the four quarters of 2021: 
foreach c of global ctrylist{
forval  i = 1/4{
local N = _N -`i'
replace CP042_`c' = CP042_`c'[_N-4] in `N'
}
}

* Now collect scalar 
foreach c of global ctrylist{
sca Agg_CP042_`c' = CP042_`c'[start_q_inc_`c'_n]*1000000                        // use the cell for 2016!!! and convert to millions NOTE THAT THIS IS YEARLY DATA EVEN THOUGH ITS IN QUARTERLY FORMAT!!!!!
}





* 3. Open Personal Final Consumption (P31) 
use "$dataoutputPath/P31_ALL.dta", clear

foreach c of global ctrylist{
sca Agg_P31_`c' = P31_`c'[start_q_inc_`c'_n]*1000000*4               // use the cell for 2016!!! and convert to millions 
}


* Lastly, Open Aggregate Saving rate for comparison 
use "$dataoutputPath/B8G_ALL.dta", clear
foreach c of global ctrylist{
sca Agg_B8G_`c' = B8G_`c'[start_q_inc_`c'_n]
}


foreach c of global ctrylist{
sca Saving_rate_`c' = 100*(1- ( Agg_P31_`c' - Agg_CP042_`c')/Agg_B6G_`c') 

di "`c' Saving Rate SDW                   2016 : " Agg_B8G_`c' "%"
di "`c' Saving Rate without Imputed rents 2016 : " Saving_rate_`c' "%"
*sca 
}

































