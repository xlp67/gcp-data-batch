{{ config(
    materialized='table',
    partition_by={
      "field": "summary_date",
      "data_type": "date",
      "granularity": "day"
    },
    cluster_by=["device_id"]
) }}
with silver_data as (
    select * from {{ ref('int_telemetry_pii_hashed') }}
),
daily_aggregation as (
    select
        DATE(timestamp) as summary_date,
        device_id,
        AVG(temperature) as avg_temperature,
        MAX(temperature) as max_temperature,
        MIN(temperature) as min_temperature,
        AVG(humidity) as avg_humidity,
        COUNT(distinct hashed_operator_name) as distinct_operators_count,
        COUNT(*) as total_readings
    from silver_data
    group by 1, 2
)
select * from daily_aggregation