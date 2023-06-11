/* eslint-disable camelcase */
/* eslint-disable require-jsdoc */
("use strict");

// global variables
const html_div_chart = document.getElementById("div_chart");
const html_sel_date_agg = document.getElementById("sel_date_agg");
const html_sel_type = document.getElementById("sel_type");
const html_sel_measure = document.getElementById("sel_measure");

// eslint-disable-next-line prefer-const
let data_all = [];

// TODO:
const session = "123";

// array of promises for async fetching
const promises = [];

//
// Data fetching
//
function fetch_data(session, date_agg) {
  const url = "https://entorb.net/strava/download/" + session + "/activityStats2_" + date_agg + ".json";
  return $.getJSON(url, function (data) {
  })
    .done(function (data) {
      console.log("done data download " + date_agg);
      data_all[date_agg] = data;
    })
    .fail(function () {
      console.log("failed data download " + date_agg);
    });
}

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
    // grid: {
    //   // define margins
    //   containLabel: false,
    //   left: 50,
    //   bottom: 20,
    //   top: 30,
    //   right: 150,
    // },
    grid: {
      top: '12%',
      left: '1%',
      right: '10%',
      containLabel: true
    }, xAxis: { type: "time", }, // will be overwritten later by category
    yAxis: { type: "value", },
    dataZoom: [
      {
        type: 'slider',
        show: true,
        start: 50,
        end: 100,
        handleSize: 8
      },],
  });
  return chart;
}

const chart = chart_create(html_div_chart);


function chart_update(data_all) {
  const date_agg = html_sel_date_agg.value;
  const type = html_sel_type.value;
  const measure = html_sel_measure.value;

  const data_echarts_x = [...data_all[date_agg][type]["date"]];
  const data_echarts_y = [...data_all[date_agg][type][measure]];

  // filter out null values
  const data_echarts_y_non_null = data_echarts_y.filter(value => value !== null);
  const y_min = Math.min(...data_echarts_y_non_null);
  const y_max = Math.max(...data_echarts_y_non_null);
  const y_delta = (y_max > y_min) ? y_max - y_min : 1;

  if (date_agg === "month") {
    addMissingMonthsInPlace(data_echarts_x, data_echarts_y);
  } else if (date_agg === "year") {
    addMissingYearsInPlace(data_echarts_x, data_echarts_y);
  } else if (date_agg === "quarter") {
    addMissingQuartersInPlace(data_echarts_x, data_echarts_y);
  }
  // console.log(data_echarts_x[0]);
  // console.log(data_echarts_y[0]);
  const title = capitalize_words("Strava Stats: " + type + " " + date_agg + " " + measure);

  chart.setOption({
    xAxis: { type: "category", data: data_echarts_x, },
    yAxis: { min: ((y_min - 0.1 * y_delta) > 0) ? Math.floor(y_min - 0.1 * y_delta) : Math.floor(y_min) },
    series: [
      {
        type: "bar",
        name: measure,
        data: data_echarts_y,
        barWidth: '100%',
        // smooth: true,
        // symbolSize: 10,
        // silent: true,
        // animation: false,
        markLine: {
          show: true,
          animation: false,
          data: [{
            name: 'average',
            type: 'average'
          }],
        }
      },
    ],
    title: {
      text: title,
      left: 'center',
      // subtext: "by Torben https://entorb.net/strava/",
      // sublink: "https://entorb.net/strava/",
    },
  });
}


// Wait for all async promises to be done (all data is fetched)
Promise.all(promises).then(function () {
  console.log("All data fetched");
  chart_update(data_all);
  populate_select_type();
  // console.log(data_echarts);
});



//
// Small helpers
//
// Formats value "Something_Is_HERE" to "Something Is Here"
function capitalize_words(str, separator) {
  const allLowerCaseValue = str.split(separator).join(" ").toLowerCase();
  return allLowerCaseValue.replace(/\w\S*/g, function (txt) { return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase(); });
}

//
// addMissing<Months/Quarters/Years
//
function addMissingYearsInPlace(data_echarts_x, data_echarts_y) {
  const minYear = data_echarts_x[0];
  const maxYear = data_echarts_x[data_echarts_x.length - 1];

  let currentYear = minYear;
  let currentIndex = 0;

  while (currentYear <= maxYear) {
    const year = currentYear;
    const dateString = year;

    if (data_echarts_x[currentIndex] !== dateString) {
      data_echarts_x.splice(currentIndex, 0, dateString);
      data_echarts_y.splice(currentIndex, 0, null);
    }

    currentIndex++;
    currentYear++;
  }
}

function addMissingMonthsInPlace(data_echarts_x, data_echarts_y) {
  const minMonth = data_echarts_x[0];
  const maxMonth = data_echarts_x[data_echarts_x.length - 1];

  const currentMonth = new Date(minMonth);
  let currentIndex = 0;

  while (currentMonth <= new Date(maxMonth)) {
    const year = currentMonth.getFullYear();
    const month = currentMonth.getMonth() + 1; // Adding 1 because getMonth() returns zero-based month index
    const dateString = `${year}-${month.toString().padStart(2, '0')}`;
    // 2023-01

    if (data_echarts_x[currentIndex] !== dateString) {
      data_echarts_x.splice(currentIndex, 0, dateString);
      data_echarts_y.splice(currentIndex, 0, null);
    }

    currentIndex++;
    currentMonth.setMonth(currentMonth.getMonth() + 1);
  }
}

function addMissingQuartersInPlace(data_echarts_x, data_echarts_y) {
  const minQuarter = data_echarts_x[0];
  const maxQuarter = data_echarts_x[data_echarts_x.length - 1];

  let currentQuarter = minQuarter;
  let currentIndex = 0;

  while (currentQuarter <= maxQuarter) {
    if (data_echarts_x[currentIndex] !== currentQuarter) {
      data_echarts_x.splice(currentIndex, 0, currentQuarter);
      data_echarts_y.splice(currentIndex, 0, null);
    }
    else {
      // console.log(currentQuarter);
    }
    currentIndex++;
    currentQuarter = getNextQuarter(currentQuarter);
  }
}

function getNextQuarter(quarter) {
  const [year, q] = quarter.split('-Q');
  const nextQuarter = parseInt(q) % 4 + 1;
  const nextYear = nextQuarter === 1 ? parseInt(year) + 1 : year;
  return `${nextYear}-Q${nextQuarter}`;
}

//
// GUI helpers
//
function populate_select_type() {
  const select = html_sel_type;
  // remove all
  L = select.options.length - 1;
  for (i = L; i >= 0; i--) {
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
    if (opt === "Run") { i_of_Run = i }
  }
  select.selectedIndex = i_of_Run;
}


//
// GUI actions
//
// eslint-disable-next-line no-unused-vars
function action_chart_update() {
  chart_update(data_all);
}
