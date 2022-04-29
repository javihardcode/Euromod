
*                  ************************
*                        ASSET UPDATE 
*                  ************************

* Last update: 23-04-2022 
* Javier Ramos Perez DG/R

*               LIST Of CONTENTS 
* 1. Import macro time series and create implied hfcs country-variable changes
* 2. Import HFCS D_compl of chosen starting wave (Wave 2)
* 3. Update debt flows (mortgage + non-mortgage)
* 4. Update asset and income items
* 5. Debt Amortization
* 6. Merge Net Income from Euromod 
* 7. Recalculate derived variables: a) Net Wealth; b) Income; c) Debt
* 8. Save results


********************************************************************************
* 1. Import macro data 
********************************************************************************

qui use "$dataoutputPath/asset_macro_data_ALL.dta", clear
global macro_vars "B2B3 Yield10yr ZCB F2M D41 D75_C F6 HICP IntRH_all IntRC_all RPP Stock USOE_D WagesPC"

foreach var  of global macro_vars {                                              // 
foreach ctry of global ctrylist   {
	
if inlist("`var'", "ZCB","F2M","F6","HICP","IntRH_all","IntRC_all","RPP","Stock","USOE_D") {
 sca `var'_growth_`ctry' = `var'_`ctry'[end_q_ass_`ctry'_n]/`var'_`ctry'[start_q_ass_`ctry'_n]
}
	
if inlist("`var'", "B2B3","D41","D75_C","WagesPC") {
 sca `var'_growth_`ctry' = `var'_`ctry'[end_q_inc_`ctry'_n]/`var'_`ctry'[start_q_inc_`ctry'_n]
}
	
	** Change 13-01-2022: for IntRH_all compute difference instead of growth rate 
if inlist("`var'", "IntRH_all"){
 sca `var'_growth_`ctry' = `var'_`ctry'[end_q_ass_`ctry'_n] - `var'_`ctry'[start_q_ass_`ctry'_n]  // negative for most cases 
}	
}
}


*** 2) Update HFCS data

* Read in D_compl
if "$unempSimulIncomeIndex" == "0" {

 qui use "$hfcsinputPath/D1.dta", clear
 qui append using "$hfcsinputPath/D2.dta"
 qui append using "$hfcsinputPath/D3.dta"
 qui append using "$hfcsinputPath/D4.dta"
 qui append using "$hfcsinputPath/D5.dta"
 qui rename *, lower
 qui drop if inlist(sa0100, "E1", "I1")
	 sort id
if "$start_wave" == "1"  {
 qui	gen dnnlaratio = dnnla/di2000									        // Net liquid assets as a fraction of annual gross income
 qui	replace dnnlaratio = dnnla/(1) if di2000<=0
}
qui	save "$hfcsinputPath/D_complete.dta", replace
}

* Open Income Simulation and replace real values for simulated values
if "$unempSimulIncomeIndex" == "1" {
 qui use "$hfcsinputPath/D_compl_incsimul_$UpdateTo.dta", replace                         
} 


********************************************************************************
*** 3) Update Debt payments (mortgage + non-mortgages)
*      Following Palligkinis (2017), 
********************************************************************************

* Generate proportion of volume of adjustable rate mortgages by country;
qui gen fractionAdjustableHMR = .   // fraction of hmr mortgages having adjustable interest rates in the data
qui gen fractionAdjustable = .      // fraction of mortgages on other propery having adjustable interest rates in the data
forval i = 1/$n_countries {

local ctry `: word `i' of $ctrylist'

 qui sum dl1110a if sa0100 == "`ctry'" [aweight = hw0010], d
 qui local adjustableHMR = r(mean) * r(N)    							// amount of adjustable interest rate hmr mortgages (country by country)                              
 qui sum dl1110b if sa0100 == "`ctry'" [aweight = hw0010], d
     local fixedHMR = r(mean) * r(N)     								// amount of fixed interest rate hmr mortgages (country by country);
 qui replace fractionAdjustableHMR = `adjustableHMR' / (`adjustableHMR' + `fixedHMR') if sa0100 == "`ctry'"	//fraction of adjustable interest rate hmr mortgages
                
 qui sum dl1120a if sa0100 == "`ctry'" [aweight = hw0010], d
     local adjustable = r(mean) * r(N)  								// amount of adjustable interest rate other mortgages (country by country);
 qui sum dl1120b if sa0100 == "`ctry'" [aweight = hw0010], d
     local fixed = r(mean) * r(N)      									// amount of fixed interest rate other mortgages (country by country);
 qui replace fractionAdjustable = `adjustable' / (`adjustable' + `fixed') if sa0100 == "`ctry'"				// fraction of adjustable interest rate other mortgages (country by country);
}
********************************************************************************
qui gen unknownadjustableHMR = fractionAdjustableHMR * dl1110c                      //calculate fraction of unknown hmr mortgage assumed to be adjustable
qui gen unknowandjustable    = fractionAdjustable * dl1120c 		                //calculate fraction of unknown other mortgage assumed to be adjustable

* Update DL2000 (Payments for household's total debt (flow)) and DL2100 (Payments for mortgages (flow)) and DL2200 (payment for non-mortgages (flow)) 
* so that dodstotalp (Debt service to income ratio, households with debt payments) and dodsmortg (Mortgage debt service to income ratio) can be recomputed below
* dl2000 = dl2100 + dl2200 
local debt_flows "dl2000 dl2100 dl2110 dl2120 dl2200"                                  //
foreach var of local debt_flows { 
qui gen      `var'_0 = `var'                                                    // dl2000 total debt payment flow = dl2100 + dl2200
qui replace  `var'_0 = 0     if `var'==.                                        // dl2100 mortgage payment flow = HMR flow + non-HMR flow                     
}                                                                               // DL2200 non-mortgage flow

* hmr mortgage - outstanding, pick only variables with variable interest rate
qui gen     dl1110_out = dl1110               if dl1110ai == 1	                    // If adjustable rate
qui replace dl1110_out = unknownadjustableHMR if dl1110ci == 1						// If rate regime unknown
qui replace dl1110_out = 0                    if dl1110_out == .				    // Set 0 if no info on rate available

* other mortgages - outstanding, pick only variables with variable interest rate
qui gen dl1120_out = dl1120                if dl1120ai == 1						    // If adjustable rate
qui replace dl1120_out = unknowandjustable if dl1120ci == 1							// If rate regime unknown
qui replace dl1120_out = 0 if  dl1120_out == .										// Set 0 if no info on rate available

* non mortgages - outstanding
qui gen dl1200_out = dl1200
qui replace dl1200_out = 0 if dl1200_out == .

qui gen dl1110_0 = 0
qui gen dl1120_0 = 0
qui gen dl1200_0 = 0

forval i = 1/$n_countries {

        local ctry `: word `i' of $ctrylist'
 qui	replace dl1110_0 = (dl1110_out*(IntRH_all_growth_`ctry' / 100)) if sa0100 == "`ctry'"	// Compute debt service of outstanding balance of HMR mortgages
 qui	replace dl1120_0 = (dl1120_out*(IntRH_all_growth_`ctry' / 100)) if sa0100 == "`ctry'"	// Compute debt service of mortgages on other properties
	
	*recompute non mortgage loans, ASSUMPTION: variable rate for all
 qui	replace dl1200_0 = (dl1200_out*(IntRC_all_growth_`ctry' / 100)) if sa0100 == "`ctry'"	// Compute debt service of other, non-mortgage debt
}

* Debt services related to mortgages 
qui gen     dl2110_simul = dl2110_0 + (dl1110_0/12)                                     // new HMR flow 
qui replace dl2110_simul = 0 if dl2110_simul <0                                            
qui gen     dl2120_simul = dl2120_0 + (dl1120_0/12)                                     // new Non-HMR flow  
qui replace dl2120_simul = 0 if dl2120_simul <0                                            

qui gen dl2100_simul = dl2110_simul + dl2120_simul                                           // new total mortgage flow 

* Debt services related to non-mortgages
qui gen dl2200_simul = dl2200_0 + (dl1200_0/12)                                        // new debt services for non-mortgage debt                            


qui gen     dl2000_simul =  dl2000_0 + (dl1110_0/12) + (dl1120_0/12) + (dl1200_0/12) 	    // Total debt flow = old total debt + increase (HMR flow + non-HMR flow + non-mortgage flow)
qui replace dl2000_simul = 0                   if dl2000_simul < 0 & dl2000_simul ~= .	    // Replace negative payments and non-missing with zero
qui replace dl2000_simul = . if dl2000_simul == 0 






*** 4) Update  assets and income (total of 27 items): Rename growth rates to be compatible with variables
foreach ctry of global ctrylist {
	* real assets (5)
	sca da1110_growth_`ctry' = RPP_growth_`ctry'      			                // HMR
	sca da1120_growth_`ctry' = RPP_growth_`ctry'      			                // Other Real Estate Property
	sca da1130_growth_`ctry' = HICP_growth_`ctry' 				                // vehicles;
	sca da1131_growth_`ctry' = HICP_growth_`ctry' 				                // valuables;
	sca da1140_growth_`ctry' = Stock_growth_`ctry'				                // self employment businesses
	
	* financial assets (9)
	*sca da2101_growth_`ctry' = F2M_growth_`ctry' 				                // deposits; don't update deposits (cons/mort simulation) 
	sca da2102_growth_`ctry' = Stock_growth_`ctry'   			                // mutual funds; 
	sca da2103_growth_`ctry' = ZCB_growth_`ctry'	  			                // bonds;
	sca da2104_growth_`ctry' = Stock_growth_`ctry'				                // non-self-employment private business;

	sca da2105_growth_`ctry' = Stock_growth_`ctry'   			                // shares;	
*	sca da2106_growth_`ctry' = HICP_growth_`ctry' 				                // managed accounts; don't update managed accounts 
*	sca da2107_growth_`ctry' = HICP_growth_`ctry' 				                // money owed to households; don't update money owed 
	sca da2108_growth_`ctry' = Stock_growth_`ctry' 				                // other assets; replace HICP by Stock 
	
	sca da2109_growth_`ctry' = F6_growth_`ctry' 				                // voluntary pension, whole life insurance - updated with insurance technical reserves(BS_F6);
	
	* income (10)
	sca di1100_simul_growth_`ctry' = WagesPC_growth_`ctry'  			        // employee income. Add _simul for name consistency;
	sca di1200_simul_growth_`ctry' = B2B3_growth_`ctry'	  			            // self employment income. Add _simul for name consistency;
	sca di1300_growth_`ctry' = B2B3_growth_`ctry'   			                // rental income from real estate property;
	sca di1400_growth_`ctry' = D41_growth_`ctry'     			                // income from financial investments;
	sca di1510_growth_`ctry' = HICP_growth_`ctry'  				                // income - public pensions;
	sca di1520_growth_`ctry' = HICP_growth_`ctry' 				                // occupational and private pension plans;
	sca di1610_simul_growth_`ctry' = HICP_growth_`ctry'  				        // unemployment benefits. Add _simul for name consistency;
	sca di1620_growth_`ctry' = HICP_growth_`ctry' 				                // income from regular social transfers;
	sca di1700_growth_`ctry' = D75_C_growth_`ctry'	  			                // income from private transfers;
	sca di1800_growth_`ctry' = HICP_growth_`ctry' 				                // other income;
	
	* liabilities (3)
	sca dl1110_growth_`ctry' = IntRH_all_growth_`ctry'    		                // HMR mortgages;
	sca dl1120_growth_`ctry' = IntRH_all_growth_`ctry'    		                // other properties mortgages;
	sca dl1200_growth_`ctry' = IntRC_all_growth_`ctry'    		                // non-mortgages;
}

* Update Real Assets, Financial Assets and Income
* Initially we include Mortgages variables: dl1110, dl1120 and dl1200 
* Now compute them on the amortization section
* Mortgage variables no longer appear here
* Deposits da2101, managed accounts da2106 and money owed da2107 are no longuer mechanically updated. They follow the consumnption/mortgage simulation. 

global allVariables "da1110 da1120 da1130 da1131 da1140 da2102 da2103 da2104 da2105 da2108 da2109 di1300 di1400 di1510 di1520 di1620 di1700 di1800"                                                                  // total of 21         
foreach var of global allVariables {
   qui gen `var'_simul = .                                                         
	foreach ctry of global ctrylist {	
		qui replace  `var'_simul = `var'*`var'_growth_`ctry' if sa0100 == "`ctry'"		             		
	}
}

* Update already simulated Income variables: di1100_simul, di1200_simul, di1610_simul  
global IncSimulVariables "di1100_simul di1200_simul di1610_simul"                             
foreach var of global IncSimulVariables {                                                        
	foreach ctry of global ctrylist {	
		qui replace  `var' = `var'*`var'_growth_`ctry' if sa0100 == "`ctry'"		             		
    }
}

* negative income arises from di1200, di1300 and di1800
* gr bar di1100 di1200 di1300 di1400 di1500 di1610 di1700 di1800 [aw=hw0010] if di2000 < 0 ,stack

foreach v of varlist di1100 di1200 di1300 di1400 di1610 di1700 di1800{
*  qui replace `v'       = 0 if `v' < 0 
   qui replace `v'_simul = . if `v'_simul < 0 
} 




* 5) Amortization
*********************************************************************************
* Principal repayment 
* Javier Ramos Perez 
* 13-01-2022
********************************************************************************
* Repay total mortgage debt: dl1100                           
* using total mortgage flow: dl2100 (udjusted to new interests)
* The idea is to recompute dl1100, accounting by debt repayment 
qui gen dl1000_amort = .                                                            // amort: outstanding after amortization
qui gen dl1100_amort = . 
qui gen dl1110_amort = . 
qui gen dl1120_amort = . 
qui gen dl1200_amort = . 
qui gen dl1100_paid  = .                                                            // paid: denotes total payments during simulation 
qui gen dl1110_paid  = . 
qui gen dl1120_paid  = . 
qui gen dl1200_paid  = . 
qui gen dl2000_paid_average = .                                                     // total amount of debt paid(flow) averaged across years
foreach c of global ctrylist {

 qui replace dl1100_paid  = dl2100_simul*12*sim_Y_ass_`c'          if sa0100=="`c'"
 qui replace dl1100_amort = dl1100 - dl1100_paid                   if sa0100=="`c'"  // Total mortgage debt, after repaying 12 months * Y years 
 qui replace dl1100_amort = 0 if dl1100_amort<0 | dl1100_amort==.  &  sa0100=="`c'"

 qui replace dl1110_paid  = dl2110_simul*12*sim_Y_ass_`c'          if sa0100=="`c'"
 qui replace dl1110_amort = dl1110 - dl1110_paid                   if sa0100=="`c'"  // HMR mortgage debt, after repaying 12 months * Y years 
 qui replace dl1110_amort = 0 if dl1110_amort<0 | dl1110_amort==.  &  sa0100=="`c'"

 qui replace dl1120_paid  = dl2120_simul*12*sim_Y_ass_`c'          if sa0100=="`c'"
 qui replace dl1120_amort = dl1120 - dl1120_paid                   if sa0100=="`c'"  // NON-HMR mortgage debt, after repaying 12 months * Y years 
 qui replace dl1120_amort = 0 if dl1120_amort<0 | dl1200_amort==.  &  sa0100=="`c'"


********************************************************************************
 * collect scalars on the difference between Wave 2 and Wave 3 with: Needed for the mortgage simulation
 qui sum dl1100    [aw=hw0010] if sa0100 == "`c'" , d                           // sum of dl1100 Wave 2 (data)
 sca Agg_dl1100_w2_`c' = r(sum)/5                                               // factor by (5) implicates and (4) convert to quarters  
 
 qui sum dl1100_amort [aw=hw0010] if sa0100 == "`c'" , d                           // sum of dl1100 after repayment 
 sca Agg_dl1100_w3_`c' = r(sum)/5 

 sca Scale_NablaMort_`c' = Agg_dl1100_w2_`c' - Agg_dl1100_w3_`c'                // Aggregate difference between W2 and W3 without new mortgages (Nabla)

 di "--------------- `c' Nabla = " Scale_NablaMort_`c' "-----------------------"
 *******************************************************************************
 
 * Amortization of non-collaterized debt: total (dl1200) - total flow (dl2200)
 qui replace dl1200_paid  = dl2200_simul*12*sim_Y_ass_`c'          if sa0100=="`c'"
 qui replace dl1200_amort = dl1200 - dl1200_paid                   if sa0100=="`c'" // Total non-mortgage debt, after repaying 12 months * Y years 
 qui replace dl1200_amort = .                 if dl1200_amort <= 0  & sa0100=="`c'"
 
 * Amortization of total debt
 qui replace dl1000_amort = dl1100_amort + dl1200_amort           if sa0100=="`c'"  // total outstanding debt  

 
 
 * Now compute the averate of the total paid money across years: 
 qui replace dl2000_paid_average = (dl1100_paid + dl1200_paid )/sim_Y_ass_`c' if sa0100 == "`c'"
}





*** 6. Merge Net Income using Euromod  

* 6.1 generate household types 
* Use dhhtype to assign household types
qui gen     famtype = "hh3"
qui replace famtype = "hh1" if dhhtype == 51 | dhhtype == 52
qui replace famtype = "hh2" if dhhtype == 9

qui gen HFCS_wave = 1 
qui gen year      = "2020"
 



* 6.2 round di1100 + di1300 + di14000 to 10 and convert to monthly quantity

* some udjustments
qui replace di1300 = . if di1300 <= 0 
qui replace di1400 = . if di1400 <= 0 
qui replace di1200 = . if di1200 <= 0 

qui egen inc_gross1       = rowtotal(di1100 di1300 di1400)                      // Employee income + other sources of income     
qui gen  inc_gross        = round(inc_gross1/12,10)                              // Self employment income 
qui gen  inc_grossselfemp = round(di1200/12,10) 

qui replace inc_gross        = . if inc_gross        <= 0 
qui replace inc_grossselfemp = . if inc_grossselfemp <= 0 



* 6.3 Merge employee income with Euromod file  
merge m:m sa0100 year famtype inc_gross using "$EuromodPath_out1/net_income_ALL_HHS.dta"
qui drop if HFCS_wave != 1 
qui duplicates drop                                                             // highly recommended...                        
qui gen still_need_taxemployeeincome = (_merge == 1)                            // identify this hh for future computations
qui drop _merge 


* 6.4 Merge selfemployment with Euromod file  
merge m:m sa0100 year famtype inc_grossselfemp using "$EuromodPath_out2\net_incomeselfemp_ALL_HHS.dta"
qui drop if HFCS_wave != 1 
qui duplicates drop                                                             // highly recommended...                        
qui gen still_need_taxselfemplincome = (_merge == 1)                            // identify this hh for future computations
qui drop _merge 


* 6.5 Convert to annual income 
qui gen     di11131400_net = inc_net * 12                                 // three categories together 
qui replace di11131400_net = . if di11131400_net <=0 

qui gen     di1200_net = inc_netselfemp * 12                              // self-employment income 
qui replace di1200_net = . if di1200_net == 0   


* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

** REPEAT PROCESS FOR SIMULATED VARIABLES  
drop inc_net inc_gross inc_grossselfemp


qui egen inc_gross_simul = rowtotal(di1100_simul di1300_simul di1400_simul)                      // Employee income + other sources of income     
qui gen  inc_gross        = round(inc_gross_simul/12,10)                              // Self employment income 
qui gen  inc_grossselfemp = round(di1200_simul/12,10) 

qui replace inc_gross        = . if inc_gross        <= 0 
qui replace inc_grossselfemp = . if inc_grossselfemp <= 0 


* 6.3 Merge employee income with Euromod file  
merge m:m sa0100 year famtype inc_gross using "$EuromodPath_out1/net_income_ALL_HHS.dta"
qui drop if HFCS_wave != 1 
qui duplicates drop                                                             // highly recommended...                        
qui gen still_need_taxemployeeincome2 = (_merge == 1)                                          // identify this hh for future computations
qui drop _merge 


* 6.3 Merge selfemployment with Euromod file  
merge m:m sa0100 year famtype inc_grossselfemp using "$EuromodPath_out2\net_incomeselfemp_ALL_HHS.dta"
qui drop if HFCS_wave != 1 
qui duplicates drop                                                             // highly recommended...                        
qui gen still_need_taxselfemplincome2 = (_merge == 1)                            // identify this hh for future computations
qui drop _merge 


* 6.4 Convert to annual income 
qui gen     di11131400_simul_net = inc_net * 12                                 // three categories together 
qui replace di11131400_simul_net = . if di11131400_simul_net <=0 

qui gen     di1200_simul_net = inc_netselfemp * 12                              // self-employment income 
qui replace di1200_simul_net = . if di1200_simul_net == 0   

** drop Euromod vars to avoid confusion 
drop inc_net inc_netselfemp 




 
 *** 7. RECALCULATE DERIVED VARIABLES 

local allVariables "dl1000_amort dl1110_amort dl1120_amort dl1200_amort"        // Outstanding liabilities: HMR, non-HMR, non-mortgage
foreach var of local allVariables {	
 qui	gen `var'_minus = -`var'                                                // replace liabilities with negatives 
}

* recompute assets - total
qui egen da1000_simul = rowtotal(da1110_simul da1120_simul da1130_simul da1131_simul da1140_simul)		// Real Assets (good)
qui egen da2100_simul = rowtotal(da2101 da2102_simul da2103_simul da2104_simul da2105_simul da2106 da2107 da2108_simul da2109_simul) // Financial Assets (good)
qui egen da3001_simul = rowtotal(da1000_simul da2100_simul)					    // Total assets excl. public and occupational pension plans (good)
qui egen dn3001_simul_NO_MORT_SIMUL = rowtotal(da3001_simul dl1000_amort_minus)
qui drop dl1000_amort_minus

* net liquid assets
qui egen dnnla_simul = rowtotal(da2101 da2102_simul da2103_simul da2104_simul da2105_simul da2106 dl1200_amort_minus)	// Net liquid assets LAST ITEM IS DIFFERENT FROM CORE-VAR REPORT



* recompute income di2000
qui egen di1500_simul = rowtotal(di1510_simul di1520_simul)						    // Income from pensions (public+private)
qui egen di1600_simul = rowtotal(di1610_simul di1620_simul)						    // Regular social transfers (Unemployment benefits+Other social transfers)
qui rename di2000_simul di2000_simul_AFTER_UPDATING 
qui egen di2000_simul = rowtotal(di1100_simul di1200_simul di1300_simul di1400_simul di1510_simul di1520_simul di1610_simul di1620_simul di1700_simul di1800_simul)
		                                                              // Total household gross income, including interest payments
qui egen di2000_simul_net = rowtotal(di11131400_simul_net di1200_simul_net di1510_simul di1520_simul di1610_simul di1620_simul di1700_simul di1800_simul)
qui egen di2000_net       = rowtotal(di11131400_net di1200_net di1510 di1520 di1610 di1620 di1700 di1800)
* raw adjustment to avoid negative incomes 
qui replace di2000_net       = 0 if di2000_net       < 0 
qui replace di2000_simul     = 0 if di2000_simul     < 0 
qui replace di2000_simul_net = 0 if di2000_simul_net < 0 

*** 6) Save results
if "$unempSimulIncomeIndex" ~= "1" {
 qui gen job_aftershock = .
}



sort sa0100 im0100 sa0010


if "$unempSimulIncomeIndex" == "1" {
 qui	save "$hfcsinputPath/D_compl_incsimul_$UpdateTo.dta", replace
}

else {
 qui	save "$hfcsinputPath/D_compl_asssimul_$UpdateTo.dta", replace
}

qui save "$hfcsinputPath/D_compl_MicroSim_$UpdateTo.dta", replace




















