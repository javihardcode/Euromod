********************************************************************************
* Simulation for one country: whats going on? 
********************************************************************************
* Example for IT: problem: few people take huger mortgages (like 2 millions...)
*******************************************************************************


cls 
* Loop over implicates 1 to 5 at household level! 
*forvalues im = 1(1)1 {

 use "$hfcsoutputPath/data_mortgage_simul_compl.dta", clear 
 keep if im0100 == 1                                                          // Keep one implicate 
 
* Run Tobit: No constant, same as Palligkinis (2017)
 drop if inlist(sa0100,"FI")                                                     // drop FI for now 
 local tobit_spec = "ihs_new_issued_mort already_mort ihs_dn3001 sq_ihs_dn3001 log_di2000 unemployed retired out_LF educ1 educ2 educ3 age1 age2 age3 age4  age5 couple female child dum_*"
 tobit `tobit_spec' [aweight=hw0010] if im0100 == 1, ll nocons                // multicolinearity including all countries: drop constant 
 predict ihs_mort_hat  , e(8,20) 
 gen upp_mort_hat_limit = ihs_mort_hat + 2
 gen low_mort_hat_limit = ihs_mort_hat - 2
 predict mort_prob_hat ,pr(low_mort_hat_limit,upp_mort_hat_limit) 
 replace mort_prob_hat = mort_prob_hat + rnormal(0,0.5)
 gen mort_hat = 0.5*exp(ihs_mort_hat)-1/exp(ihs_mort_hat)                        // convert to euros 
 gen mort_hat_weight = mort_hat*hw0010

 scatter ihs_mort_hat  mort_prob_hat
  
  
  keep if sa0100=="SK"

 
* Simulation:                                                                   // 
*forvalues j=1(1)150{

 global varlist = "rand_LTV down_pay afford aux1 aux2 target new_mort mort_simul loan dl1100 dnnla dn3001 da1120 Agg_Loans"
foreach v of global varlist{
   gen  `v'_1 = .                                                             // create temporal variables 
}

*foreach ii of global ctrylist {                                                 // Country loop
 
* 1) If aggregate Mortgages increases 
 local delta_mort = Scale_deltaMort_SK

 if `delta_mort' > 0 {
 
   di "-------------------------------------------------------------------"
   di "------------`ii' Increases Mortgages: Run Simulation --------------"
   di "-------------------------------------------------------------------"

 *Loan-to-Value distribution 
  local mean_ltv = mean_LTV_SK
  local sder_ltv = sder_LTV_SK
* replace rand_LTV_`j' = rnormal(`mean_ltv',`sder_ltv') if sa0100 == "`ii'"     // normal with information from the cross section 
  

  
  if inlist("`ii'", "IE", "GR","CY","LV","NL","PT","FI"){                // Centered countries rbeta(5,5)
  replace rand_LTV_`j' = rbeta(2,2)                     if sa0100 == "`ii'"
  }
  
  
  
  else{                                                                         // Left-skewed countries rbeta(5,5)
  replace rand_LTV_1 = rbeta(3,6)                     if sa0100 == "SK"
  }
  
  
  replace rand_LTV_1 = -rand_LTV_1 if rand_LTV_1 < 0 & sa0100 == "SK"   // dirty trick to avoid negative LTV 
  
 *Affordability & Down Payment 
  replace down_pay_1 = (1-rand_LTV_1)*mort_hat         if sa0100 == "SK"        // down payment 
  replace down_pay_1 = 0              if rand_LTV_1 >=1 & sa0100 == "SK"        // No downpayment for people with LTV>1 
  replace down_pay_1 = .              if down_pay_1<0
  
  replace afford_1   = 0 if down_pay_1>dnnla & sa0100 == "SK"
  replace afford_1   = 1 if inrange(down_pay_1,-0.001,dnnla) & sa0100 == "SK"  // Affordable (and positive) 
                                
   
   * Sort by probability of getting a mortgage
  gsort sa0100 -afford_1-mort_prob_hat                                        // sort country, afford (yes to no), and prob (high to low)

  replace target_1 = Scale_deltaMort_SK if sa0100 == "SK"                 // Target: change in aggregate mortgages
  replace aux1_1   = sum(mort_hat_weight) if sa0100 == "SK"                 // Running sum over weighted predicted mortgages  
  replace aux2_1   = 1 if aux1_1 <= target_1 & sa0100=="SK" & afford_1==1   // This number identify the last person affected by the simul

  replace new_mort_1 = 0  if sa0100 =="SK"
  replace new_mort_1 = 1  if aux2_1 ==1 & sa0100=="SK" & afford_1==1            // identifies newly issued mortgages 
  
  replace loan_1 = mort_hat if new_mort_1 == 1 & sa0100 == "SK"                 // Loan aquired        
 
  * Aggregate newly issued loans
  qui sum loan_1 [aw=hw0010]       if new_mort_1 == 1 & sa0100 == "SK", d 
  replace Agg_Loans_1 = r(sum)     if sa0100 == "SK"
	
   
  *** Now udjust variables:::::: 

  * New issued loans to dl1100 
  replace dl1100_`j' = dl1100
  replace dl1100_`j' = dl1100 + loan_`j'   if sa0100=="DE" & new_mort_`j'==1           // New loans factored by weight
  
  replace dnnla_`j'  = dnnla                if sa0100=="DE"
  replace dnnla_`j'  = dnnla - down_pay_`j' if sa0100=="DE" & new_mort_`j'== 1 // Reduce Liquid Wealth
  
                                                                           
  
  
 }


 else {
    di "-------------------------------------------------------------------"
    di "-------`ii' Decreases Mortgages: skip to next country--------------" 
    di "-------------------------------------------------------------------"

	}
	}
	
   di "-------------------------------------------------------------------"
   di "-------------Simulation `j', implicate `im' Completed--------------"
   di "-------------------------------------------------------------------"

}


* Collect statistics on the simulation: 
 di "Compute mean cross simulations"

 
 egen new_mort   = rowmean(new_mort_*)                                             // New Mortgage 
 drop new_mort_*

 egen afford     = rowmean(afford_*)                                                 // Afford  
 drop afford_*

 egen down_pay   = rowmean(down_pay_*)                                             // Down Payment 
 drop down_pay_* 

 egen loan       = rowmean(loan_*)                                                     // Issued loans 
 drop loan_*

 egen LTV        = rowmean(rand_LTV_*)                                                  // LTV                                    
 drop rand_LTV_*

 egen new_dl1100 = rowmean(dl1100_*)                                             // Outstanding mortgages  
 drop dl1100_*

 egen new_dnnla  = rowmean(dnnla_*)                                               // Liquid assets after simulation 
 drop dnnla_*

 egen new_da1110 = rowmean(da1120_*)                                             // Other properties Non-HMR
 drop da1120_*

 egen target     = rowmean(target_*)
 drop target_*

 egen Agg_Loans  = rowmean(Agg_Loans_*)
 drop Agg_Loans_*
 
* Save result for one implicate

 di "-------------------------------------------------------------------"
 di "----------- Save results for implicate `im' -----------------------"
 di "-------------------------------------------------------------------"

save "$hfcsoutputPath/mortSimResults_imp`im'.dta", replace
}



replace loan_1 = asinh(loan_1)



hist ihs_mort_hat if afford == 1

hist loan_1













 