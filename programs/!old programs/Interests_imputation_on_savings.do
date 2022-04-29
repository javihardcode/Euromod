
* Imputation of interest to savings:

* 1) Open D41_ALL.dta 
use "P:\ECB business areas\DGR\Databases and Programme files\DGR\Javier Ramos\microsim\1_0_2\data\macrodata\asset_macro_data_ALL.dta", clear 

keep PERIOD_NAME D41*

* Merge with Currency and Deposits data
merge 1:1 PERIOD_NAME using "P:\ECB business areas\DGR\Databases and Programme files\DGR\Javier Ramos\microsim\1_0_2\data\macrodata\CurrencyDeposits_ALL.dta"
drop if _merge !=3

keep PERIOD_NAME D41* F2M_*

* Create returns to each country:
foreach c of global ctrylist { 
gen deposit_return_`c' = D41_`c' / F2M_`c'
}

* Create the quarterly return for each country: 
foreach c of global ctrylist { 
forval t = 1/`=sim_q_ass_`c'_n' {
sca r_`c'_`t' = deposit_return_`c'[start_q_ass_`c'_n + `t' -1] 
}
}













