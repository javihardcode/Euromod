

*** Perform the consumption imputation into w1 (AP 2014 + Error Correction of C et al 2019)

* Loop over all countries of w1

*** Housekeeping

global SOURCES  = "P:/ECB business areas/DGR/Databases and Programme files/DGR/Alessandro Pizzigolotto/data"
global HFCSDATA = "P:/ECB business areas/DGR/Databases and Programme files/DGR/Johannes Fleck/MicroSim_develop/1_0_2/data/input_w1"

global data_HBS  = "P:/ECB business areas/DGR/Databases and Programme files/DGR/Johannes Fleck/HFCS_consumption/hbsconsumption/data/sets/hbs/dta"
global data_HFCS = "P:/ECB business areas/DGR/Databases and Programme files/DGR/Johannes Fleck/MicroSim_develop/1_0_2/data/input_w1"
global FS_model  = "P:/ECB business areas/DGR/Databases and Programme files/DGR/Johannes Fleck/HFCS_consumption/Imputation_JF"
global output   =  "P:/ECB business areas/DGR/Databases and Programme files/DGR/Johannes Fleck/HFCS_consumption/Imputation_JF"


*** Fun will now commence
********************************************************************************


foreach ii of global ctrylist {

	if inlist("`ii'", "AT", "IT", "NL") di "No HBS data for AT and NL; IT no net income --> skipping"
	
	else {
	
*** Stage I: Estimate model parameters with HBS data

** Prepare HBS data

* Start with person dataset
use "$data_HBS/`ii'_HBS_hm.dta", clear

* Number of children
generate auxchild = ((age5 == 1 | age5 == 2 | age5 == 3 | age5 == 4) & (mb05 == 3 | missing(mb05) == 1))
bysort sa0100 ha04 : egen number_children = total(auxchild)
drop auxchild

* eur_mf099 is total net income by household member
bysort sa0100 ha04 : egen max_income = max(eur_mf099)

* calculate household size from here, hb05 has some missing values
bysort sa0100 ha04 : egen hhsize = count(pid)

* level of education in categories, not in years
generate educ = mc01
* labour status in categories
generate labour_status = me01
* sex
generate sex = mb02

keep if pid == 1

* marital status of the household head
generate couple = (mb04 == 2 | mb042 == 1)

generate familytype = .
replace  familytype = 1 if couple == 1 & number_children > 0
replace  familytype = 2 if couple == 1 & number_children == 0
replace  familytype = 3 if couple == 0 & number_children > 0
replace  familytype = 4 if couple == 0 & number_children == 0

keep sa0100 ha04 age5 educ labour_status sex number_children max_income familytype couple

* Merge family dataset
merge 1:1 sa0100 ha04 using "$data_HBS/`ii'_HBS_hh.dta"
drop if _m != 3
drop _m

* food consumption
* eur_he01   : food and non-alcoholic beverages
* eur_he0211 : spirits
* eur_he0212 : wine
* eur_HE0213 : beer
* eur_he111  : catering services
egen totalfood = rowtotal(eur_he01 eur_he0211 eur_he0212 eur_he0213 eur_he111)
label variable totalfood "Total food and beverage consumption"

* total consumption
gen C_hbs = eur_he00

* generate dummies for age
generate agerp_1 = (age5 > 0 & age5 < 7)
generate agerp_2 = (age5 == 7  | age5 == 8)
generate agerp_3 = (age5 == 9  | age5 == 10)
generate agerp_4 = (age5 == 11 | age5 == 12)
generate agerp_5 = (age5 == 13 | age5 == 14)
generate agerp_6 = (age5 >= 15)

* gender dummy
generate head_male = (sex == 1)

* household size dummy
generate hhsize = hb05

* household size dummies
generate hhsize_1 = (hhsize == 1)
generate hhsize_2 = (hhsize == 2)
generate hhsize_3 = (hhsize >= 3)

* number of children dummies
generate number_children_1 = (number_children == 1)
generate number_children_2 = (number_children == 2)
generate number_children_3 = (number_children >= 3)

* education level dummies
generate diploma_1 = (educ == 0 | educ == 1)
generate diploma_2 = (educ == 2)
generate diploma_3 = (educ == 3 | educ == 4)
generate diploma_5 = (educ == 5 | educ == 6)

* labour status dummies
* employed
generate labour_status_1 = (labour_status == 1)
* unemployed, student, housekeeper, disabled, on duty
generate labour_status_2 = (labour_status == 2 | (labour_status > 3 & labour_status < 8))
* retired
generate labour_status_3 = (labour_status == 3)

* Income quintiles
generate net_income = cond(missing(eur_hh095) == 1, 0, eur_hh095)
xtile dhiq01 = net_income [pw=ha10], n(5)

levelsof dhiq01, local(qtiles)
foreach q in `qtiles' {
    generate income_quintile_`q' = (dhiq01 == `q')
}

* Food polynomial
gen c_F  = totalfood/10^3
gen c_F2 = totalfood^2/10^6
gen c_F3 = totalfood^3/10^12

* total less food consumption
gen CminuscF_hbs = C_hbs - totalfood
*gen lnCminuscF_hbs = ln(CminuscF_hbs)
local remove CminuscF_hbs

** Run regression

local spec1 = "CminuscF_hbs c_F c_F2 c_F3 income_quintile_2 income_quintile_3 income_quintile_4 income_quintile_5 agerp_1 agerp_2 agerp_4 agerp_5 agerp_6 head_male hhsize_1 hhsize_3 number_children_1 number_children_2 number_children_3 diploma_1 diploma_2 diploma_5 labour_status_2 labour_status_3 couple"
regress `spec1' [pw=ha10]

** Save estimated coefficients, R2 and rmse

global FS_model_cols: list spec1 - remove
global FS_model_cols = "$FS_model_cols intercept R2 rmse"

matrix betas  = e(b)
matrix R2     = e(r2_a)
matrix rmse   = e(rmse)

matrix FS_model = betas, R2, rmse
matrix colnames FS_model = $FS_model_cols

clear

svmat FS_model, names(col)

* replace zeros with missing, for the omitted regressors due collinearity
foreach v of varlist *_* {
    replace `v' = . if `v' == 0
}

* rename variables so that we can use the same names in the hfcs code
rename *_* b_*_*
rename couple b_couple
rename intercept b_intercept

gen sa0100 = "`ii'"

save "$FS_model/params_FS_`ii'.dta", replace

}

}
*




*** Stage II: Feed HFCS data into estimated model

** Import HFCS data

* core variables from derived dataset
use "$data_HFCS/D1.dta", clear
keep id sa0100 sa0010 im0100 di2000 dh0001 da3001 dn3001 dhidh1

append using "$data_HFCS/D2.dta", keep(id sa0100 sa0010 im0100 di2000 dh0001 da3001 dn3001 dhidh1)
append using "$data_HFCS/D3.dta", keep(id sa0100 sa0010 im0100 di2000 dh0001 da3001 dn3001 dhidh1)
append using "$data_HFCS/D4.dta", keep(id sa0100 sa0010 im0100 di2000 dh0001 da3001 dn3001 dhidh1)
append using "$data_HFCS/D5.dta", keep(id sa0100 sa0010 im0100 di2000 dh0001 da3001 dn3001 dhidh1)

save "$output/temp_HFCS.dta", replace

* core variables at household level
* hi0210 amount spend on utilities ( -> hni0100 in the 1st wave ) * REMOVED
* hi0100 amount spent on food at home
* hi0200 amount spent on food outside home
* hb0300 tenure status
* hb2300 monthly amount paid as rent
use "$data_HFCS/H1.dta", clear
keep sa0100 sa0010 im0100 hw0010 hi0100 hi0200 hb0300 hb2300
append using "$data_HFCS/H2.dta", keep(sa0100 sa0010 im0100 hw0010 hi0100 hi0200 hb0300 hb2300)
append using "$data_HFCS/H3.dta", keep(sa0100 sa0010 im0100 hw0010 hi0100 hi0200 hb0300 hb2300)
append using "$data_HFCS/H4.dta", keep(sa0100 sa0010 im0100 hw0010 hi0100 hi0200 hb0300 hb2300)
append using "$data_HFCS/H5.dta", keep(sa0100 sa0010 im0100 hw0010 hi0100 hi0200 hb0300 hb2300)

merge 1:1 sa0100 sa0010 im0100 using "$output/temp_HFCS.dta"
drop if _merge !=3
drop _merge
save "$output/temp_HFCS.dta", replace

* non-core variables at household level
* hnb0920 HMR/Imputed Rent
* hni0210 expenditure on regular payments
* hni0300 total consumption expenditure (removed, not in the 2nd wave)
use "$data_HFCS/HN1.dta", clear
keep sa0100 sa0010 im0100 hnb0920 hni0210
append using "$data_HFCS/HN2.dta", keep(sa0100 sa0010 im0100 hnb0920 hni0210)
append using "$data_HFCS/HN3.dta", keep(sa0100 sa0010 im0100 hnb0920 hni0210)
append using "$data_HFCS/HN4.dta", keep(sa0100 sa0010 im0100 hnb0920 hni0210)
append using "$data_HFCS/HN5.dta", keep(sa0100 sa0010 im0100 hnb0920 hni0210)

merge 1:1 sa0100 sa0010 im0100 using "$output/temp_HFCS.dta"
drop if _merge !=3
drop _merge
save "$output/temp_HFCS.dta", replace

// if $NINCOME == 1 {
//     * variation of the original work : merge net income calculated by my program
//     * and use that income quintiles
//     * output of the other program of hfcs income
//     use "$data_HFCS/NINC1.dta", replace
//     keep sa0100 sa0010 im0100 di2001
//     append using "$data_HFCS/NINC2.dta", keep(sa0100 sa0010 im0100 di2001)
//     append using "$data_HFCS/NINC3.dta", keep(sa0100 sa0010 im0100 di2001)
//     append using "$data_HFCS/NINC4.dta", keep(sa0100 sa0010 im0100 di2001)
//     append using "$data_HFCS/NINC5.dta", keep(sa0100 sa0010 im0100 di2001)
//     merge 1:1 sa0100 sa0010 im0100 using "$output/temp_HFCS.dta"
//     drop if _merge !=3
//     drop _merge
//     save "$output/temp_HFCS.dta", replace
// }

* core variables at individual level
use "$data_HFCS/P1.dta", clear
keep sa0100 sa0010 im0100 ra0010 ra0100 ra0200 ra0300 pg0110 pg0210 pg0310 pg0410 pg0510 pe0100a pa0100 pa0200

append using "$data_HFCS/P2.dta", keep(sa0100 sa0010 im0100 ra0010 ra0100 ra0200 ra0300 pg0110 pg0210 pg0310 pg0410 pg0510 pe0100a pa0100 pa0200)
append using "$data_HFCS/P3.dta", keep(sa0100 sa0010 im0100 ra0010 ra0100 ra0200 ra0300 pg0110 pg0210 pg0310 pg0410 pg0510 pe0100a pa0100 pa0200)
append using "$data_HFCS/P4.dta", keep(sa0100 sa0010 im0100 ra0010 ra0100 ra0200 ra0300 pg0110 pg0210 pg0310 pg0410 pg0510 pe0100a pa0100 pa0200)
append using "$data_HFCS/P5.dta", keep(sa0100 sa0010 im0100 ra0010 ra0100 ra0200 ra0300 pg0110 pg0210 pg0310 pg0410 pg0510 pe0100a pa0100 pa0200)

* personal ID
gen dhidh1 = ra0010

* counting the number of children
* consider children all the individuals in the household at most 19yo
* before it was 18yo, but to be coherent with HBS we add one year more
sort sa0100 sa0010 im0100
gen auxchild = (ra0300 < 20 & (ra0100 == 3 | ra0300 == 7 | missing(ra0100) == 1))
by sa0100 sa0010 im0100 :  egen number_children = total(auxchild)
drop auxchild

merge 1:1 sa0100 sa0010 dhidh1 im0100 using "$output/temp_HFCS.dta"
keep if _merge == 3
drop _merge

sort id sa0100 sa0010 im0100

save "$output/temp_HFCS.dta", replace


* Feed into estimated model

foreach ii of global ctrylist {


use "$output/temp_HFCS.dta", clear	

keep if sa0100 == "`ii'"

** Compute covariates as inputs for the regression prediction

* NO MODEL ESTIMATES FOR AT, IT and NL. Use FR instead
if inlist("`ii'", "AT", "IT", "NL") { 

replace sa0100 = "FR"
merge m:1 sa0100 using "$output/params_FS_FR.dta"
drop if _merge != 3
drop _merge

replace sa0100 = "`ii'"

}

	
else {
merge m:1 sa0100 using "$output/params_FS_`ii'.dta"
drop if _merge != 3
drop _merge

}

generate cfood = cond(missing(hi0100) == 1, 0, hi0100 * 12)
generate cresto = cond(missing(hi0200) == 1, 0, hi0200 * 12)

// generate i_food = (hi0100 > 0 & missing(hi0100) == 0)
// generate i_resto =  (hi0200 > 0 & missing(hi0200) == 0)
// generate l_cfood = log(max(cfood, 1))
// generate l_cfood2 = l_cfood^2
// generate l_cfood3 = l_cfood^3
// generate l_cresto = log(max(cresto, 1))
// generate l_cresto2 = l_cresto^2
// generate l_cresto3 = l_cresto^3

* Scale food as in First Stage Estimation
gen c_F = (cfood + cresto)/10^3
gen c_F2 = c_F^2/10^6
gen c_F3 = c_F^3/10^12

generate rent = cond(missing(hb2300) == 1, 0, hb2300 * 12)
// generate l_rent = log(max(rent, 1))
// generate l_rent2 = l_rent^2
// generate l_rent3 = l_rent^3

generate head_male = (ra0200 == 1)

generate owner_or_free = (inlist(hb0300, 1, 2, 4))

generate hhsize_1 = (dh0001 == 1)
generate hhsize_3 = (dh0001 >= 3)

generate agerp_1 = (ra0300 < 30)
generate agerp_2 = (ra0300 >= 30 & ra0300 < 40)
generate agerp_3 = (ra0300 >= 40 & ra0300 < 50)
generate agerp_4 = (ra0300 >= 50 & ra0300 < 60)
generate agerp_5 = (ra0300 >= 60 & ra0300 < 70)
generate agerp_6 = (ra0300 >= 70)

generate number_children_1 = (number_children == 1)
generate number_children_2 = (number_children == 2)
generate number_children_3 = (number_children >= 3)

generate labour_status_1 = (inlist(pe0100a, 1, 2))
generate labour_status_2 = (inlist(pe0100a, 3, 4, 6, 7, 8, 9))
generate labour_status_3 = (pe0100a == 5)

generate diploma_1 = (pa0200 == 1)
generate diploma_2 = (pa0200 == 2)
generate diploma_5 = (pa0200 == 5)

generate couple = (inlist(pa0100, 2, 3))

* EDIT : net income quintiles

generate q1 = .
generate q2 = .
generate q3 = .
generate q4 = .
levelsof im0100, local(imputations)
*levelsof sa0100, local(countries)

// * select gross or net income for the quintiles
// if $NINCOME == 1 {
//     local incometype = "di2000"
// }
// else {
//     local incometype = "di2001"
// }

local incometype = "di2000"

    foreach i in `imputations' {
        _pctile `incometype' if im0100 == `i' [weight=hw0010], nq(5)
        scalar q1_`i' = r(r1)
        scalar q2_`i' = r(r2)
        scalar q3_`i' = r(r3)
        scalar q4_`i' = r(r4)
    }

    replace q1 = (q1_1 + q1_2 + q1_3 + q1_4 + q1_5) / 5 // if sa0100 == "`c'"
    replace q2 = (q2_1 + q2_2 + q2_3 + q2_4 + q2_5) / 5 // if sa0100 == "`c'"
    replace q3 = (q3_1 + q3_2 + q3_3 + q3_4 + q3_5) / 5 // if sa0100 == "`c'"
    replace q4 = (q4_1 + q4_2 + q4_3 + q4_4 + q4_5) / 5 // if sa0100 == "`c'"


generate income_quintile_1 = (`incometype' <= q1)
generate income_quintile_2 = (`incometype'  > q1 & `incometype' <= q2)
generate income_quintile_3 = (`incometype'  > q2 & `incometype' <= q3)
generate income_quintile_4 = (`incometype'  > q3 & `incometype' <= q4)
generate income_quintile_5 = (`incometype'  > q4)


** Feed into estimated model

* Initialize with intercept

generate X = b_intercept

local n_covariates : word count $FS_model_cols
local n_covariates = `n_covariates' - 3			// Remove intercept, R2, rmse

forval k = 1/`n_covariates' {

	local k_covariate `: word `k' of $FS_model_cols'
	
	generate k_tmp = `k_covariate' * b_`k_covariate'
	
	replace X = X + cond(missing(k_tmp) == 1, 0, k_tmp)
	
	drop k_tmp
	
}

* Add error correction a la Crossley 2019
gen error = rnormal(0, rmse)
gen Chat = c_F + X + error

keep Chat sa0100 sa0010 id im0100

save "$output/Chat_`ii'.dta", replace


}




* Combine countries into one file
local country1 `: word 1 of $ctrylist'

use "$output/Chat_`country1'.dta", clear
rm "$output/Chat_`country1'.dta"

local n_countries `: word count $ctrylist'
forval i = 2/`n_countries' {

 	local country `: word `i' of $ctrylist'
	
	append using "$output/Chat_`country'.dta", keep(sa0100 sa0010 im0100 id Chat)
 	rm "$output/Chat_`country'.dta"
	
}

 save "$output/Chat_ALL.dta", replace



//
//
//
//
//
//
//
//
//
//
//
//
// *** Stage I: Estimate model parameters with HBS data
//
// ** Prepare HBS data
//
// * Start with person dataset
// use "$data_HBS/FR_HBS_hm.dta", clear
//
// * Number of children
// generate auxchild = ((age5 == 1 | age5 == 2 | age5 == 3 | age5 == 4) & (mb05 == 3 | missing(mb05) == 1))
// bysort sa0100 ha04 : egen number_children = total(auxchild)
// drop auxchild
//
// * eur_mf099 is total net income by household member
// bysort sa0100 ha04 : egen max_income = max(eur_mf099)
//
// * calculate household size from here, hb05 has some missing values
// bysort sa0100 ha04 : egen hhsize = count(pid)
//
// * level of education in categories, not in years
// generate educ = mc01
// * labour status in categories
// generate labour_status = me01
// * sex
// generate sex = mb02
//
// keep if pid == 1
//
// * marital status of the household head
// generate couple = (mb04 == 2 | mb042 == 1)
//
// generate familytype = .
// replace  familytype = 1 if couple == 1 & number_children > 0
// replace  familytype = 2 if couple == 1 & number_children == 0
// replace  familytype = 3 if couple == 0 & number_children > 0
// replace  familytype = 4 if couple == 0 & number_children == 0
//
// keep sa0100 ha04 age5 educ labour_status sex number_children max_income familytype couple
//
// * Merge family dataset
// merge 1:1 sa0100 ha04 using "$data_HBS/FR_HBS_hh.dta"
// drop if _m != 3
// drop _m
//
// * food consumption
// * eur_he01   : food and non-alcoholic beverages
// * eur_he0211 : spirits
// * eur_he0212 : wine
// * eur_HE0213 : beer
// * eur_he111  : catering services
// egen totalfood = rowtotal(eur_he01 eur_he0211 eur_he0212 eur_he0213 eur_he111)
// label variable totalfood "Total food and beverage consumption"
//
// * total consumption
// gen C_hbs = eur_he00
//
// * generate dummies for age
// generate agerp_1 = (age5 > 0 & age5 < 7)
// generate agerp_2 = (age5 == 7  | age5 == 8)
// generate agerp_3 = (age5 == 9  | age5 == 10)
// generate agerp_4 = (age5 == 11 | age5 == 12)
// generate agerp_5 = (age5 == 13 | age5 == 14)
// generate agerp_6 = (age5 >= 15)
//
// * gender dummy
// generate head_male = (sex == 1)
//
// * household size dummy
// generate hhsize = hb05
//
// * household size dummies
// generate hhsize_1 = (hhsize == 1)
// generate hhsize_2 = (hhsize == 2)
// generate hhsize_3 = (hhsize >= 3)
//
// * number of children dummies
// generate number_children_1 = (number_children == 1)
// generate number_children_2 = (number_children == 2)
// generate number_children_3 = (number_children >= 3)
//
// * education level dummies
// generate diploma_1 = (educ == 0 | educ == 1)
// generate diploma_2 = (educ == 2)
// generate diploma_3 = (educ == 3 | educ == 4)
// generate diploma_5 = (educ == 5 | educ == 6)
//
// * labour status dummies
// * employed
// generate labour_status_1 = (labour_status == 1)
// * unemployed, student, housekeeper, disabled, on duty
// generate labour_status_2 = (labour_status == 2 | (labour_status > 3 & labour_status < 8))
// * retired
// generate labour_status_3 = (labour_status == 3)
//
// * Income quintiles
// generate net_income = cond(missing(eur_hh095) == 1, 0, eur_hh095)
// xtile dhiq01 = net_income [pw=ha10], n(5)
//
// levelsof dhiq01, local(qtiles)
// foreach q in `qtiles' {
//     generate income_quintile_`q' = (dhiq01 == `q')
// }
//
// * Food polynomial
// gen c_F  = totalfood/10^3
// gen c_F2 = totalfood^2/10^6
// gen c_F3 = totalfood^3/10^12
//
// * total less food consumption
// gen CminuscF_hbs = C_hbs - totalfood
// *gen lnCminuscF_hbs = ln(CminuscF_hbs)
// local remove CminuscF_hbs
//
// ** Run regression
//
// local spec1 = "CminuscF_hbs c_F c_F2 c_F3 income_quintile_2 income_quintile_3 income_quintile_4 income_quintile_5 agerp_1 agerp_2 agerp_4 agerp_5 agerp_6 head_male hhsize_1 hhsize_3 number_children_1 number_children_2 number_children_3 diploma_1 diploma_2 diploma_5 labour_status_2 labour_status_3 couple"
// regress `spec1' [pw=ha10]
//
// ** Save estimated coefficients, R2 and rmse
//
// global FS_model_cols: list spec1 - remove
// global FS_model_cols = "$FS_model_cols intercept R2 rmse"
//
// matrix betas  = e(b)
// matrix R2     = e(r2_a)
// matrix rmse   = e(rmse)
//
// matrix FS_model = betas, R2, rmse
// matrix colnames FS_model = $FS_model_cols
//
// clear
//
// svmat FS_model, names(col)
//
// * replace zeros with missing, for the omitted regressors due collinearity
// foreach v of varlist *_* {
//     replace `v' = . if `v' == 0
// }
//
// * rename variables so that we can use the same names in the hfcs code
// rename *_* b_*_*
// rename couple b_couple
// rename intercept b_intercept
//
// gen sa0100 = "FR"
//
// save "$FS_model/params_FS.dta", replace
//
//
//
//
// *** Stage II: Feed HFCS data into estimated model
//
// ** Import HFCS data
//
// * core variables from derived dataset
// use "$data_HFCS/D1.dta", clear
// keep id sa0100 sa0010 im0100 di2000 dh0001 da3001 dn3001 dhidh1
//
// append using "$data_HFCS/D2.dta", keep(id sa0100 sa0010 im0100 di2000 dh0001 da3001 dn3001 dhidh1)
// append using "$data_HFCS/D3.dta", keep(id sa0100 sa0010 im0100 di2000 dh0001 da3001 dn3001 dhidh1)
// append using "$data_HFCS/D4.dta", keep(id sa0100 sa0010 im0100 di2000 dh0001 da3001 dn3001 dhidh1)
// append using "$data_HFCS/D5.dta", keep(id sa0100 sa0010 im0100 di2000 dh0001 da3001 dn3001 dhidh1)
//
// save "$output/temp_HFCS.dta", replace
//
// * core variables at household level
// * hi0210 amount spend on utilities ( -> hni0100 in the 1st wave )
// * hi0100 amount spent on food at home
// * hi0200 amount spent on food outside home
// * hb0300 tenure status
// * hb2300 monthly amount paid as rent
// use "$data_HFCS/H1.dta", clear
// keep sa0100 sa0010 im0100 hw0010 hi0100 hi0200 hb0300 hb2300
// append using "$data_HFCS/H2.dta", keep(sa0100 sa0010 im0100 hw0010 hi0100 hi0200 hi0210 hb0300 hb2300)
// append using "$data_HFCS/H3.dta", keep(sa0100 sa0010 im0100 hw0010 hi0100 hi0200 hi0210 hb0300 hb2300)
// append using "$data_HFCS/H4.dta", keep(sa0100 sa0010 im0100 hw0010 hi0100 hi0200 hi0210 hb0300 hb2300)
// append using "$data_HFCS/H5.dta", keep(sa0100 sa0010 im0100 hw0010 hi0100 hi0200 hi0210 hb0300 hb2300)
//
// merge 1:1 sa0100 sa0010 im0100 using "$output/temp_HFCS.dta"
// drop if _merge !=3
// drop _merge
// save "$output/temp_HFCS.dta", replace
//
// * non-core variables at household level
// * hnb0920 HMR/Imputed Rent
// * hni0210 expenditure on regular payments
// * hni0300 total consumption expenditure (removed, not in the 2nd wave)
// use "$data_HFCS/HN1.dta", clear
// keep sa0100 sa0010 im0100 hnb0920 hni0210
// append using "$data_HFCS/HN2.dta", keep(sa0100 sa0010 im0100 hnb0920 hni0210)
// append using "$data_HFCS/HN3.dta", keep(sa0100 sa0010 im0100 hnb0920 hni0210)
// append using "$data_HFCS/HN4.dta", keep(sa0100 sa0010 im0100 hnb0920 hni0210)
// append using "$data_HFCS/HN5.dta", keep(sa0100 sa0010 im0100 hnb0920 hni0210)
//
// merge 1:1 sa0100 sa0010 im0100 using "$output/temp_HFCS.dta"
// drop if _merge !=3
// drop _merge
// save "$output/temp_HFCS.dta", replace
//
// // if $NINCOME == 1 {
// //     * variation of the original work : merge net income calculated by my program
// //     * and use that income quintiles
// //     * output of the other program of hfcs income
// //     use "$data_HFCS/NINC1.dta", replace
// //     keep sa0100 sa0010 im0100 di2001
// //     append using "$data_HFCS/NINC2.dta", keep(sa0100 sa0010 im0100 di2001)
// //     append using "$data_HFCS/NINC3.dta", keep(sa0100 sa0010 im0100 di2001)
// //     append using "$data_HFCS/NINC4.dta", keep(sa0100 sa0010 im0100 di2001)
// //     append using "$data_HFCS/NINC5.dta", keep(sa0100 sa0010 im0100 di2001)
// //     merge 1:1 sa0100 sa0010 im0100 using "$output/temp_HFCS.dta"
// //     drop if _merge !=3
// //     drop _merge
// //     save "$output/temp_HFCS.dta", replace
// // }
//
// * core variables at individual level
// use "$data_HFCS/P1.dta", clear
// keep sa0100 sa0010 im0100 ra0010 ra0100 ra0200 ra0300 pg0110 pg0210 pg0310 pg0410 pg0510 pe0100a pa0100 pa0200
//
// append using "$data_HFCS/P2.dta", keep(sa0100 sa0010 im0100 ra0010 ra0100 ra0200 ra0300 pg0110 pg0210 pg0310 pg0410 pg0510 pe0100a pa0100 pa0200)
// append using "$data_HFCS/P3.dta", keep(sa0100 sa0010 im0100 ra0010 ra0100 ra0200 ra0300 pg0110 pg0210 pg0310 pg0410 pg0510 pe0100a pa0100 pa0200)
// append using "$data_HFCS/P4.dta", keep(sa0100 sa0010 im0100 ra0010 ra0100 ra0200 ra0300 pg0110 pg0210 pg0310 pg0410 pg0510 pe0100a pa0100 pa0200)
// append using "$data_HFCS/P5.dta", keep(sa0100 sa0010 im0100 ra0010 ra0100 ra0200 ra0300 pg0110 pg0210 pg0310 pg0410 pg0510 pe0100a pa0100 pa0200)
//
// * personal ID
// gen dhidh1 = ra0010
//
// * counting the number of children
// * consider children all the individuals in the household at most 19yo
// * before it was 18yo, but to be coherent with HBS we add one year more
// sort sa0100 sa0010 im0100
// gen auxchild = (ra0300 < 20 & (ra0100 == 3 | ra0300 == 7 | missing(ra0100) == 1))
// by sa0100 sa0010 im0100 :  egen number_children = total(auxchild)
// drop auxchild
//
// merge 1:1 sa0100 sa0010 dhidh1 im0100 using "$output/temp_HFCS.dta"
// keep if _merge == 3
// drop _merge
//
// sort id sa0100 sa0010 im0100
//
// keep if sa0100 == "FR"
//
// save "$output/temp_HFCS.dta", replace
//
//
//
// ** Compute covariates as inputs for the regression prediction
//
// merge m:1 sa0100 using "$output/params_FS.dta"
// drop if _merge != 3
// drop _merge
//
// generate cfood = cond(missing(hi0100) == 1, 0, hi0100 * 12)
// generate cresto = cond(missing(hi0200) == 1, 0, hi0200 * 12)
//
// // generate i_food = (hi0100 > 0 & missing(hi0100) == 0)
// // generate i_resto =  (hi0200 > 0 & missing(hi0200) == 0)
// // generate l_cfood = log(max(cfood, 1))
// // generate l_cfood2 = l_cfood^2
// // generate l_cfood3 = l_cfood^3
// // generate l_cresto = log(max(cresto, 1))
// // generate l_cresto2 = l_cresto^2
// // generate l_cresto3 = l_cresto^3
//
// * Scale food as in First Stage Estimation
// gen c_F = (cfood + cresto)/10^3
// gen c_F2 = c_F^2/10^6
// gen c_F3 = c_F^3/10^12
//
// generate rent = cond(missing(hb2300) == 1, 0, hb2300 * 12)
// // generate l_rent = log(max(rent, 1))
// // generate l_rent2 = l_rent^2
// // generate l_rent3 = l_rent^3
//
// generate head_male = (ra0200 == 1)
//
// generate owner_or_free = (inlist(hb0300, 1, 2, 4))
//
// generate hhsize_1 = (dh0001 == 1)
// generate hhsize_3 = (dh0001 >= 3)
//
// generate agerp_1 = (ra0300 < 30)
// generate agerp_2 = (ra0300 >= 30 & ra0300 < 40)
// generate agerp_3 = (ra0300 >= 40 & ra0300 < 50)
// generate agerp_4 = (ra0300 >= 50 & ra0300 < 60)
// generate agerp_5 = (ra0300 >= 60 & ra0300 < 70)
// generate agerp_6 = (ra0300 >= 70)
//
// generate number_children_1 = (number_children == 1)
// generate number_children_2 = (number_children == 2)
// generate number_children_3 = (number_children >= 3)
//
// generate labour_status_1 = (inlist(pe0100a, 1, 2))
// generate labour_status_2 = (inlist(pe0100a, 3, 4, 6, 7, 8, 9))
// generate labour_status_3 = (pe0100a == 5)
//
// generate diploma_1 = (pa0200 == 1)
// generate diploma_2 = (pa0200 == 2)
// generate diploma_5 = (pa0200 == 5)
//
// generate couple = (inlist(pa0100, 2, 3))
//
// * EDIT : net income quintiles
//
// generate q1 = .
// generate q2 = .
// generate q3 = .
// generate q4 = .
// levelsof im0100, local(imputations)
// *levelsof sa0100, local(countries)
//
// // * select gross or net income for the quintiles
// // if $NINCOME == 1 {
// //     local incometype = "di2000"
// // }
// // else {
// //     local incometype = "di2001"
// // }
//
// local incometype = "di2000"
//
// foreach c in `countries' {
//
//     foreach i in `imputations' {
//         _pctile `incometype' if im0100 == `i' [weight=hw0010], nq(5)
//         scalar q1_`i' = r(r1)
//         scalar q2_`i' = r(r2)
//         scalar q3_`i' = r(r3)
//         scalar q4_`i' = r(r4)
//     }
//
//     replace q1 = (q1_1 + q1_2 + q1_3 + q1_4 + q1_5) / 5 // if sa0100 == "`c'"
//     replace q2 = (q2_1 + q2_2 + q2_3 + q2_4 + q2_5) / 5 // if sa0100 == "`c'"
//     replace q3 = (q3_1 + q3_2 + q3_3 + q3_4 + q3_5) / 5 // if sa0100 == "`c'"
//     replace q4 = (q4_1 + q4_2 + q4_3 + q4_4 + q4_5) / 5 // if sa0100 == "`c'"
//
// }
//
// generate income_quintile_1 = (`incometype' <= q1)
// generate income_quintile_2 = (`incometype'  > q1 & `incometype' <= q2)
// generate income_quintile_3 = (`incometype'  > q2 & `incometype' <= q3)
// generate income_quintile_4 = (`incometype'  > q3 & `incometype' <= q4)
// generate income_quintile_5 = (`incometype'  > q4)
//
//
// ** Feed into estimated model
//
// * Initialize with intercept
//
// generate X = b_intercept
//
// local n_covariates : word count $FS_model_cols
// local n_covariates = `n_covariates' - 3			// Remove intercept, R2, rmse
//
// forval k = 1/`n_covariates' {
//
// 	local k_covariate `: word `k' of $FS_model_cols'
//	
// 	generate k_tmp = `k_covariate' * b_`k_covariate'
//	
// 	replace X = X + cond(missing(k_tmp) == 1, 0, k_tmp)
//	
// 	drop k_tmp
//	
// }
//
// * Add error correction a la Crossley 2019
// gen error = rnormal(0, rmse)
//
// gen Chat = c_F + X + error
//
//
//
// * Do some comparisons
// gen HFCS_cons = cfood + cresto + rent

