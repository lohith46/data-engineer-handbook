WITH last_year AS (
    SELECT * FROM actors
    WHERE current_year = 1970

), this_year AS (
    SELECT * FROM actor_films
    WHERE year = 1971
)
INSERT INTO actors
SELECT
    COALESCE(ly.actor, ty.actor) as actor,
    COALESCE(ly.actorid, ty.actorid) as actorid,
    COALESCE(ly.film, ty.film) as actorid,
    CASE WHEN ly.film_stats IS NULL
        THEN ARRAY[ROW(
            ty.votes,
            ty.rating,
            ty.filmid)::film_stats]
        WHEN ty.year IS NOT NULL then ly.film_stats || ARRAY[ROW(
            ty.votes,
            ty.rating,
            ty.filmid)::film_stats]
        ELSE ly.film_stats
    END as film_stats,
    CASE
        WHEN ty.film IS NOT NULL THEN
            (CASE WHEN ty.rating > 8 THEN 'star'
                  WHEN ty.rating > 7 and ty.rating <= 8 THEN 'good'
                  WHEN ty.rating > 6 and ty.rating <= 7 THEN 'average'
                  ELSE 'bad' END)::quality_class
        ELSE ly.quality_class
    END as quality_class,
    CASE
        WHEN ty.actorid IS NOT NULL THEN TRUE
        ELSE FALSE
    END as is_active,
    COALESCE(ty.year, ly.current_year + 1) as current_year

FROM this_year ty
         FULL OUTER JOIN last_year ly
                         ON ty.actor = ly.actor
