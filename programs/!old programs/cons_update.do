

* Load consumption growth rates
use "$dataoutputPath/P31_ALL.dta", clear                                        // open macrodata

* For each country, compute aggregage consumption growth rate btw w1 and w2

foreach ctry of global ctrylist {

	sca P31_growth_`ctry' = P31_`ctry'[end_q_ass_`ctry'_n]/P31_`ctry'[start_q_ass_`ctry'_n]

}

* Load Wave 2 data with imputed consumption 
use "P:/ECB business areas/DGR/Databases and Programme files/DGR/Javier Ramos/microsim/1_0_2/data/output/Chat_ALL.dta", clear

rename Chat di3001

gen di3001_w2 = di3001

* Keep consumption
* keep di3001 sa0100 sa0010 im0100 id

* Update by aggregate consumption growth rate
foreach ctry of global ctrylist {
	
	replace di3001_w2 = di3001_w2*P31_growth_`ctry' if sa0100 == "`ctry'"

}

* Compute level difference
gen di3001_deltaw1w2sim = di3001_w2 - di3001

save "P:/ECB business areas/DGR/Databases and Programme files/DGR/Javier Ramos/microsim/1_0_2/data/output/di3001_deltaw1w2sim.dta", replace                         

