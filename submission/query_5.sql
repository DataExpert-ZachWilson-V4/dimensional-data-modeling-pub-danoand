-- Query 5 incrementally populate the table with the history of actors with Slowly Changing Dimension (SCD) Type 2 attributes 
INSERT INTO danfanderson48529.actors_history_scd
WITH
    -- cte_strt_year houses the requested processsing year
    cte_strt_year as (
        select 2005 as prev_scd_year
    ),
    -- cte_last_year_scd represents previous year's SCD Type 2 records
    cte_last_year_scd AS (
        SELECT
            *
        FROM
            danfanderson48529.actors_history_scd
        WHERE
            end_date = (SELECT prev_scd_year FROM cte_strt_year)
    ),
    -- cte_current_year_actors represents the scd next year's actor details
    cte_current_year_actors AS (
        SELECT
            *
        FROM
            danfanderson48529.actors
        WHERE
            current_year = (SELECT prev_scd_year FROM cte_strt_year) + 1
    ),
    -- cte_combined represents the union of the previous year's SCD Type 2 records and current year's actor details
    cte_combined AS (
        SELECT
            COALESCE(ctlst.actor, ctcur.actor) AS actor,
            COALESCE(ctlst.actor_id, ctcur.actor_id) AS actor_id,
            -- determine changes in the quality_class or is_active values
            CASE
                WHEN (ctlst.quality_class <> ctcur.quality_class) OR (ctlst.is_active <> ctcur.is_active) THEN 1
                ELSE 0 END AS did_change,
            -- combined start date is either the SCD start_date or the current actor's year
            COALESCE(ctlst.start_date, ctcur.current_year) AS start_date,
            -- combined end date is either the SCD end_date or the current actor's year
            COALESCE(ctlst.end_date, ctcur.current_year) AS end_date,
            -- persist the previous year's and current year's quality_class and is_active values
            ctlst.quality_class AS quality_class_last_year,
            ctcur.quality_class AS quality_class_this_year,
            ctlst.is_active AS is_active_last_season,
            ctcur.is_active AS is_active_this_season,
            (SELECT prev_scd_year FROM cte_strt_year) + 1 AS current_year
        FROM
            cte_last_year_scd ctlst
            FULL OUTER JOIN cte_current_year_actors ctcur ON ctlst.actor = ctcur.actor
            AND ctcur.current_year = ctlst.end_date + 1
    ),
    -- cte_changes represents the changes in quality_class and is_active values for each actor between the previous year and the current year
    cte_changes AS (
        SELECT
            actor,
            actor_id,
            -- generate an array of ROWs that represent the changes in quality_class and is_active values
            CASE
                -- scenario: no change to the quality_class or is_active values
                WHEN did_change = 0 THEN ARRAY[ROW(quality_class_last_year, is_active_last_season, start_date, end_date + 1)]
                -- scenario: at least one change to the quality_class or is_active values
                WHEN did_change = 1 THEN ARRAY[ROW(quality_class_last_year, is_active_last_season, start_date, end_date),
                                               ROW(quality_class_this_year, is_active_this_season, current_year, current_year)]
                -- scenario: the actor is new to the SCD table or not present in the current year's actor details
                WHEN did_change IS NULL THEN ARRAY[ROW(
                                                        COALESCE(quality_class_last_year, quality_class_this_year),
                                                        COALESCE(is_active_last_season, is_active_this_season),
                                                        COALESCE(start_date, current_year),
                                                        COALESCE(end_date, current_year)
                                                    )]
            END AS change_array
        FROM
            cte_combined
    )
-- construct the SCD Type 2 records for each actor and transform the array of changes into individual rows
SELECT
    ctc.actor,
    ctc.actor_id,
    t.*
FROM
    cte_changes ctc
    CROSS JOIN UNNEST (ctc.change_array) AS t(quality_class, is_active, start_date, end_date) 

--
