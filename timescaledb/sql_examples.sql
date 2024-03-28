-- Table Creation --
create table
    if not exists public.air_quality (
        index bigint,
        city text,
        country text,
        datetime timestamp
        with
            time zone not null,
            location text,
            parameter text,
            value double precision,
            unit text
    );

SELECT
    create_hypertable (
        'air_quality',
        by_range ('datetime'),
        migrate_data = true
    );

-- Pandas Equivalent

SELECT
    date_part ('hour', air_quality.datetime) AS hourly,
    avg(air_quality.value)
FROM
    air_quality
GROUP BY
    hourly
ORDER BY
    hourly ASC;

SELECT
    datetime AS "time",
    location,
    value AS "value"
FROM
    air_quality
ORDER BY
    datetime ASC;

SELECT
    time_bucket ('1 day', datetime) AS "time",
    location,
    avg(value) AS "value"
FROM
    air_quality
GROUP BY
    time,
    location
ORDER BY
    time ASC;



-- Creating Materialized View --
-- CREATE  MATERIALIZED VIEW <view_name> [ ( column_name [, ...] ) ]
-- WITH    ( timescaledb.continuous [, timescaledb.<option> = <value> ] )
-- AS    <select_query>;

CREATE MATERIALIZED VIEW conditions_summary_daily
WITH (timescaledb.continuous) AS
SELECT device,
   time_bucket(INTERVAL '1 day', time) AS bucket,
   AVG(temperature),
   MAX(temperature),
   MIN(temperature)
FROM conditions
GROUP BY device, bucket;

SELECT add_continuous_aggregate_policy('conditions_summary_daily',
  start_offset => INTERVAL '1 month',
  end_offset => INTERVAL '1 day',
  schedule_interval => INTERVAL '1 hour');

ALTER MATERIALIZED VIEW table_name set (timescaledb.materialized_only = false);

-- Time Zones Example --
SELECT
    time_bucket ('1 month', ts, 'Europe/Warsaw') 
                AS month_bucket,
    avg(temperature)
        AS avg_temp
FROM
    weather;

    SELECT create_hypertable('conditions', by_range('time'));


-- State Aggregation --
SELECT
    state,
    duration
FROM
    into_values (
        (
            SELECT
                state_agg (time, state)
            FROM
                states_test
        )
    );

-- Query Result:
-- state | duration
-- ------+----------
-- ERROR | 00:00:03
-- OK    | 00:01:46
-- START | 00:00:11
