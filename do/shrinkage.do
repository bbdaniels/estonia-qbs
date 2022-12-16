// Implement Kaine-Staiger --------------------------------------------
clear
tempfile all
save `all' , emptyok

use "${git}/constructed/qbs.dta" , clear
drop hypr1_a hypr1_b

// Set up ultra-long data
qui foreach var of varlist *a {
  preserve
  local type = substr("`var'",1,strpos("`var'","_")-1)
  local label : var label `var'
  keep uid year `type'_?
  gen type = "`label'"
  ren `type'_? ?
  append using `all'
    save `all' , replace
  restore
}

use `all' , clear
  encode type , gen(type_code)
  expand a
  bys uid type_code year : gen treat = (_n < b)

// Get parameters

  // Step 1: Get residuals
  qui reg treat , a(type_code)
    predict e , resid
    qui su e , d
      local vijt_var = r(Var)

  // Step 2: Get diagnosis variance
  bys uid type_code year: egen vjt_bar = mean(e)
    gen e_var = e - vjt_bar
    qui su e_var , d
      local e = r(Var)

  // Step 3: Get provider variance
  egen doctype = group(uid type_code)
    duplicates drop doctype year, force
    xtset doctype year
    sort doctype year
      gen lag = L.vjt_bar
      expand a
      correlate vjt_bar lag , covariance
        local u = r(cov_12)

  // Get remainder
  local t = `vijt_var' - `u' - `e'

  di "`vijt_var'"
  di "`e'"
  di "`u'"
  di "`t'"

// Create naive weights for vjt_bar
duplicates drop doctype year, force
gen h = 1 / (`t' + (`e'/a))
  bys doctype year : egen h_sum = sum(h)
  replace h = h/h_sum

collapse (rawsum) a (mean) vjt_bar [aweight = h] , by(uid year)

// Create shrunken weights for vjt_bar
gen w = `u' / (`u' + (1/a))
  gen vjt_shr = vjt_bar * w

  keep uid year vjt_shr vjt_bar
    lab var vjt_bar "Naive Value Add"
    lab var vjt_shr "Kaine-Saiger Value Add"

  save "${git}/constructed/value-add.dta" , replace

// Implement Need-Based --------------------------------------------
clear
tempfile all
save `all' , emptyok

use "${git}/constructed/qbs.dta" , clear
qui foreach var of varlist *a {
  local type = substr("`var'",1,strpos("`var'","_")-1)
  gen `type'_d = (`type'_b/`type'_a)
}
  pca *_d
  mat pca = e(L)

// Set up ultra-long data
local x = 0
qui foreach var of varlist *a {
  local ++x
  preserve
  local type = substr("`var'",1,strpos("`var'","_")-1)
  local label : var label `var'
  keep uid year `type'_?
  gen type = "`label'"
  ren `type'_? ?
  gen weight = pca[`x',1]
  drop d
  append using `all'
    save `all' , replace
  restore
}

use `all' , clear
encode type , gen(type_code)

bys year type_code : egen a_bar = mean(a)
bys year type_code : egen b_bar = mean(b)

gen d = (b+b_bar)/(a+a_bar)
  collapse (mean) vjt_nb = d [pweight=weight], by(uid year)
    lab var vjt_nb "Need Based Performance"
  gen qbs_nb = vjt_nb * 800
    lab var qbs_nb "Need Based QBS"
  keep uid year vjt_nb qbs_nb

  save "${git}/constructed/need-based.dta" , replace

//
