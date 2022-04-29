

* 1) Open mortgage simulation and keep relevant variables
qui use "$hfcsoutputPath/mort_simul_compl.dta", clear 

* Merge with D_compl_microsim
qui merge 1:1 sa0100 sa0010 im0100 using "$hfcsinputPath/D_compl_MicroSim_$print_ts.dta" // FI unmatched because does not belong to the income simulation
qui drop _merge 


* 2) Generate Expected Value of Loan, debt services and down-payment
sort sa0100 -new_mort

local varlist "loan debt_serv down_pay"                                         // Multiply to new_mort to generate the expected value
foreach v of local varlist{
qui replace `v' = new_mort * `v'
qui replace `v' = . if `v' == 0 
}

********************************************************************************
* 3) Update debt oustanding & debt services
********************************************************************************
* I Debt Outstandings (dl1100 & dl1000)
qui replace down_pay = . if down_pay == 0                                       // Give . to those who dont enter the simulation 
qui gen down_pay_minus = - down_pay                                             // convert to negative 

* Loans go to dl1100 without spcifying HMR or non-HMR 
qui egen dl1100_simul = rowtotal(loan dl1100_amort down_pay_minus)              // New mortgages = Old mortgages + new loans - down-payment 
qui replace dl1100_simul = . if dl1100_simul == 0 


qui rename dl1000_simul dl1000_simultemp1                                       // QUESTION:  where do we create dl1000_simul? ??????
qui egen dl1000_simul = rowtotal(dl1100_simul dl1200_amort)                     // New total debt = new mortgages debt + old non-mortgage debt 
qui replace dl1000_simul = . if dl1000_simul == 0                                

* II Debt services goes without specifying as HMR or not, just mortgages..
qui rename dl2100_simul dl2100_simul_temp                                       // Change name with respect Asset Update 
qui egen   dl2100_simul = rowtotal(dl2100_simul_temp debt_serv)                 // Add new debt services for mortgages 
qui replace dl2100_simul = . if dl2100_simul == 0 

qui rename  dl2000_simul dl2000_simul_temp                                              
qui egen    dl2000_simul = rowtotal(dl2100_simul dl2200_simul)                  // New total debt services           
qui replace dl2000_simul = . if dl2000 == 0 




********************************************************************************
* Compute savings considering new debt services from Mortgage Simulation: 
********************************************************************************
* 1. Generate average change in debt services payments from Wave 2 to Simulated Wave 3 (dbar in the model)
*qui gen     dl2000_simul_bar = .
*qui replace dl2000_simul     = 0 if dl2000_simul == . 
*qui replace dl2000           = 0 if dl2000       == .  
*foreach c of global ctrylist{
*qui replace dl2000_simul_bar = (dl2000_simul - dl2000)/sim_Y_inc_`c'  if sa0100 == "`c'"
*}


* 2. Distribute new debt services contracted to dl2000_paid_average (Increasing d(t) in the model)
*qui replace dl2000_paid_average = 0 if dl2000_paid_average == .                 // Do this to avoid missing values                                     
*foreach c of global ctrylist{
*qui replace dl2000_paid_average = dl2000_paid_average + (dl2000_simul - dl2000)  if sa0100 == "`c'" 
*}



