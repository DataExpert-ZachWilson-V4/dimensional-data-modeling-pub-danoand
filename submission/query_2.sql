INSERT INTO danfanderson48529.actors (actor, actor_id, films, quality_class, is_active, current_year)

--
-- cte that holds config values (i.e., query year)
WITH cte_cfg AS (
    SELECT 2000 AS current_year
),
-- cte that reflects the universe of actors
cte_unique_actors AS (
    SELECT DISTINCT fl.actor as actor, fl.actor_id as actor_id
    FROM bootcamp.actor_films fl
),
-- cte that surfaces each actor's most recent year of activity 
cte_most_recent_year AS (
    SELECT
        fl.actor as actor,
        fl.actor_id as actor_id,
        -- indicator for whether the actor is active in the requested year
        CASE WHEN MAX(fl.year) = (SELECT current_year FROM cte_cfg) THEN true ELSE false END AS is_active,
        -- the actor's most recent year of activity
        MAX(fl.year) AS most_recent_year
    FROM
        bootcamp.actor_films fl
    WHERE fl.year <= (SELECT current_year FROM cte_cfg)
    GROUP BY fl.actor, fl.actor_id
),
-- cte that houses actor films for the most recent active year equal to or less than the requested year
cte_most_recent_year_films AS (
    SELECT
        fl.actor as actor,
        fl.actor_id as actor_id,
        fl.year as year,
        fl.rating as rating,
        fl.film as film,
        fl.votes as votes,
        fl.film_id as film_id,
        mr.most_recent_year as most_recent_year,
        mr.is_active as is_active
    FROM
        bootcamp.actor_films fl
    JOIN cte_most_recent_year mr ON fl.actor = mr.actor AND fl.actor_id = mr.actor_id AND fl.year = mr.most_recent_year
),
-- cte that aggregates actor films for the most recent active year 
cte_years_agg AS (
    SELECT
        fl.actor as actor,
        fl.actor_id as actor_id,
        CASE WHEN AVG(fl.rating) > 8.0 THEN 'star'
             WHEN AVG(fl.rating) > 7.0 AND AVG(fl.rating) <= 8.0 THEN 'good'
             WHEN AVG(fl.rating) > 6.0 AND AVG(fl.rating) <= 7.0 THEN 'average'
             WHEN AVG(fl.rating) <= 6.0 THEN 'poor'
             ELSE NULL END AS quality_class,
        ROUND(AVG(fl.rating), 1) AS avg_rating,
        -- indicator for whether the actor is active in the requested year
        fl.is_active AS is_active,
        -- current_year is the requested year
        (SELECT current_year FROM cte_cfg) AS current_year
    FROM
        cte_most_recent_year_films fl 
    GROUP BY fl.actor, fl.actor_id, fl.is_active
),
-- cte that collects actor films for the requested year into a films array
cte_years_films AS (
    SELECT
        ag.actor,
        ag.actor_id,
        CASE WHEN ag.is_active THEN ARRAY_AGG(ROW(dt.year, dt.film, dt.votes, dt.rating, dt.film_id)) ELSE ARRAY[] END AS films,
        ag.quality_class,
        ag.is_active,
        ag.current_year
    FROM
        cte_years_agg ag
    LEFT JOIN cte_most_recent_year_films dt ON ag.actor = dt.actor AND ag.actor_id = dt.actor_id AND ag.current_year = dt.year
    GROUP BY ag.actor, ag.actor_id, ag.quality_class, ag.is_active, ag.current_year
)
SELECT actor, actor_id, films, quality_class, is_active, current_year
FROM cte_years_films

--
