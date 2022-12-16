// Import excel

  import excel "${box}/data/2019.xlsx" , first clear
    keep Nimistu Registrikood Arstinimi s_* t_*
    ren Nimistu uid
      isid uid, sort

    save "${git}/data/2019.dta" , replace

  import excel "${box}/data/2020.xlsx" , first clear
    keep nimistu Registrikood Arstinimi s_* t_*
    ren nimistu uid
      isid uid, sort

    save "${git}/data/2020.dta" , replace

  import excel "${box}/data/2019-qbs.xlsx" , first clear
    keep Registrikood Saavutatudpunkte Perearstinimikesosales2019
    ren (Registrikood Saavutatudpunkte Perearstinimikesosales2019)(pid qbs name)
      lab var pid "Provider ID"
      lab var qbs "QBS"
      lab var name "Name"
    duplicates drop name , force
    drop if pid == .
      drop pid
      gen year = 1
      isid name, sort

    save "${git}/data/2019-qbs.dta" , replace

  import excel "${box}/data/2020-qbs.xlsx" , first clear
    keep Registrikood Saavutatudpunkte Seisuga31122020nimistuttee
    ren (Registrikood Saavutatudpunkte Seisuga31122020nimistuttee)(pid qbs name)
      lab var pid "Provider ID"
      lab var qbs "QBS"
      lab var name "Name"
    duplicates drop name , force
    drop if pid == .
      drop pid
      gen year = 2
      isid name, sort

    save "${git}/data/2020-qbs.dta" , replace

// Fix things

  iecodebook append ///
    "${git}/data/2019.dta" "${git}/data/2020.dta" ///
  using "${git}/data/qbs.xlsx" ///
  , clear surveys(2019 2020) gen(year)

  merge m:1 name year using "${git}/data/2019-qbs.dta" , keep(1 3) nogen
  merge m:1 name year using "${git}/data/2020-qbs.dta" , update nogen
  drop if qbs == .

  isid uid year, sort
  egen a = group(uid)
    drop uid
    ren a uid
    lab var uid "Provider ID"
  xtset uid year
  drop name pid
  order uid year qbs, first
  compress

  save "${git}/constructed/qbs.dta" , replace
//
