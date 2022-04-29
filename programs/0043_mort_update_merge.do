* Mortgage Update Merge
* Still need to figure out some stuff
***********************************************************************************


* Open Mortgage Simulation and merge with D_compl_microsim

qui use "$hfcsoutputPath/mort_simul_compl.dta", clear 
merge m:m sa0100 sa0010 im0100 using "$hfcsinputPath/D_compl_MicroSim_$UpdateTo.dta" // FI unmatched because does not belong to the income simulation
qui drop _merge 
sort sa0100


********************************************************************************
*** 1. Generate Expected Value of Loan, debt services and down-payment
*      If number of simulations = 1, nothing changes.. 
********************************************************************************
local varlist "loan debt_serv down_pay"                                         // Multiply to new_mort to generate the expected value
foreach v of local varlist{
qui replace `v' = new_mort * `v'
qui replace `v' = . if `v' <= 0 
}


********************************************************************************
* 2. Update debt oustanding & debt services
********************************************************************************
* Debt Outstandings (dl1100 & dl1000)
qui gen down_pay_minus = - down_pay                                             

* I. Loans go to dl1100 without spcifying HMR or non-HMR 
qui egen dl1100_simul = rowtotal(loan dl1100_amort down_pay_minus)              // New mortgages = Old mortgages + new loans - down-payment 
qui replace dl1100_simul = . if dl1100_simul <= 0 

* II. Total mortgage debt 
qui rename dl1000_simul dl1000_simultempp
qui egen dl1000_simul = rowtotal(dl1100_simul dl1200_amort)                     // New total debt = new mortgages debt + old non-mortgage debt 
qui replace dl1000_simul = . if dl1000_simul <= 0                                

* III.  Debt services goes without specifying as HMR 
qui rename  dl2100_simul dl2100_simul_temp                                        
qui egen    dl2100_simul = rowtotal(dl2100_simul_temp debt_serv)                 // Add new debt services
qui replace dl2100_simul = . if dl2100_simul <= 0 

* IV. Total debt services 
qui rename  dl2000_simul dl2000_simul_temp                                              
qui egen    dl2000_simul = rowtotal(dl2100_simul dl2200_simul)                  // New total debt services           
qui replace dl2000_simul = . if dl2000 <= 0 



********************************************************************************
* 3. Udjust Wealth variables
********************************************************************************

* 1. Liquidate Down-payment from liquid assets: 

* I. substract down-payment from deposits 
qui egen  temp1   = rowtotal(da2101_simul down_pay_minus)  
qui replace da2101_simul = temp1
qui replace da2101_simul = . if temp1 <= 0 
qui replace temp1 = . if temp1 >=0 

* II. Liquidate shares (da2105_simul)
qui egen temp2 = rowtotal(da2105_simul temp1)
replace da2105_simul = temp2 
replace da2105_simul = .    if temp2 <= 0 
replace temp2 = . if temp2 >=1 

* III. Liquidate Bonds (da2103_simul)
qui egen temp3 = rowtotal(da2103_simul temp2)
replace da2103_simul = temp3 
replace da2103_simul = .    if temp3 <= 0 
replace temp3 = . if temp3 >=1 

* IV. Liquidate Funds (da2102_simul)
qui egen temp4 = rowtotal(da2102_simul temp3)
replace da2102_simul = temp4 
replace da2102_simul = .    if temp4 <= 0 
replace temp4 = . if temp4 >=1 

* V. Liquidate managed accounts (da2106)
qui egen temp5 = rowtotal(da2106 temp4)
qui replace da2106_simul = temp5 
qui replace da2106_simul = .    if temp5 <= 0 
qui replace temp5 = . if temp5 >=1 

* VI. Liquidate priv. business liq wealth (da2104_simul)
qui egen temp6 = rowtotal(da2104_simul temp5)
replace da2104_simul = temp6 
replace da2104_simul = .    if temp6 < 0 
replace temp6 = . if temp6 >=1 

drop temp* 

* 2. Recompute liquid assets
qui rename dnnla_simul dnnla_simultemp22 
qui egen dnnla_simul = rowtotal(da2101_simul da2102_simul da2103_simul da2104_simul da2105_simul da2106_simul dl1200_amort_minus)

* 3. Recompute financial assets: 
rename da2100_simul da2100_simultemp22
qui egen da2100_simul = rowtotal(da2101_simul da2102_simul da2103_simul da2104_simul da2105_simul da2106_simul da2107 da2108_simul da2109_simul)

* 4. Recompute housing wealth: loan for HMR to housing wealth 
qui rename da1110_simul da1110_simultemp22
qui egen   da1110_simul = rowtotal(da1110_simultemp22 loan) 

* 5. Recompute Real Assets: 
qui rename da1000_simul da1000_simultemp22 
qui egen da1000_simul = rowtotal(da1110_simul da1120_simul da1130_simul da1131_simul da1140_simul)

* 6. Recompute Total Assets: 
qui rename da3001_simul da3001_simultemp22
qui egen   da3001_simul = rowtotal(da1000_simul da2100_simul)


* 6. Recompute Total Net Assets 
qui rename dn3001_simul dn3001_simultemp22
qui gen    dl1000_simul_minus = -dl1000_simul
qui egen dn3001_simul = rowtotal(da3001_simul dl1000_simul_minus)      



********************************************************************************
* 4. Save final result: 
********************************************************************************


qui save "$hfcsinputPath/D_compl_MicroSim_$UpdateTo.dta" , replace






















