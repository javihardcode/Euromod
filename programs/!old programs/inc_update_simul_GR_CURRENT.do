

*** THIS FILE IS USED TO DEBUG THE INCOME UPDATE PROCEDURE


*** 1) Generate required data
* a) P files (w1 or w2); b) D_compl (w1 or w2); c) sector u shocks; d) RR rates; e) Agg. unemployment rate changes


**** FURTHER ISSUES:
* - why are there 132 sa0010 missing in each country?
* - Does the replrate assignment work correctly? E.g. what about one child families?


* 1a) Merge the 5 implicates of the P files
use "$datainputPath/P1.dta", clear
append using "$datainputPath/P2.dta"
append using "$datainputPath/P3.dta"
append using "$datainputPath/P4.dta"
append using "$datainputPath/P5.dta"

keep hid sa0010 sa0100 im0100 ra0010 pa0100 pa0200 pe0100a pe0100b pe0100c pe0100d pe0100e pe0100f pe0100g pe0100h pe0100i pe0200 pe0400 pg0110 pg0210 pg0510 ra0100 ra0200 ra0300 ra0300_b
rename hid id
sort id

save "$dataoutputPath/data_u_simul.dta", replace


* 1b) Merge with D_compl file
use "$datainputPath/D_compl.dta", clear
keep id dhchildrendependent hw0010
sort id

merge 1:m id using "$dataoutputPath/data_u_simul.dta"							// Wave 1: ALL matched
drop _merge

* Generate a variable containing the sector of work according to the level of dissagregation of the macro data
gen sect = ""
replace sect = "A" if pe0400 == "A"
replace sect = "BDE" if pe0400 == "B" | pe0400 == "D" | pe0400 == "E" | pe0400 == "DE"  | pe0400 == "B-E" 	// DE for ES (w1), B-E for PT (w1, w2)
replace sect = "C" if pe0400 == "C"
replace sect = "F" if pe0400 == "F"
replace sect = "GTI" if pe0400 == "G" | pe0400 == "H" | pe0400 == "I" | pe0400 == "HJ" // HJ for ES (w1)
replace sect = "J" if pe0400 == "J"
replace sect = "K" if pe0400 == "K"
replace sect = "L" if pe0400 == "L"
replace sect = "M_N" if pe0400 == "M" | pe0400 == "N" | pe0400 == "L-N" // L-N for ES (w1) and PT (w1, w2)
replace sect = "OTQ" if pe0400 == "O" | pe0400 == "P" | pe0400 == "Q"
replace sect = "RTU" if pe0400 == "R" | pe0400 == "S" | pe0400 == "T" | pe0400 == "U" | pe0400 == "R-U" // R-U for PT (w1, w2)


* 1c) Merge with the file containing the sector specific unemployment shocks
merge m:1 sa0100 sect using "$dataoutputPath/Ushock_sect.dta"

* Note: wave 1:
* merge == 1: 533,456 (obs for which sec is missing)
* merge == 3: 237,729 (obs for which sector is known and shock available)
* merge == 2: 4 (sectoral shock known but no obs works in it)
drop if _merge == 2
drop _merge

* Generate variable indicating employed/unemployed;
gen job = 1 if pe0100a == 1 | pe0100a == 2
replace job = 0 if pe0100a == 3

* Generate variable single/ no single;
gen single = 1 if pa0100 == 1 | pa0100 == 4 | pa0100 == 5
replace single = 0 if pa0100 == 2 | pa0100 == 3

*** NOTE: in some countries, pa0100 (marital status) is missing for many observations. Hence, the single variable has LOTS of missings
* bys sa0100: tab single, m
* Wave 1: CY: 70%; FI: 20%; (all others are lower)

* for completeness set missing marital status to single
replace single = 1 if single == .

* Generate variable children/no children;
gen children = 1 if dhchildrendependent > 0 & dhchildrendependent != . & ra0100 == 1
replace children = 1 if dhchildrendependent > 0 & dhchildrendependent != . & ra0100 == 2
replace children = 0 if dhchildrendependent == 0
replace children = 0 if children == .

* Generate a variable for labor income (adding employee and self-employed income together);

*** NOTE: about 60% are missing in each country (min 50%; max 71%)
gen wages = pg0110																// For wave1, there are no negative values.
replace wages = 0 if wages == .

*** NOTE: about 90% are missing in each country (min 85%; max 95%)
gen selfemployedincome = pg0210													// For wave1, there are negative values in FR, NL, and SI.
replace selfemployedincome = 0 if selfemployedincome == .

gen laborincome = wages + selfemployedincome
replace laborincome = . if laborincome <= 0										// 62% are set to missing

* Generate a variable for the unemployment benefits;

*** NOTE: For wave1, there are VERY few obs. Missing rates around 95% (98% in ES, GR, IT, LU, MT, NL)
gen unemp_benefits = pg0510														// For wave1, there are negative values in FI
replace unemp_benefits = 0 if unemp_benefits == .								// 95% of all obs are set to 0

*** NOTE: THERE ARE OBS WHICH HAVE BOTH UNEMP BENEFITS >0 and LABOR INCOME > 0  
* Example: 
* sa0100	sa0010	inc	single	children	date	laborincome	im0100	hw0010	dhchildrendependent	id	ra0010
* AT		106201	150	1		0			2011	37000		1		1485.502	0			AT1106201001	1


* Generate variable classifying individuals according to their income wrt average income
** NOTE: This piece of code had two problems:
* 1) WAS NOT DONE WITH RESPECT TO INCOME OF SPECIFIC COUNTRY
* 2) ASSIGNED MISSING laborincome = inc150
gen inc = .	

foreach ii of global ctrylist {

	sum laborincome [aweight=hw0010] if sa0100 == "`ii'"
	scalar `ii'_inc67 = r(mean)*0.67
	scalar `ii'_inc100 = r(mean)
	scalar `ii'_inc150 = r(mean)*1.5
	
	replace inc = 67 if laborincome <= `ii'_inc67 & sa0100 == "`ii'"
	replace inc = 100 if laborincome > `ii'_inc67 & laborincome <= `ii'_inc150 & sa0100 == "`ii'"
	replace inc = 150 if laborincome > `ii'_inc150 & sa0100 == "`ii'"
	replace inc = . if laborincome == . & sa0100 == "`ii'"
	
}

* 1d) Merge with file containing the OECD income replacement rates

* Generate variable containing the year of which unemployment status refers to for each country (will be used for merging with OECD RR)
gen date = .
forval kk = 1/$n_countries {
	local ctry = word("$ctrylist",`kk')
	
	if "$start_wave" == "1" {
	local ctry_u_year = substr(word("$ctry_u_ref_w1",`kk'),1,4)
	}
	
	if "$start_wave" == "2" {
	local ctry_u_year = substr(word("$ctry_u_ref_w2",`kk'),1,4)
	}
	
	replace date = `ctry_u_year' if sa0100 == "`ctry'"	
}

* Merge with RR of corresponding year and country
if "$unempLTreplRatiosIndex"=="1" {
	merge m:1 sa0100 inc single children date using "$dataoutputPath/RR_LongTerm.dta"
}
else {
	merge m:1 sa0100 inc single children date using "$dataoutputPath/RR_Initial.dta"
}

* Note: wave 1:
* merge == 1: 425,721 (obs for which inc is missing; because laborincome is missing)
* merge == 3: 345,464 (obs for which individual characteristics for merge are known and replrate available)
* merge == 2: 1,981 ('using' file contains more years than master)
drop if _merge == 2
drop _merge

* 1e) Merge with file containing ratios of total aggregate unemployment change
sort sa0100
merge sa0100 using "$dataoutputPath/UnemplT_Target.dta", keep(ScaleF_UT)
drop _merge

* Generate the variables that will be used in the probit (mainly dummies for education, gender and age brackets);

* Education;
gen college = 1 if pa0200 == 5
replace college = 0 if college == .
replace college = . if pa0200 == .
gen highschool = 1 if pa0200 == 3
replace highschool = 0 if highschool == .
replace highschool = . if pa0200 == .

* Gender;
gen gender = 1 if ra0200 == 1
replace gender = 0 if ra0200 == 2

*Age brackets;
gen agebracket=16
replace agebracket=35 if ra0300_b == 8 | ra0300_b == 9
replace agebracket=45 if ra0300_b == 10 | ra0300_b == 11
replace agebracket=55 if ra0300_b == 12 | ra0300_b == 13
replace agebracket=65 if ra0300_b == 14 | ra0300_b == 15
replace agebracket=75 if ra0300_b == 16 | ra0300_b == 17 | ra0300_b == 18

gen age1 = 1 if agebracket == 16
replace age1 = 0 if age1 == .
gen age2 = 1 if agebracket == 35
replace age2 = 0 if age2 == .
gen age3 = 1 if agebracket == 45
replace age3 = 0 if age3 == .
gen age4 = 1 if agebracket == 55
replace age4 = 0 if age4 == .
gen age5 = 1 if agebracket == 65
replace age5 = 0 if age5 == .
gen age6 = 1 if agebracket == 75
replace age6 = 0 if age6 == .

* I am going to create a category comprising the last 3 age brackets. 
* This is because when runnng the probits there were brackets that were predicting the outcome of the regression perfectly and thus they were drop off;
gen age456 = 1 if age4 == 1 | age5 == 1 | age6 == 1
replace age456 = 0 if age456 == .

* There is 1 individual without id (neither population weight). I am going to drop it.;
* Wave 1: This is not true any longer
drop if id == ""
sort id ra0010

save "$dataoutputPath/data_u_simul_compl.dta", replace


*** 2) a) Probit; b) Heckman; c) Simulation

* Loop over implicates 1 to 5


	* Load and restrict data
	use "$dataoutputPath/data_u_simul_compl.dta", clear
	
	keep if sa0100 == "GR"
	
	keep if im0100 == 1
	
	* We just consider household members above 16 years old
	keep if ra0300 >= 16

	* 2a) Generate predicted employment status: Run Probits country by country
	// egen countryid = group(sa0100) USE sa0100 INSTEAD
	gen job_hat = .
		
		probit job gender college highschool age2 age3 age456 single children
		predict job_hat_aux
		replace job_hat = job_hat_aux
		drop job_hat_aux
	
	*** Note: Wave 1
	* job_hat missing for 27,447 (17.80%); roughly equal % across countries except CY (70%), FI (20%), FR (19%), LU (20%)
	* min: 0.253025
	* mean: 0.855
	
	* Country adjustments - FOR WAVE 1 ONLY ???????
	* FOLLOW UP - WHAT ABOUT WAVE 2?
// 	if "$start_wave" == "1" {
// 	* FI: few obs w/o prediction since education is missing -> assign mean
// 	sum job_hat if sa0100 == "FI"
// 	replace job_hat = r(mean) if job_hat == . & sa0100 == "FI"
// 	* CY: no info on marital status, gender or education for all members other than reference person -> run different probit (using less info) for these individuals
// 	probit job age2 age3 age456 children if job_hat == . & sa0100 == "CY" 
// 	predict job_hat_aux
// 	replace job_hat = job_hat_aux if job_hat == . & sa0100 == "CY" 
// 	drop job_hat_aux
// 	}

	*** Note: Wave 2
	* No more missing job_hat for FI and CY
	
	* ushock is the sector "rebalancing" (this info is not available for all household members) ???? 
	
	*** NOTE: Wave 1
	* ushock has 69% missings; roughly equal % across countries 
	* mean: .0031
	
	replace ushock = 0 if ushock == .
	replace job_hat = job_hat + ushock

	replace job_hat = . if job == .
	
	*** NOTE: wave 1
	* job_hat: 54 % missing
	* max: 1.26
	* mean: 0.88

	label variable job_hat "Predicted employment probability, continuous"

	* 2b) Generate predicted labor incomes (replacing income of those moving from unemployment to employment)
	* Use two step Heckman selection model (ML estimation was giving convergence problems, also # of active members in hh as exclusion restriction gave problems) 
	* Weights are not used in the regression (they cannot be used with the two step heckman, and it is not clear conceptually if they should be used)
	gen laborincome_hat = .
	

		heckman laborincome gender college highschool age2 age3 age456, select(job = gender college highschool age2 age3 age456 single children) twostep
		predict laborincome_hat_aux
		replace laborincome_hat = laborincome_hat_aux
		drop laborincome_hat_aux

	
	* Country adjustments - FOR WAVE 1 ONLY ???????
	* FOLLOW UP - WHAT ABOUT WAVE 2?
// 	if "$start_wave" == "1" {
// 	* FI: few obs w/o prediction since education is missing -> assign mean
// 	sum laborincome_hat if sa0100 == "FI"
// 	replace laborincome_hat = r(mean) if laborincome_hat == . & sa0100 == "FI"
// 	* CY: no info on marital status, gender or education for all members other than reference person -> run different probit (using less info) for these individuals
// 	heckman laborincome age2 age3 age456 if sa0100 == "CY" & laborincome_hat == ., select(job = age2 age3 age456 children) twostep
// 	predict laborincome_hat_aux
// 	replace laborincome_hat = laborincome_hat_aux if laborincome_hat == . & sa0100 == "CY"
// 	drop laborincome_hat_aux
// 	}

	label variable laborincome_hat "Predicted labor income"
	
	*** NOTE: wave 1
	* laborincome_hat: 12.24% missing
	* min: -9078.773; neg values in CY, ES, FR, LU								// NEED TO CHANGE THIS. Example: set to lowest positive value
	
	* 2c) Simulation
	
	* # of simulations
	local simul = $noOfSimulations

	forvalues j = 1(1)25 {
		
		* Note: job can be 0,1 or missing
		gen ind = 0 if job == 0			
		replace ind = 1 if ind == .												// makes ind = 1 if job is 1 or missing; 0 if job is 0

		* Generate a random draw in the [0,1] space from a uniform distr.
		gen rnd_jobprob = runiform()
		
		* Compute the distance to the threshold: rnd_jobprob is epsilon; job_hat is Y_hat minus eta; So temp = Y_hat + eta - epsilon = - Delta_c 
		gen temp = (job_hat-rnd_jobprob)
		
		*** NOTE: wave 1
		* missing temp: 54.83%
		
		* Identify  "marginal" agents: sort according to marginal probabilites // WHAT ABOUT MISSING TEMP?
		sort sa0100 ind temp id							// ind is 0 of no job so this sorts: country, unemployed then employed (or missing!), - Delta_c, id
		by sa0100 ind: gen marg_rank =_n
		replace marg_rank=. if ind==0					// set rank 0 missing for those obs which are unemployed
		* marg_rank == 1 indicates the next agent to drop out of a job 

		* Carry out simulation

		* USE IF WE DONT WANT TO DEAL WITH COUNTRIES WHERE UNEMPLOYMENT HAS GONE DOWN		??? How does it work in this case?
		****************************************************
		*replace  ScaleF_UT = 1 if ScaleF_UT < 1
		****************************************************

		gen job_aftershock=job // job = 1 if empl; 0 if unempl; . if missing
		

			sum job [aweight=hw0010]
			scalar unemp0 = (1 - r(mean))	// unemp0 = unemployment rate in sample [1 - mean of job = 1 - fraction of obs having job in sample]													
											
			sum ScaleF_UT
			scalar unemp1 = unemp0*r(mean)	// ScaleF_UT = ratio of aggregate unemployment change
														// -> unemp 1 = unemploymentrate in sample * ratio of aggregate unemployment change
											
			egen totalW = total(hw0010) if job != . // egen, sum() is the same as egen, total() So this sums all hhs in country who are either unemployed or unemployed; = total laborforce 
			
			*** NOTE: Is this correct?											/// DONT WE NEED P WEIGHTS HERE?
			
			gen aux1 = hw0010/totalW		// weight of specific hh divided by sum of all households -> individual contribution to aggregate
			gen aux2 = sum(aux1)	 		// sum() creates a running sum, i.e. cumsum. So this should go from epsilon to 1.
			gen aux3 = 0 if aux2 < unemp1
		
			* Individuals moving into unemployment (employment prob < threshold)
			replace job_aftershock = 0 if aux3 == 0
			
			
			* Individuals moving out of unemployment
			replace job_aftershock = 1 if job == 0 & aux3 == .

			
			drop totalW aux1 aux2 aux3




		* Set new incomes equal to old ones or zero if missing
		gen pg0110_NEW = pg0110									// pg0110 Gross cash employee income
		replace pg0110_NEW = 0 if pg0110_NEW == .
		gen pg0210_NEW = pg0210									// pg0210 Gross self-employment income
		replace pg0210_NEW = 0 if pg0210_NEW == .
		gen pg0510_NEW = pg0510									// pg0510 Gross income from unemployment benefits
		replace pg0510_NEW = 0 if pg0510_NEW == .

		* E to U: Set all incomes to zero and assign unemployment benefits using replacement rate
		replace pg0110_NEW = 0 if job == 1 & job_aftershock == 0
		replace pg0210_NEW = 0 if job == 1 & job_aftershock == 0
		replace pg0510_NEW = pg0510_NEW + replrate/100*wages if job == 1 & job_aftershock == 0									
		replace pg0510_NEW = pg0510_NEW + replrate/100*selfemployedincome if job == 1 & job_aftershock == 0	// NOTE: THIS ASSUMES THAT RR FOR WAGES AND SELF-EMPLOYMENT ARE THE SAME
		
		* U to E: Set unemployment income to zero and add predicted wages to reported past income
		replace pg0510_NEW = 0 if job == 0 & job_aftershock == 1										
		replace pg0110_NEW = pg0110_NEW + laborincome_hat if job == 0 & job_aftershock == 1			
		
		* Make sure that pattern of missing is same as before for unaffected observations (who stay employed or unemployed)
// 		replace pg0110_NEW = . if pg0110_NEW == 0 & replrate != 0 & job != .
// 		replace pg0210_NEW = . if pg0210_NEW == 0 & replrate != 0 & job != .
// 		replace pg0510_NEW = . if pg0510_NEW == 0 & replrate != 0 & job != .
				
		* Store results of each simulation
		gen pg0110_NEW_`j' = pg0110_NEW
		gen pg0210_NEW_`j' = pg0210_NEW
		gen pg0510_NEW_`j' = pg0510_NEW
		gen job_aftershock_`j' = job_aftershock
		drop ind rnd_jobprob temp marg_rank job_aftershock pg0110_NEW pg0210_NEW pg0510_NEW

}

**** END OF SIMULATIONS - Begin consolidating

	* Average across simulations
	egen pg0110_NEW = rowmean(pg0110_NEW_*)
	drop pg0110_NEW_*

	egen pg0210_NEW = rowmean(pg0210_NEW_*)
	drop pg0210_NEW_*

	egen pg0510_NEW = rowmean(pg0510_NEW_*)
	drop pg0510_NEW_*

	egen job_aftershock = rowmean(job_aftershock_*)
	drop job_aftershock_*
	
	* Make sure that pattern of missing is same as before for obs not affected by the income simulation
	* a) For obs not in the labor force (job == .)
	replace pg0110_NEW = pg0110 if job == .
	replace pg0210_NEW = pg0210 if job == .
	replace pg0510_NEW = pg0510 if job == .
	* b) For obs never moved btw E <-> U (job_aftershock == 1 | job_aftershock == 0)
	replace pg0110_NEW = pg0110 if job_aftershock == 1 | job_aftershock == 0
	replace pg0210_NEW = pg0210 if job_aftershock == 1 | job_aftershock == 0
	replace pg0510_NEW = pg0510 if job_aftershock == 1 | job_aftershock == 0

	* Sum the different income components for all the individuals of a household
	bysort id: egen di1100_NEW = total(pg0110_NEW)			// di1100 Employee income (D_compl)
	bysort id: egen di1200_NEW = total(pg0210_NEW)			// di1200 Self-employment income (D_compl)
	bysort id: egen di1610_NEW = total(pg0510_NEW)			// di1610 Unemployment benefits (D_compl)

	rename di1100_NEW di1100_unempSimul
	rename di1200_NEW di1200_unempSimul
	rename di1610_NEW di1610_unempSimul
	
	keep id di1100_unempSimul di1200_unempSimul di1610_unempSimul job_aftershock ra0010
	sort id
	save "$dataoutputPath/uSimResults_imp1.dta", replace









/*
use "$dataoutputPath/uSimResults_imp1.dta", clear
rm "$dataoutputPath/uSimResults_imp1.dta"

forvalues im = 2(1)5 {
	append using "$dataoutputPath/uSimResults_imp`im'.dta"
	rm "$dataoutputPath/uSimResults_imp`im'.dta"
}

save "$dataoutputPath/u_simul_results.dta", replace
*/

