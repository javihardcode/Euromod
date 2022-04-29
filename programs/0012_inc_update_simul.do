
*              **********************************
*               INCOME & UNEMPLOYMENT SIMULATION
*              **********************************

* Last update: 09-03-2022 
* Javier Ramos Perez DG/R

*               LIST OF CONTENTS 

* 1. Open P-files and D-files and merge with u-shochs 
* 2. Variables for Probit/Heckman 
* 3. Probit/Heckman simulation 






********************************************************************************
* 1.     Open P-file & D-file and merge with relevant variables
********************************************************************************

* 1.1 P files (w1 or w2); b) D_compl (w1 or w2); c) sector u shocks; d) RR rates; e) Agg. unemployment rate changes
qui use "$hfcsinputPath/P1.dta", clear
forval i = 2/5{
 qui append using "$hfcsinputPath/P`i'.dta"
}
qui rename *, lower
qui drop if inlist(sa0100, "E1", "I1")
qui keep hid sa0010 sa0100 im0100 ra0010 pa0100 pa0200 pe0100a pe0100b pe0100c pe0100d pe0100e pe0100f pe0100g pe0100h pe0100i pe0200 pe0400 pg0110 pg0210 pg0510 ra0100 ra0200 ra0300 ra0300_b
qui rename hid id
sort id
qui save "$hfcsoutputPath/data_u_simul.dta", replace


* 1.2 Merge with D_compl file
qui use "$hfcsinputPath/D1.dta", clear
forval i = 2/5{
qui append using "$hfcsinputPath/D`i'.dta"
}
qui rename *, lower
qui drop if inlist(sa0100, "E1", "I1")
qui keep id dhchildrendependent hw0010
sort id

qui merge 1:m id using "$hfcsoutputPath/data_u_simul.dta"	                        // 100% matched                   						
qui drop _merge
qui rm "$hfcsoutputPath/data_u_simul.dta"
* 1.3 Generate a variable containing the sector of work according to the level of dissagregation of the macro data
qui gen sect = ""
qui replace sect = "A" if pe0400 == "A"
qui replace sect = "BTE" if pe0400 == "B" | pe0400 == "D" | pe0400 == "E" | pe0400 == "DE"  | pe0400 == "B-E" 	// DE for ES (w1), B-E for PT (w1, w2)
qui replace sect = "C" if pe0400 == "C"
qui replace sect = "F" if pe0400 == "F"
qui replace sect = "GTI" if pe0400 == "G" | pe0400 == "H" | pe0400 == "I" | pe0400 == "HJ"                      // HJ for ES (w1)
qui replace sect = "J" if pe0400 == "J"
qui replace sect = "K" if pe0400 == "K"
qui replace sect = "L" if pe0400 == "L"
qui replace sect = "M_N" if pe0400 == "M" | pe0400 == "N" | pe0400 == "L-N"                                      // L-N for ES (w1) and PT (w1, w2)
qui replace sect = "OTQ" if pe0400 == "O" | pe0400 == "P" | pe0400 == "Q"
qui replace sect = "RTU" if pe0400 == "R" | pe0400 == "S" | pe0400 == "T" | pe0400 == "U" | pe0400 == "R-U"      // R-U for PT (w1, w2)


* 1.3 Merge with u-shocks 
qui merge m:1 sa0100 sect using "$dataoutputPath/Ushock_sect_$UpdateTo.dta"                   
qui drop if _merge == 2
qui drop _merge


* Generate variable indicating employed/unemployed;
qui gen job = 1 if pe0100a == 1 | pe0100a == 2
qui replace job = 0 if pe0100a == 3

* Generate variable single/ no single;
qui gen single = 1 if pa0100 == 1 | pa0100 == 4 | pa0100 == 5
qui replace single = 0 if pa0100 == 2 | pa0100 == 3
qui replace single = 1 if single == .                                           // do this for completness 

* Generate variable children/no children;
qui gen children = 1 if dhchildrendependent > 0 & dhchildrendependent != . & ra0100 == 1
qui replace children = 1 if dhchildrendependent > 0 & dhchildrendependent != . & ra0100 == 2
qui replace children = 0 if dhchildrendependent == 0
qui replace children = 0 if children == .

* Labor Income = wage + self_empl
qui gen      wages              = pg0110													        
qui gen      selfemployedincome = pg0210											// W2: negative values in DE, FR, IE, NL and SI. 
qui egen     laborincome = rowtotal(wages selfemployedincome)
qui replace  laborincome = . if laborincome <= 0								    // 0-to-missing

* Generate a variable for the unemployment benefits;
qui gen unemp_benefits = pg0510														// W2: negative values in FI 
qui replace unemp_benefits = 0 if unemp_benefits == .								// 95% of all obs are set to 0


* Generate variable classifying individuals according to their income wrt average income
** NOTE: This piece of code had two problems:
* 1) WAS NOT DONE WITH RESPECT TO INCOME OF SPECIFIC COUNTRY
* 2) ASSIGNED MISSING laborincome = inc150
qui gen inc = .	
foreach ii of global ctrylist {
 qui sum laborincome [aweight=hw0010] if sa0100 == "`ii'"
 scalar `ii'_inc67 = r(mean)*0.67
 scalar `ii'_inc100 = r(mean)
 scalar `ii'_inc150 = r(mean)*1.5
	
 qui replace inc = 67 if laborincome <= `ii'_inc67 & sa0100 == "`ii'"
 qui replace inc = 100 if laborincome > `ii'_inc67 & laborincome <= `ii'_inc150 & sa0100 == "`ii'"
 qui replace inc = 150 if laborincome > `ii'_inc150 & sa0100 == "`ii'"
 qui replace inc = . if laborincome == . & sa0100 == "`ii'"	
}

* 1d) Merge with file containing the OECD income replacement rates

* Generate variable containing the year of which unemployment status refers to for each country (will be used for merging with OECD RR)
qui gen date = .
forval kk = 1/$n_countries {
 local ctry = word("$ctrylist",`kk')	
if "$start_wave" == "1" {
 local ctry_u_year = substr(word("$ctry_u_ref_w1",`kk'),1,4)
}
	
if "$start_wave" == "2" {
 local ctry_u_year = substr(word("$ctry_u_ref_w2",`kk'),1,4)
}
	
if "$start_wave" == "3" {
 local ctry_u_year = substr(word("$ctry_u_ref_w3",`kk'),1,4)
}	
qui	replace date = `ctry_u_year' if sa0100 == "`ctry'"	
}

* Merge with RR of corresponding year and country
if "$unempLTreplRatiosIndex"=="1" {
qui	merge m:1 sa0100 inc single children date using "$dataoutputPath/RR_LongTerm.dta"
}
else {
qui	merge m:1 sa0100 inc single children date using "$dataoutputPath/RR_Initial.dta"
}
qui drop if _merge == 2
qui drop _merge

* Note: wave 1:
* merge == 1: 425,721 (obs for which inc is missing; because laborincome is missing)
* merge == 3: 345,464 (obs for which individual characteristics for merge are known and replrate available)
* merge == 2: 1,981 ('using' file contains more years than master)

* Note: wave 2:
* merge == 1: 588.627 (obs for which inc is missing; because laborincome is missing)
* merge == 3: 463.103 (obs for which individual characteristics for merge are known and replrate available)
* merge == 2: 2.640 ('using' file contains more years than master)


* 1e) Merge with file containing ratios of total aggregate unemployment change
sort sa0100
qui merge m:1 sa0100 using "$dataoutputPath/UnemplT_Target.dta"                     
qui drop _merge







********************************************************************************
* 2.       Probit variables: educ, gender, age, self-empl
********************************************************************************
* Education;
qui gen college = 1 if pa0200 == 5 
qui replace college = 0 if college == .
qui replace college = . if pa0200 == .
qui gen highschool = 1 if pa0200 == 3
qui replace highschool = 0 if highschool == .
qui replace highschool = . if pa0200 == .

* Gender;
qui gen gender = 1 if ra0200 == 1
qui replace gender = 0 if ra0200 == 2

* Age brackets 
if inlist("$start_wave","1"){
qui gen agebracket=16
qui replace agebracket=35 if ra0300_b == 8 | ra0300_b == 9
qui replace agebracket=45 if ra0300_b == 10 | ra0300_b == 11
qui replace agebracket=55 if ra0300_b == 12 | ra0300_b == 13
qui replace agebracket=65 if ra0300_b == 14 | ra0300_b == 15
qui replace agebracket=75 if ra0300_b == 16 | ra0300_b == 17 | ra0300_b == 18
}

if inlist("$start_wave","2","3"){
qui gen agebracket=16
qui replace agebracket=35 if ra0300_b == 35 | ra0300_b == 40
qui replace agebracket=45 if ra0300_b == 45 | ra0300_b == 50
qui replace agebracket=55 if ra0300_b == 55 | ra0300_b == 60
qui replace agebracket=65 if ra0300_b == 65 | ra0300_b == 70
qui replace agebracket=75 if ra0300_b == 75 | ra0300_b == 80 | ra0300_b == 85
}

qui gen     age1   = 1 if agebracket == 16 
qui replace age1   = (age1==1)
qui gen     age2   = 1 if agebracket == 35
qui replace age2   = (age2==1)
qui gen     age3   = 1 if agebracket == 45
qui replace age3   = (age3==1)
qui gen     age456 = 1 if inrange(agebracket,54,76)                                 // do this to avoid multicolinearity in Probit
qui replace age456 = (age456==1)


*Dummy for self-employed individuals
qui gen selfemployed = .
qui replace selfemployed = 0 if inlist(pe0200, 1, 4)                                // Max comment: include un-paid family workers?
qui replace selfemployed = 1 if inlist(pe0200, 2, 3)
sort id ra0010

*save "$dataoutputPath/data_u_simul_compl.dta", replace
qui save "$hfcsoutputPath/data_u_simul_compl.dta", replace





********************************************************************************
* 3.                  Probit/Heckman/simulation
********************************************************************************

forvalues im = 1(1)5 {
                                                          // Loop over implicates
 di "++++++++++++++++++++++++++++++++++++++++++"
 di "Executing Income Simulation... Implicate " 
 di "++++++++++++++++++++++++++++++++++++++++++"

 qui use "$hfcsoutputPath/data_u_simul_compl.dta", clear
 qui keep if im0100 == `im' & ra0300 >=16                                       // keep implicate above 16 y/o

* Predicted employment status: Probit Simulation
 qui gen job_hat = .	
 foreach ii of global ctrylist {
 qui	probit job gender college highschool age2 age3 age456 single children if sa0100 == "`ii'"
 qui	predict job_hat_aux
 qui	replace job_hat = job_hat_aux if sa0100 == "`ii'"
 qui	drop job_hat_aux
}

 if "$start_wave" == "1" {
	* FI: few obs w/o prediction since education is missing -> assign mean
 qui sum job_hat if sa0100 == "FI"
 qui replace job_hat = r(mean) if job_hat == . & sa0100 == "FI"
	* CY: no info on marital status, gender or education for all members other than reference person -> run different probit (using less info) for these individuals
 probit job age2 age3 age456 children if job_hat == . & sa0100 == "CY" 
 qui predict job_hat_aux
 qui replace job_hat = job_hat_aux if job_hat == . & sa0100 == "CY" 
 qui drop job_hat_aux
}

 qui replace        ushock  = 0 if ushock == .
 qui replace        job_hat = job_hat + ushock
 qui replace        job_hat = . if job == .
 qui label variable job_hat "Predicted employment probability, continuous"

* Predicted labor income: Heckman estimation (two-steps)
 qui gen laborincome_hat = .
 foreach ii of global ctrylist {
qui	heckman laborincome gender college highschool age2 age3 age456 if sa0100 == "`ii'", select(job = gender college highschool age2 age3 age456 single children) twostep
 qui	predict laborincome_hat_aux
 qui	replace laborincome_hat = laborincome_hat_aux if sa0100 == "`ii'" 
 qui	drop laborincome_hat_aux
}
	
* Country adjustments - FOR WAVE 1 ONLY ???????
if "$start_wave" == "1" {
	* FI: few obs w/o prediction since education is missing -> assign mean
qui	sum laborincome_hat if sa0100 == "FI"
qui	replace laborincome_hat = r(mean) if laborincome_hat == . & sa0100 == "FI"
	* CY: no info on marital status, gender or education for all members other than reference person -> run different probit (using less info) for these individuals
qui	heckman laborincome age2 age3 age456 if sa0100 == "CY" & laborincome_hat == ., select(job = age2 age3 age456 children) twostep
qui	predict laborincome_hat_aux
qui	replace laborincome_hat = laborincome_hat_aux if laborincome_hat == . & sa0100 == "CY"
qui	drop laborincome_hat_aux
}

label variable laborincome_hat "Predicted labor income"
	
* Simulation: matching aggregate unempl change
local simul = $noOfSimulations
forvalues j = 1(1)`simul' {
	
 qui	gen ind = 0 if job == 0			
 qui	replace ind = 1 if ind == .												// makes ind = 1 if job is 1 or missing; 0 if job is 0
 qui	gen rnd_jobprob = runiform()                                            // random draw [0,1]
 qui	gen temp = (job_hat-rnd_jobprob)                                        // temp = Y_hat + eta - epsilon = - Delta_c
		
* Identify  "marginal" agents: sort according to marginal probabilites 
 sort sa0100 ind temp id							                             // ind is 0 of no job so this sorts: country, unemployed then employed (or missing!), - Delta_c, id
 by sa0100 ind: gen marg_rank =_n
 qui	replace marg_rank=. if ind==0					                        // set rank 0 missing for those obs which are unemployed

qui gen job_aftershock=job                                                      // job = 1 if empl; 0 if unempl; . if missing
		
foreach ii of global ctrylist {

 qui	sum job [aw=hw0010] if sa0100 == "`ii'"
 scalar `ii'_unemp0 = (1 - r(mean))	                                            // Unemployment rate in sample 													
											
 qui	sum ScaleF_UT if sa0100 == "`ii'"
		scalar `ii'_unemp1 = `ii'_unemp0*r(mean)	                            // ScaleF_UT = ratio of aggregate unemployment change
														
 qui	egen totalW = total(hw0010) if job != . & sa0100 == "`ii'"              // total labor force			
 qui	gen aux1 = hw0010/totalW		                                        // individual contribution to total labor force 
 qui	gen aux2 = sum(aux1)	 		                                        // cumsum labor force  
 qui	gen aux3 = 0 if aux2 < `ii'_unemp1
		
 qui	replace job_aftershock = 0 if aux3 == 0 & sa0100 == "`ii'"		        // Unemployed individuals after shock (employment prob < threshold)
 qui    replace job_aftershock = 1 if job == 0 & aux3 == . & sa0100 == "`ii'"   // Employed individuals aftershock (employment prob >=threshold)		
 qui    drop totalW aux1 aux2 aux3
}


* Set new incomes equal to old ones or zero if missing
 qui gen     pg0110_NEW = pg0110									                // pg0110 Gross cash employee income
 qui replace pg0110_NEW = 0 if pg0110_NEW == .
 qui gen     pg0210_NEW = pg0210									                // pg0210 Gross self-employment income
 qui replace pg0210_NEW = 0 if pg0210_NEW == .
 qui gen     pg0510_NEW = pg0510									                // pg0510 Gross income from unemployment benefits
 qui replace pg0510_NEW = 0 if pg0510_NEW == .

* E to U: Set all incomes to zero and assign unemployment benefits using replacement rate
 qui replace pg0110_NEW = 0 if job == 1 & job_aftershock == 0
 qui replace pg0210_NEW = 0 if job == 1 & job_aftershock == 0
 qui replace pg0510_NEW = pg0510_NEW + (replrate/100)*wages if job == 1 & job_aftershock == 0									
 qui replace pg0510_NEW = pg0510_NEW + (replrate/100)*selfemployedincome if job == 1 & job_aftershock == 0	// NOTE: THIS ASSUMES THAT RR FOR WAGES AND SELF-EMPLOYMENT ARE THE SAME
	
* U to E: Set unemployment income to zero and add predicted wages to reported past income
 qui replace pg0510_NEW = 0 if job == 0 & job_aftershock == 1										
 qui replace pg0110_NEW = pg0110_NEW + laborincome_hat if job == 0 & job_aftershock == 1			
 
* Store results of each simulation
 qui gen pg0110_NEW_`j' = pg0110_NEW
 qui gen pg0210_NEW_`j' = pg0210_NEW
 qui gen pg0510_NEW_`j' = pg0510_NEW
 qui gen job_aftershock_`j' = job_aftershock
 qui drop ind rnd_jobprob temp marg_rank job_aftershock pg0110_NEW pg0210_NEW pg0510_NEW
}
	
	* Average across simulations
 qui egen pg0110_NEW = rowmean(pg0110_NEW_*)
 qui drop pg0110_NEW_*

 qui egen pg0210_NEW = rowmean(pg0210_NEW_*)
 qui drop pg0210_NEW_*

qui egen pg0510_NEW = rowmean(pg0510_NEW_*)
qui drop pg0510_NEW_*

qui egen job_aftershock = rowmean(job_aftershock_*)
qui drop job_aftershock_*
	
foreach ii of global ctrylist  {
 qui sum pg0510_NEW [aw=hw0010] if sa0100 == "`ii'"                                     
}
	
* Make sure that pattern of missing is same as before for obs not affected by the income simulation
* a) For obs not in the labor force (job == .)
 qui replace pg0110_NEW = pg0110 if job == .
 qui replace pg0210_NEW = pg0210 if job == .
 qui replace pg0510_NEW = pg0510 if job == .
	
* Sum the different income components for all the individuals of a household
 bysort id: egen di1100_NEW = total(pg0110_NEW)			                        // di1100 Employee income (D_compl)
 bysort id: egen di1200_NEW = total(pg0210_NEW)			                        // di1200 Self-employment income (D_compl)
 bysort id: egen di1610_NEW = total(pg0510_NEW)			                        // di1610 Unemployment benefits (D_compl)

qui rename di1100_NEW di1100_simul
qui rename di1200_NEW di1200_simul
qui rename di1610_NEW di1610_simul
	
qui keep id di1100_simul di1200_simul di1610_simul job_aftershock ra0010 ra0100 job
 sort id
qui save "$hfcsoutputPath/uSimResults_imp`im'.dta", replace
 
 di "++++++++++++++++++++++++++++++++++++++++++++++"
 di "Income Simulation Finished... Implicate  " `im' 
 di "++++++++++++++++++++++++++++++++++++++++++++++"
}



* Combine all implicates 
qui use "$hfcsoutputPath/uSimResults_imp1.dta", clear
qui rm "$hfcsoutputPath/uSimResults_imp1.dta"
forvalues im = 2(1)5 {
 qui append using "$hfcsoutputPath/uSimResults_imp`im'.dta"
 qui rm "$hfcsoutputPath/uSimResults_imp`im'.dta"
}
qui save "$hfcsoutputPath/u_simul_results_$UpdateTo.dta", replace                         // save final data Income simulation 







