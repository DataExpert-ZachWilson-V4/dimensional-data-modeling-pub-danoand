-- DDL code to stand up 'actor_films' as a Trino powered table
CREATE OR REPLACE TABLE danfanderson48529.actors (
  actor VARCHAR,
  actor_id VARCHAR,
  -- films is an array of ROWs describing the actor's films for the year
  films ARRAY(
    ROW(
      year INTEGER,
      film VARCHAR,
      votes INTEGER,
      rating DOUBLE,
      film_id VARCHAR
    )
  ),
  quality_class VARCHAR,
  is_active BOOLEAN,
  current_year INTEGER
)
WITH
  (
    FORMAT = 'PARQUET',
    partitioning = ARRAY['current_year']
  )

-- update query1.sql | #2
