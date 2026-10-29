# Strava Äpp

Source code of Torben's Strava Äpp V1

* 2026-10-29: archived this old app
* 2025-01-02: rewritten in modern technology (Python Streamlit), see [entorb/strava-perl/](https://github.com/entorb/strava-perl/)

---

[OpenSource](https://github.com/entorb/strava-perl/) Äpp using [Strava™'s](https://www.strava.com) [API](https://developers.strava.com/) to visualize your activity data.

## User Features

* Import and Export of Activities
  * Excel/CSV Import
  * Excel Export
  * Calendar (iCal) Export
* Analysis
  * Filterable Table of all Activities
  * Activity Statistics
    * Per Activity Type: Run, Ride, Swim, ...
    * Measures: Distance, Elevation, Heart Rate, ...
    * Aggregations: Sum and Average
    * Grouped by: Month, Quarter and Year
  * Top10 Activities Regarding Various Measures
* Geo locations
  * Find and Name Frequent Start/End Geo Locations
  * Search for Activities based on Location
* Segments
  * Table of your Starred Segments
  * ~~Segment Leaderboard Table~~ (API endpoint removed by Strava)
* Activity Modification
  * Bulk Modify of Activity Meta Data: \
set name, description, commute-flag, training-machine-flag for multiple activities

## Technical Features

* OpenSource: source code available at [GitHub](https://github.com/entorb/strava-perl/)
* Proudly made without cookies, database and of course free from advertisement
* Plain and simple layout
* Coded mainly in [Perl](/wickie/Perl) and [Gnuplot](/wickie/Gnuplot), recently extended by [Python](/wickie/Python) [Pandas](/wickie/Pandas) and JavaScript [Tabulator](https://tabulator.info/) and [ECharts](https://echarts.apache.org/)
* High level of security and privacy
  * HTTPS encrypted communication
  * no data is kept in a database
  * a temporary access token to your Strava profile is used and deleted after logout
  * your temporarily cached data is deleted upon logout
  * no third party APIs used (no Google Analytics, Maps, etc)

## List of Changes

* 2026-10-29: archived this old app
* 2025-01-02: rewriting the app in modern technology (Python Streamlit), see [entorb/strava-perl/](https://github.com/entorb/strava-perl/)
* 2024-11-16: activity bulk modify now supports update gear
* 2024-11-16: hit a Strava limit of 1000 active athlets of this app, they now raised the limit to 10000
* 2023-07-02: activity Top10 V2
* 2023-06-12: fancy activity statistics charts
* 2023-06-08: usage stats: 2697 unique and 669 returning users.
* 2020-07-24: usage stats: this tool passed the 1000-unique-users milestone!
* 2020-07-21: fancy activity table
* 2020-01-06: published source code on [GitHub](https://github.com/entorb/strava-perl/)
* 2019-06-08: top10 activities
* 2019-05-21: starred segments overview
* 2019-05-21: Excel import of activities
* 2019-05-16: limited caching to max 1000 activities per run and optimized performance, to prevent timeouts
* 2019-05-05: charts for activity statistics
* 2019-04-03: nearest city via an offline database of cities\\'s geo location, created from [MaxMind\\'s GeoLite2 data](https://www.maxmind.com)
* 2019-03-20: search for activities
* 2019-01-12: activities sorted now ASC by date, statistics extended to record speed and elevation/distance
* 2019-01-03: gear name (bike/shoe) in Excel export
* 2018-12-05: activity statistics
* 2018-11-30: caching of activities per year, besides caching of all at once, to prevent timeout issues

## User Feedback

* 2025-02-20 Franco: Thanks a lot for this tool man, really saved me lots of time getting a json of my 3400 activities so I can send them to AI for analytics. THANKS!
* 2025-01-07 Todd: Just wanted to say a massive thank you for the Strava bulk upload app. You saved me soooooo much time trying to import 2 years worth of manually tracked weight training data. Absolutely brilliant app. Thank you!
* 2024-08-01 Gustavo: It's a super nice tool. THANK YOU!!
* 2022-12-06 Angela: Just wanted to say a huge thank you for your Strava upload solution - it seems to be the only one out there. I'm super grateful to you for sharing this.
* 2022-11-23 Jacob: I cannot thank you enough for this exceptionally useful tool. I was able to upload about 10 years of running data from my Garmin Connect to my Strava account. (even more blessings at Twitter)
* 2022-09-12 Ricardo: Used it to upload data from CSV created by Zepp. I am switching to Polar, so your tool was EXTREMELY helpfull. Thank you so much!! Cheers
* 2022-03-18 Claudia: besten Dank für die Strava Äpp! Genau das, was ich gesucht habe
* 2021-12-20 Stefan: Many thanks for your Strava app. Finally did I find a way to see my Nordic Skiing stats.
* 2021-08-15 Chinmay: Kudos to you. What an app! Thank you so much.
* 2021-05-13 Markus: Thanks for the app, it's very helpful.
* 2021-04-03 Peter: Fantastic stuff, many thanks for this! It converts Strava data from fun to a great analysis base. Have a nice day!
* 2021-03-01 Eugene: This app is amazing and full of useful details.
* 2020-12-27 Mike: Excellent work! Thank YOU!!!
* 2020-09-23 Tom: big thanks from australia here for your strava manual upload plugin.
* 2020-09-16 Don: This is fantastic. I was excited to learn that I have a cumulative elevation gain in all my activities to summit Mt. Everest over 7 times! Thanks for putting this together. Much appreciated.
* 2020-08-25 Franz: vielen Dank für dein klasse Exporttool Strava→Excel
* 2020-07-10 John: Great tool!! Worked superbly.
* 2020-05-28 Sebastian: großartiges Tool, ich war schon dabei mir etwas eigenes zu basteln (was definitiv nicht deine Qualität erreicht hätte) - awesome tool and thanks for all the work!
* 2020-05-23 Mike: Thanks for sharing your great interface with everyone!
* 2020-05-09 Martin: I just want to say BIG THANK you for your great tool. I needed the export to gather my life time sport-related data. I also like statistics a lot. Keep up great work you do!
* 2020-02-25 Tony: Thanks so much for this tool, I've been able to load years of past information in a couple of hours.
* 2020-01-21 Chris: Hi. I love your Strava app. I use the excel export on a regular basis and for my needs
* 2020-01-19 Mike: Great program. Many thanks! This means a lot to me, and I am sure a lot of other people. Have a great year!
* 2020-01-07 Ben: Awesome set of tools, love all the data!
* 2019-12-30 Jon: Your strava import/export site is excellent! I just imported years of manual data and it worked perfectly. And the export will allow me to recreate my excel pivot charts using the entirety of my training data. Thank you for sharing it!
* 2019-12-17 Tim: Thanks for the useful tool. I really just needed to be able to see my total miles for 2019 and 2020. Only your tool seems to be able to do it.
* 2019-12-02 Cody: I got it all figured out! Things are importing smoothly now. Hundreds of rides from 2007 to 2014. This is making me so happy! I will definitely spread the word with anyone who needs something like this.
* 2019-09-11 Georg: Thank you Torben for making this facility available
* 2019-08-27 Sergio: Brilliant job. I have been looking for something like that for ages. And it's written in Perl! I thought I was the last one Perl Programmer... Keep up with the good work!
* 2019-08-07 Scott: Thanks for making the application!
* 2019-07-02 Rob: This is a cool tool!
* 2019-06-26 Chris: Your app works great and I believe will be a big value to people who use Strava. The import function will be great when Strava or Garmin doesn't work right leaving us to do manual input. Your answers were so quick also. I didn't expect you to do this work on such a expedient basis, nor did you have to do this for us, but you did, and it works wonderfully. Thank you so much.
* 2019-06-26 Dave: The Excel data importer is a great feature of this Strava app. Instead of having to manually transcribe my activity data that predates Strava, I was able to quickly setup my old Excel data into a format compatible with this tool. Copy, paste, preview and submit and the data is in Strava correctly. Thank you.
* 2019-06-23 Richard: Thank you, Worked perfectly!
* 2019-05-06 Rémi: Awesome tool! As I wasn't really familiar with Strava Apps, it took me a couple of minutes to understand how to use it, maybe it's worth producing a little "tutorial" in a few steps. Anyway, that's a great help and it brought me exactly what I needed to analyze and measure my progresses from my Strava stats! Thanks for your work!
* 2019-04-20 Brie: Thanks so much for making it! It's great!
* 2019-03-28 Wilton: That's fantastic work! Thanks for all your work. Exactly what I was after.
* 2019-03-20 Jon Magnus: Great site! I'm very grateful that I found info about it on a discussion forum.
* 2019-02-23 Nick: thanks for the strava tool! incredibly useful!
* 2019-02-08 Daniel: thanks man! this works great!!!
* 2019-01-01 David: Great excel exporter tool Torben!! Thanks
* 2019-01-01 Johan: Perfect tool...all i was looking for for years. Thanks
* 2018-12-31 Bill: Really cool! Works great. Thanks!
* 2018-12-31 Gabe: Thanks for the cool Strava exporter. It was exactly what I was looking for -- frustrating that Strava doesn't provide these features themselves! Anyway your tool works great and, as a fellow perl coder, I'm happy to see such nice work written in perl :-)
* 2018-12-03 Stephen: super awesome and thank you!
* 2018-11-28 Wayne: Excellent tool, just downloaded my Strava history, and its impressive the no of fields that the data contains. Now we need a tool to download segments :)
* 2018-11-27 Ken: Thanks Torben! The extract worked extremely well!
* 2018-11-24 Kyle: Thank you!
* 2018-11-24 Volker: Vielen Dank dafür!
* 2018-11-17 John: Excellent tool. Exactly what everyone is looking for in terms of Excel export. Thank you for your effort!
