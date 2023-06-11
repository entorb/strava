/* eslint-disable camelcase */
/* eslint-disable require-jsdoc */
("use strict");


// eslint-disable-next-line no-unused-vars
function defineTable() {
    const table = new Tabulator("#table-activity-list", {
        height: "100%",
        // height: 800,
        layout: "fitDataStretch", // fit columns to width of table (optional)
        tooltipsHeader: true,
        //        selectable: false, // for row click
        initialSort: [
            { column: "x_date", dir: "desc" },],
        columns: [ // Define Table Columns
            { title: "Date", field: "x_date", sorter: "string", headerFilter: true },
            { title: "Type", field: "type", sorter: "string", headerFilter: true },
            { title: "Name", field: "name", sorter: "string", headerFilter: true, width: 120 },
            { title: "City", field: "x_nearest_city_start", sorter: "string", headerFilter: true, width: 120 },
            { title: "Known location start", field: "x_start_locality", sorter: "string", headerFilter: true },
            { title: "-end", field: "x_end_locality", sorter: "string", headerFilter: true },
            { title: "Gear", field: "x_gear_name", sorter: "string", headerFilter: true, width: 120 },
            {
                title: "Minutes", field: "x_min", sorter: "number", hozAlign: "right", sorterParams: {
                    alignEmptyValues: "bottom"
                }, headerFilter: true, headerFilterPlaceholder: "filter >=", headerFilterFunc: ">="
            },
            {
                title: "Kilometer", field: "x_km", sorter: "number", hozAlign: "right", sorterParams: {
                    alignEmptyValues: "bottom"
                }, headerFilter: true, headerFilterPlaceholder: "filter >=", headerFilterFunc: ">="
            },
            {
                title: "km/h", field: "km/h", sorter: "number", hozAlign: "right", sorterParams: {
                    alignEmptyValues: "bottom"
                }, headerFilter: true, headerFilterPlaceholder: "filter >=", headerFilterFunc: ">="
            },
            {
                title: "max km/h", field: "x_max_km/h", sorter: "number", hozAlign: "right", sorterParams: {
                    alignEmptyValues: "bottom"
                }, headerFilter: true, headerFilterPlaceholder: "filter >=", headerFilterFunc: ">="
            },
            {
                title: "elevation (m)", field: "total_elevation_gain", sorter: "number", hozAlign: "right", sorterParams: {
                    alignEmptyValues: "bottom"
                }, headerFilter: true, headerFilterPlaceholder: "filter >=", headerFilterFunc: ">="
            },
            {
                title: "elevation (m/km)", field: "x_elev_m/km", sorter: "number", hozAlign: "right", sorterParams: {
                    alignEmptyValues: "bottom"
                }, headerFilter: true, headerFilterPlaceholder: "filter >=", headerFilterFunc: ">="
            },
            {
                title: "HR avg", field: "average_heartrate", sorter: "number", hozAlign: "right", sorterParams: {
                    alignEmptyValues: "bottom"
                }, headerFilter: true, headerFilterPlaceholder: "filter >=", headerFilterFunc: ">="
            },
            {
                title: "HR max", field: "max_heartrate", sorter: "number", hozAlign: "right", sorterParams: {
                    alignEmptyValues: "bottom"
                }, headerFilter: true, headerFilterPlaceholder: "filter >=", headerFilterFunc: ">="
            },
            {
                title: "cadence", field: "average_cadence", sorter: "number", hozAlign: "right", sorterParams: {
                    alignEmptyValues: "bottom"
                }, headerFilter: true, headerFilterPlaceholder: "filter >=", headerFilterFunc: ">="
            },
            {
                title: "watts avg", field: "average_watts", sorter: "number", hozAlign: "right", sorterParams: {
                    alignEmptyValues: "bottom"
                }, headerFilter: true, headerFilterPlaceholder: "filter >=", headerFilterFunc: ">="
            },
            {
                title: "KJ", field: "kilojoules", sorter: "number", hozAlign: "right", sorterParams: {
                    alignEmptyValues: "bottom"
                }, headerFilter: true, headerFilterPlaceholder: "filter >=", headerFilterFunc: ">="
            },
            {
                title: "visible", field: "visibility", sorter: "number", hozAlign: "right", sorterParams: {
                    alignEmptyValues: "bottom"
                }, headerFilter: true, headerFilterPlaceholder: "filter >=", headerFilterFunc: ">="
            },
            {
                title: "athletes", field: "athlete_count", sorter: "number", hozAlign: "right", sorterParams: {
                    alignEmptyValues: "bottom"
                }, headerFilter: true, headerFilterPlaceholder: "filter >=", headerFilterFunc: ">="
            },
            {
                title: "W-Type", field: "workout_type", sorter: "number", hozAlign: "right", sorterParams: {
                    alignEmptyValues: "bottom"
                }, headerFilter: true, headerFilterPlaceholder: "filter >=", headerFilterFunc: ">="
            },
            {
                title: "kudos", field: "kudos_count", sorter: "number", hozAlign: "right", sorterParams: {
                    alignEmptyValues: "bottom"
                }, headerFilter: true, headerFilterPlaceholder: "filter >=", headerFilterFunc: ">="
            },
            {
                title: "comments", field: "comment_count", sorter: "number", hozAlign: "right", sorterParams: {
                    alignEmptyValues: "bottom"
                }, headerFilter: true, headerFilterPlaceholder: "filter >=", headerFilterFunc: ">="
            },
            {
                title: "achievements", field: "achievement_count", sorter: "number", hozAlign: "right", sorterParams: {
                    alignEmptyValues: "bottom"
                }, headerFilter: true, headerFilterPlaceholder: "filter >=", headerFilterFunc: ">="
            },
        ],
    });

    return table;
}

var table = defineTable();

table.on("tableBuilt", function () {
    table.setData("https://entorb.net/strava/./download/" + session + "/activityList.json")
});

table.on("cellClick", function (e, cell) {
    const row = cell.getRow();
    const rowData = row.getData();
    const activityUrl = rowData["x_url"];
    window.open(activityUrl);
});



