*
* This script aims at describing the distribution of consumption used on Microsim 
* 

* 1. Open the HBS household data for DE and ES. 
* 2. Process data as in the microsimulation 
* 3. Append together 
* 4. Describe data 

global countries = "DE ES"
global data_HBS  "D:\data\hbs" 

/////////////////////////////////////////////////////////////////////////////////
* 1 
/////////////////////////////////////////////////////////////////////////////////

foreach c of global countries{
* Start with person dataset
qui use "$data_HBS/`c'_HBS_hm.dta", clear

* Number of children
qui generate auxchild = ((age5 == 1 | age5 == 2 | age5 == 3 | age5 == 4) & (mb05 == 3 | missing(mb05) == 1))     // Number of children
bysort sa0100 ha04 : egen number_children = total(auxchild)
qui drop auxchild

* eur_mf099 is total net income by household member
bysort sa0100 ha04 : egen max_income = max(eur_mf099)

* calculate household size from here, hb05 has some missing values
bysort sa0100 ha04 : egen hhsize = count(pid)

* level of education in categories, not in years
qui generate educ = mc01
* labour status in categories
qui generate labour_status = me01
* sex
qui generate sex = mb02

qui keep if pid == 1

* marital status of the household head
qui generate couple = (mb04 == 2 | mb042 == 1)

qui generate familytype = .
qui replace  familytype = 1 if couple == 1 & number_children > 0
qui replace  familytype = 2 if couple == 1 & number_children == 0
qui replace  familytype = 3 if couple == 0 & number_children > 0
qui replace  familytype = 4 if couple == 0 & number_children == 0

qui keep sa0100 ha04 age5 educ labour_status sex number_children max_income familytype couple

* Merge family dataset
qui merge 1:1 sa0100 ha04 using "$data_HBS/`c'_HBS_hh.dta"
qui drop if _m != 3
qui drop _m

* food consumption
* eur_he01   : food and non-alcoholic beverages
* eur_he0211 : spirits
* eur_he0212 : wine
* eur_HE0213 : beer
* eur_he111  : catering services
qui egen totalfood = rowtotal(eur_he01 eur_he0211 eur_he0212 eur_he0213 eur_he111)
label variable totalfood "Total food and beverage consumption"

* total consumption
qui gen C_hbs = eur_he00

* generate dummies for age
qui generate agerp_1 = (age5 > 0 & age5 < 7)
qui generate agerp_2 = (age5 == 7  | age5 == 8)
qui generate agerp_3 = (age5 == 9  | age5 == 10)
qui generate agerp_4 = (age5 == 11 | age5 == 12)
qui generate agerp_5 = (age5 == 13 | age5 == 14)
qui generate agerp_6 = (age5 >= 15)

* gender dummy
qui generate head_male = (sex == 1)

* household size dummy
qui generate hhsize = hb05

* household size dummies
qui generate hhsize_1 = (hhsize == 1)
qui generate hhsize_2 = (hhsize == 2)
qui generate hhsize_3 = (hhsize >= 3)

* number of children dummies
qui generate number_children_1 = (number_children == 1)
qui generate number_children_2 = (number_children == 2)
qui generate number_children_3 = (number_children >= 3)

* education level dummies
qui generate diploma_1 = (educ == 0 | educ == 1)
qui generate diploma_2 = (educ == 2)
qui generate diploma_3 = (educ == 3 | educ == 4)
qui generate diploma_5 = (educ == 5 | educ == 6)

* labour status dummies
* employed
qui generate labour_status_1 = (labour_status == 1)
* unemployed, student, housekeeper, disabled, on duty
qui generate labour_status_2 = (labour_status == 2 | (labour_status > 3 & labour_status < 8))
* retired
qui generate labour_status_3 = (labour_status == 3)

* Income quintiles (changed to deciles)
qui generate net_income = cond(missing(eur_hh095) == 1, 0, eur_hh095)
qui xtile dhiq01 = net_income [pw=ha10], n(10)

*qui levelsof dhiq01, local(qtiles)
*foreach q in `qtiles' {
*  qui  generate income_quintile_`q' = (dhiq01 == `q')
*}

* Food polynomial
qui gen c_F  = totalfood/10^3
qui gen c_F2 = totalfood^2/10^6
qui gen c_F3 = totalfood^3/10^12

* total less food consumption
qui gen CminuscF_hbs = C_hbs - totalfood
*gen lnCminuscF_hbs = ln(CminuscF_hbs)
local remove CminuscF_hbs

qui keep sa0100 CminuscF_hbs c_F c_F2 c_F3 agerp_1 agerp_2 agerp_4 agerp_5 agerp_6 head_male hhsize_1 hhsize_3 number_children_1 number_children_2 number_children_3 diploma_1 diploma_2 diploma_5 labour_status_2 labour_status_3 couple ha10
save "$data_HBS/`c'_HBS_temp.dta", replace
}


use "$data_HBS\DE_HBS_temp.dta", clear 
append using "$data_HBS\ES_HBS_temp.dta"




* Summarize the consumption variable 

sum CminuscF_hbs [aw=ha10] if sa0100 == "DE",d
sum CminuscF_hbs [aw=ha10] if sa0100 == "ES",d































