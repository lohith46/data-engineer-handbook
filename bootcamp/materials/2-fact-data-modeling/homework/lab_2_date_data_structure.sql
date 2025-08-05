-- DROP table users_cumulated;
-- CREATE table users_cumulated (
--     user_id TEXT,
--     dates_active DATE[],
--     date DATE,
--      PRIMARY KEY (user_id, date)
-- )
--
-- INSERT INTO users_cumulated
-- WITH YESTERDAY as (
--     select
--         *
--     from users_cumulated
--     where date =  DATE('2023-01-04')
-- ),
--      today as (
--          select
--              CAST(user_id as TEXT) as user_id,
--              DATE( CAST(event_time as timestamp)) as dates_active
--          from events
--          where date (CAST(event_time as timestamp)) = DATE('2023-01-05')
--          and user_id is not null
--          group by user_id, DATE( CAST(event_time as timestamp))
--      )
--
-- select
--     coalesce(t.user_id, y.user_id) as user_id,
--     CASE WHEN y.dates_active is null
--         THEN Array[t.dates_active]
--         when t.dates_active is null then y.dates_active
--         ELSE Array[t.dates_active] || y.dates_active
--             END
--         as dates_active,
--     coalesce(t.dates_active, y.date + Interval '1 day') as date
--     from today t
--     full outer join yesterday y
--         on t.user_id = y.user_id;
--
--
-- select * from users_cumulated
-- where date = DATE('2023-01-01');

-- Turn into Date Array

with users as (
    select * from users_cumulated
             where date = DATE('2023-01-31')
),
    series as (
        SELECT generate_series('2023-01-01'::date, '2023-01-31'::date, '1 day'::interval)::date as series_date
    ),

place_holder_ints AS (
SELECT
    CASE WHEN
        dates_active @> ARRAY [DATE(series_date)]
    THEN CAST(POW(2, 32 - (date - DATE(series_date))) as BIGINT)
    ELSE 0
    END as placeholder_int_value,
    *
from users CROSS JOIN series
--where user_id = '137925124111668560'
)

-- Daily active
-- select
--     user_id,
--     sum(placeholder_int_value),
--     CAST(CAST(sum(placeholder_int_value) as BIGINT) as bit(32))
--     from place_holder_ints
-- group by user_id


-- Monthly active

-- select
--     user_id,
--     CAST(CAST(sum(placeholder_int_value) as BIGINT) as bit(32)),
--     bit_count(CAST(CAST(sum(placeholder_int_value) as BIGINT) as bit(32))) > 0 as dim_is_monthly_active
-- from place_holder_ints
-- group by user_id

 --weekly active
select
    user_id,
    CAST(CAST(sum(placeholder_int_value) as BIGINT) as bit(32)),
    bit_count(CAST(CAST(sum(placeholder_int_value) as BIGINT) as bit(32))) > 0 as dim_is_monthly_active,
    bit_count(CAST('11111110000000000000000000000000' AS BIT(32)) &
    CAST(CAST(sum(placeholder_int_value) as BIGINT) as bit(32))) > 0 as dim_is_weekly_active,
    bit_count(CAST('10000000000000000000000000000000' AS BIT(32)) &
              CAST(CAST(sum(placeholder_int_value) as BIGINT) as bit(32))) > 0 as dim_is_daily_active
from place_holder_ints
group by user_id
