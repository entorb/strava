/* eslint-disable camelcase */
/* eslint-disable require-jsdoc */
"use strict";

const columns = [];

columns.push(helper_tabulator_col_str("x_date", "Date"));
columns.push(helper_tabulator_col_str("type", "Type"));
columns.push(helper_tabulator_col_str("name", "Name", 120));
columns.push(helper_tabulator_col_str("x_nearest_city_start", "City", 120));
columns.push(
  helper_tabulator_col_str("x_start_locality", "Known location start")
);
columns.push(helper_tabulator_col_str("x_end_locality", "-end"));
columns.push(helper_tabulator_col_str("x_gear_name", "Gear", 120));
columns.push(helper_tabulator_col_num("x_min", "Minutes"));
columns.push(helper_tabulator_col_num("x_km", "Kilometers"));
columns.push(helper_tabulator_col_num("km/h", "km/h"));
columns.push(helper_tabulator_col_num("x_max_km/h", "max km/h"));
columns.push(helper_tabulator_col_num("total_elevation_gain", "Elevation (m)"));
columns.push(helper_tabulator_col_num("x_elev_m/km", "Elevation (m/km)"));
columns.push(helper_tabulator_col_num("average_heartrate", "HR avg"));
columns.push(helper_tabulator_col_num("max_heartrate", "HR max"));
columns.push(helper_tabulator_col_num("average_cadence", "Cadence"));
columns.push(helper_tabulator_col_num("average_watts", "Watts avg"));
columns.push(helper_tabulator_col_num("kilojoules", "KJ"));
columns.push(helper_tabulator_col_str("visibility", "visibility"));
columns.push(helper_tabulator_col_num("athlete_count", "Athletes"));
columns.push(helper_tabulator_col_num("workout_type", "W-Type"));
columns.push(helper_tabulator_col_num("commute", "Commute"));
columns.push(helper_tabulator_col_num("kudos_count", "Kudos"));
columns.push(helper_tabulator_col_num("comment_count", "Comments"));
columns.push(helper_tabulator_col_num("achievement_count", "Achievements"));

function defineTable() {
  const table = new Tabulator("#table-activity-list", {
    // height: "100%",
    maxHeight: "100%", // do not let table get bigger than the height of its parent element
    // height: 800,
    layout: "fitDataStretch", // fit columns to width of table (optional)
    tooltipsHeader: false,
    selectable: false, // for row click
    columns: columns,
    initialSort: [{ column: "x_date", dir: "desc" }]
  });
  return table;
}
const table = defineTable();

// wait for tableBuilt event and set data afterwards
table.on("tableBuilt", () => {
  table.setData(
    `https://entorb.net/strava-old/download/${session}/activityList.json`
  );
});

// row click event -> open Strava
table.on("cellClick", (e, cell) => {
  const row = cell.getRow();
  const rowData = row.getData();
  const activityUrl = rowData.x_url;
  window.open(activityUrl);
});
