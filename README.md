# Strava Äpp

Source code of Torben's Strava Äpp hosted at <https://entorb.net/strava-old/>

[OpenSource](https://github.com/entorb/strava) Äpp using [Strava™'s](https://www.strava.com) [API](https://developers.strava.com/) to visualize your activity data.

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

* OpenSource: source code available at [GitHub](https://github.com/entorb/strava)
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

* 2023-07-02: activity Top10 V2
* 2023-06-12: fancy activity statistics charts
* 2023-06-08: usage stats: 2697 unique and 669 returning users.
* 2020-07-24: usage stats: this tool passed the 1000-unique-users milestone!
* 2020-07-21: fancy activity table
* 2020-01-06: published source code on [GitHub](https://github.com/entorb/strava/)
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
