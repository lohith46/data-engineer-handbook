--drop table array_metrics
-- CREATE TABLE array_metrics (
--     user_id numeric,
--     month_start DATE,
--     metric_name TEXT,
--     metric_array REAL[],
--     primary key (user_id, month_start, metric_name)
-- )
--delete from array_metrics where user_id is not null;
-- Create daily aggregated
INSERT INTO array_metrics
with daily_aggregate as (
    select
        user_id,
        DATE(event_time) as date,
        count(1) as num_site_hits
    FROM events
    where DATE(event_time) = DATE('2023-01-04') and user_id is not null
    group by user_id, DATE(event_time)
),
    yesterdays_array as (
        select * from array_metrics
                 where month_start = DATE('2023-01-01')
    )

select
    COALESCE(da.user_id, ya.user_id) as user_id,
    COALESCE(ya.month_start, date_trunc( 'month' ,da.date)) as month_start,
    'site_hits' as metric_name,
    CASE WHEN ya.metric_array is not null then
        ya.metric_array || array[COALESCE(da.num_site_hits, 0)]
        WHEN ya.metric_array is null then
        array_fill (0, ARRAY[COALESCE(date - DATE(date_trunc( 'month' , date)), 0)]) || array[COALESCE(da.num_site_hits, 0)]
    END as metric_array

    from daily_aggregate da
    full outer join  yesterdays_array ya on da.user_id = ya.user_id
    on conflict  (user_id, month_start, metric_name)
    DO
        update set metric_array = excluded.metric_array;


select cardinality(metric_array), count(1) from array_metrics
group by 1;


with agg as (
    select metric_name, month_start, ARRAY[sum(metric_array[1]),
        sum(metric_array[2]),
        sum(metric_array[3]),
        sum(metric_array[4])] as summed_array from array_metrics
    group by metric_name, month_start
)

select metric_name,
       month_start + CAST(CAST(index -1 as TEXT) || 'day' AS interval),
       elem as value

    from agg
    CROSS JOIN unnest(agg.summed_array)
    with ordinality AS a(elem, index)



