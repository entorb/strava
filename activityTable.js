/* eslint-disable camelcase */
/* eslint-disable require-jsdoc */
"use strict";

// eslint-disable-next-line no-unused-vars
function defineTable() {
  const table = new Tabulator("#table-activity-list", {
    // height: "100%",
    maxHeight: "100%", //do not let table get bigger than the height of its parent element
    // height: 800,
    layout: "fitDataStretch", // fit columns to width of table (optional)
    tooltipsHeader: true,
    //        selectable: false, // for row click
    initialSort: [{ column: "x_date", dir: "desc" }],
    columns: [
      // Define Table Columns
      { title: "Date", field: "x_date", sorter: "string", headerFilter: true },
      { title: "Type", field: "type", sorter: "string", headerFilter: true },
      {
        title: "Name",
        field: "name",
        sorter: "string",
        headerFilter: true,
        width: 120,
      },
      {
        title: "City",
        field: "x_nearest_city_start",
        sorter: "string",
        headerFilter: true,
        width: 120,
      },
      {
        title: "Known location start",
        field: "x_start_locality",
        sorter: "string",
        headerFilter: true,
      },
      {
        title: "-end",
        field: "x_end_locality",
        sorter: "string",
        headerFilter: true,
      },
      {
        title: "Gear",
        field: "x_gear_name",
        sorter: "string",
        headerFilter: true,
        width: 120,
      },
      {
        title: "Minutes",
        field: "x_min",
        sorter: "number",
        headerFilter: "number",
        hozAlign: "right",
        sorterParams: {
          alignEmptyValues: "bottom",
        },
        headerFilterPlaceholder: "filter >=",
        headerFilterFunc: ">=",
      },
      {
        title: "Kilometers",
        field: "x_km",
        sorter: "number",
        headerFilter: "number",
        hozAlign: "right",
        sorterParams: {
          alignEmptyValues: "bottom",
        },
        headerFilterPlaceholder: "filter >=",
        headerFilterFunc: ">=",
      },
      {
        title: "km/h",
        field: "km/h",
        sorter: "number",
        headerFilter: "number",
        hozAlign: "right",
        sorterParams: {
          alignEmptyValues: "bottom",
        },
        headerFilterPlaceholder: "filter >=",
        headerFilterFunc: ">=",
      },
      {
        title: "max km/h",
        field: "x_max_km/h",
        sorter: "number",
        headerFilter: "number",
        hozAlign: "right",
        sorterParams: {
          alignEmptyValues: "bottom",
        },
        headerFilterPlaceholder: "filter >=",
        headerFilterFunc: ">=",
      },
      {
        title: "Elevation (m)",
        field: "total_elevation_gain",
        sorter: "number",
        headerFilter: "number",
        hozAlign: "right",
        sorterParams: {
          alignEmptyValues: "bottom",
        },
        headerFilterPlaceholder: "filter >=",
        headerFilterFunc: ">=",
      },
      {
        title: "Elevation (m/km)",
        field: "x_elev_m/km",
        sorter: "number",
        headerFilter: "number",
        hozAlign: "right",
        sorterParams: {
          alignEmptyValues: "bottom",
        },
        headerFilterPlaceholder: "filter >=",
        headerFilterFunc: ">=",
      },
      {
        title: "HR avg",
        field: "average_heartrate",
        sorter: "number",
        headerFilter: "number",
        hozAlign: "right",
        sorterParams: {
          alignEmptyValues: "bottom",
        },
        headerFilterPlaceholder: "filter >=",
        headerFilterFunc: ">=",
      },
      {
        title: "HR max",
        field: "max_heartrate",
        sorter: "number",
        headerFilter: "number",
        hozAlign: "right",
        sorterParams: {
          alignEmptyValues: "bottom",
        },
        headerFilterPlaceholder: "filter >=",
        headerFilterFunc: ">=",
      },
      {
        title: "Cadence",
        field: "average_cadence",
        sorter: "number",
        headerFilter: "number",
        hozAlign: "right",
        sorterParams: {
          alignEmptyValues: "bottom",
        },
        headerFilterPlaceholder: "filter >=",
        headerFilterFunc: ">=",
      },
      {
        title: "Watts avg",
        field: "average_watts",
        sorter: "number",
        headerFilter: "number",
        hozAlign: "right",
        sorterParams: {
          alignEmptyValues: "bottom",
        },
        headerFilterPlaceholder: "filter >=",
        headerFilterFunc: ">=",
      },
      {
        title: "KJ",
        field: "kilojoules",
        sorter: "number",
        headerFilter: "number",
        hozAlign: "right",
        sorterParams: {
          alignEmptyValues: "bottom",
        },
        headerFilterPlaceholder: "filter >=",
        headerFilterFunc: ">=",
      },
      {
        title: "Visible",
        field: "visibility",
        sorter: "number",
        headerFilter: "number",
        hozAlign: "right",
        sorterParams: {
          alignEmptyValues: "bottom",
        },
        headerFilterPlaceholder: "filter >=",
        headerFilterFunc: ">=",
      },
      {
        title: "Athletes",
        field: "athlete_count",
        sorter: "number",
        headerFilter: "number",
        hozAlign: "right",
        sorterParams: {
          alignEmptyValues: "bottom",
        },
        headerFilterPlaceholder: "filter >=",
        headerFilterFunc: ">=",
      },
      {
        title: "W-Type",
        field: "workout_type",
        sorter: "number",
        headerFilter: "number",
        hozAlign: "right",
        sorterParams: {
          alignEmptyValues: "bottom",
        },
        headerFilterPlaceholder: "filter >=",
        headerFilterFunc: ">=",
      },
      {
        title: "Kudos",
        field: "kudos_count",
        sorter: "number",
        headerFilter: "number",
        hozAlign: "right",
        sorterParams: {
          alignEmptyValues: "bottom",
        },
        headerFilterPlaceholder: "filter >=",
        headerFilterFunc: ">=",
      },
      {
        title: "Comments",
        field: "comment_count",
        sorter: "number",
        headerFilter: "number",
        hozAlign: "right",
        sorterParams: {
          alignEmptyValues: "bottom",
        },
        headerFilterPlaceholder: "filter >=",
        headerFilterFunc: ">=",
      },
      {
        title: "Achievements",
        field: "achievement_count",
        sorter: "number",
        headerFilter: "number",
        hozAlign: "right",
        sorterParams: {
          alignEmptyValues: "bottom",
        },
        headerFilterPlaceholder: "filter >=",
        headerFilterFunc: ">=",
      },
    ],
  });

  return table;
}

const table = defineTable();

// wait for tableBuilt event and set data afterwards
table.on("tableBuilt", () => {
  table.setData(
    `https://entorb.net/strava/download/${session}/activityList.json`
  );
});

table.on("cellClick", (e, cell) => {
  const row = cell.getRow();
  const rowData = row.getData();
  const activityUrl = rowData.x_url;
  window.open(activityUrl);
});
