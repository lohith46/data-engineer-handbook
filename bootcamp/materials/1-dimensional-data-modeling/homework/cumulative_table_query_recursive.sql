WITH RECURSIVE
    ordered_years AS (SELECT year, ROW_NUMBER() OVER (ORDER BY year) AS rn
                      FROM (SELECT DISTINCT year FROM actor_films) y),

    actor_films_by_year AS (SELECT af.actorid,
                                   af.actor,
                                   af.year,
                                   ARRAY_AGG(ROW (af.film, af.votes, af.rating, af.filmid)::film_stats) AS film_stats,
                                   AVG(af.rating)                                                       AS avg_rating
                            FROM actor_films af
                            GROUP BY af.actorid, af.actor, af.year),

    recursive_actors AS (
        -- Base case: first year
        SELECT f.actorid,
               f.actor,
               f.film_stats,
               f.avg_rating,
               CASE
                   WHEN f.avg_rating > 8 THEN 'star'
                   WHEN f.avg_rating > 7 THEN 'good'
                   WHEN f.avg_rating > 6 THEN 'average'
                   ELSE 'bad'
                   END::quality_class AS quality_class,
               TRUE                   AS is_active,
               f.year                 AS current_year,
               1::BIGINT              AS rn
        FROM actor_films_by_year f
        WHERE f.year = (SELECT MIN(year) FROM ordered_years)

        UNION ALL

        -- Recursive step: process next year
        SELECT COALESCE(n.actorid, p.actorid)                 AS actorid,
               COALESCE(n.actor, p.actor)                     AS actor,
               COALESCE(p.film_stats, ARRAY []::film_stats[]) ||
               COALESCE(n.film_stats, ARRAY []::film_stats[]) AS film_stats,
               COALESCE(n.avg_rating, 0)                      AS avg_rating,
               CASE
                   WHEN n.avg_rating > 8 THEN 'star'
                   WHEN n.avg_rating > 7 THEN 'good'
                   WHEN n.avg_rating > 6 THEN 'average'
                   ELSE 'bad'
                   END::quality_class                         AS quality_class,
               (n.actorid IS NOT NULL)                        AS is_active,
               oy.year                                        AS current_year,
               oy.rn                                          AS rn
        FROM recursive_actors p
                 JOIN ordered_years oy ON oy.rn = p.rn + 1
                 LEFT JOIN actor_films_by_year n
                           ON n.year = oy.year AND n.actorid = p.actorid)

INSERT
INTO actors (actorid, actor, film_stats, quality_class, is_active, current_year)
SELECT actorid,
       actor,
       film_stats,
       quality_class,
       is_active,
       current_year
FROM recursive_actors;
