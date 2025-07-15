INSERT INTO actors_history_scd
WITH previous_streak as (
    SELECT
        actorid,
        actor,
        current_year,
        quality_class,
        is_active,
        lag(quality_class, 1) over (partition by actorid order by current_year) as previous_quality_class,
        lag(is_active, 1) over (partition by actorid order by current_year)     as previous_is_active
    FROM actors
   -- where current_year <= 2021
),

with_indicator as (
    SELECT *,
           CASE
               WHEN quality_class <> previous_quality_class THEN 1
               WHEN is_active <> previous_is_active THEN 1
               ELSE 0
               END as change_indicator
    FROM previous_streak
),

with_streaks as (
     SELECT *,
            SUM(change_indicator) over (partition by actorid order by current_year) as streak_identifier
     FROM with_indicator
             )

SELECT
    actorid,
    actor,
    quality_class,
    is_active,
    MIN(current_year) as start_year,
    MAX(current_year) as end_year,
    MAX(current_year) as current_year
FROM with_streaks
GROUP BY actorid, actor, quality_class, is_active, streak_identifier
