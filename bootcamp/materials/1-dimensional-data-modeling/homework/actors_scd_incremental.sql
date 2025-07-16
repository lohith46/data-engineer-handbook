drop
    type
    scd_type cascade;
CREATE
    TYPE scd_type AS
(
    quality_class quality_class,
    is_active     BOOLEAN,
    start_year    INTEGER,
    end_year      INTEGER
);

WITH last_year_scd AS (SELECT *
                       FROM actors_history_scd
                       WHERE current_year = 2020
                         AND end_year = 2020),

     historical_scd AS (SELECT actor,
                               actorid,
                               quality_class,
                               is_active,
                               start_year,
                               end_year
                        FROM actors_history_scd
                        WHERE current_year = 2020
                          AND end_year < 2020),
     this_year_data AS (SELECT *
                        FROM actors
                        WHERE current_year = 2021),
     unchanged_records AS (SELECT ty.actor,
                                  ty.actorid,
                                  ty.quality_class,
                                  ty.is_active,
                                  ly.start_year,
                                  ty.current_year as end_year
                           FROM this_year_data ty
                                    JOIN last_year_scd ly
                                         ON ly.actorid = ty.actorid
                           WHERE ty.quality_class = ly.quality_class
                             AND ty.is_active = ly.is_active),
     changed_records AS (SELECT ty.actor,
                                ty.actorid,
                                UNNEST(ARRAY [
                                    ROW (
                                        ly.quality_class,
                                        ly.is_active,
                                        ly.start_year,
                                        ly.end_year
                                        )::scd_type,
                                    ROW (
                                        ty.quality_class,
                                        ty.is_active,
                                        ty.current_year,
                                        ty.current_year
                                        ) ::scd_type ]) as records
                         FROM this_year_data ty
                                  LEFT JOIN last_year_scd ly
                                            ON ly.actorid = ty.actorid
                         WHERE (ty.quality_class <> ly.quality_class
                             OR ty.is_active <> ly.is_active)),
     unnested_changed_records AS (SELECT actor,
                                         actorid,
                                         (records::scd_type).quality_class,
                                         (records::scd_type).is_active,
                                         (records::scd_type).start_year,
                                         (records::scd_type).end_year
                                  FROM changed_records),
     new_records AS (SELECT ty.actor,
                            ty.actorid,
                            ty.quality_class,
                            ty.is_active,
                            ty.current_year as start_year,
                            ty.current_year as end_year
                     FROM this_year_data ty
                              LEFT JOIN last_year_scd ly
                                        ON ly.actorid = ty.actorid
                     WHERE ly.actorid IS NULL)
SELECT actor, actorid, quality_class, is_active, start_year, end_year, 2025 as current_year
FROM historical_scd
UNION ALL
SELECT actor, actorid, quality_class, is_active, start_year, end_year, 2025 as current_year
FROM unchanged_records
UNION ALL
SELECT actor, actorid, quality_class, is_active, start_year, end_year, 2025 as current_year
FROM unnested_changed_records
UNION ALL
SELECT actor, actorid, quality_class, is_active, start_year, end_year, 2025 as current_year
FROM new_records;
