
*** This file computes the aggregate targets for the mortgage updates
* 08-12-2021 Javier Ramos 
* Working on last version

* Load the mortgage stock data
qui use "$dataoutputPath/Mort_stock_ALL.dta", clear	

*** 1) Set values of start and target quarters and compute changes as scalars

qui gen ref_date = quarterly(PERIOD_NAME, "YQ")

forval i = 1/$n_countries {

	local ctry `: word `i' of $ctrylist'
	
	preserve
	
qui	gen start_date = quarterly(start_q_ass_`ctry', "YQ")
qui	gen end_date   = quarterly(end_q_ass_`ctry', "YQ")
	
qui	keep if ctryid == "`ctry'" & (ref_date == start_date | ref_date == end_date)
	sca Scale_Mort_`ctry' = Mort_stock[2]/Mort_stock[1]                         // Ratio new-to-old mortgages
	sca Scale_deltaMort_`ctry' = (Mort_stock[2] - Mort_stock[1])*1000000        // New - old mortgages
	
qui	drop start_date end_date
	
	restore

}

*** 2) Transform scalars to variables in one dataset and save

keep ctryid
duplicates drop ctryid, force

gen Scale_Mort = .
gen Scale_deltaMort = .

forval i = 1/$n_countries {

	local ctry `: word `i' of $ctrylist'
	
qui	replace Scale_Mort = Scale_Mort_`ctry' in `i'
qui	replace Scale_deltaMort = Scale_deltaMort_`ctry' in `i'

}

rename ctryid sa0100

compress
qui save "$dataoutputPath/Mort_target.dta", replace


*** 3) Retrieve Loan-to-value data: 
* open  HFCS Wave 2

/*
use "D:\data\hfcs\wave2/DP_extended.dta", clear
decode sa0100, gen(country) 

*hist doltvratio if inrange(doltvratio, 0, 1.2) & im0100 == 1, by(sa0100)                        // hist LTV 

foreach ii of global ctrylist {
qui sum doltvratio [w=hw0010] if country == "`ii'"
sca mean_LTV_`ii' = r(mean)
sca sder_LTV_`ii' = r(sd)    

* Compute parameters for beta distirbution (https://stats.stackexchange.com/questions/12232/calculating-the-parameters-of-a-beta-distribution-using-the-mean-and-variance)
*sca aalpha_`ii' = (mean_LTV_`ii')^2*( (1-mean_LTV_`ii')/(sder_LTV_`ii')^2 - 1/(mean_LTV_`ii'))
*di "Alpha_`ii' = " aalpha_`ii' 

*sca bbeta_`ii'  = aalpha_`ii'*(1/(mean_LTV_`ii' - 1))
*di "Beta_`ii' = " bbeta_`ii' 
}

*/














