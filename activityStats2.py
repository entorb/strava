#!/usr/bin/env python3.10

"""
Stats for Strava App V2.
"""

# import datetime as dt
import json
import sys
from pathlib import Path

import numpy as np
import pandas as pd

# requirements
# pip3.10 install numpy pandas

if len(sys.argv) == 2:
    session = sys.argv[1]
else:
    session = "SessionIdPlaceholder"

# Path(__file__).parents[0] = location of current Python script
pathStatsExport = Path(__file__).parents[0] / "download" / session
if not pathStatsExport.is_dir():
    # raise FileNotFoundError(f"session {session} invalid")
    sys.stderr.write(f"session {session} invalid")
    sys.exit(1)

pathToActivityListJsonDump = pathStatsExport / "activityList.json"
if not pathToActivityListJsonDump.is_file():
    # raise FileNotFoundError(f"file activityList.json missing")
    sys.stderr.write("file activityList.json missing")
    sys.exit(1)

p = pathStatsExport / "activityStats2_year.json"
if p.is_file():
    # nothing to do
    exit()


def read_activityListJson(pathToActivityListJsonDump: Path) -> pd.DataFrame:
    """
    Read "activityList.json" file.

    parse date columns
    return DataFrame
    """
    # read json to DataFrame
    df_all = pd.read_json(pathToActivityListJsonDump)  # type: ignore

    # print(sorted(df.columns))
    # 'achievement_count', 'athlete', 'athlete_count', 'average_cadence', 'average_heartrate', 'average_speed', 'average_temp', 'average_watts', 'comment_count', 'commute', 'device_watts', 'display_hide_heartrate_option', 'distance', 'elapsed_time', 'elev_high', 'elev_low', 'end_latlng', 'external_id', 'flagged', 'from_accepted_tag', 'gear_id', 'has_heartrate', 'has_kudoed', 'heartrate_opt_out', 'id', 'kilojoules', 'km/h', 'kudos_count', 'location_city', 'location_country', 'location_state', 'manual', 'map', 'max_heartrate', 'max_speed', 'moving_time', 'name', 'photo_count', 'pr_count', 'private', 'resource_state', 'sport_type', 'start_date', 'start_date_local', 'start_latlng', 'timezone', 'total_elevation_gain', 'total_photo_count', 'trainer', 'type', 'upload_id', 'upload_id_str', 'utc_offset', 'visibility', 'workout_type', 'x_date', 'x_dist_start_end_km', 'x_elev_%', 'x_elev_m/km', 'x_end_locality', 'x_gear_name', 'x_km', 'x_max_km/h', 'x_max_mph', 'x_mi', 'x_min', 'x_min/km', 'x_min/mi', 'x_mph', 'x_nearest_city_start', 'x_start_h', 'x_start_locality', 'x_url'  # noqa: E501 # cspell:disable-line

    # parse date columns
    date_cols = ["start_date", "start_date_local", "x_date"]
    for col in date_cols:
        df_all[col] = pd.to_datetime(df_all[col])  # type: ignore

    # filter out act < 10min
    df_all = df_all[df_all["x_min"] >= 10]

    return df_all


def gen_types_time_series(df_all: pd.DataFrame, pathStatsExport: Path) -> None:
    """
    Perform GROUP BY aggregation for time_freq (month, week, quarter, year) and activity_type.

    exports resulting df as JSONs to pathStatsExport
    """
    df = df_all[
        [
            "id",
            "type",
            "x_date",
            "x_min",
            "x_km",
            "total_elevation_gain",
            "x_elev_m/km",
            "km/h",
            "average_heartrate",
            "max_heartrate",
            "x_max_km/h",
        ]
    ]

    # replace 0 by nan (and later by JSON "none")
    df = df.replace(0, np.nan, inplace=False)  # type: ignore

    df = df.rename(
        columns={
            "x_date": "date",
            "x_min": "hours(sum)",
            "x_km": "kilometers(sum)",
            "total_elevation_gain": "elevation(sum)",
            "x_elev_m/km": "elevation_m/km(avg)",
            "km/h": "speed_km/h(avg)",
            "average_heartrate": "heartrate(avg)",
        },
    )  # not inplace here!
    df["hours(sum)"] = df["hours(sum)"] / 60
    df["hours(avg)"] = df["hours(sum)"]
    df["kilometers(avg)"] = df["kilometers(sum)"]
    df["elevation(avg)"] = df["elevation(sum)"]
    df["heartrate(max)"] = df["heartrate(avg)"]
    df["speed_km/h(max)"] = df["speed_km/h(avg)"]

    my_aggregations = {
        "id": "count",
        "hours(sum)": "sum",
        "hours(avg)": "mean",
        "kilometers(sum)": "sum",
        "kilometers(avg)": "mean",
        "elevation(sum)": "sum",
        "elevation(avg)": "mean",
        "elevation_m/km(avg)": "mean",
        "speed_km/h(avg)": "mean",
        "speed_km/h(max)": "max",
        "heartrate(avg)": "mean",
        "heartrate(max)": "max",
    }

    df_week = df.groupby(["type", pd.Grouper(key="date", freq="W")]).agg(
        my_aggregations
    )  # type: ignore
    df_week = df_week.rename(columns={"id": "count"})

    # group by month
    df_month = df.groupby(["type", pd.Grouper(key="date", freq="MS")]).agg(  # type: ignore # noqa: E501
        my_aggregations,
    )
    df_month = df_month.rename(columns={"id": "count"})

    # cols_na = (
    #     "km(sum)",
    #     "km(avg)",
    #     "elevation(sum)",
    #     "elevation(avg)",
    #     "elevation_m/km(avg)",
    #     "km/h(avg)",
    # )
    # for col in cols_na:
    #     df_month[col] = df_month[col].fillna(0)

    # group by quarter
    del my_aggregations["id"]
    my_aggregations["count"] = "sum"
    df_quarter = (
        df_month.reset_index()  # type: ignore
        .groupby(["type", pd.Grouper(key="date", freq="QS")])
        .agg(my_aggregations)  # type: ignore
    )

    # group by year
    df = df_quarter.reset_index()  # type: ignore
    df["date"] = df["date"].dt.year
    df_year = (
        df.reset_index()  # type: ignore
        .groupby(["type", "date"])
        .agg(my_aggregations)  # type: ignore
    )

    # TODO: round prior to fillna!
    for df in (df_month, df_quarter, df_year):
        for measure in my_aggregations.keys():
            if measure in ("count", "elevation(sum)"):
                df[measure] = df[measure].astype(np.int64)  # type: ignore
            else:
                df[measure] = df[measure].round(1)  # type: ignore

    # replace 0 by nan (and later by JSON "null")
    df_week = df_week.replace(0, np.nan, inplace=False)  # type: ignore
    df_month = df_month.replace(0, np.nan, inplace=False)  # type: ignore
    df_quarter = df_quarter.replace(0, np.nan, inplace=False)  # type: ignore
    df_year = df_year.replace(0, np.nan, inplace=False)  # type: ignore

    # fill na value by None for JSON "null" conversion at export
    # from https://stackoverflow.com/questions/46283312/how-to-proceed-with-none-value-in-pandas-fillna
    # The first fillna will replace all of (None, NAT, np.nan, etc) with Numpy's NaN, then replace Numpy's NaN with python's None. # noqa: E501
    df_week = df_week.fillna(np.nan).replace([np.nan], [None])  # type: ignore
    df_month = df_month.fillna(np.nan).replace([np.nan], [None])  # type: ignore
    df_quarter = df_quarter.fillna(np.nan).replace([np.nan], [None])  # type: ignore
    df_year = df_year.fillna(np.nan).replace([np.nan], [None])  # type: ignore

    # # add missing months per activity type
    # # generate index of the desired month-freq:
    # idx = pd.date_range(
    #     start=df["date"].min().replace(day=1),
    #     end=df["date"].max().replace(day=1),
    #     freq="MS",  # MS = Month Start
    # )

    # # add missing months per activity type
    # df_month = df_month.reindex(
    #     pd.MultiIndex.from_product(
    #         [df_month.index.get_level_values("type"), idx],
    #         names=["type", "date"],
    #     )
    # )
    # df_month = df_month.fillna(0).astype({"count": int})

    measures = list(my_aggregations.keys())

    types_time_series_json_export(df=df_week, freq="week", measures=measures)
    types_time_series_json_export(df=df_month, freq="month", measures=measures)
    types_time_series_json_export(df=df_quarter, freq="quarter", measures=measures)
    types_time_series_json_export(df=df_year, freq="year", measures=measures)


def types_time_series_json_export(
    df: pd.DataFrame,
    freq: str,
    measures: list[str],
) -> None:
    """
    Freq: month, week, quarter, year.
    """
    # Convert DataFrame to JSON with nested lists
    json_data = {}
    cols = ["date"]
    cols.extend(measures)

    for act_type, data in df.groupby(level="type"):  # type: ignore
        data = data.droplevel("type")
        data.reset_index(inplace=True)
        if freq == "week":
            data["date"] = data["date"].dt.strftime("%Y-W%W")
        elif freq == "month":
            data["date"] = data["date"].dt.strftime("%Y-%m")
        elif freq == "quarter":
            data["date"] = data["date"].dt.to_period("Q").dt.strftime("%Y-Q%q")
        elif freq == "year":
            data["date"] = data["date"].astype(int)  # year as int # type: ignore
        d = {}
        for col in cols:
            d[col] = data[col].values.tolist()  # type: ignore
        json_data[act_type] = d

    with Path(pathStatsExport / f"activityStats2_{freq}.json").open(
        "w",
        encoding="UTF-8",
    ) as fh:
        json.dump(
            json_data,
            fp=fh,
            ensure_ascii=False,
            sort_keys=False,
            # indent=2,
        )


if __name__ == "__main__":
    df_all = read_activityListJson(
        pathToActivityListJsonDump=pathToActivityListJsonDump,
    )
    gen_types_time_series(df_all=df_all, pathStatsExport=pathStatsExport)
