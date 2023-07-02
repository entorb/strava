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
// let yearMin = 1900;
// let yearMax = new Date().getFullYear();;

const promises = []; // array of promises for async fetching

const measures = {
  "x_min": "Duration",
  "x_km": "Distance",
  "km/h": "Speed",
  "total_elevation_gain": "Elevation",
  "x_elev_m/km": "Elevation Gain per Distance",
  "x_dist_start_end_km": "Distance Start-End",
  "average_heartrate": "Average Heartrate",
  "kilojoules": "Kilo Joule",
};

// add options to html_sel_measure
for (const key in measures) {
  const option = document.createElement('option');
  option.value = key;
  option.text = measures[key];
  html_sel_measure.appendChild(option);
};

const table_columns = [

  {
    title: "#", field: "rank",
    sorter: "number",
    headerFilter: false,
    headerSortStartingDir: "",
    // headerFilterPlaceholder: "filter >=",
    // headerFilterFunc: "<=",
  },
  { title: "Date", field: "x_date", sorter: "string", headerFilter: false },
  {
    title: "Name",
    field: "name",
    sorter: "string",
    headerFilter: true,
    width: 300,
    widthGrow: 3,
  },
  // {
  //   title: "Known location start",
  //   field: "x_start_locality",
  //   sorter: "string",
  //   headerFilter: true,
  // },
];

for (const key in measures) {
  table_columns.push({
    title: measures[key],
    field: key,
    sorter: "number",
    headerFilter: "number",
    hozAlign: "right",
    // sorterParams: {
    //   alignEmptyValues: "bottom",
    // },
    // headerFilterPlaceholder: "filter >=",
    headerFilterFunc: ">=",
    formatter: function (cell, formatterParams, onRendered) {
      if (cell.getValue()) { return Math.round(cell.getValue() * 10) / 10; }
    },

  },);
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
    data.forEach(obj => {
      Object.entries(obj).forEach(([key]) => {
        if (!measures.hasOwnProperty(key)
          && key !== 'type'
          && key !== 'name'
          && key !== 'x_date'
          // && key !== 'x_start_locality'
          && key !== 'x_url' // for click on the row -> open at strava
        ) {
          delete obj[key];
        }
      });
      // extract year from x_date and add as property
      obj.year = parseInt(obj.x_date.substr(0, 4));
    });

    data_all = data;

    // extract activity types
    const act_types = [...new Set(data_all.map(obj => obj.type))].sort();

    // remove all
    while (html_sel_type.firstChild) {
      html_sel_type.removeChild(html_sel_type.firstChild);
    }
    // add options
    act_types.forEach(type => {
      const option = document.createElement('option');
      option.value = type;
      option.text = type;
      if (type === 'Run') {
        option.selected = true;
      }
      html_sel_type.appendChild(option);
    });


    const yearMin = Math.min(...data_all.map(obj => obj.year));
    const yearMax = Math.max(...data_all.map(obj => obj.year));
    html_yearMin.value = yearMin;
    html_yearMin.min = yearMin;
    html_yearMin.max = yearMax;
    html_yearMax.value = yearMax;
    html_yearMax.min = yearMin;
    html_yearMax.max = yearMax;
  } catch (error) {
    console.log("failed download activityList.json");
  }
};

// Start the async fetching
promises.push(fetch_data(session));



// eslint-disable-next-line no-unused-vars
function defineTable() {
  const table = new Tabulator("#table-activity-list", {
    // height: "100%",
    maxHeight: "100%", //do not let table get bigger than the height of its parent element
    // height: 800,
    layout: "fitDataStretch", // fit columns to width of table (optional)
    tooltipsHeader: false,
    selectable: false,
    columns: table_columns,
  });

  return table;
}

const table = defineTable();

// add promise for tableBuilt event
promises.push(new Promise((resolve) => {
  table.on("tableBuilt", () => {
    console.log("tableBuilt")
    resolve();
  });
}));

table.on("cellClick", (e, cell) => {
  const row = cell.getRow();
  const rowData = row.getData();
  const activityUrl = rowData.x_url;
  window.open(activityUrl);
});

function ranking() {
  const type = html_sel_type.value;
  const measure = html_sel_measure.value;

  // filter data on type and measure not null/missing
  data_rank = data_all.filter(obj => obj.type === type
    && obj[measure] !== null && obj[measure] !== undefined
    && obj[measure] != 0
    && obj["year"] >= html_yearMin.value
    && obj["year"] <= html_yearMax.value
  );

  // sort by measure DESC
  data_rank = data_rank.sort((a, b) => b[measure] - a[measure]);

  // add rank column
  data_rank = data_rank.map((element, index) => {
    return {
      ...element,
      rank: index + 1
    };
  });

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
