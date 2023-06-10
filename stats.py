import pandas as pd
import datetime as dt
from pathlib import Path
import json

# TODO: pass as parameter
session = "123"

# set paths and mkdir stats-py
pathToActivityListJsonDump = Path("./download") / session / "activityList.json"
pathStatsExport = Path("./download") / session / "stats-py"
pathStatsExport.mkdir(parents=False, exist_ok=True)


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

    return df_all


def gen_types_time_series(df_all: pd.DataFrame, pathStatsExport: Path) -> None:
    """
    Perform GROUP BY aggregation for time_freq (month, quarter, year) and activity_type.
    exports resulting df as JSONs to pathStatsExport
    """
    df = df_all[
        [
            "id",
            "type",
            "x_date",
            "x_min",
        ]
    ]
    df = df.rename(columns={"x_date": "date", "x_min": "minutes"})  # not inplace here!

    # group by month
    df_month = df.groupby(["type", pd.Grouper(key="date", freq="MS")]).agg(  # type: ignore # noqa: E501
        {"id": "count", "minutes": "sum"}
    )
    df_month = df_month.rename(columns={"id": "count"})

    # group by quarter
    df_quarter = (
        df_month.reset_index()  # type: ignore
        .groupby(["type", pd.Grouper(key="date", freq="QS")])
        .agg({"count": "sum", "minutes": "sum"})
    )

    # group by year
    df = df_quarter.reset_index()  # type: ignore
    df["date"] = df["date"].dt.year
    df_year = (
        df.reset_index()  # type: ignore
        .groupby(["type", "date"])
        .agg({"count": "sum", "minutes": "sum"})
    )

    # min -> hour
    for df in (df_month, df_quarter, df_year):
        df["hours"] = (df["minutes"] / 60).round(1)  # type: ignore
        df.drop(
            columns=["minutes"],
            inplace=True,
        )

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

    for df in (df_month, df_quarter, df_year):
        types_time_series_json_export(df=df_month, freq="month")
        types_time_series_json_export(df=df_quarter, freq="quarter")
        types_time_series_json_export(df=df_year, freq="year")


def types_time_series_json_export(df: pd.DataFrame, freq: str) -> None:
    """
    freq: month, quarter, year
    """
    # Convert DataFrame to JSON with nested lists
    json_data = {}

    for act_type, data in df.groupby(level="type"):  # type: ignore
        data = data.droplevel("type")
        data.reset_index(inplace=True)
        data["hours"] = data["hours"].round(1)  # fix float issues # type: ignore
        if freq in ("month", "quarter"):
            data["date"] = data["date"].astype(str)  # date as string # type: ignore
        elif freq == "year":
            data["date"] = data["date"].astype(int)  # year as int # type: ignore
        # using zip instead of data.values.tolist(), since df.values converts all elements to same format # noqa: E501
        json_data[act_type] = tuple(  # type: ignore
            zip(
                data["date"].values.tolist(),  # str|int # type: ignore
                data["count"].values.tolist(),  # int # type: ignore
                data["hours"].values.tolist(),  # float # type: ignore
            )
        )

    with Path(pathStatsExport / f"ts_types_{freq}.json").open(
        "w", encoding="UTF-8"
    ) as fh:
        json.dump(
            json_data,
            fp=fh,
            ensure_ascii=False,
            sort_keys=True,
            # indent=2,
        )
    return


# old
# df_month.reset_index(inplace=True)
# # Set names of index levels and convert index to string
# df_month["date"] = df_month["date"].astype(str)
# print(df_month)

# # # Convert 'date' column to string format
# # df_month["date"] = df_month.index.get_level_values("date").strftime("%Y-%m-%d")
# # print(df_month)

# #    df_month.to_json(pathStatsExport / "ts_types_month.json", orient="split")

# # Convert DataFrame to nested lists
# json_data = df_month.reset_index().values.tolist()
# # print(json_data)

# json_str = json.dumps(json_data)
# print(json_str)
# exit()

# df["date_month"] = df["x_date"].apply(get_first_day_of_the_month)  # type: ignore
# df["date_month"] = pd.to_datetime(df["date_month"])  # type: ignore
# df_month = df.groupby(  # type: ignore
#     [pd.Grouper(key="type"), pd.Grouper(key="date_month", freq="1M")]
# ).agg({"id": "count", "x_min": "sum"})
# # df_month = df.groupby(["type", "date_month"]).agg(  # type: ignore
# #     {"id": "count", "x_min": "sum"}
# # )
# df_month = df_month.rename(columns={"id": "count", "x_min": "minutes"})

# print(df_month)

# # exit()
# # group by quarter
# df = df_month.reset_index()
# df["date_quarter"] = df["date_month"].apply(get_first_day_of_the_quarter)  # type: ignore  # noqa: E501
# df["date_quarter"] = pd.to_datetime(df["date_quarter"])  # type: ignore
# df_quarter = df.groupby(["type", "date_quarter"]).agg(  # type: ignore
#     {"count": "sum", "minutes": "sum"}
# )

# # group by year
# df = df_quarter.reset_index()
# df["date_year"] = df["date_quarter"].apply(get_first_day_of_the_year)  # type: ignore  # noqa: E501
# df["date_year"] = pd.to_datetime(df["date_year"])  # type: ignore
# df_year = df.groupby(["type", "date_year"]).agg(  # type: ignore
#     {"count": "sum", "minutes": "sum"}
# )

# # min -> hour
# for df in (df_month, df_quarter, df_year):
#     df["hours"] = (df["minutes"] / 60).round(1)  # type: ignore
#     df.drop(
#         columns=["minutes"],
#         inplace=True,
#     )

# df_month = df_month.asfreq("M", fill_value=0)
# # print results
# print(df_month)
# # print(df_quarter)
# # print(df_year)
# #
# df_month.reset_index().to_json(  # type: ignore
#     pathStatsExport / "ts_types_month.json",
#     indent=2,
#     orient="records",
#     date_format="iso",
# )


def get_first_day_of_the_month(date_value: dt.date) -> dt.date:
    return dt.date(date_value.year, date_value.month, 1)


def get_first_day_of_the_quarter(date_value: dt.date) -> dt.date:
    return dt.date(date_value.year, 3 * ((date_value.month - 1) // 3) + 1, 1)


def get_first_day_of_the_year(date_value: dt.date) -> dt.date:
    return dt.date(date_value.year, 1, 1)


if __name__ == "__main__":
    df_all = read_activityListJson(
        pathToActivityListJsonDump=pathToActivityListJsonDump
    )
    gen_types_time_series(df_all=df_all, pathStatsExport=pathStatsExport)
