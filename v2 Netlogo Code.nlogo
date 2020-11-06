;V2 NETLOGO CODE

; Model Setup
extensions [ gis ]

breed [refugees refugee]
breed [ sewage-tanks sewage-tank ]
breed [ water-pumps water-pump ]
breed [ wash-n-sinks wash-n-sink ]
breed [ tent-centroids tent-centroid ]
breed [ sec-centroids sec-centroid ]
undirected-link-breed [ Friends Friend ]

tent-centroids-own [
  nationality
  hhnumber
  hhparents
  hhkids_elderly
]

sec-centroids-own [
  nationality
]

refugees-own [
  nationality
  houselocation
  age
  sex
  activitycategory
  activitylocation
  pdi
  idv
  mas
  uai
  lto
  ivr
  ach
  pow
  hed
  stm
  sd
  ben
  cft
  sec
  uni
  ig2-ach
  ig2-pow
  ig2-hed
  ig2-stm
  ig2-sd
  ig2-ben
  ig2-cft
  ig2-sec
  ig2-uni
]

globals [
  det-building-dataset
  gov-building-dataset
  isobox-double-dataset
  isobox-single-dataset
  levels-dataset
  med-facil-dataset
  mil-shelters-dataset
  misc-building-dataset
  mosque-dataset
  msf-zone-dataset
  ngo-building-dataset
  pow-n-pump-sta-dataset
  ric-outline-dataset
  river-dataset
  road-borders-dataset
  road-fill-dataset
  rubb-halls-dataset
  sec-building-dataset
  sewage-tank-dataset
  sgv-markers-dataset
  tents-dataset
  unhcr-tents-dataset
  walls-borders-dataset
  wash-facil-dataset
  wash-icons-dataset
  wash-n-sinks-dataset
  water-pumps1-dataset
  water-pumps2-dataset
  zones-labels-dataset
  zones-on-31219-dataset
  playareas
  foodcenter
  male_percent
  age_10
  age_20
  age_30
  age_40
  age_50
  age_60
  age_70
  afghan
  cameroon
  congo
  iran
  iraq
  somalia
  syria
  value_std_dev
  max-friends
  numberofunaccompaniedyouth
  hour
  day
]

patches-own [
 land-type
]

to setup
  clear-all
  reset-ticks
  set male_percent 0.54 ; 6981/12883 = 54%
  set age_10 0.21 ; 2727/12883 = 21%
  set age_20 0.38 ; 4922/12883 = 38% ; youth cutoff
  set age_30 0.64 ; 8280/12883 = 64%
  set age_40 0.82 ; 10522/12883 = 82%
  set age_50 0.91 ; 11711/12883 = 91%
  set age_60 0.96 ; 12421/12883 = 96% ; adult cutoff
  set age_70 0.99 ; 12779/12883 = 99%
  set afghan 0.78 ; 7919/10135 = 78%
  set cameroon 0.795 ; 149/10135 = 1.5%
  set congo 0.865 ; 706/10135 = 7%
  set iran 0.875 ; 107/10135 = 1%
  set iraq 0.883 ; 83/10135 = 0.8%
  set somalia 0.923 ; 442/10135 = 4%
  set syria 1 ; 729/10135 = 7%
  set value_std_dev 10
  set max-friends 3
  set numberofunaccompaniedyouth 500


  ;gis:load-coordinate-system (word "WGS_84_Geographic.prj")
  load-data
  display-all
  createpeople
  createfriendlinks
  ask patch 40 -60 [set playareas patches with [pcolor = black] in-radius 250 ]
  set foodcenter patch -28 -99
end


; Model Go
to go
  set hour floor (ticks mod 24) ;the ticks are 10 minutes, so this translates it into hours
  set day floor (ticks / 24) + 1 ;the ticks are 10 minutes, so this translates it into days
  activity
  tick
end


;Physical Layout Module:

to load-data
  set det-building-dataset gis:load-dataset "Detention_Buildings.shp"
  set gov-building-dataset gis:load-dataset "Government_Buildings.shp"
  ;set isobox-double-dataset gis:load-dataset "ISObox double.shp"
  ;set isobox-single-dataset gis:load-dataset "ISObox single.shp"
  ;set levels-dataset gis:load-dataset "Levels.shp"
  set med-facil-dataset gis:load-dataset "Medical_Facilities.shp"
  set mil-shelters-dataset gis:load-dataset "Military_Shelters.shp"
  set misc-building-dataset gis:load-dataset "MISC_buildings.shp"
  set mosque-dataset gis:load-dataset "Mosque.shp"
  ;set msf-zone-dataset gis:load-dataset "MSF zone.shp"
  set ngo-building-dataset gis:load-dataset "NGO_buildings.shp"
  set pow-n-pump-sta-dataset gis:load-dataset "Power_and_Pump_Stations.shp"
  ;set ric-outline-dataset gis:load-dataset "RIC outline.shp"
  set river-dataset gis:load-dataset "River.shp"
  ;set road-borders-dataset gis:load-dataset "Road-borders.shp"
  set road-fill-dataset gis:load-dataset "Road-fill.shp"
  ;set rubb-halls-dataset gis:load-dataset "Rubb Halls.shp"
  set sec-building-dataset gis:load-dataset "Sections_Buildings.shp"
  set sewage-tank-dataset gis:load-dataset "Sewage Tank.shp"
  ;set sgv-markers-dataset gis:load-dataset "SGV Markers.shp"
  set tents-dataset gis:load-dataset "Tents.shp"
  set unhcr-tents-dataset gis:load-dataset "UNHCR_Tentst.shp"
  ;set walls-borders-dataset gis:load-dataset "Walls Borders.shp"
  ;set wash-facil-dataset gis:load-dataset "WASH Facilities.shp"
  ;set wash-icons-dataset gis:load-dataset "WASH Icons.shp"
  set wash-n-sinks-dataset gis:load-dataset "Washpads and Sinks.shp"
  set water-pumps1-dataset gis:load-dataset "Water Pumps1.shp"
  set water-pumps2-dataset gis:load-dataset "Water Pumps2.shp"
  ;set zones-labels-dataset gis:load-dataset "Zones Labels.shp"
  ;set zones-on-31219-dataset gis:load-dataset "Zones on 3.12.19 RIC vs OG.shp"

  gis:set-world-envelope (gis:envelope-union-of
    (gis:envelope-of det-building-dataset)
    (gis:envelope-of gov-building-dataset)
    ;(gis:envelope-of isobox-double-dataset)
    ;(gis:envelope-of isobox-single-dataset)
    ;(gis:envelope-of levels-dataset)
    (gis:envelope-of med-facil-dataset)
    (gis:envelope-of mil-shelters-dataset)
    (gis:envelope-of misc-building-dataset)
    (gis:envelope-of mosque-dataset)
    ;(gis:envelope-of msf-zone-dataset)
    (gis:envelope-of ngo-building-dataset)
    (gis:envelope-of pow-n-pump-sta-dataset)
    ;(gis:envelope-of ric-outline-dataset)
    (gis:envelope-of river-dataset)
    ;(gis:envelope-of road-borders-dataset)
    (gis:envelope-of road-fill-dataset)
    ;(gis:envelope-of rubb-halls-dataset)
    (gis:envelope-of sec-building-dataset)
    (gis:envelope-of sewage-tank-dataset)
    ;(gis:envelope-of sgv-markers-dataset)
    (gis:envelope-of tents-dataset)
    (gis:envelope-of unhcr-tents-dataset)
    ;(gis:envelope-of walls-borders-dataset)
    ;(gis:envelope-of wash-facil-dataset)
    ;(gis:envelope-of wash-icons-dataset)
    (gis:envelope-of wash-n-sinks-dataset)
    (gis:envelope-of water-pumps1-dataset)
    (gis:envelope-of water-pumps2-dataset)
    ;(gis:envelope-of zones-labels-dataset)
    ;(gis:envelope-of zones-on-31219-dataset)
    )
end

to display-all
  display-rivers
  display-buildings
end

to display-rivers
  gis:set-drawing-color blue
  gis:draw river-dataset 1
end

to display-buildings
  ; det-building
  ask patches gis:intersecting det-building-dataset
  [ set pcolor green set land-type "detention-building" ]
  ; gov-building
  ask patches gis:intersecting gov-building-dataset
  [ set pcolor green + 3 set land-type "government-building" ]
  ; med-facil
  ask patches gis:intersecting med-facil-dataset
  [ set pcolor yellow]
  ; mil-shelters
  ask patches gis:intersecting mil-shelters-dataset
  [ set pcolor orange ]
  ; misc-building
  ask patches gis:intersecting misc-building-dataset
  [ set pcolor yellow + 3 ]
  ; mosque
  ask patches gis:intersecting mosque-dataset
  [ set pcolor white ]
  ; ngo
  ask patches gis:intersecting ngo-building-dataset
  [ set pcolor pink ]
  ; pow-n-pump
  ask patches gis:intersecting pow-n-pump-sta-dataset
  [ set pcolor blue + 2 ]
  ; road
  ask patches gis:intersecting road-fill-dataset
  [ set pcolor gray ]
  ;gis:set-drawing-color gray
  ;gis:draw road-fill-dataset 1
  ; sec-building
  ask patches gis:intersecting sec-building-dataset
  [ set pcolor brown + 2 ]
  ; tents
  ask patches gis:intersecting unhcr-tents-dataset
  [ set pcolor red ]
  ask patches gis:intersecting tents-dataset
  [ set pcolor red + 1 ]
  ask patches gis:intersecting sewage-tank-dataset
  [ set pcolor brown]
  ask patches gis:intersecting water-pumps1-dataset
  [ sprout 1 [set color blue ]]
  ask patches gis:intersecting water-pumps2-dataset
  [ sprout 1 [set color blue ]]
  ask patches gis:intersecting wash-n-sinks-dataset
  [ set pcolor blue - 1]
  set-default-shape turtles "circle"

  foreach gis:feature-list-of tents-dataset [ vector-feature ->
    let cent gis:location-of gis:centroid-of vector-feature
    ; centroid will be an empty list if it lies outside the bounds
    ; of the current NetLogo world, as defined by our current GIS
    ; coordinate transformation
    if not empty? cent
    [ create-tent-centroids 1
      [ set xcor item 0 cent
        set ycor item 1 cent
        set size 0.2
        set color pcolor
      ]
    ]
  ]
  foreach gis:feature-list-of unhcr-tents-dataset [ vector-feature ->
    let cent gis:location-of gis:centroid-of vector-feature
    ; centroid will be an empty list if it lies outside the bounds
    ; of the current NetLogo world, as defined by our current GIS
    ; coordinate transformation
    if not empty? cent
    [ create-tent-centroids 1
      [ set xcor item 0 cent
        set ycor item 1 cent
        set size 0.2
        set color pcolor
      ]
    ]
  ]

 foreach gis:feature-list-of sec-building-dataset [ vector-feature ->
    let cent gis:location-of gis:centroid-of vector-feature
    ; centroid will be an empty list if it lies outside the bounds
    ; of the current NetLogo world, as defined by our current GIS
    ; coordinate transformation
    if not empty? cent
    [ create-sec-centroids 1
      [ set xcor item 0 cent
        set ycor item 1 cent
        set size 0.2
        set color pcolor
      ]
    ]
  ]

 foreach gis:feature-list-of wash-n-sinks-dataset [ vector-feature ->
    let cent gis:location-of gis:centroid-of vector-feature
    ; centroid will be an empty list if it lies outside the bounds
    ; of the current NetLogo world, as defined by our current GIS
    ; coordinate transformation
    if not empty? cent
    [ create-wash-n-sinks 1
      [ set xcor item 0 cent
        set ycor item 1 cent
        set size 0.2
        set color pcolor
      ]

    ]
  ]
end

to export
  let x user-input "Enter filename: "
  export-world x
end

to import
  clear-all
  reset-ticks
  let x user-input "Enter filename: "
  import-world x
end

;Agent Module:

to setage
  let dice1 random-float 1
  set age (ifelse-value
    dice1 < age_20 ["youth"] ; youth are below 20
    dice1 >= age_20 and dice1 < age_60 ["adult"] ; adults are below 60
    ["elderly"]) ; elderly are above 60
end

to setsex
  let dice2 random-float 1
  ifelse dice2 >= male_percent [ set sex "female" ] [ set sex "male" ]
end

to setnationality
  let dice3 random-float 1
  set nationality (ifelse-value
    dice3 <= afghan ["afghan"]
    dice3 > afghan and dice3 <= cameroon ["cameroon"]
    dice3 > cameroon and dice3 <= congo ["congo"]
    dice3 > congo and dice3 <= iran ["iran"]
    dice3 > iran and dice3 <= iraq ["iraq"]
    dice3 > iraq and dice3 <= somalia ["somalia"]
    ["syria"])
end

to sethhcharacteristics ; used data from UN
  let dice4 random-float 1
  (ifelse
    nationality = "afghan" [
      set hhnumber (ifelse-value
        dice4 <= 0.03 [2] ; split in half using data from column 4
        dice4 > 0.03 and dice4 <= 0.06 [3] ; split in half using data from column 4
        dice4 > 0.06 and dice4 <= 0.14 [4] ; split in half using data from column 5
        dice4 > 0.14 and dice4 <= 0.23 [5] ; split in half using data from column 5
        [6])
      set hhparents (ifelse-value
        dice4 <= 0.01 ["father only"] ; column 16
        dice4 > 0.01 and dice4 <= 0.06 ["mother only"] ; column 15
        ["father and mother"])
      set hhkids_elderly (ifelse-value
        dice4 <= 0.64 ["kids only"] ; column 10 - 12 normalized to 100
        dice4 > 0.64 and dice4 <= 0.83 ["elderly only"] ; column 10 - 12 normalized to 100
        ["kids and elderly"])
    ]
    nationality = "cameroon" [
      set hhnumber (ifelse-value
        dice4 <= 0.12 [1] ; column 3
        dice4 > 0.12 and dice4 <= 0.23 [2] ; split in half using data from column 4
        dice4 > 0.23 and dice4 <= 0.35 [3] ; split in half using data from column 4
        dice4 > 0.35 and dice4 <= 0.47 [4] ; split in half using data from column 5
        dice4 > 0.47 and dice4 <= 0.59 [5] ; split in half using data from column 5
        [6])
      set hhparents (ifelse-value
        dice4 <= 0.04 ["father only"] ; column 16
        dice4 > 0.04 and dice4 <= 0.25 ["mother only"] ; column 15
        ["father and mother"])
      set hhkids_elderly (ifelse-value
        dice4 <= 0.67 ["kids only"] ; column 10 - 12 normalized to 100
        dice4 > 0.67 and dice4 <= 0.87 ["elderly only"] ; column 10 - 12 normalized to 100
        ["kids and elderly"])
    ]
    nationality = "congo" [
      set hhnumber (ifelse-value
        dice4 <= 0.13 [1] ; column 3
        dice4 > 0.13 and dice4 <= 0.28 [2] ; split in half using data from column 4
        dice4 > 0.28 and dice4 <= 0.43 [3] ; split in half using data from column 4
        dice4 > 0.43 and dice4 <= 0.58 [4] ; split in half using data from column 5
        dice4 > 0.58 and dice4 <= 0.72 [5] ; split in half using data from column 5
        [6])
      set hhparents (ifelse-value
        dice4 <= 0.12 ["father only"] ; column 16
        dice4 > 0.12 and dice4 <= 0.44 ["mother only"] ; column 15
        ["father and mother"])
      set hhkids_elderly (ifelse-value
        dice4 <= 0.73 ["kids only"] ; column 10 - 12 normalized to 100
        dice4 > 0.73 and dice4 <= 0.91 ["elderly only"] ; column 10 - 12 normalized to 100
        ["kids and elderly"])
    ]
    nationality = "iran" [
      set hhnumber (ifelse-value
        dice4 <= 0.07 [1] ; column 3
        dice4 > 0.07 and dice4 <= 0.30 [2] ; split in half using data from column 4
        dice4 > 0.30 and dice4 <= 0.52 [3] ; split in half using data from column 4
        dice4 > 0.52 and dice4 <= 0.72 [4] ; split in half using data from column 5
        dice4 > 0.72 and dice4 <= 0.91 [5] ; split in half using data from column 5
        [6])
      set hhparents (ifelse-value
        dice4 <= 0.01 ["father only"] ; column 16
        dice4 > 0.01 and dice4 <= 0.05 ["mother only"] ; column 15
        ["father and mother"])
      set hhkids_elderly (ifelse-value
        dice4 <= 0.68 ["kids only"] ; column 10 - 12 normalized to 100
        dice4 > 0.68 and dice4 <= 0.97 ["elderly only"] ; column 10 - 12 normalized to 100
        ["kids and elderly"])
    ]
    nationality = "iraq" [
      set hhnumber (ifelse-value
        dice4 <= 0.01 [1] ; column 3
        dice4 > 0.01 and dice4 <= 0.06 [2] ; split in half using data from column 4
        dice4 > 0.06 and dice4 <= 0.11 [3] ; split in half using data from column 4
        dice4 > 0.11 and dice4 <= 0.22 [4] ; split in half using data from column 5
        dice4 > 0.22 and dice4 <= 0.32 [5] ; split in half using data from column 5
        [6])
      set hhparents (ifelse-value
        dice4 <= 0.02 ["father only"] ; column 16
        dice4 > 0.02 and dice4 <= 0.14 ["mother only"] ; column 15
        ["father and mother"])
      set hhkids_elderly (ifelse-value
        dice4 <= 0.64 ["kids only"] ; column 10 - 12 normalized to 100
        dice4 > 0.64 and dice4 <= 0.85 ["elderly only"] ; column 10 - 12 normalized to 100
        ["kids and elderly"])
    ]
    nationality = "somalia" [  ; used Ethiopia dimensions
      set hhnumber (ifelse-value
        dice4 <= 0.08 [1] ; column 3
        dice4 > 0.08 and dice4 <= 0.22 [2] ; split in half using data from column 4
        dice4 > 0.22 and dice4 <= 0.35 [3] ; split in half using data from column 4
        dice4 > 0.35 and dice4 <= 0.51 [4] ; split in half using data from column 5
        dice4 > 0.51 and dice4 <= 0.67 [5] ; split in half using data from column 5
        [6])
      set hhparents (ifelse-value
        dice4 <= 0.05 ["father only"] ; column 16
        dice4 > 0.05 and dice4 <= 0.23 ["mother only"] ; column 15
        ["father and mother"])
      set hhkids_elderly (ifelse-value
        dice4 <= 0.65 ["kids only"] ; column 10 - 12 normalized to 100
        dice4 > 0.65 and dice4 <= 0.86 ["elderly only"] ; column 10 - 12 normalized to 100
        ["kids and elderly"])
    ]
    [ ; syria (used values from Jordan)
      set hhnumber (ifelse-value
        dice4 <= 0.04 [1] ; column 3
        dice4 > 0.04 and dice4 <= 0.16 [2] ; split in half using data from column 4
        dice4 > 0.16 and dice4 <= 0.27 [3] ; split in half using data from column 4
        dice4 > 0.27 and dice4 <= 0.43 [4] ; split in half using data from column 5
        dice4 > 0.43 and dice4 <= 0.58 [5] ; split in half using data from column 5
        [6])
      set hhparents (ifelse-value
        dice4 <= 0.02 ["father only"] ; column 16
        dice4 > 0.02 and dice4 <= 0.07 ["mother only"] ; column 15
        ["father and mother"])
      set hhkids_elderly (ifelse-value
        dice4 <= 0.68 ["kids only"] ; column 10 - 12 normalized to 100
        dice4 > 0.68 and dice4 <= 0.94 ["elderly only"] ; column 10 - 12 normalized to 100
        ["kids and elderly"])
    ]
)
end

to setculture
  (ifelse
    nationality = "afghan" [ ; used Hofstede dimensions from Pakistan
      set pdi 55
      set idv 14
      set mas 50
      set uai 70
      set lto 50
      set ivr 0
    ]
    nationality = "cameroon" [ ; from Fatima-Zohra Er-Rafia report
      set pdi 78 ; 78 in Pendati, 2016, "Cultural Implications on Management Practices in Cameroon"
      set idv 25 ; 18 in Pendati, 2016, "Cultural Implications on Management Practices in Cameroon"
      set mas 53 ; 64 in Pendati, 2016, "Cultural Implications on Management Practices in Cameroon"
      set uai 54 ; 48 in Pendati, 2016, "Cultural Implications on Management Practices in Cameroon"
      set lto 16 ; 13 in Nigeria
      set ivr 78 ; 84 in Nigeria
    ]
    nationality = "congo" [ ; from Fatima-Zohra Er-Rafia report
      set pdi 77 ; 70 in Matondo, 2012, "A comparative study of five cross-cultural dimensions: Chinese construction companies in Congo"
      set idv 20 ; 23 in Matondo, 2012, "A comparative study of five cross-cultural dimensions: Chinese construction companies in Congo"
      set mas 46 ; 77 in Matondo, 2012, "A comparative study of five cross-cultural dimensions: Chinese construction companies in Congo"
      set uai 54 ; 44 in Matondo, 2012, "A comparative study of five cross-cultural dimensions: Chinese construction companies in Congo"
      set lto 19 ; 59 in Matondo, 2012, "A comparative study of five cross-cultural dimensions: Chinese construction companies in Congo"
      set ivr 80
    ]
    nationality = "iran" [ ; Hofstede dimensions
      set pdi 58
      set idv 41
      set mas 43
      set uai 59
      set lto 14
      set ivr 40
    ]
    nationality = "iraq" [ ; Hofstede dimensions
      set pdi 95
      set idv 30
      set mas 70
      set uai 85
      set lto 25
      set ivr 17
    ]
    nationality = "somalia" [ ; Hofstede dimensions (used Ethiopia dimensions)
      set pdi 70
      set idv 20
      set mas 65
      set uai 55
      set lto 0
      set ivr 46
    ]
    [ ; Hofstede dimensions Syria
      set pdi 80
      set idv 35
      set mas 52
      set uai 60
      set lto 30
      set ivr 0
    ]
)
end

to setvalues
  set ach (idv + mas) / 2
  set pow (idv + uai + mas) / 3
  set hed (idv + ivr) / 2
  set stm (idv + (100 - uai) + (100 - pdi)) / 3
  set sd (idv + (100 - uai) + (100 - pdi)) / 3
  set ben ((100 - idv) + (100 - uai) + (100 - mas)) / 3
  set cft ((100 - idv) + uai + pdi + (100 - ivr)) / 4
  set sec ((100 - idv) + uai + pdi) / 3
  set uni ((100 - idv) + (100 - uai) + (100 - mas)) / 3

  set ig2-ach (random-normal (ach) (value_std_dev))
  set ig2-pow (random-normal (pow) (value_std_dev))
  set ig2-hed (random-normal (hed) (value_std_dev))
  set ig2-stm (random-normal (stm) (value_std_dev))
  set ig2-sd (random-normal (sd) (value_std_dev))
  set ig2-ben (random-normal (ben) (value_std_dev))
  set ig2-cft (random-normal (cft) (value_std_dev))
  set ig2-sec (random-normal (sec) (value_std_dev))
  set ig2-uni (random-normal (uni) (value_std_dev))
end

to setkidselderly
(ifelse
  [hhkids_elderly] of tent-centroids-here = "kids only" [ set age "youth" setsex ]
  [hhkids_elderly] of tent-centroids-here = "elderly only" [ set age "elderly" setsex ]
  [let x random-float 1
   ifelse x > 0.5 [set age "youth"] [set age "elderly"]
   setsex ]
)
end

to createpeople
  ask tent-centroids [
    setnationality
    sethhcharacteristics
    ask patch-here [
      sprout-refugees [hhnumber] of myself [ sproutsettings ]
    ]
    (ifelse
      hhnumber = 1 [ ask refugees-here [
        let x random-float 1
        ifelse x < 0.96 [set age "adult"] [set age "elderly"] ;unaccompanied youth have their own area, so are not in tents
        setsex
        if age = "adult" and sex = "male" [set activitycategory "Activity B"]
        if age = "adult" and sex = "female" [set activitycategory "Activity B"]
        if age = "eldery" [set activitycategory "Activity B"]
      ]]
      hhnumber > 1 [
        (ifelse
          hhparents = "father only" [
            ask one-of refugees-here [ set age "adult" set sex "male" set activitycategory "Activity B"
              ask other refugees-here [ setkidselderly if age = "youth" [set activitycategory "Activity A"] if age = "elderly" [set activitycategory "Activity A"]]
           ]
          ]
          hhparents = "mother only" [
            ask one-of refugees-here [ set age "adult" set sex "female" set activitycategory "Activity B"
              ask other refugees-here [ setkidselderly if age = "youth" [set activitycategory "Activity A"] if age = "elderly" [set activitycategory "Activity A"]]
            ]
          ]
          [ask one-of refugees-here [ set age "adult" set sex "male" set activitycategory "Activity B"
            ask one-of other refugees-here [ set age "adult" set sex "female" set activitycategory "Activity A"]]
           let remaining refugees-here with [age != "adult"]
           if any? remaining [ ask remaining [ setkidselderly if age = "youth" [set activitycategory "Activity A"] if age = "elderly" [set activitycategory "Activity A"]]]
          ]
        )
      ]
    )
  ]

  ask sec-centroids [ ; where unaccompanied youth stay
    setnationality
    ask patch-here [
      sprout-refugees numberofunaccompaniedyouth / count sec-centroids [ sproutsettings ]
      ask refugees-here [set age "youth" setsex set activitycategory "Activity A"]
    ]
  ]
end

to sproutsettings
  set color white
  set shape "person"
  set nationality [nationality] of tent-centroids-here
  set houselocation patch-here
  setculture
  setvalues
end

;Network Module: save network
to-report value-euclidean-distance [other-agent]
  report sqrt sum (list
    ((ig2-hed - [ig2-hed] of other-agent) ^ 2)
    ((ig2-stm - [ig2-stm] of other-agent) ^ 2)
    ((ig2-sd - [ig2-sd] of other-agent) ^ 2)
    ((ig2-uni - [ig2-uni] of other-agent) ^ 2)
    ((ig2-ben - [ig2-ben] of other-agent) ^ 2)
    ((ig2-cft - [ig2-cft] of other-agent) ^ 2)
    ((ig2-sec - [ig2-sec] of other-agent) ^ 2)
    ((ig2-pow - [ig2-pow] of other-agent) ^ 2)
    ((ig2-ach - [ig2-ach] of other-agent) ^ 2))
end

to-report possible-friends
   report other refugees with [ houselocation != [houselocation] of myself and age = [age] of myself ]
end

to createfriendlinks
  ask refugees [
    if count my-links = 0 [create-Friends-with turtle-set up-to-n-of max-friends (sort-on [value-euclidean-distance myself] possible-friends)]
    ask my-links [hide-link]
  ]
end



; Activity Module:

; ticks are 1 hour intervals

to activity
  ask refugees with [activitycategory = "Activity A"] [
    if hour < 6 [gohome]
    if hour >= 6 and hour < 9 [
      let x random-float 1
      if x < 0.33 [gototoilet]
      if x > 0.66 [meetwithfriends]
    ]
    if hour = 9 [gohome]
    if hour >= 10 and hour < 13 [
      let x random-float 1
      if x < 0.33 [gototoilet]
      if x > 0.66 [meetwithfriends]
    ]
    if hour = 13 [gohome]
    if hour >= 14 and hour < 20 [
      let x random-float 1
      if x < 0.33 [gototoilet]
      if x > 0.66 [meetwithfriends]
    ]
    if hour = 20 [gohome]
    if hour >= 21 and hour < 23 [
      let x random-float 1
      if x < 0.33 [gototoilet]
      if x > 0.66 [meetwithfriends]
    ]
    if hour = 23 [gohome]
  ]

  ask refugees with [activitycategory = "Activity B"] [
    if hour >= 4 and hour < 6 [
      let x random-float 1
      if x < 0.5 [gototoilet]
      if x > 0.5 [gohome]
    ]
    if hour >= 6 and hour < 9 [waitforfood]
    if hour = 9 [gohome]
    if hour >= 10 and hour < 13 [waitforfood]
    if hour = 13 [gohome]
    if hour >= 14 and hour < 17 [
      let x random-float 1
      if x < 0.33 [gototoilet]
      if x > 0.66 [meetwithfriends]
    ]
    if hour >= 17 and hour < 20 [waitforfood]
    if hour = 20 [gohome]
    if hour >= 21 and hour < 23 [
      let x random-float 1
      if x < 0.33 [gototoilet]
      if x > 0.66 [meetwithfriends]
    ]
    if hour = 23 [gohome]
  ]
end

to meetwithfriends
  if member? activitylocation playareas = false [set activitylocation one-of playareas]
  ask Friend-neighbors [set activitylocation [activitylocation] of myself]
  move-to activitylocation
end

to gototoilet
  set activitylocation [patch-here] of min-one-of wash-n-sinks [distance myself] ;closest toilet
  move-to activitylocation
end

to waitforfood
  set activitylocation foodcenter
  move-to activitylocation
end

to gohome
  set activitylocation houselocation
  move-to activitylocation
end


; Contagion Module:



; Interventions Module:
@#$#@#$#@
GRAPHICS-WINDOW
47
10
1048
1020
-1
-1
0.6
1
10
1
1
1
0
0
0
1
-500
500
-500
500
0
0
1
ticks
30.0

BUTTON
1112
28
1237
63
setup new world
setup\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1115
86
1179
120
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

MONITOR
1198
86
1262
131
NIL
hour
17
1
11

BUTTON
1263
29
1366
64
export world
export
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1390
28
1490
63
import world
import
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
