* Runs the tobit regression as in Palligkinis 2017 (table 1)
* 08-12-2021 Javier Ramos 
* Working on last version

** 1. Prepare H files so that year when mortgage was taken out can be merged to D_compl

* open  HFCS data 
if "$start_wave" == "1" | "$start_wave" == "2" {
qui use "$hfcsinputPath/h1.dta", clear
qui keep id im0100 sa0100 sa0010 hb1301 hb1701 hb1302 hb1702 hb1303 hb1703 hb1010 hb3301 hb3302 
forvalues ii = 2(1)5{
qui append using "$hfcsinputPath/h`ii'.dta", keep(id im0100 sa0100 sa0010 hb1301 hb1701 hb1302 hb1702 hb1303 hb1703 hb1010 hb3301 hb3302 )
}
}

if "$start_wave" == "3" {
qui use "$hfcsinputPath/h1.dta", clear
qui keep ID IM0100 SA0100 SA0010 HB1301 HB1701 HB1302 HB1702 HB1303 HB1703 HB1010 HB33011 HB33021 
forvalues ii = 2(1)5{
qui append using "$hfcsinputPath/h`ii'.dta", keep(ID IM0100 SA0100 SA0010 HB1301 HB1701 HB1302 HB1702 HB1303 HB1703 HB1010 HB33011 HB33021)
}
qui rename *, lower
}





* hb1010: number of mortgages or loans using HMR as collateral
* -> use this variable to create "already has mortgage index" (NOT IN w1 D_compl)
qui gen already_mort = 0 

* Reference year for mortgages: 
if "$start_wave" == "1" | "$start_wave" == "2" {
sca ref_Y_mort = 2010
}
if "$start_wave" == "3" {
sca ref_Y_mort = 2015
}

* Change 24-01-2022 
qui replace already_mort = 1 if hb1301 < ref_Y_mort | hb1302 < ref_Y_mort | hb1303 < ref_Y_mort     // some HMR mortgage aquired before 2010 

qui replace already_mort = 1 if already_mort == 0 & (hb3301<=ref_Y_mort | hb3302<=ref_Y_mort)      // some non-HMR mortgage aquired before 2010 
															
* hb130$x: HMR mortgage $x: year when loan taken or refinanced
* -> Set all hhs without mortgage as taken out in year 0
forvalues i = 1(1)3{
qui replace hb130`i' = 0 if hb130`i' == .
}

*save "$dataoutputPath/mort_year.dta", replace	                                // Original saving directory
qui save "$hfcsinputPath/mort_year.dta" , replace                               // Save locally (need for speed)

** 2. Prepare data inputs for Tobit estimation (P files)
qui use "$hfcsinputPath/p1.dta", clear
forvalues ii = 2(1)5{
qui append using "$hfcsinputPath/p`ii'.dta"
}
qui rename *, lower
qui keep hid im0100 sa0100 sa0010 pe0100a pa0200 ra0300 pa0100 ra0200 ra0100
qui rename hid id 
/* COVARIATES FOR TOBIT REGRESSION
unemployed / retired / out of job market: pe0100a
educ (lower sec) / educ (upper sec) / tertiary: pa0200
Age: 35-44 / Age: 45-54 / Age: 55-64 / Age: 65-74 / Age: 75 and above: ra0300
couple: pa0100 (marital status)
female: ra0200 (gender)
has a child: ra0100 (relship to RP)
(in D_compl: DHIDH1 RP as of Canberra definition)
*/

qui gen unemployed = 0
qui replace unemployed = 1 if pe0100a == 3
qui gen retired = 0
qui replace retired = 1 if pe0100a == 5
qui gen out_LF = 0
qui replace out_LF = 1 if pe0100a==4 | pe0100a==6 | pe0100a==7 | pe0100a==8| pe0100a==9

qui gen educ1 = 0
qui replace educ1 = 1 if pa0200 == 2
qui gen educ2 = 0
qui replace educ2 = 1 if pa0200 == 3
qui gen educ3 = 0
qui replace educ3 = 1 if pa0200 == 5

qui gen age1 = 0
qui replace age1 = 1 if ra0300 > 34 & ra0300 < 45
qui gen age2 = 0
qui replace age2 = 1 if ra0300 > 44 & ra0300 < 55
qui gen age3 = 0
qui replace age3 = 1 if ra0300 > 54 & ra0300 < 65
qui gen age4 = 0
qui replace age4 = 1 if ra0300 > 64 & ra0300 < 75
qui gen age5 = 0
qui replace age5 = 1 if ra0300 >= 74

qui gen female = 0
qui replace female = 1 if ra0200 == 2

qui gen child = 0
qui replace child = 1 if ra0300 < 19
by sa0100 sa0010 im0100, sort: egen n_child = sum(child)
qui replace child = 1 if n_child > 0
qui drop n_child

* Couple: using pa0100 for all except FI, CY and ra0100 for them 
qui gen couple1 = 0
qui replace couple1 = 1 if pa0100 == 2 | pa0100 == 3

qui gen spouse_tmp = 0
qui replace spouse_tmp = 1 if ra0100 == 2
by sa0100 sa0010 im0100, sort: egen spouse_fam_tmp = sum(spouse_tmp)
qui gen couple2 = 0
qui replace couple2 = 1 if spouse_fam_tmp > 0
qui drop spouse_tmp spouse_fam_tmp

qui replace couple1 = couple2
qui drop couple2
qui rename couple1 couple

* Keep only reference person and drop all non-input variables
qui keep if ra0100 == 1
qui drop pe0100a pa0200 ra0300 pa0100 ra0200 ra0100

*save "$dataoutputPath/tobit_data.dta", replace	                                // Original saving directory 
qui save "$hfcsinputPath/tobit_data.dta", replace                               // Save locally (need 4 speed)


********************************************************************************
* Comments from Johannes (see original mort_update_main.do)
** Generate macro mortgage targets (as scalars) -> have already been generated earlier! (are as variables in "$dataoutputPath/Mort_target.dta")
* do "P:\ECB business areas\DGR\Databases and Programme files\DGR\Johannes Fleck\MicroSim_develop\mortgage_update\mort_update_target.do"
* use "$dataoutputPath/Mort_Target.dta", clear
** 3. Generate new micro mortgage levels -> FIGURE OUT HOW TO LOAD D_compl of wave 2 given that wave 1 is standard input

* Load target D_compl
//if "$start_wave" == "1" {
//global DcomplnputPath "/Users/main/OneDrive - Istituto Universitario Europeo/data/HFCS_update/1_0_2_dev/data/input_w1"
//}
//if "$start_wave" == "2" {
//global datainputPath "/Users/main/OneDrive - Istituto Universitario Europeo/data/HFCS_update/1_0_2_dev/data/input_w2"
//}
********************************************************************************


use "$hfcsinputPath/D_compl_MicroSim_$UpdateTo.dta", clear                      // Open HFCS Wave 2 and Simulated Wave 3
sort sa0100

/*
* Targets for mortgages: 
foreach ii of global ctrylist {
	preserve
    qui	keep if sa0100 == "`ii'"
	* Get sum of all mortgage debt: Sum up all implicates and divide by 5
    qui	sum dl1100 [aweight=hw0010]
	
	sca mort_current_`ii' = r(sum)/5                                            // Aggregate mortgages Wave 2
	sca mort_new_`ii' = Scale_Mort_`ii' * mort_current_`ii'                     // Aggregate targeted mortgages (Wave 3)
	sca mort_change_`ii' = mort_new_`ii' - mort_current_`ii'                    // Aggregate difference 
	restore
}
*/ 


** Add year when mortgage was taken out (from H files)
qui merge m:1 sa0100 sa0010 im0100 using "$hfcsinputPath/mort_year.dta"            // 100% matched
qui drop if _merge != 3
qui drop _merge

** Add variables for tobit estimation (from P files)
qui merge m:1 sa0100 sa0010 im0100 using "$hfcsinputPath/tobit_data.dta"            // 100% matched
qui drop if _merge != 3
qui drop _merge

* Prepare Tobit data
qui replace dl1100 = 0 if dl1100 == .                                               // All mortgages

* Identify newly issued mortgages: 
qui gen new_issued_mort = 0                                                         
qui replace new_issued_mort = hb1701 if hb1301 >= ref_Y_mort                    // Outstanding of x1 mortgage 
qui replace new_issued_mort = hb1702 if hb1302 > hb1301 & hb1301 >= ref_Y_mort  // if x2 mortgage was contracted after x1: set as new mortgage
qui replace new_issued_mort = hb1703 if hb1303 > hb1302 & hb1302 > ref_Y_mort   // if x3 mortgage was contracted after x2: set as new mortgage
qui gen     new_issued_mort_ind = (new_issued_mort > 0 )                        // indicator variable for newly contracted mortgages 
*br hb1301 hb1701 hb1302 hb1702 hb1303 hb1703 new_issued_mort                   // Activate to visualize

* Log income
qui gen log_di2000_simul_net = log(di2000_simul_net)                                                // 2754 missing generated 
tab sa0100 if log_di2000_simul_net == .                                                   // distribution of lost observations across countries 

* Inverse hyperbolic sine: Net worth and new mortgages
qui gen ihs_dn3001          = asinh(dn3001)                                     // 870 missings generated
qui gen sq_ihs_dn3001       = (ihs_dn3001)^2                                    // net wealth squared
qui gen ihs_dnnla           = asinh(dnnla)                                      // Liquid Wealth
qui gen ihs_da1120          = asinh(da1120)
qui gen ihs_dl1100          = asinh(dl1100)                                     // mortgage debt
qui gen ihs_new_issued_mort = asinh(new_issued_mort)

* Country dummies                                                               // country dummies 
qui levelsof sa0100, local(ctries) 
foreach j of local ctries {
	qui gen dum_`j' = 0
	qui replace dum_`j' = 1 if sa0100 == "`j'"
} 

* Lastly, add simulated liquid wealth (dnnla_simul) and simulated debt services for mortgages (dl2100_simul)
qui gen ihs_dnnla_simul  = asinh(dnnla_simul) 
qui gen ihs_dl2100_simul = asinh(dl2100_simul)
qui save "$hfcsoutputPath/data_mortgage_simul_compl.dta", replace                   // Save data locally (need 4 speed)

********************************************************************************
*  TOBIT SIMULATION UNDER CONSTRUCTION:
********************************************************************************
cls 
* Loop over implicates 1 to 5 at household level! 
forvalues im = 1(1)5{

qui use "$hfcsoutputPath/data_mortgage_simul_compl.dta", clear 
qui keep if im0100 == `im'                                                      // Keep one implicate 

* Run Tobit: No constant, same as Palligkinis (2017)
qui drop if inlist(sa0100,"FI")                                                 // drop countries with no new mortgages on the data: FI  
 local tobit_spec = "ihs_new_issued_mort already_mort ihs_dn3001 log_di2000_simul_net unemployed retired out_LF educ1 educ2 educ3 age1 age2 age3 age4  age5 couple female child dum_*"
qui tobit `tobit_spec' [aweight=hw0010] if im0100 == `im', ll                   // multicolinearity including all countries: drop constant 
qui predict ihs_mort_hat  , e(8,20) 
qui gen upp_mort_hat_limit = ihs_mort_hat + 0.5
qui gen low_mort_hat_limit = ihs_mort_hat - 0.5
qui predict mort_prob_hat ,pr(low_mort_hat_limit,upp_mort_hat_limit)            // interval computed in mort_simul_Development_TOBIT as good 
qui replace mort_prob_hat = mort_prob_hat + rnormal(0,1)
qui gen mort_hat = 0.5*exp(ihs_mort_hat)-1/exp(ihs_mort_hat)                    // convert to euros 
qui gen mort_hat_weight = mort_hat*hw0010                                       // accounts for household weights
 
 * Run OLS for debt services
qui reg ihs_dl2100_simul ihs_dl1100 dum_* if im0100 == `im'                        // OLS for debt services 
 sca R2_ds = 100*e(r2)
 di "++++++++++++++++++++++++++++++++++++++++++++++++++"
 di "      Debt Services R-squared = " R2_ds  "%"
 di "++++++++++++++++++++++++++++++++++++++++++++++++++"

* Project OLS on conditional mortgage from Tobit:
qui gen ihs_debt_serv_hat = _b[_cons] + _b[ihs_dl1100]*ihs_mort_hat + _b[dum_AT]*dum_AT + _b[dum_BE]*dum_BE + _b[dum_CY]*dum_CY + _b[dum_DE]*dum_DE + _b[dum_EE]*dum_EE + _b[ dum_ES]*dum_ES + _b[dum_FR]*dum_FR + _b[dum_GR]*dum_GR + _b[dum_HU]*dum_HU + _b[dum_IE]*dum_IE + _b[dum_IT]*dum_IT + _b[dum_LU]*dum_LU + _b[dum_LV]*dum_LV + _b[dum_MT]* dum_MT + _b[dum_NL]*dum_NL + _b[dum_PL]*dum_PL + _b[dum_PT]*dum_PT + _b[dum_SI]*dum_SI + _b[dum_SK]*dum_SK
qui gen debt_serv_hat = 0.5*exp(ihs_debt_serv_hat) - 1/exp(ihs_debt_serv_hat)
 
* Simulation:
local simul = $noOfSimulations                                                                   // 
forvalues j=1(1)`simul'{

 global varlist = "rand_LTV down_pay afford aux1 aux2 target new_mort mort_simul loan dn3001 da1120 Agg_Loans debt_serv"
foreach v of global varlist{
 qui  gen  `v'_`j' = .                                                             // create temporal variables 
}

foreach ii of global ctrylist {                                                 // Country loop
 
* 1) If aggregate Mortgages increases 
 local delta_mort = Scale_deltaMort_`ii' + Scale_NablaMort_`ii'

 if `delta_mort' > 0 {
 
   di "-------------------------------------------------------------------"
   di "------------`ii' Increases Mortgages: Run Simulation --------------"
   di "-------------------------------------------------------------------"

 *Loan-to-Value distribution                                                                          
qui replace rand_LTV_`j' = rbeta(2,2)   if sa0100 == "`ii'"  
qui replace rand_LTV_`j' = doltvratio if inrange(doltvratio,0,1) & new_issued_mort_ind == 1 & sa0100 == "`ii'"  // If has contracted a recent mortgage, same LTV                
qui replace rand_LTV_`j' = -rand_LTV_`j' if rand_LTV_`j' < 0 & sa0100 == "`ii'"   // dirty trick to avoid negative LTV 
 
 
 *Affordability & Down Payment 
qui  replace down_pay_`j' = (1-rand_LTV_`j')*mort_hat         if sa0100 == "`ii'"  // down payment 
qui  replace down_pay_`j' = 0              if rand_LTV_`j' >=1 & sa0100 == "`ii'"  // No downpayment for people with LTV>1 
qui  replace down_pay_`j' = .              if down_pay_`j'<0   & sa0100 == "`ii'"
qui  replace afford_`j'   = 0 if down_pay_`j'>dnnla_simul      & sa0100 == "`ii'"
qui  replace afford_`j'   = 1 if inrange(down_pay_`j',-0.5,dnnla_simul) & sa0100 == "`ii'"  // Affordable (and positive) 
                                   
* Sort by probability of getting a mortgage
gsort sa0100 -afford_`j'-mort_prob_hat                                          // sort country, afford (yes to no), and prob (high to low)
sca   Target_`ii'= Scale_deltaMort_`ii' + Scale_NablaMort_`ii'                  // Target = Delta + Nabla 
qui  replace aux1_`j' = sum(mort_hat_weight)        if sa0100 == "`ii'"         // Running sum over weighted predicted mortgages  
qui  replace aux2_`j' = 1 if aux1_`j' <= Target_`ii' & sa0100=="`ii'" & afford_`j'==1 // This number identify the last person affected by the simul

qui  replace new_mort_`j' = 0  if sa0100 =="`ii'"
qui  replace new_mort_`j' = 1  if aux2_`j'==1 & sa0100=="`ii'" & afford_`j'==1  // identify newly issued mortgages 
  
qui  replace loan_`j' = mort_hat if new_mort_`j' == 1 & sa0100 == "`ii'"        // New loan        
 
  * Aggregate newly issued loans
qui  sum loan_`j' [aw=hw0010]       if new_mort_`j' == 1 & sa0100 == "`ii'", d 
qui  replace Agg_Loans_`j' = r(sum)     if sa0100 == "`ii'"                     // just for one imp, so no need to divide by 5
	
  *Compute new debt services for those who contract a mortgage:
qui  replace debt_serv_`j' = dl2100_simul  if already_mort == 1 & new_mort_`j' == 1 // new debt services equal to the olds for people with mortgage
qui  replace debt_serv_`j' = debt_serv_hat if already_mort == 0 & new_mort_`j' == 1 // projection of services onto payments for people without mortgage 
qui  replace debt_serv_`j' = .             if                     new_mort_`j' != 1 
qui  replace debt_serv_`j' = debt_serv_hat if already_mort == 1 & new_mort_`j' == 1 & dl2100_simul > 0.25*loan_`j'  // do this to avoid having people contracting new mortgages with very high debt services. 
  }
 
 else {
    di "-------------------------------------------------------------------"
    di "-----`ii' Decreases Mortgages: collect target and skip-------------" 
    di "-------------------------------------------------------------------"
	
}
}	
   di "-------------------------------------------------------------------"
   di "-------------Simulation `j', implicate `im' Completed--------------"
   di "-------------------------------------------------------------------"
}


* Collect statistics on the simulation: 
 di "Compute mean cross simulations"
 
qui egen new_mort   = rowmean(new_mort_*)                                          // New Mortgage 
qui drop new_mort_*

qui egen afford     = rowmean(afford_*)                                            // Afford  
qui drop afford_*

qui egen down_pay   = rowmean(down_pay_*)                                          // Down Payment 
qui drop down_pay_* 

qui egen loan       = rowmean(loan_*)                                              // Issued loans 
qui drop loan_*

qui egen debt_serv  = rowmean(debt_serv_*)                                         // Debt Services
 
qui egen LTV        = rowmean(rand_LTV_*)                                          // LTV                                    
qui drop rand_LTV_*

qui egen Agg_Loans  = rowmean(Agg_Loans_*)
qui drop Agg_Loans_*
 
* Save result for one implicate

 di "-------------------------------------------------------------------"
 di "----------- Save results for implicate `im' -----------------------"
 di "-------------------------------------------------------------------"

qui save "$hfcsoutputPath/mortSimResults_imp`im'.dta", replace
}

qui use "$hfcsoutputPath/mortSimResults_imp1.dta", clear 
qui rm "$hfcsoutputPath/mortSimResults_imp1.dta"

forvalues im = 2(1)5 {
qui	append using "$hfcsoutputPath/mortSimResults_imp`im'.dta"
qui	rm "$hfcsoutputPath/mortSimResults_imp`im'.dta"
}

* Keep relevant variables
qui keep sa0100 sa0010 im0100 hw0010 id already_mort new_mort afford down_pay loan debt_serv LTV Agg_Loans ihs_new_issued_mort
qui save "$hfcsoutputPath/mort_simul_compl.dta", replace 











