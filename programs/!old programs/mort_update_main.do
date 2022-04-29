
*** WHAT DOES THIS FILE DO?: Runs the tobit regression as in Palligkinis 2017 (table 1)
* 08-12-2021 Javier Ramos 
* Working on last version

** 1. Prepare H files so that year when mortgage was taken out can be merged to D_compl

* Change directories to open  HFCS Wave 2
use "D:\data\hfcs\wave2/h1.dta", clear
append using "D:\data\hfcs\wave2/h2.dta"
append using "D:\data\hfcs\wave2/h3.dta"
append using "D:\data\hfcs\wave2/h4.dta"
append using "D:\data\hfcs\wave2/h5.dta"
keep im0100 sa0100 sa0010 hb1301 hb1010

* hb1010: number of mortgages or loans using HMR as collateral
* -> use this variable to create "already has mortgage index" (NOT IN w1 D_compl)
gen already_mort = 0																
replace already_mort = 1 if hb1010 > 1								
drop hb1010

* hb1301: HMR mortgage $x: year when loan taken or refinanced
* -> Set all hhs without mortgage as taken out in year 0
replace hb1301 = 0 if hb1301 == .

save "$dataoutputPath/mort_year.dta", replace	


** 2. Prepare data inputs for Tobit estimation (P files)

use "D:\data\hfcs\wave2/p1.dta", clear
append using "D:\data\hfcs\wave2/p2.dta"
append using "D:\data\hfcs\wave2/p3.dta"
append using "D:\data\hfcs\wave2/p4.dta"
append using "D:\data\hfcs\wave2/p5.dta"
rename *, lower
keep im0100 sa0100 sa0010 pe0100a pa0200 ra0300 pa0100 ra0200 ra0100

/* COVARIATES FOR TOBIT REGRESSION
unemployed / retired / out of job market: pe0100a
educ (lower sec) / educ (upper sec) / tertiary: pa0200
Age: 35-44 / Age: 45-54 / Age: 55-64 / Age: 65-74 / Age: 75 and above: ra0300
couple: pa0100 (marital status)
female: ra0200 (gender)
has a child: ra0100 (relship to RP)
(in D_compl: DHIDH1 RP as of Canberra definition)
*/

gen unemployed = 0
replace unemployed = 1 if pe0100a == 3
gen retired = 0
replace retired = 1 if pe0100a == 5
gen out_LF = 0
replace out_LF = 1 if pe0100a==4 | pe0100a==6 | pe0100a==7 | pe0100a==8| pe0100a==9

gen educ1 = 0
replace educ1 = 1 if pa0200 == 2
gen educ2 = 0
replace educ2 = 1 if pa0200 == 3
gen educ3 = 0
replace educ3 = 1 if pa0200 == 5

gen age1 = 0
replace age1 = 1 if ra0300 > 34 & ra0300 < 45
gen age2 = 0
replace age2 = 1 if ra0300 > 44 & ra0300 < 55
gen age3 = 0
replace age3 = 1 if ra0300 > 54 & ra0300 < 65
gen age4 = 0
replace age4 = 1 if ra0300 > 64 & ra0300 < 75
gen age5 = 0
replace age5 = 1 if ra0300 >= 74

gen female = 0
replace female = 1 if ra0200 == 2

gen child = 0
replace child = 1 if ra0300 < 19
by sa0100 sa0010 im0100, sort: egen n_child = sum(child)
replace child = 1 if n_child > 0
drop n_child

* Couple: using pa0100 for all except FI, CY and ra0100 for them 
gen couple1 = 0
replace couple1 = 1 if pa0100 == 2 | pa0100 == 3

gen spouse_tmp = 0
replace spouse_tmp = 1 if ra0100 == 2
by sa0100 sa0010 im0100, sort: egen spouse_fam_tmp = sum(spouse_tmp)
gen couple2 = 0
replace couple2 = 1 if spouse_fam_tmp > 0
drop spouse_tmp spouse_fam_tmp

replace couple1 = couple2
drop couple2
rename couple1 couple

* Keep only reference person and drop all non-input variables
keep if ra0100 == 1
drop pe0100a pa0200 ra0300 pa0100 ra0200 ra0100

save "$dataoutputPath/tobit_data.dta", replace	                                // saved on the :P file 


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


*use $datainputPath                                                             // whats this??
use "P:\ECB business areas\DGR\Databases and Programme files\DGR\Johannes Fleck\MicroSim_develop\1_0_2\data\input_w2\D_compl.dta", clear

keep sa0100 sa0010 im0100 hw0010 dn3001 di2000 dl1100
sort sa0100
* keep sa0100 sa0010 im0100 hw0010 dn3001 di2000 dl1110 // only HMR mortgage

foreach ii of global ctrylist {
	preserve

	keep if sa0100 == "`ii'"
	
	* Get sum of all mortgage debt: Sum up all implicates and divide by 5
	sum dl1100 [aweight=hw0010]
	sca mort_current_`ii' = r(sum)/5

	sca mort_new_`ii' = Scale_Mort_`ii' * mort_current_`ii'
	
	sca mort_change_`ii' = mort_new_`ii' - mort_current_`ii'
	
	restore
}

** Add year when mortgage was taken out (from H files)
merge 1:1 sa0100 sa0010 im0100 using "$dataoutputPath/mort_year.dta"
drop if _merge != 3
drop _merge

** Add variables for tobit estimation (from P files)
merge 1:1 sa0100 sa0010 im0100 using "$dataoutputPath/tobit_data.dta"			// WHY SO MANY NOT MATCHED (70 unmatched, is this so bad?)
drop if _merge != 3
drop _merge

// * Create indicator for already has mortgage
// gen has_mort = 0
// replace has_mort = 1 if dl1100 >0 


* Prepare Tobit data
gen new_m_ind = 0
replace new_m_ind = 1 if hb1301 > 2008											// ADJUST THE HARD CODED YEAR
keep if new_m_ind == 1
keep if dl1100 != .

* Log income
gen log_di2000 = log(di2000)

* Inverse hyperbolic sine: Net worth and new mortgages
gen ihs_dn3001 = asinh(dn3001)
gen ihs_dl1100 = asinh(dl1100)


* Create country dummies
levelsof sa0100, local(ctries) 
foreach j of local ctries {
	
	gen dum_`j' = 0
	replace dum_`j' = 1 if sa0100 == "`j'"
	
}



************
*** PROBLEM: cannot save coefficients as matrix because of _cons.               // Apparently solved (dropping out the constant, which, in fact generated a multicolinearity problem)
*** Need a work around...


global test = "ihs_dl1100 already_mort dn3001 log_di2000 unemployed retired out_LF educ1 educ2 educ3 age1 age2 age3 age4 age5 couple female child `ctries'"

di "`test'"

local tobit_spec = "ihs_dl1100 already_mort dn3001 log_di2000 unemployed retired out_LF educ1 educ2 educ3 age1 age2 age3 age4 age5 couple female child `ctries'"

di "`tobit_spec'"






* Run Tobit as in Spyros paper:

local tobit_spec = "ihs_dl1100 already_mort dn3001 log_di2000 unemployed retired out_LF educ1 educ2 educ3 age1 age2 age3 age4 age5 couple female child dum_*"


tobit `tobit_spec' [aweight=hw0010] if im0100 == 1, ll nocons                   // 08-12-2021: multicolinearity including all countries: drop constant 

* I dont understand anything of this: 
matrix tobit_coeffs_1  = e(b)

local names : colfullnames tobit_coeffs_1
local newnames : subinstr local names "_cons" "cons", word
matrix colnames tobit_coeffs_1 = `newnames'




global Tobit_model_cols: list tobit_spec - remove
global Tobit_model_cols = "$Tobit_model_cols intercept"

matrix colnames tobit_coeffs_1 = $Tobit_model_cols




matrix A = r(table)
local names : colfullnames A
local newnames : subinstr local names "_cons" "cons", word

// rename columns of matrix
matrix colnames A = `newnames'


// convert to dataset

clear

***************************
* help matselrc and install
***************************

matselrc A B, c(1/36) r(1/9)                                                    //  08-12-2021: Removes column for constant & the last one

svmat B , names(col)                                                            // Aparently, this solves the problem 


*********************************************************************************************************





forvalues im = 1(1)5 {

	tobit `tobit_spec' [aweight=hw0010] if im0100 == `im', ll 

	matrix tobit_coeffs_`im'  = e(b)



// get original column names of matrix
    local names : colfullnames tobit_coeffs_`im'
	
	di `names'

    // get original row names of matrix (and row count)
    local rownames : rowfullnames tobit_coeffs_`im'
    local c : word count `rownames'

    // make original names legal variable names
    local newnames
    foreach name of local names {
        local newnames `newnames' `=strtoname("`name'")'
    }

    // rename columns of matrix
    matrix colnames tobit_coeffs_`im' = `newnames'

}









local newnames
	foreach name of local tobit_spec {
        local newnames `newnames' `=strtoname("`tobit_spec'")'
	}



local remove CminuscF_hbs

global FS_model_cols: list spec1 - remove


restore                                                                           ////////////////////////////////////////////////////////////////






regress `spec1' [pw=ha10]

forvalues im = 1(1)5 {

tobit ihs_dl1100 already_mort dn3001 log_di2000 unemployed retired out_LF educ1 educ2 educ3 age1 age2 age3 age4 age5 couple female child dum_* [aweight=hw0010] if im0100 == `im', ll 

matrix tobit_coeffs_`im'  = e(b)


}

* Create set of scalars with coefficients
sca tobit_b_intercept = 1/5*( tobit_coeffs_1[1,25] + tobit_coeffs_2[1,25] + tobit_coeffs_3[1,25] +tobit_coeffs_4[1,25] +tobit_coeffs_5[1,25] )
sca tobit_b_already_mort = 1/5*( tobit_coeffs_1[1,1] + tobit_coeffs_2[1,1] + tobit_coeffs_3[1,1] +tobit_coeffs_4[1,1] +tobit_coeffs_5[1,1] )
sca tobit_b_already_mort = 1/5*( tobit_coeffs_1[1,1] + tobit_coeffs_2[1,1] + tobit_coeffs_3[1,1] +tobit_coeffs_4[1,1] +tobit_coeffs_5[1,1] )





** Implement adjustment of mortgages
foreach ii of global ctrylist {

	preserve ////////////////////////////////////////////////////////
	
	keep if sa0100 == `ii'
	gen ind_m = 0
	replace ind_m = 1 if dl1100 != . & dl1100 > 0

	if mort_change_`ii' > 0 {
	
	* Tobit assignment: 
	/* "The explained variable consists of all the new mortgages that households 
	were granted on the year of the interview, or the year before (approximately 
	1100 households in the entire euro area dataset).*/ 
	
	// Identify hhs who just took out a mortgage
	gen new_m_ind = 0
	replace new_m_ind = 1 if hb1301 > 2008										// ADJUST THE HARD CODED YEAR
	keep if new_m_ind == 1
	
	/*
	Has old mortgage: ind_m
	Net worth (IHS): dn3001
	Log income: di2000
	unemployed / retired / out of job market: PE0100$X
	educ (lower sec) / educ (upper sec) / tertiary: PA0200
	Age: 35-44 / Age: 45-54 / Age: 55-64 / Age: 65-74 / Age: 75 and above: ra0300
	couple: pa0100 (marital status)
	female: ra0200 (gender)
	has a child: RA0100 RELATIONSHIP TO REFERENCE PERSON
	country dummies: sa0100
	
	in D_compl: DHIDH1 Reference person (Canberra definition)
	
	*/
	
	
	tobit dl1100 
	
	}
	
	
	
	
	else if mort_change_`ii' < 0 {
	
	* Deflate existing loans, no new loans
	
	egen n_mortgage = sum(ind_m) 				// Number of hh reporting mortgage - WHAT ABOUT WEIGHTS AND IMPLICATES?
	gen m_new = mort_change_`ii'/n_mortgage 	// Split required change among all mortgage holders
	gen	dl2110_new = dl2110 + m_new 			// Adjust mortgage repayment (flow)
	gen dl1100_new = dl1100 + dl2110_new		// Adjust mortgage outstandning (stock)
	
	* Need to make sure that their dispoisavle income etc. gets lowered in the same way
	
	}

	
	else {
	
	* Do nothing
	di "No mortgage update required"
	
	}
	
	
	
}




