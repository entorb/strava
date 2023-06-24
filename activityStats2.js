/* eslint-disable camelcase */
/* eslint-disable require-jsdoc */
"use strict";

//
// DOM elements
//
const html_div_chart = document.getElementById("div-chart");
const html_div_chart_cnt = document.getElementById("div-chart-act-count");
const html_sel_date_agg = document.getElementById("sel-date-agg");
const html_sel_type = document.getElementById("sel-type");
const html_sel_measure = document.getElementById("sel-measure");

//
// Global variables
//
// eslint-disable-next-line prefer-const
const data_all = [];
const data_all_comparison = {};
const promises = []; // array of promises for async fetching

//
// Data fetching
//
const fetch_data = async (session, date_agg) => {
  const url = `https://entorb.net/strava/download/${session}/activityStats2_${date_agg}.json`;
  try {
    const response = await fetch(url);
    const data = await response.json();
    console.log(`done data download ${date_agg}`);
    data_all[date_agg] = data;
  } catch (error) {
    console.log(`failed data download ${date_agg}`);
  }
};

// Start the async fetching
promises.push(fetch_data(session, "month"));
promises.push(fetch_data(session, "quarter"));
promises.push(fetch_data(session, "year"));

//
// Chart functions
//
function chart_create(html_div_chart) {
  const chart = echarts.init(html_div_chart);
  // https://echarts.apache.org/en/option.html#color
  // const chart_colors = ['#5470c6', '#91cc75', '#fac858', '#ee6666', '#73c0de', '#3ba272', '#fc8452', '#9a60b4', '#ea7ccc'];
  chart.setOption({
    // title: { text: 'Items per Minute' },
    tooltip: {},
    legend: { show: false },
    grid: {
      top: "12%",
      left: "1%",
      right: "10%",
      containLabel: true,
    },
    xAxis: { type: "time" }, // will be overwritten later by category
    yAxis: { type: "value" },
    dataZoom: [
      {
        type: "slider",
        show: true,
        start: 50,
        end: 100,
        handleSize: 8,
      },
    ],
  });
  return chart;
}

const chart = chart_create(html_div_chart);
const chart_cnt = chart_create(html_div_chart_cnt);

function chart_update(data_all) {
  const date_agg = html_sel_date_agg.value;
  const type = html_sel_type.value;
  const measure = html_sel_measure.value;

  const data_echarts_x = [...data_all[date_agg][type]["date"]];
  const data_echarts_y = [...data_all[date_agg][type][measure]];

  // filter out null values
  const data_echarts_y_non_null = data_echarts_y.filter(
    (value) => value !== null
  );
  const y_min = Math.min(...data_echarts_y_non_null);
  const y_max = Math.max(...data_echarts_y_non_null);
  const y_delta = y_max > y_min ? y_max - y_min : 1;

  if (date_agg === "month") {
    addMissingMonthsInPlace(data_echarts_x, data_echarts_y);
  } else if (date_agg === "year") {
    addMissingYearsInPlace(data_echarts_x, data_echarts_y);
  } else if (date_agg === "quarter") {
    addMissingQuartersInPlace(data_echarts_x, data_echarts_y);
  }
  // console.log(data_echarts_x[0]);
  // console.log(data_echarts_y[0]);
  const title = capitalize_words(
    "Strava Stats: " + type + " " + date_agg + " " + measure
  );

  chart.setOption({
    xAxis: { type: "category", data: data_echarts_x },
    yAxis: {
      min:
        y_min - 0.1 * y_delta > 0
          ? Math.floor(y_min - 0.1 * y_delta)
          : Math.floor(y_min),
    },
    series: [
      {
        type: "bar",
        name: measure,
        data: data_echarts_y,
        barWidth: "100%",
        // smooth: true,
        // symbolSize: 10,
        // silent: true,
        // animation: false,
        markLine: {
          show: true,
          animation: false,
          data: [
            {
              name: "average",
              type: "average",
            },
          ],
        },
      },
    ],
    title: {
      text: title,
      left: "center",
      // subtext: "by Torben https://entorb.net/strava/",
      // sublink: "https://entorb.net/strava/",
    },
  });
}

function chart_cnt_update(data_all_comparison) {
  const date_agg = html_sel_date_agg.value;
  let measure = html_sel_measure.value;

  const act_types = Object.keys(data_all[date_agg]);
  const series = [];
  for (const type of act_types) {
    if (!(measure in data_all_comparison[date_agg][type])) {
      measure = "count";
    }
    series.push({
      type: "bar",
      stack: "x",
      data: data_all_comparison[date_agg][type][measure],
      name: type,
    });
  }
  chart_cnt.setOption({
    xAxis: {
      type: "category",
      data: data_all_comparison[date_agg]["date"],
    },
    yAxis: {},
    series: series,
    title: {
      text: "Strava Stats: All Activity " + capitalize_words(measure),
      left: "center",
    },
    legend: {
      show: true,
      orient: "vertical",
      right: 10,
      top: "center",
    },
  });
}

function calc_data_for_act_comparison(data_all_comparison) {
  const starts_and_ends = {};
  for (const date_agg of ["month", "quarter", "year"]) {
    // extract min start and max end date
    const act_types = Object.keys(data_all[date_agg]);
    starts_and_ends[date_agg] = [];
    data_all_comparison[date_agg] = {};
    for (const type of act_types) {
      const myArray = data_all[date_agg][type]["date"];
      const start = myArray[0];
      const end = myArray[myArray.length - 1];
      // console.log(type);
      // add if not in
      if (!starts_and_ends[date_agg].includes(start)) {
        starts_and_ends[date_agg].unshift(start);
      }
      if (!starts_and_ends[date_agg].includes(end)) {
        starts_and_ends[date_agg].push(end);
      }
    }
    starts_and_ends[date_agg].sort();
    const start = starts_and_ends[date_agg][0];
    const end = starts_and_ends[date_agg][starts_and_ends[date_agg].length - 1];
    // delete starts_and_ends;

    // now add first an last to data
    for (const type of act_types) {
      data_all_comparison[date_agg][type] = {};
      const data_x = [...data_all[date_agg][type]["date"]];
      const data_y = [...data_all[date_agg][type]["count"]];
      const data_y2 = [...data_all[date_agg][type]["hours(sum)"]];
      const data_y3 = [...data_all[date_agg][type]["kilometers(sum)"]];
      if (data_x[0] != start) {
        data_x.unshift(start);
        data_y.unshift(null);
        data_y2.unshift(null);
        data_y3.unshift(null);
      }
      if (data_x[data_x.length - 1] != end) {
        data_x.push(end);
        data_y.push(null);
        data_y2.push(null);
        data_y3.push(null);
      }

      if (date_agg === "month") {
        addMissingMonthsInPlace(data_x, data_y, data_y2, data_y3);
      } else if (date_agg === "year") {
        addMissingYearsInPlace(data_x, data_y, data_y2, data_y3);
      } else if (date_agg === "quarter") {
        addMissingQuartersInPlace(data_x, data_y, data_y2, data_y3);
      }

      // store data to global array
      if (!("date" in data_all_comparison[date_agg])) {
        data_all_comparison[date_agg]["date"] = data_x;
      }
      data_all_comparison[date_agg][type]["count"] = data_y;
      data_all_comparison[date_agg][type]["hours(sum)"] = data_y2;
      data_all_comparison[date_agg][type]["kilometers(sum)"] = data_y3;
    }
  }
}


//
// Small helpers
//
// Formats value "Something_Is_HERE" to "Something Is Here"
function capitalize_words(str, separator) {
  const allLowerCaseValue = str.split(separator).join(" ").toLowerCase();
  return allLowerCaseValue.replace(/\w\S*/g, function (txt) {
    return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();
  });
}

//
// addMissing<Months/Quarters/Years
//
function addMissingYearsInPlace(
  data_echarts_x,
  data_echarts_y,
  data_echarts_y2 = [],
  data_echarts_y3 = [],
  data_echarts_y4 = []
) {
  const minYear = data_echarts_x[0];
  const maxYear = data_echarts_x[data_echarts_x.length - 1];

  let currentYear = minYear;
  let currentIndex = 0;

  while (currentYear <= maxYear) {
    const year = currentYear;
    const dateString = year;

    if (data_echarts_x[currentIndex] !== dateString) {
      data_echarts_x.splice(currentIndex, 0, dateString);

      // data_echarts_y.splice(currentIndex, 0, null);
      [data_echarts_y, data_echarts_y2, data_echarts_y3, data_echarts_y4]
        .filter(data => data.length > 0) // only work on the ones not empty
        .forEach(data => data.splice(currentIndex, 0, null)); // insert data

    }

    currentIndex++;
    currentYear++;
  }
}

function addMissingMonthsInPlace(
  data_echarts_x,
  data_echarts_y,
  data_echarts_y2 = [],
  data_echarts_y3 = [],
  data_echarts_y4 = []
) {
  const minMonth = data_echarts_x[0];
  const maxMonth = data_echarts_x[data_echarts_x.length - 1];

  const currentMonth = new Date(minMonth);
  let currentIndex = 0;

  while (currentMonth <= new Date(maxMonth)) {
    const year = currentMonth.getFullYear();
    const month = currentMonth.getMonth() + 1; // Adding 1 because getMonth() returns zero-based month index
    const dateString = `${year}-${month.toString().padStart(2, "0")}`;
    // 2023-01

    if (data_echarts_x[currentIndex] !== dateString) {
      data_echarts_x.splice(currentIndex, 0, dateString);
      // data_echarts_y.splice(currentIndex, 0, null);
      [data_echarts_y, data_echarts_y2, data_echarts_y3, data_echarts_y4]
        .filter(data => data.length > 0) // only work on the ones not empty
        .forEach(data => data.splice(currentIndex, 0, null)); // insert data
    }

    currentIndex++;
    currentMonth.setMonth(currentMonth.getMonth() + 1);
  }
}

function addMissingQuartersInPlace(
  data_echarts_x,
  data_echarts_y,
  data_echarts_y2 = [],
  data_echarts_y3 = [],
  data_echarts_y4 = []
) {
  const minQuarter = data_echarts_x[0];
  const maxQuarter = data_echarts_x[data_echarts_x.length - 1];

  let currentQuarter = minQuarter;
  let currentIndex = 0;

  while (currentQuarter <= maxQuarter) {
    if (data_echarts_x[currentIndex] !== currentQuarter) {
      data_echarts_x.splice(currentIndex, 0, currentQuarter);
      // data_echarts_y.splice(currentIndex, 0, null);
      [data_echarts_y, data_echarts_y2, data_echarts_y3, data_echarts_y4]
        .filter(data => data.length > 0) // only work on the ones not empty
        .forEach(data => data.splice(currentIndex, 0, null)); // insert data
    }
    currentIndex++;
    currentQuarter = getNextQuarter(currentQuarter);
  }
}

function getNextQuarter(quarter) {
  const [year, q] = quarter.split("-Q");
  const nextQuarter = (parseInt(q) % 4) + 1;
  const nextYear = nextQuarter === 1 ? parseInt(year) + 1 : year;
  return `${nextYear}-Q${nextQuarter}`;
}

//
// GUI helpers
//
function populate_select_type() {
  const select = html_sel_type;
  // remove all
  const L = select.options.length - 1;
  for (let i = L; i >= 0; i--) {
    select.remove(i);
  }
  // populate from array
  let i_of_Run = 0;
  const options = Object.keys(data_all["year"]);
  for (let i = 0; i < options.length; i++) {
    const opt = options[i];
    const el = document.createElement("option");
    el.textContent = opt;
    el.value = opt;
    select.appendChild(el);
    if (opt === "Run") {
      i_of_Run = i;
    }
  }
  select.selectedIndex = i_of_Run;
}

//
// GUI actions
//
// eslint-disable-next-line no-unused-vars
function charts_update() {
  chart_update(data_all);
  chart_cnt_update(data_all_comparison);
}

//
// Event listeners
//
html_sel_date_agg.addEventListener("change", () => {
  charts_update();
});

html_sel_type.addEventListener("change", () => {
  charts_update();
});

html_sel_measure.addEventListener("change", () => {
  charts_update();
});

//
// Initialize the chart after all data is fetched
//
// Wait for all async promises to be done (all data is fetched)
Promise.all(promises).then(function () {
  console.log("All data fetched");
  populate_select_type();
  // console.log(data_echarts);
  calc_data_for_act_comparison(data_all_comparison);
  chart_update(data_all);
  chart_cnt_update(data_all_comparison);
});
