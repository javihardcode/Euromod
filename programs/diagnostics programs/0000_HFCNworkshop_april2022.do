* 
*  HFCS_research conference 
*

global charts = "D:/microsim/results/HFCS_April_workshop/HFCS_april_2020Q3_NOFOODOUTSIDEHOME"



qui use "$hfcsinputPath/D_compl_MicroSim_$print_ts.dta", clear
keep if im0100 == 1 
keep if inlist(sa0100,"DE","ES")
global countries = "DE ES"
 



 
 **** FIGURE 1. Change in income 
preserve 
qui xtile di2000_simul_net_xtile_ES = di2000_simul_net [aw=hw0010] if sa0100 == "ES", nq(5)
qui xtile di2000_simul_net_xtile_DE = di2000_simul_net [aw=hw0010] if sa0100 == "DE", nq(5)
 
qui gen     xxtile =  di2000_simul_net_xtile_ES if sa0100 == "ES"
qui replace xxtile =  di2000_simul_net_xtile_DE if sa0100 == "DE" 
 
collapse (p50) di2000_net di2000_simul_net [aw=hw0010], by(sa0100 xxtile)
gen diff = 100*(di2000_simul_net - di2000_net)/di2000_net

gen diff_ES = diff if sa0100 == "ES"
gen diff_DE = diff if sa0100 == "DE"

gr bar diff_DE diff_ES, over(xxtile) legend(order(1 "Germany" 2 "Spain")) b1title("Net income quintiles") title("Income change HFCS 2017 - 2019Q4") ytitle("Percentage change %") note("Percentage change in median household net income by quintiles.")
gr export "$charts/inc_change_by_quint_DE_ES2019.png", replace
restore 
 
 
 
 
**** FIGURE 2. Change liquid assets
preserve
 
qui xtile dnnla_simul_xtile_ES = dnnla_simul [aw=hw0010] if sa0100 == "ES", nq(5)
qui xtile dnnla_simul_xtile_DE = dnnla_simul [aw=hw0010] if sa0100 == "DE", nq(5)
 
qui gen     xxtile =  dnnla_simul_xtile_ES if sa0100 == "ES"
qui replace xxtile =  dnnla_simul_xtile_DE if sa0100 == "DE" 
 
collapse (p50) dnnla dnnla_simul [aw=hw0010], by(sa0100 xxtile)
gen diff = 100*(dnnla_simul - dnnla)/dnnla

gen diff_ES = diff if sa0100 == "ES"
gen diff_DE = diff if sa0100 == "DE"

gr bar diff_DE diff_ES, over(xxtile) legend(order(1 "Germany" 2 "Spain")) b1title("Net liquid assets quintiles") title("Net liquid assets change HFCS 2017 - 2019Q4") ytitle("Percentage change %") note("Percentage change in median household net liquid assets by quintiles.")
gr export "$charts/liqassets_change_by_quint_DE_ES2019.png", replace
restore 
 
 
 
**** FIGURE 3. Change total assets
preserve
 
qui xtile dn3001_simul_xtile_ES = dn3001_simul [aw=hw0010] if sa0100 == "ES", nq(5)
qui xtile dn3001_simul_xtile_DE = dn3001_simul [aw=hw0010] if sa0100 == "DE", nq(5)
 
qui gen     xxtile =  dn3001_simul_xtile_ES if sa0100 == "ES"
qui replace xxtile =  dn3001_simul_xtile_DE if sa0100 == "DE" 
 
collapse (p50) dn3001 dn3001_simul [aw=hw0010], by(sa0100 xxtile)
gen diff = 100*(dn3001_simul - dn3001)/dn3001

gen diff_ES = diff if sa0100 == "ES"
gen diff_DE = diff if sa0100 == "DE"

gr bar diff_DE diff_ES, over(xxtile) legend(order(1 "Germany" 2 "Spain")) b1title("Total net wealth quintiles") title("Total net wealth change HFCS 2017 - 2019Q4") ytitle("Percentage change %") note("Percentage change in median household total net wealth by quintiles.")
gr export "$charts/totalassets_change_by_quint_DE_ES2019.png", replace
restore 
 
 

*** FIGURE 4. Saving rates by income deciles 
preserve 
gen s_rate       = (di2000_net - di3001)/di2000_net
gen s_rate_simul = (di2000_simul_net - di3001_simul)/di2000_simul_net

qui xtile di2000_simul_net_xtile_ES = di2000_simul_net [aw=hw0010] if sa0100 == "ES", nq(5)
qui xtile di2000_simul_net_xtile_DE = di2000_simul_net [aw=hw0010] if sa0100 == "DE", nq(5)
 
qui gen     xxtile =  di2000_simul_net_xtile_ES if sa0100 == "ES"
qui replace xxtile =  di2000_simul_net_xtile_DE if sa0100 == "DE" 
 

collapse (p50) s_rate s_rate_simul [aw=hw0010], by(sa0100 xxtile)
gen     abs_srate = s_rate 
replace abs_srate = -s_rate if s_rate < 0 

gen diff = 100*(s_rate_simul - s_rate) / abs_srate   

gen diff_ES = diff if sa0100 == "ES"
gen diff_DE = diff if sa0100 == "DE"
 
gr bar diff_DE diff_ES, over(xxtile) legend(order(1 "Germany" 2 "Spain")) title("Change in saving rates HFCS 2017 - 2020Q3") b1title("Net income quintiles") ytitle("Percentage change %") note("Median saving rates across net income quintiles.")
gr export "$charts/change_saving_rate_by_inc_`c'2020_nofood.png", replace
restore 
 
 

*** FIGURE 4. Saving rates by income deciles 
foreach c of global countries{
preserve 
keep if sa0100 == "`c'"
qui gen s_rate       = (di2000_net - di3001)     / di2000_net 
qui gen s_rate_simul = savings_flow_w3_simul     / di2000_simul_net  

qui xtile di2000_simul_net_xtile = di2000_simul_net [aw=hw0010], nq(5)

collapse (p50) s_rate s_rate_simul [aw=hw0010] , by(di2000_simul_net_xtile)
replace s_rate       = s_rate * 100
replace s_rate_simul = s_rate_simul * 100


gr bar s_rate s_rate_simul, over(di2000_simul_net_xtile) title("`c' Saving rates") legend(order(1 "HFCS 2017" 2 "2020Q3")) b1title("Net income quintiles") name(`c'_srates, replace) note("Median saving across net income quintiles") ytitle("Percentage %")
gr export "$charts/saving_rate_by_inc_`c'2020Q3_NOFOOD.png", replace
restore
}







*** FIGURE 5. Unemployment changes 
qui use "$dataoutputPath/Ushock_sect.dta", clear                                
keep if inlist(sa0100,"DE","ES")

* Sectors of relevance NACE classification 
* C: manufacturing                   HFCS: C
* F: constructions                   HFCS: F
* I: accomodation & food services    HFCS: GTI (includes retail & transport) 
* P: education                       HFCS: OTQ (social security & health)
* S: other services                  HFCS: RTU (includes hh works, international bodies, etc)



preserve 
keep if inlist(sect, "C", "F", "GTI","OTQ","RTU")
qui replace ushock = 100 * ushock


gr bar ushock, over(sa0100) bar(2, bcolor(red)) over(sect, relabel(1 "Manufacturing" 2 "Construction" 3 `""Accommodation" "food services""' 4 "Education" 5 `""Other" "services""' )) ytitle("Percentage change") title("Employment change in %: HFCS 2017 - 2019Q4") scale(*.95) 
gr export "$charts/empl_change_by_sects_DE_ES2019.png", replace
restore

/* leave this to see sectorial employment data 
*** ad-hoc chart: time series employment by sector 
qui use "$dataoutputPath/Employment_sect_ALL'.dta", clear
*/ 

























