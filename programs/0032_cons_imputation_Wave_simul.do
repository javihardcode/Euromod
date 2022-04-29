*** Impute household consumption for all countries of Simulated Wave 3

* Javier Ramos Perez 03-11-2021
* 04-11-2021: working 

** Generates two imputed household consumption variables:
** 1) Chat 				As in Lamarche 2017
** 2) Chat_c 			Implements the error correction proposed in "Regression with an Imputed Dependent Variable" (Crossley, Levell, Poupakis 2019) 

********************************************************************************
* Change 29-04-2022 : 
* if updated quarter = 2020Q1,  2020Q2, 2020Q3,  2020Q4: 
* recompute HBS regression substracting items not-available during COVID. 


* basic idea: keeps everything as in Stage I, but reduce the level of the endogenous variable: 

* Change in MPC:: ilustration: 

* Case 1:   100 income --> 80 consumption:   MPC = 0.8 
* Case 2:   90  income --> 65 consumption:   MPC = 0.72 

* Question: what about the other regressors?? 

foreach ii of global ctrylist {

	if inlist("`ii'", "AT", "IT", "NL", "HR", "LT") di "No HBS data for AT and NL; IT no net income --> skipping"
	
	else {

** Prepare HBS data

* Start with person dataset
qui use "$data_HBS/`ii'_HBS_hm.dta", clear

* Number of children
qui generate auxchild = ((age5 == 1 | age5 == 2 | age5 == 3 | age5 == 4) & (mb05 == 3 | missing(mb05) == 1))     // Number of children
bysort sa0100 ha04 : egen number_children = total(auxchild)
qui drop auxchild

* eur_mf099 is total net income by household member
bysort sa0100 ha04 : egen max_income = max(eur_mf099)

* calculate household size from here, hb05 has some missing values
bysort sa0100 ha04 : egen hhsize = count(pid)

* level of education in categories, not in years
qui generate educ = mc01
* labour status in categories
qui generate labour_status = me01
* sex
qui generate sex = mb02

qui keep if pid == 1

* marital status of the household head
qui generate couple = (mb04 == 2 | mb042 == 1)

qui generate familytype = .
qui replace  familytype = 1 if couple == 1 & number_children > 0
qui replace  familytype = 2 if couple == 1 & number_children == 0
qui replace  familytype = 3 if couple == 0 & number_children > 0
qui replace  familytype = 4 if couple == 0 & number_children == 0

qui keep sa0100 ha04 age5 educ labour_status sex number_children max_income familytype couple

* Merge family dataset
qui merge 1:1 sa0100 ha04 using "$data_HBS/`ii'_HBS_hh.dta"
qui drop if _m != 3
qui drop _m

* food consumption
* eur_he01   : food and non-alcoholic beverages
* eur_he0211 : spirits
* eur_he0212 : wine
* eur_HE0213 : beer
* eur_he111  : catering services
qui egen totalfood = rowtotal(eur_he01 eur_he0211 eur_he0212 eur_he0213 eur_he111)
label variable totalfood "Total food and beverage consumption"

* total consumption
qui gen C_hbs = eur_he00

* generate dummies for age
qui generate agerp_1 = (age5 > 0 & age5 < 7)
qui generate agerp_2 = (age5 == 7  | age5 == 8)
qui generate agerp_3 = (age5 == 9  | age5 == 10)
qui generate agerp_4 = (age5 == 11 | age5 == 12)
qui generate agerp_5 = (age5 == 13 | age5 == 14)
qui generate agerp_6 = (age5 >= 15)

* gender dummy
qui generate head_male = (sex == 1)

* household size dummy
qui generate hhsize = hb05

* household size dummies
qui generate hhsize_1 = (hhsize == 1)
qui generate hhsize_2 = (hhsize == 2)
qui generate hhsize_3 = (hhsize >= 3)

* number of children dummies
qui generate number_children_1 = (number_children == 1)
qui generate number_children_2 = (number_children == 2)
qui generate number_children_3 = (number_children >= 3)

* education level dummies
qui generate diploma_1 = (educ == 0 | educ == 1)
qui generate diploma_2 = (educ == 2)
qui generate diploma_3 = (educ == 3 | educ == 4)
qui generate diploma_5 = (educ == 5 | educ == 6)

* labour status dummies
* employed
qui generate labour_status_1 = (labour_status == 1)
* unemployed, student, housekeeper, disabled, on duty
qui generate labour_status_2 = (labour_status == 2 | (labour_status > 3 & labour_status < 8))
* retired
qui generate labour_status_3 = (labour_status == 3)


* Income quintiles (changed to deciles)                                         // !!! Eliminate income quintiles
qui generate net_income = cond(missing(eur_hh095) == 1, 0, eur_hh095)           

* Food polynomial
qui gen c_F  = totalfood/10^3
qui gen c_F2 = totalfood^2/10^6
qui gen c_F3 = totalfood^3/10^12

* total less food consumption
qui gen CminuscF_hbs = C_hbs                                                    //!!!- totalfood temporal changes                                    
local remove CminuscF_hbs

* Compute consumption & net-income deciles 
qui xtile CminuscF_hbs_xtile = CminuscF_hbs [aw=ha10], nq($numqj)

if "$UseIncDist" == "1" {
qui xtile Income_hbs_xtile   = eur_hh095    [aw=ha10], nq($numqk)
}

if "$UseIncDist" == "0" {
qui gen Income_hbs_xtile   = 1 
}



forval k = 1/$numqk{
forval j = 1/$numqj{
qui sum CminuscF_hbs [aw=ha10] if CminuscF_hbs_xtile == `j' & Income_hbs_xtile == `k',d     
sca Agg_CminusF_hbs_xtile_`k'_`j'_`ii' = r(sum)
}
}


qui sum CminuscF_hbs [aw=ha10],d                                                // agg total consumption  
sca Agg_CminusF_hbs_total_`ii' = r(sum)

forval k = 1/$numqk{
forval j = 1/$numqj{
sca Share`k'`j'_hbs_`ii' = Agg_CminusF_hbs_xtile_`k'_`j'_`ii' / Agg_CminusF_hbs_total_`ii' // Share parameter for the calibration. 
*di "`ii' Consumption share Income decile `k' and Consumption decile `j' = " Share`k'`j'_hbs_`ii'
}
}


** Run regression

local spec1 = "CminuscF_hbs c_F c_F2 c_F3 net_income agerp_1 agerp_2 agerp_4 agerp_5 agerp_6 head_male hhsize_1 hhsize_3 number_children_1 number_children_2 number_children_3 diploma_1 diploma_2 diploma_5 labour_status_2 labour_status_3 couple"
regress `spec1' [pw=ha10], robust
 sca R2_`ii' = 100*e(r2)
 sca  N_`ii' = e(N)
 
 di "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
 di "HBS regression `ii': R-Squared = " R2_`ii' "%  ,"  "N ="  N_`ii' 
 di "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
 
** Save estimated coefficients, R2 and rmse

global FS_model_cols: list spec1 - remove
global FS_model_cols = "$FS_model_cols intercept R2 rmse"

qui matrix betas  = e(b)
qui matrix R2     = e(r2_a)
qui matrix rmse   = e(rmse)

qui matrix FS_model = betas, R2, rmse
qui matrix colnames FS_model = $FS_model_cols

clear

qui svmat FS_model, names(col)

* replace zeros with missing, for the omitted regressors due collinearity
foreach v of varlist *_* {
 qui   replace `v' = . if `v' == 0
}

* rename variables so that we can use the same names in the hfcs code
qui rename *_* b_*_*
qui rename couple b_couple
qui rename intercept b_intercept

qui gen sa0100 = "`ii'"

                      	        
qui save "$basePath/data/output/params_FS_`ii'.dta", replace
	
}
}


* Do this to account for countries with missing HBS waves 
global countries_no_HBS = "AT IT NL HR LV"
foreach c of global countries_no_HBS{ 
forval  k = 1/$numqk{
forval  j = 1/$numqj{
sca Share`k'`j'_hbs_`c' = Share`k'`j'_hbs_FR
}
}
}













********************************************************************************


** 1. Feed HFCS Simulated Wave 3 data with estimation parameters from HBS 


* Open organized data from the Stage II of Wave 2 imputation and merge with simulated Wave 3 to retrieve di2000_simul_net 
qui use "$hfcsinputPath/temp_HFCS.dta", clear
qui merge m:m sa0100 sa0010 id using "$hfcsinputPath/D_compl_MicroSim_$UpdateTo.dta" // 100% matched                        
qui drop _merge
 
qui save "$hfcsinputPath/temp_HFCS2.dta", replace


** 2. Feed into estimated model

foreach ii of global ctrylist {

qui use "$hfcsinputPath/temp_HFCS2.dta", clear

qui keep if sa0100 == "`ii'"

** Compute covariates as inputs for the regression prediction

* NO MODEL ESTIMATES FOR AT, IT and NL. Use FR instead
if inlist("`ii'", "AT", "IT", "NL", "HR", "LT") { 

qui replace sa0100 = "FR"
*merge m:1 sa0100 using "P:/ECB business areas/DGR/Databases and Programme files/DGR/Javier Ramos/microsim/1_0_2/data/output/params_FS_FR.dta"
qui merge m:1 sa0100 using "$basePath/data/output/params_FS_FR.dta"
qui drop if _merge != 3
qui drop _merge

qui replace sa0100 = "`ii'"

}

	
else {
*merge m:1 sa0100 using "P:/ECB business areas/DGR/Databases and Programme files/DGR/Javier Ramos/microsim/1_0_2/data/output/params_FS_`ii'.dta"
qui merge m:1 sa0100 using "$basePath/data/output/params_FS_`ii'.dta"
qui drop if _merge != 3
qui drop _merge

}

qui generate cfood = cond(missing(hi0100) == 1, 0, hi0100 * 12)
qui generate cresto = cond(missing(hi0200) == 1, 0, hi0200 * 12)

*** ad-hoc change 
qui replace cresto = 0 


* Scale food as in First Stage Estimation
qui gen c_F = (cfood + cresto)/10^3
qui gen c_F2 = c_F^2/10^6
qui gen c_F3 = c_F^3/10^12

qui generate rent = cond(missing(hb2300) == 1, 0, hb2300 * 12)
// generate l_rent = log(max(rent, 1))
// generate l_rent2 = l_rent^2
// generate l_rent3 = l_rent^3

qui generate head_male = (ra0200 == 1)

qui generate owner_or_free = (inlist(hb0300, 1, 2, 4))

qui generate hhsize_1 = (dh0001 == 1)
qui generate hhsize_3 = (dh0001 >= 3)


*Update ra0300 according to the number of simulated years:
qui generate ra0300_simul = ra0300 + sim_Y_inc_`ii'  
qui generate agerp_1 = (ra0300_simul < 30)
qui generate agerp_2 = (ra0300_simul >= 30 & ra0300_simul < 40)
qui generate agerp_3 = (ra0300_simul >= 40 & ra0300_simul < 50)
qui generate agerp_4 = (ra0300_simul >= 50 & ra0300_simul < 60)
qui generate agerp_5 = (ra0300_simul >= 60 & ra0300_simul < 70)
qui generate agerp_6 = (ra0300_simul >= 70)

qui generate number_children_1 = (number_children == 1)
qui generate number_children_2 = (number_children == 2)
qui generate number_children_3 = (number_children >= 3)


* We need to modify this in order to consider status changes in the consumption Simulation: 
qui generate labour_status_1 = (inrange(job_aftershock, 0.3,1))
qui generate labour_status_2 = (inrange(job_aftershock, 0,0.29)) | (job_aftershock == . & inlist(pe0100a,3,4,6,7,8,9))
qui generate labour_status_3 = 1 if job_aftershock == . & pe0100a == 5               // Retired people 

* 
qui generate diploma_1 = (pa0200 == 1)
qui generate diploma_2 = (pa0200 == 2)
qui generate diploma_5 = (pa0200 == 5)

qui generate couple = (inlist(pa0100, 2, 3))


* Net Income 
qui gen net_income = di2000_simul_net

* Load estimated parameters to feed data into estimated model 

* Initialize with intercept
qui generate X = b_intercept

local n_covariates : word count $FS_model_cols
local n_covariates = `n_covariates' - 3			                                // Remove intercept, R2, rmse

forval k = 1/`n_covariates' {

	local k_covariate `: word `k' of $FS_model_cols'
	
qui	generate k_tmp = `k_covariate' * b_`k_covariate'
	
qui	replace X = X + cond(missing(k_tmp) == 1, 0, k_tmp)
	
qui	drop k_tmp
	
}

qui gen di3000_simul = HICP_growth_`ii'*(c_F + X)

* Add error correction a la Crossley, Levell and Poupakis 2019

qui gen error = rnormal(0, rmse)
qui gen di3000_c_simul = HICP_growth_`ii'*(c_F + X + error)

qui keep di3000_simul di3000_c_simul sa0100 sa0010 id im0100 di2000_simul hi0100 hi0200 di2000_simul_net

qui save "$basePath/data/output/Chat_`ii'_wave_simul.dta", replace
}


** 3. Combine countries into one file
local country1 `: word 1 of $ctrylist'
qui use "$basePath/data/output/Chat_`country1'_wave_simul.dta", clear
qui rm  "$basePath/data/output/Chat_`country1'_wave_simul.dta"

local n_countries `: word count $ctrylist'
forval i = 2/`n_countries' {

 	local country `: word `i' of $ctrylist'
	
qui	append using "$basePath/data/output/Chat_`country'_wave_simul.dta", keep(sa0100 sa0010 im0100 id di3000_simul di3000_c_simul di2000_simul di2000_simul_net)
qui	rm "$basePath/data/output/Chat_`country'_wave_simul.dta"
	
}

*save "P:/ECB business areas/DGR/Databases and Programme files/DGR/Javier Ramos/microsim/1_0_2/data/output/Chat_ALL.dta", replace

* Write everything as initially in Chat_ALL:
qui keep  sa0010 sa0100 im0100 id di3000_simul di3000_c_simul di2000_simul di2000_simul_net hi0200 


*save "P:/ECB business areas/DGR/Databases and Programme files/DGR/Javier Ramos/microsim/1_0_2/data/output/Chat_ALL.dta", replace
qui save "$hfcsinputPath/Chat_ALL1_wave_simul.dta", replace      


