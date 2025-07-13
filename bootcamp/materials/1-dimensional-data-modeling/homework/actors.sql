CREATE TYPE film_stats AS (
                         votes INTEGER,
                         rating REAL,
                         filmid TEXT
                       );
 CREATE TYPE quality_class AS
     ENUM ('bad', 'average', 'good', 'star');

CREATE TABLE actors (
                         actorid TEXT,
                         actor TEXT,
                         film TEXT,
                         film_stats film_stats[],
                         quality_class quality_class,
                         is_active BOOLEAN,
                         current_year INTEGER,
                         PRIMARY KEY (actorid, film, current_year)
);

