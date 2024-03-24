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
promises.push(fetch_data(session, "week"));
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
      containLabel: true
    },
    xAxis: { type: "category" },
    yAxis: { type: "value" },
    dataZoom: [
      {
        type: "slider",
        show: true,
        start: 0,
        end: 100
        // handleSize: 8,
      }
    ]
  });
  return chart;
}

const chart = chart_create(html_div_chart);
const chart_cnt = chart_create(html_div_chart_cnt);

function chart_update(data_all) {
  console.log("fnc chart_update()");
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

  fillGapsInDateDataInPlace(data_echarts_x, data_echarts_y);

  chart.setOption({
    xAxis: { data: data_echarts_x },
    yAxis: {
      min:
        y_min - 0.1 * y_delta > 0
          ? Math.floor(y_min - 0.1 * y_delta)
          : Math.floor(y_min)
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
              type: "average"
            }
          ]
        }
      }
    ],
    title: {
      text: `Strava Stats: ${type} ${date_agg} ${measure}`,
      left: "center"
    }
  });
}

function chart_cnt_update(data_all_comparison) {
  console.log("fnc chart_cnt_update()");
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
      name: type
    });
  }
  chart_cnt.setOption({
    xAxis: {
      data: data_all_comparison[date_agg]["date"]
    },
    yAxis: {},
    series: series,
    title: {
      text: "Strava Stats: All Activity " + capitalize_words(measure),
      left: "center"
    },
    legend: {
      show: true,
      orient: "vertical",
      right: 10,
      top: "center"
    }
  });
}

function charts_update() {
  console.log("fnc charts_update()");
  chart_update(data_all);
  chart_cnt_update(data_all_comparison);
}

function calc_data_for_act_comparison(data_all_comparison) {
  console.log("fnc calc_data_for_act_comparison()");
  for (const date_agg of ["week", "month", "quarter", "year"]) {
    data_all_comparison[date_agg] = {};

    // loop over act_types and extract min start and max end date
    let start = "";
    let end = "";
    const act_types = Object.keys(data_all[date_agg]);
    for (const type of act_types) {
      const myArray = data_all[date_agg][type]["date"];
      const currentStart = myArray[0];
      const currentEnd = myArray[myArray.length - 1];

      if (start === "" || currentStart < start) {
        start = currentStart;
      }
      if (end === "" || currentEnd > end) {
        end = currentEnd;
      }
    }

    // now add min start and max end to data for each act_type and fill the gaps
    for (const type of act_types) {
      data_all_comparison[date_agg][type] = {};
      const data_x = [...data_all[date_agg][type]["date"]];
      const data_y = [...data_all[date_agg][type]["count"]];
      const data_y2 = [...data_all[date_agg][type]["hours(sum)"]];
      const data_y3 = [...data_all[date_agg][type]["kilometers(sum)"]];

      // add start
      if (data_x[0] != start) {
        data_x.unshift(start);
        data_y.unshift(null);
        data_y2.unshift(null);
        data_y3.unshift(null);
      }

      // add end
      if (data_x[data_x.length - 1] != end) {
        data_x.push(end);
        data_y.push(null);
        data_y2.push(null);
        data_y3.push(null);
      }

      // fill gaps
      fillGapsInDateDataInPlace(data_x, data_y, data_y2, data_y3);

      // store data to global array
      if (!("date" in data_all_comparison[date_agg])) {
        data_all_comparison[date_agg]["date"] = data_x;
      }
      data_all_comparison[date_agg][type]["count"] = data_y;
      data_all_comparison[date_agg][type]["hours(sum)"] = data_y2;
      data_all_comparison[date_agg][type]["kilometers(sum)"] = data_y3;
    }
  }
  console.log(data_all_comparison);
}

//
// Small helpers
//
// Formats value "Something_Is_HERE" to "Something Is Here"
function capitalize_words(str, separator) {
  console.log("fnc capitalize_words()");
  const allLowerCaseValue = str.split(separator).join(" ").toLowerCase();
  return allLowerCaseValue.replace(/\w\S*/g, function (txt) {
    return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();
  });
}

// fill gaps in the data
// supports x data of years (integer), quarters ("2023-Q2"), weeks ("2023-W02"), month "2023-03"
function fillGapsInDateDataInPlace(
  data_echarts_x,
  data_echarts_y,
  data_echarts_y2 = [],
  data_echarts_y3 = [],
  data_echarts_y4 = []
) {
  console.log("fnc fillGapsInDateDataInPlace()");
  const minDate = data_echarts_x[0];

  const maxDate = data_echarts_x[data_echarts_x.length - 1];

  let currentDate = minDate;
  let currentIndex = 0;

  while (currentDate <= maxDate) {
    const isDateMissing = data_echarts_x[currentIndex] !== currentDate;

    if (isDateMissing) {
      data_echarts_x.splice(currentIndex, 0, currentDate); // start, deleteCount, item)
      // loop over all 4 (optional) y data sets
      [data_echarts_y, data_echarts_y2, data_echarts_y3, data_echarts_y4]
        .filter((data) => data.length > 0) // only work on the non-empty data sets
        .forEach((data) => data.splice(currentIndex, 0, null)); // insert data
    }

    currentIndex++;
    currentDate = getNextDate(currentDate);
    // if (currentIndex > 100) { return }// TODO
  }
}

// calculate the next date for my period
// supports x data of years (integer), quarters ("2023-Q2"), month "2023-03"
function getNextDate(date) {
  //  console.log(["fnc getNextDate()", date]);
  if (typeof date === "number") {
    // 2023
    return date + 1;
  } else if (date.includes("-Q")) {
    // "2023-Q2"
    const [year, quarter] = date.split("-Q").map(Number);
    const nextQuarter = (quarter % 4) + 1;
    const nextYear = nextQuarter === 1 ? year + 1 : year;
    return `${nextYear}-Q${nextQuarter}`;
  } else if (date.includes("-W")) {
    // "2023-W02"
    const [year, week] = date.split("-W").map(Number);
    const nextWeek = week === 53 ? 0 : week + 1;
    const nextYear = nextWeek === 0 ? year + 1 : year;
    return `${nextYear}-W${nextWeek.toString().padStart(2, "0")}`;
  } else if (date.includes("-")) {
    // "2023-02"
    const [year, month] = date.split("-").map(Number);
    const nextMonth = month === 12 ? 1 : month + 1;
    const nextYear = nextMonth === 1 ? year + 1 : year;
    return `${nextYear}-${nextMonth.toString().padStart(2, "0")}`; // 2 digit month
  }
}

//
// GUI helpers
//
function populate_select_type() {
  console.log("fnc populate_select_type()");
  const act_types = Object.keys(data_all["year"]);
  const act_types_map = helper_array_to_object_of_key_eq_value(act_types);
  helper_populate_select(html_sel_type, act_types_map, "Run", true);
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
  calc_data_for_act_comparison(data_all_comparison);
  charts_update();
});
