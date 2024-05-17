-- Query 3: Create a table to store the history of actors with Slowly Changing Dimension (SCD) Type 2 attributes
CREATE OR REPLACE TABLE danfanderson48529.actors_history_scd (
    actor VARCHAR,
    actor_id VARCHAR,
    quality_class VARCHAR,
    is_active BOOLEAN,
    start_date INTEGER,
    end_date INTEGER
)
WITH
    (FORMAT = 'PARQUET')

-- update query_3.sql
