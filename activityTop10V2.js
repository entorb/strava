/* eslint-disable camelcase */
/* eslint-disable require-jsdoc */
"use strict";

//
// DOM elements
//
const html_sel_type = document.getElementById("sel-type");
const html_sel_measure = document.getElementById("sel-measure");
const html_yearMin = document.getElementById("sel-yearMin");
const html_yearMax = document.getElementById("sel-yearMax");

//
// Global variables
//
let data_all = [];
let data_rank = [];
const promises = []; // array of promises for async fetching

// measures used in table and in select
const measures = {
  x_min: "Duration",
  x_km: "Distance",
  "km/h": "Speed",
  total_elevation_gain: "Elevation",
  "x_elev_m/km": "Elevation Gain per Distance",
  x_dist_start_end_km: "Distance Start-End",
  average_heartrate: "Average Heartrate",
  kilojoules: "Kilo Joule",
};

// add options to html_sel_measure
helper_populate_select(html_sel_measure, measures, null, true);

const table_columns = [];

table_columns.push(helper_tabulator_col_num("rank", "#"));
table_columns.push(helper_tabulator_col_str("x_date", "Date"));
table_columns.push(helper_tabulator_col_str("name", "Name", 300));

for (let i = 0; i < Object.keys(measures).length; i++) {
  const key = Object.keys(measures)[i];
  table_columns.push(helper_tabulator_col_num(key, measures[key]));
}

//
// Data fetching
//
const fetch_data = async (session) => {
  const url = `https://entorb.net/strava/download/${session}/activityList.json`;
  try {
    const response = await fetch(url);
    const data = await response.json();
    console.log("done download activityList.json");

    // delete not needed object properties
    const allowedKeys = new Set([
      "type",
      "name",
      "x_date",
      "x_url",
      ...Object.keys(measures),
    ]);
    data.forEach((obj) => {
      Object.entries(obj).forEach(([key]) => {
        if (!allowedKeys.has(key)) {
          delete obj[key];
        }
      });
      // extract year from x_date and add as property
      obj.year = parseInt(obj.x_date.substr(0, 4));
    });

    data_all = data;
    use_data_all_to_populate_html_elements();
  } catch (error) {
    console.log("failed download activityList.json");
  }
};

// Start the async fetching
promises.push(fetch_data(session));

function use_data_all_to_populate_html_elements() {
  // extract activity types and populate select
  const act_types = [...new Set(data_all.map((obj) => obj.type))].sort();
  // convert into object of key->value with key = value
  const act_types_map = helper_array_to_object_of_key_eq_value(act_types);
  helper_populate_select(html_sel_type, act_types_map, "Run", true);

  // extract min and may year value
  const yearMin = Math.min(...data_all.map((obj) => obj.year));
  const yearMax = Math.max(...data_all.map((obj) => obj.year));
  html_yearMin.value = yearMin;
  html_yearMin.min = yearMin;
  html_yearMin.max = yearMax;
  html_yearMax.value = yearMax;
  html_yearMax.min = yearMin;
  html_yearMax.max = yearMax;
}

function defineTable() {
  const table = new Tabulator("#table-activity-list", {
    // height: "100%",
    maxHeight: "100%", // do not let table get bigger than the height of its parent element
    // height: 800,
    layout: "fitDataStretch", // fit columns to width of table (optional)
    tooltipsHeader: false,
    selectable: false, // for row click
    columns: table_columns,
  });
  return table;
}
const table = defineTable();

// row click event -> open Strava
table.on("cellClick", (e, cell) => {
  const row = cell.getRow();
  const rowData = row.getData();
  const activityUrl = rowData.x_url;
  window.open(activityUrl);
});

// add promise for tableBuilt event
promises.push(
  new Promise((resolve) => {
    table.on("tableBuilt", () => {
      console.log("tableBuilt");
      resolve();
    });
  })
);

// data_all -> data_rank
function ranking() {
  const type = html_sel_type.value;
  const measure = html_sel_measure.value;

  // filter data on
  // type
  // measure not null/missing
  // year
  data_rank = data_all.filter(
    (obj) =>
      obj.type === type &&
      obj[measure] !== null &&
      obj[measure] !== undefined &&
      obj[measure] != 0 &&
      obj["year"] >= html_yearMin.value &&
      obj["year"] <= html_yearMax.value
  );

  // sort by measure DESC
  data_rank = data_rank.sort((a, b) => b[measure] - a[measure]);

  // add rank column
  data_rank = data_rank.map((element, index) => {
    return {
      ...element,
      rank: index + 1,
    };
  });

  // send data to table
  table.setData(data_rank);

  // unhide all columns
  table.getColumns().forEach(function (column) {
    table.showColumn(column.getField());
  });
  if (type === "Swim") {
    table.hideColumn("total_elevation_gain");
    table.hideColumn("x_elev_m/km");
  }
}

//
// Event listeners
//
html_sel_type.addEventListener("change", () => {
  ranking();
});
html_sel_measure.addEventListener("change", () => {
  ranking();
});
html_yearMin.addEventListener("change", () => {
  html_yearMax.min = html_yearMin.value;
  ranking();
});
html_yearMax.addEventListener("change", () => {
  html_yearMin.max = html_yearMax.value;
  ranking();
});

// Wait for all async promises to be done (all data is fetched)
Promise.all(promises).then(function () {
  ranking();
});
