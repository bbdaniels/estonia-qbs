// Figure 1. QBS by year
use uid year qbs using "${git}/constructed/qbs.dta" , clear
  reshape wide qbs , i(uid) j(year)
  egen rank = rank(qbs2) , unique

  tw ///
    (pcspike qbs1 rank qbs2 rank , lw(vthin) lc(gs14) mc(black) msize(tiny) m(.)) ///
    (scatter qbs1 rank , mc(gs12) msize(tiny) m(.)) ///
    (scatter qbs2 rank , mc(black) msize(tiny) m(.)) ///
  , yline(0 512 576 800 , lc(black)) ylab(0 512 576 800) ///
    legend(on order(2 "2019" 3 "2020") pos(11) ring(0) c(1) region(lc(none))) ///
    xlab(0 "Lowest" 400 "{&larr} 2020 QBS Rank {&rarr}" 800 "Highest" , notick) ///
      yscale(noline) ylab(, notick) xtit("") xscale(noline) xoverhang

// Figure 2. Incentive failures
use "${git}/constructed/qbs.dta" , clear

  local yline_diab    .76
  local yline_diabr   .70
  local yline_hyp1    .76
  local yline_hyp2    .73
  local yline_hyp3    .70
  local yline_hypr1   .90
  local yline_hypr2   .83
  local yline_inf     .90
  local yline_infr1   .70
  local yline_infr2   .70
  local yline_e032    .90

foreach var of varlist *_a {
  local type = substr("`var'",1,strpos("`var'","_")-1)
  local label : var label `var'
  di "`type'"
  tempfile `type'
  gen `type' = `type'_b/`type'_a
  tw ///
    (scatter `type' `type'_a ///
      , mc(black) mc(vtiny) m(.) mc(gray%20) mlc(none)) ///
    (lpoly `type' `type'_a , lc(red) lw(thick)) ///
  , yline(`yline_`type'' , lc(black)) title("`label'" , size(small)) ///
    ylab(0 "0%" .5 "50%" 1 "100%" `yline_`type'' "{&rarr}" , notick) ///
    nodraw saving(``type'')
  local graphs `"`graphs' "\``type''" "'
}

  graph combine `graphs'

//
