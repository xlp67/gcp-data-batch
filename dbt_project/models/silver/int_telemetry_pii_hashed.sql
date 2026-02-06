with source_data as (
    select * from {{ source('gcs_raw_zone', 'external_telemetry_data') }}
),
hashed_pii as (
    select
        device_id,
        timestamp,
        temperature,
        humidity,
        status_code,
        TO_HEX(SHA256(CONCAT(operator_name, '{{ var("pii_hashing_salt") }}'))) as hashed_operator_name,
        TO_HEX(SHA256(CONCAT(operator_email, '{{ var("pii_hashing_salt") }}'))) as hashed_operator_email,
        current_timestamp() as _silver_loaded_at
    from source_data
    where
        device_id is not null
        and timestamp is not null
)
select * from hashed_pii