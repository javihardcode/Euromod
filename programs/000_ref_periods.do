*** SET COUNTRY LISTS AND REFERENCE PERIODS FOR WAVES 1, 2, 3
* 18-03-2022 Javier Ramos Perez Last Version

* Set start year for macro update (HFCS ncome of wave 1 for ES is 2007)
global year_start "2007"
global year_start_Q = "$year_start" + "Q1"

********************************************************************************
*** Need to take care of 6 Cases
* 1) 	start_wave == 1 & UpdateTo == wave2
* 2.1) 	start_wave == 1 & UpdateTo == YYYYQQ
* 2.2)	start_wave == 2 & UpdateTo == YYYYQQ
* 3.1)	start_wave == 1 & UpdateTo == n
* 3.2)	start_wave == 2 & UpdateTo == n
* 4)    start_wave == 2 & UpdateTo == wave3
* 5)    start_wave == 3 & UpdateTo == YYYYQQ                                    // This is the relevant case now: Wave 3 to 2019Q4 

********************************************************************************

* 1)
if "$UpdateTo" == "wave2" {
	global updatetoWave2 = "1"
	global start_wave = "1"
	global case = "1"
}

* 4)
else if "$UpdateTo" == "wave3" {
	global updatetoWave3 = "1"
	global start_wave = "2"
	global case = "4"
}
// else if strpos("$UpdateTo", "wave3") {
// 	global updatetoWave3 = "1"						                            // simulate forward to wave2
// 	*global start_wave = "2"							                        // set wave2 as starting wave
// 	global case = "4"
// }

* 2)
else if strpos("$UpdateTo", "Q") {
	global updatetoQuarter = "$UpdateTo"			                            // simulate to specific quarter
	if "$start_wave" == "1" global case = "21"
	else global case = "22"
}

* 3)
else {
	global numQuarter = "$UpdateTo"					                            // simulate by number of quarters
	if "$start_wave" == "1" global case = "31"
	else global case = "32"		
}


********************************************************************************
* Javier Ramos Perez 
* 08-02-2022
* Goal: set reference periods to simulate from Wave 3 to 2019Q4 
********************************************************************************
* 5) 
if strpos("$UpdateTo", "Q") {                                                   // simulate to specific quarter (case 51... yeah a bit random)
	global updatetoQuarter = "$UpdateTo"			                            //       
	if "$start_wave" == "3" global case = "51"                                
}
********************************************************************************




*** Country lists
*** Keep the alphabetical order: change by hand whenever a new country enter the sample

if "$start_wave" == "1" {
global ctrylist = "AT BE CY DE ES FI FR GR IT LU MT NL PT SI SK"                 // good 
}
if "$start_wave" == "2" {
global ctrylist = "AT BE CY DE EE ES FI FR GR HU IE IT LU LV MT NL PL PT SI SK"  // good 
}
if "$start_wave" == "3" {
global ctrylist = "AT BE CY DE EE ES FI FR GR HU IE IT LU LV MT NL PL PT SI SK"  // good 
}
global n_countries : word count $ctrylist

* reference periods: quarters for assets; years for income (use 3rd quarter for calendar year and midquarter for last 12 months)
* Spain has the new reference periods
global ctry_ass_ref_w1 = "2011Q1 2010Q3 2010Q4 2011Q2 2012Q1 2010Q1 2009Q4 2009Q3 2011Q1 2011Q1 2011Q1 2010Q1 2010Q2 2010Q4 2010Q4" // good 
global ctry_inc_ref_w1 = "2009Q1 2009Q1 2009Q1 2009Q1 2010Q1 2009Q1 2009Q1 2008Q3 2010Q1 2009Q1 2009Q4 2009Q1 2009Q1 2009Q4 2009Q4" // good 


global ctry_ass_ref_w2 = "2014Q4 2014Q4 2014Q2 2014Q3 2013Q2 2015Q1 2014Q1 2014Q4 2014Q3 2014Q4 2013Q2 2015Q1 2014Q3 2014Q3 2014Q1 2014Q1 2014Q1 2013Q2 2014Q4 2014Q2" // good
global ctry_inc_ref_w2 = "2013Q1 2013Q1 2013Q2 2013Q1 2012Q1 2013Q1 2013Q1 2014Q1 2013Q3 2013Q4 2012Q2 2014Q1 2013Q1 2013Q1 2013Q1 2013Q1 2013Q1 2012Q1 2013Q1 2010Q1" // good

global ctry_ass_ref_w3 = "2017Q1 2017Q2 2017Q2 2017Q3 2017Q2 2018Q1 2016Q4 2017Q2 2018Q1 2017Q4 2016Q3 2016Q4 2018Q2 2017Q4 2016Q4 2016Q4 2016Q4 2017Q3 2016Q4 2017Q2" // good 
global ctry_inc_ref_w3 = "2016Q1 2016Q1 2016Q1 2016Q1 2013Q1 2016Q1 2017Q1 2016Q1 2016Q1 2017Q1 2016Q1 2017Q1 2016Q1 2016Q1 2016Q1 2016Q1 2016Q1 2016Q1 2016Q1 2016Q1" // good

* reference periods for unemployment (use asset reference periods; best we can do...)
global ctry_u_ref_w1 = "$ctry_ass_ref_w1"
global ctry_u_ref_w2 = "$ctry_ass_ref_w2"
global ctry_u_ref_w3 = "$ctry_ass_ref_w3"





*** Set start reference periods

forval i = 1/$n_countries {

local ctry `: word `i' of $ctrylist'

* If starting from wave 1
if inlist("$case","1","21","31") {
* a) Assets
sca start_q_ass_`ctry' = "`: word `i' of $ctry_ass_ref_w1'"
* b) Income
sca start_q_inc_`ctry' = "`: word `i' of $ctry_inc_ref_w1'"
* c) Unemployment
sca start_q_u_`ctry'   = "`: word `i' of $ctry_u_ref_w1'"
}

* If starting from wave 2
if inlist("$case","22","32","4") {
* a) Assets
sca start_q_ass_`ctry' = "`: word `i' of $ctry_ass_ref_w2'"
* b) Income
sca start_q_inc_`ctry' = "`: word `i' of $ctry_inc_ref_w2'"
* c) Unemployment
sca start_q_u_`ctry'   = "`: word `i' of $ctry_u_ref_w2'"
}

* Added on 08-02-2022 by Javier Ramos 
if inlist("$case","51") {        
* a) assets 
sca start_q_ass_`ctry' = "`: word `i' of $ctry_ass_ref_w3'"                     
* b) Income 
sca start_q_inc_`ctry' = "`: word `i' of $ctry_inc_ref_w3'"
* c) Unemployment
sca start_q_u_`ctry'   = "`: word `i' of $ctry_u_ref_w3'"

}
}


*** Set end reference periods
forval i = 1/$n_countries {

local ctry `: word `i' of $ctrylist'

if "$case" == "1" {
* a) Assets
sca end_q_ass_`ctry' = "`: word `i' of $ctry_ass_ref_w2'"
* b) Income
sca end_q_inc_`ctry' = "`: word `i' of $ctry_inc_ref_w2'"
* c) Unemployment
sca end_q_u_`ctry'   = "`: word `i' of $ctry_u_ref_w2'"
	}

else if "$case" == "4" {
* a) Assets
sca end_q_ass_`ctry' = "`: word `i' of $ctry_ass_ref_w3'"
* b) Income
sca end_q_inc_`ctry' = "`: word `i' of $ctry_inc_ref_w3'"
* c) Unemployment
sca end_q_u_`ctry'   = "`: word `i' of $ctry_u_ref_w3'"

	}		
	
else if "$case" == "21" | "$case" == "22" | "$case" == "51" {
* a) Assets
sca end_q_ass_`ctry' = "$UpdateTo"
* b) Income
sca end_q_inc_`ctry' = "$UpdateTo"
* c) Unemployment
sca end_q_u_`ctry'   = "$UpdateTo"

	}		

else {

* a) Assets
*sca end_q_ass_`ctry' = upper(string(scalar(quarterly(start_q_ass_`ctry', "YQ") + $numQuarter ), "%tq"))
* b) Income
*sca end_q_inc_`ctry' = upper(string(scalar(quarterly(start_q_inc_`ctry', "YQ") + $numQuarter ), "%tq"))
* c) Unemployment
*sca end_q_u_`ctry'   = upper(string(scalar(quarterly(start_q_u_`ctry', "YQ") + $numQuarter ), "%tq"))
}	
}


*** Compute implied number of simulated quarters and years. 
forval i = 1/$n_countries {

local ctry `: word `i' of $ctrylist'

* Compute number of quarters simulated
sca sim_q_ass_`ctry'_n = quarterly(end_q_ass_`ctry', "YQ") - quarterly(start_q_ass_`ctry', "YQ")
sca sim_q_inc_`ctry'_n = quarterly(end_q_inc_`ctry', "YQ") - quarterly(start_q_inc_`ctry', "YQ")
sca sim_q_u_`ctry'_n   = quarterly(end_q_u_`ctry', "YQ") - quarterly(start_q_u_`ctry', "YQ")

* Compute number of years simulated
sca sim_Y_inc_`ctry' = round(sim_q_inc_`ctry'_n/4)
sca sim_Y_ass_`ctry' = round(sim_q_ass_`ctry'_n/4)


*** Compute implied cell numbers for the macro data update

sca start_q_ass_`ctry'_n = quarterly(start_q_ass_`ctry', "YQ") - quarterly("$year_start_Q", "YQ") + 1
sca start_q_inc_`ctry'_n = quarterly(start_q_inc_`ctry', "YQ") - quarterly("$year_start_Q", "YQ") + 1
sca start_q_u_`ctry'_n   = quarterly(start_q_u_`ctry', "YQ")   - quarterly("$year_start_Q", "YQ") + 1

sca end_q_ass_`ctry'_n = quarterly(end_q_ass_`ctry', "YQ")  - quarterly("$year_start_Q", "YQ") + 1
sca end_q_inc_`ctry'_n = quarterly(end_q_inc_`ctry', "YQ")  - quarterly("$year_start_Q", "YQ") + 1
sca end_q_u_`ctry'_n   = quarterly(end_q_u_`ctry', "YQ")    - quarterly("$year_start_Q", "YQ") + 1

}
