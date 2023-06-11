/* eslint-disable camelcase */
/* eslint-disable require-jsdoc */
("use strict");


// eslint-disable-next-line no-unused-vars
function defineTable() {
    const table = new Tabulator("#table-activity-list", {
        height: "100%",
        // height: 800,
        layout: "fitDataStretch", // fit columns to width of table (optional)
        // autoColumns: true, // very nice!!!
        tooltipsHeader: true,
        selectable: false,
        initialSort: [
            { column: "x_date", dir: "desc" },],
        columns: [ // Define Table Columns
            { title: "Date", field: "x_date", sorter: "string", headerFilter: true },
            { title: "Type", field: "type", sorter: "string", headerFilter: true },
            { title: "Name", field: "name", sorter: "string", headerFilter: true },
            { title: "City", field: "x_nearest_city_start", sorter: "string", headerFilter: true },
            { title: "Known location start", field: "x_start_locality", sorter: "string", headerFilter: true },
            { title: "-end", field: "x_end_locality", sorter: "string", headerFilter: true },
            { title: "Gear", field: "x_gear_name", sorter: "string", headerFilter: true },
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
                title: "elev-gain (m)", field: "total_elevation_gain", sorter: "number", hozAlign: "right", sorterParams: {
                    alignEmptyValues: "bottom"
                }, headerFilter: true, headerFilterPlaceholder: "filter >=", headerFilterFunc: ">="
            },
            {
                title: "elev-gain (%)", field: "x_elev_%", sorter: "number", hozAlign: "right", sorterParams: {
                    alignEmptyValues: "bottom"
                }, headerFilter: true, headerFilterPlaceholder: "filter >=", headerFilterFunc: ">="
            },

            {
                title: "average_heartrate", field: "average_heartrate", sorter: "number", hozAlign: "right", sorterParams: {
                    alignEmptyValues: "bottom"
                }, headerFilter: true, headerFilterPlaceholder: "filter >=", headerFilterFunc: ">="
            },
            {
                title: "max_heartrate", field: "max_heartrate", sorter: "number", hozAlign: "right", sorterParams: {
                    alignEmptyValues: "bottom"
                }, headerFilter: true, headerFilterPlaceholder: "filter >=", headerFilterFunc: ">="
            },
            {
                title: "average_cadence", field: "average_cadence", sorter: "number", hozAlign: "right", sorterParams: {
                    alignEmptyValues: "bottom"
                }, headerFilter: true, headerFilterPlaceholder: "filter >=", headerFilterFunc: ">="
            },
            {
                title: "average_watts", field: "average_watts", sorter: "number", hozAlign: "right", sorterParams: {
                    alignEmptyValues: "bottom"
                }, headerFilter: true, headerFilterPlaceholder: "filter >=", headerFilterFunc: ">="
            },
            {
                title: "kilojoules", field: "kilojoules", sorter: "number", hozAlign: "right", sorterParams: {
                    alignEmptyValues: "bottom"
                }, headerFilter: true, headerFilterPlaceholder: "filter >=", headerFilterFunc: ">="
            },
            {
                title: "visibility", field: "visibility", sorter: "number", hozAlign: "right", sorterParams: {
                    alignEmptyValues: "bottom"
                }, headerFilter: true, headerFilterPlaceholder: "filter >=", headerFilterFunc: ">="
            },
            {
                title: "athletes", field: "athlete_count", sorter: "number", hozAlign: "right", sorterParams: {
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
        rowClick: function (_e, row) {
            const rowData = row.getData();
            const activityUrl = rowData["x_url"];
            window.open(activityUrl);
        },
    });

    // table.setSort([
    //     { column: "start_date_local", dir: "asc" },
    // ]);

    return table;
}
