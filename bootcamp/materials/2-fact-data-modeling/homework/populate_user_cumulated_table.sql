-- Method 1: Using Variables
DO $$
DECLARE
    current_date_param DATE;
previous_date_param DATE;
BEGIN
    -- Loop through dates from Jan 1 to Jan 31, 2023
    FOR current_date_param IN
    SELECT generate_series('2023-01-01'::date, '2023-01-31'::date, '1 day'::interval)::date
    LOOP
        previous_date_param := current_date_param - INTERVAL '1 day';

        INSERT INTO users_cumulated
        WITH YESTERDAY as (
            SELECT *
            FROM users_cumulated
            WHERE date = previous_date_param
        ),
             TODAY as (
                 SELECT
                     CAST(user_id as TEXT) as user_id,
                     DATE(CAST(event_time as timestamp)) as dates_active
                 FROM events
                 WHERE DATE(CAST(event_time as timestamp)) = current_date_param
                   AND user_id IS NOT NULL
                 GROUP BY user_id, DATE(CAST(event_time as timestamp))
             )
        SELECT
            COALESCE(t.user_id, y.user_id) as user_id,
            CASE
                WHEN y.dates_active IS NULL THEN ARRAY[t.dates_active]
                WHEN t.dates_active IS NULL THEN y.dates_active
                ELSE ARRAY[t.dates_active] || y.dates_active
                END as dates_active,
            current_date_param as date
        FROM TODAY t
                 FULL OUTER JOIN YESTERDAY y ON t.user_id = y.user_id;

    END LOOP;
END $$;

-- Method 2: Parameterized Single Query (for stored procedures/functions)
-- CREATE OR REPLACE FUNCTION update_users_cumulated(
--     p_current_date DATE,
--     p_previous_date DATE DEFAULT NULL
-- ) RETURNS VOID AS $$
-- BEGIN
--     -- Default previous date to current_date - 1 if not provided
--     IF p_previous_date IS NULL THEN
--         p_previous_date := p_current_date - INTERVAL '1 day';
--     END IF;
--
--     INSERT INTO users_cumulated
--     WITH YESTERDAY as (
--         SELECT *
--         FROM users_cumulated
--         WHERE date = p_previous_date
--     ),
--          TODAY as (
--              SELECT
--                  CAST(user_id as TEXT) as user_id,
--                  DATE(CAST(event_time as timestamp)) as dates_active
--              FROM events
--              WHERE DATE(CAST(event_time as timestamp)) = p_current_date
--                AND user_id IS NOT NULL
--              GROUP BY user_id, DATE(CAST(event_time as timestamp))
--          )
--     SELECT
--         COALESCE(t.user_id, y.user_id) as user_id,
--         CASE
--             WHEN y.dates_active IS NULL THEN ARRAY[t.dates_active]
--             WHEN t.dates_active IS NULL THEN y.dates_active
--             ELSE ARRAY[t.dates_active] || y.dates_active
--             END as dates_active,
--         p_current_date as date
--     FROM TODAY t
--              FULL OUTER JOIN YESTERDAY y ON t.user_id = y.user_id;
-- END;
-- $$ LANGUAGE plpgsql;

-- Usage: Call the function for each date
-- SELECT update_users_cumulated('2023-01-02');
-- SELECT update_users_cumulated('2023-01-03');
-- ... etc

-- Method 3: Application-level parameterization template
-- Use this template in your application code and replace {PREVIOUS_DATE} and {CURRENT_DATE}
/*
INSERT INTO users_cumulated
WITH YESTERDAY as (
    SELECT *
    FROM users_cumulated
    WHERE date = '{PREVIOUS_DATE}'
),
TODAY as (
    SELECT
        CAST(user_id as TEXT) as user_id,
        DATE(CAST(event_time as timestamp)) as dates_active
    FROM events
    WHERE DATE(CAST(event_time as timestamp)) = '{CURRENT_DATE}'
    AND user_id IS NOT NULL
    GROUP BY user_id, DATE(CAST(event_time as timestamp))
)
SELECT
    COALESCE(t.user_id, y.user_id) as user_id,
    CASE
        WHEN y.dates_active IS NULL THEN ARRAY[t.dates_active]
        WHEN t.dates_active IS NULL THEN y.dates_active
        ELSE ARRAY[t.dates_active] || y.dates_active
    END as dates_active,
    '{CURRENT_DATE}' as date
FROM TODAY t
FULL OUTER JOIN YESTERDAY y ON t.user_id = y.user_id;
*/
