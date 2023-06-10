/* eslint-disable camelcase */
/* eslint-disable require-jsdoc */
("use strict");

// global variables
let my_data;
const html_div_chart = document.getElementById("div_chart");

// array of promises for async fetching
const promises = [];

// ref dictionary to be fetched: Country Code -> Country Name
var mapCountryNames = {};

// fetch countries-latest-all.json containing country reference data like code and continent
function fetch_data() {
  const url = "download/123/stats-py/ts_types_month.json";
  return $.getJSON(url, function (data) {
    console.log("success: data fetched");
  })
    .done(function (data) {
      console.log("done: data");
      console.log(data);
      //   $.each(data, function (key, val) {
      //     mapCountryNames[data[key].Code] = data[key].Country;
      //   });
    })
    .fail(function () {
      console.log("fail: data download");
    });
}

// Start the async fetching
promises.push(fetch_data());

// Wait for all async promises to be done (all data is fetched), then print message
Promise.all(promises).then(function () {
  console.log("All data fetched");
});
