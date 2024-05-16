-- Query 4 populate the table with the history of actors with Slowly Changing Dimension (SCD) Type 2 attributes
INSERT INTO danfanderson48529.actors_history_scd
WITH
    -- cte_strt_year houses the requested processsing year
    cte_strt_year as (
        select 2005 as proc_year
    ),
    -- cte_lagged represents the actors current_year and the previous year's quality_class and is_active values
    cte_lagged AS (
        SELECT
            actor,
            actor_id,
            quality_class,
            -- display last year's quality_class
            LAG(quality_class, 1) OVER (PARTITION BY actor_id ORDER BY current_year) AS quality_class_last_year,
            -- express the is_active boolean value as an integer (0, 1)
            CASE
                WHEN is_active THEN 1
                ELSE 0
            END AS is_active,
            -- express last year's is_active boolean value as an integer (0, 1)
            CASE
                WHEN LAG(is_active, 1) OVER (PARTITION BY actor_id ORDER BY current_year) THEN 1
                ELSE 0
            END AS is_active_last_year,
            current_year
        FROM
            danfanderson48529.actors
        WHERE
            current_year <= (SELECT proc_year FROM cte_strt_year)
    ),
    -- cte_streaked identifies the start and end of a quality_class or is_active streak
    cte_streaked AS (
        SELECT
            ct.*,
            -- identify a change in quality_class or is_active
            SUM(CASE WHEN (ct.is_active <> ct.is_active_last_year) 
                       OR (ct.quality_class <> ct.quality_class_last_year) THEN 1
                     ELSE 0
                END
            ) OVER (PARTITION BY ct.actor_id ORDER BY ct.current_year) AS streak_identifier
        FROM
            cte_lagged ct
    )
-- construct the SCD Type 2 records for each actor that
-- tracks each actor's state of quality_class and is_active values over time
SELECT
    cts.actor,
    cts.actor_id,
    MIN(cts.quality_class) AS quality_class,
    MAX(cts.is_active) = 1 AS is_active,
    -- persist the min current_year value as the start of SCD Type 2 record
    MIN(cts.current_year) AS start_date,
    -- persist the max current_year value as the end of SCD Type 2 record
    MAX(cts.current_year) AS end_date
FROM
    cte_streaked cts
GROUP BY
    cts.actor,
    cts.actor_id,
    cts.streak_identifier

--
