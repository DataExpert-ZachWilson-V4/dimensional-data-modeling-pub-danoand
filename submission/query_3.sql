-- Query 3: Create a table to store the history of actors with Slowly Changing Dimension (SCD) Type 2
CREATE OR REPLACE TABLE danfanderson48529.actors_history_scd (
  quality_class VARCHAR,
  is_active BOOLEAN,
  start_date DATE,
  end_date DATE
)
WITH
  (
    FORMAT = 'PARQUET'
  )