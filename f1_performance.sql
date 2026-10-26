-- Check imported row counts.

SELECT 'races' AS table_name, COUNT(*) AS row_count FROM raw_races
UNION ALL SELECT 'results', COUNT(*) FROM raw_results
UNION ALL SELECT 'drivers', COUNT(*) FROM raw_drivers
UNION ALL SELECT 'constructors', COUNT(*) FROM raw_constructors
UNION ALL SELECT 'circuits', COUNT(*) FROM raw_circuits
UNION ALL SELECT 'qualifying', COUNT(*) FROM raw_qualifying
UNION ALL SELECT 'pit_stops', COUNT(*) FROM raw_pit_stops
UNION ALL SELECT 'status', COUNT(*) FROM raw_status;

SELECT *
FROM raw_races;

-- This query checks the race data for 2022–2025

SELECT
    CAST(`year` AS UNSIGNED) AS season,  -- CAST(`year` AS UNSIGNED)` converts the year from text to a number.
    COUNT(*) AS race_count,
    MIN(`date`) AS first_race,
    MAX(`date`) AS last_race
FROM raw_races
WHERE CAST(`year` AS UNSIGNED) BETWEEN 2022 AND 2025
GROUP BY `year`
ORDER BY season ASC ;


SELECT *
FROM raw_results;

SELECT *
FROM raw_drivers;

SELECT *
FROM raw_constructors;

SELECT *
FROM raw_status;

-- Count result rows and check whether their IDs match the related tables

SELECT
    COUNT(*) AS result_rows,
    SUM(r.raceId IS NULL) AS missing_race_matches,
    SUM(d.driverId IS NULL) AS missing_driver_matches,
    SUM(c.constructorId IS NULL) AS missing_constructor_matches,
    SUM(s.statusId IS NULL) AS missing_status_matches
FROM raw_results AS rr
LEFT JOIN raw_races AS r  -- LEFT JOIN keeps every result row, even when a matching record isn’t found
    ON rr.raceId = r.raceId
LEFT JOIN raw_drivers AS d
    ON rr.driverId = d.driverId
LEFT JOIN raw_constructors AS c
    ON rr.constructorId = c.constructorId
LEFT JOIN raw_status AS s
    ON rr.statusId = s.statusId;
    
--  Check the number of rows and unique driver IDs in the driver table
    
SELECT
    COUNT(*) AS driver_rows,
    COUNT(DISTINCT driverId) AS unique_driver_ids
FROM raw_drivers;

--  Find result records whose driver IDs are missing from the driver table
-- Show the 20 missing IDs that appear most often

SELECT
    rr.driverId,
    COUNT(*) AS affected_result_rows
FROM raw_results AS rr
LEFT JOIN raw_drivers AS d
    ON rr.driverId = d.driverId
WHERE d.driverId IS NULL
GROUP BY rr.driverId
ORDER BY affected_result_rows DESC
LIMIT 20;

--  Preview the raw driver table

SELECT *
FROM raw_drivers
;

--  CHECK DRIVER ID RANGE AND DUPLICATES

SELECT
    COUNT(*) AS driver_rows,
    COUNT(DISTINCT driverId) AS unique_driver_ids,
    MIN(CAST(driverId AS UNSIGNED)) AS lowest_driver_id,
    MAX(CAST(driverId AS UNSIGNED)) AS highest_driver_id
FROM raw_drivers;   
 
 --  VIEW THE 10 HIGHEST DRIVER IDs IN NUMERIC ORDER
 
SELECT driverId, driverRef, forename, surname
FROM raw_drivers
ORDER BY CAST(driverId AS UNSIGNED) DESC
LIMIT 10;

--  CLEAR THE DRIVER TABLE BEFORE A REIMPORT
-- CAUTION: This permanently removes all rows from raw_drivers.
-- Keep this commented out unless you intentionally need to reload it.

-- TRUNCATE TABLE raw_drivers;

--  PREVIEW DRIVERS AFTER A REIMPORT

SELECT *
FROM raw_drivers
ORDER BY driverId DESC;

--  RECHECK DRIVER ROW COUNT AND ID RANGE

SELECT
    COUNT(*) AS driver_rows,
    COUNT(DISTINCT driverId) AS unique_driver_ids,
    MIN(CAST(driverId AS UNSIGNED)) AS lowest_driver_id,
    MAX(CAST(driverId AS UNSIGNED)) AS highest_driver_id
FROM raw_drivers;  
  
 --  RECHECK THE 10 HIGHEST DRIVER IDs
 
SELECT driverId, driverRef, forename, surname
FROM raw_drivers
ORDER BY CAST(driverId AS UNSIGNED) DESC
LIMIT 10;

--  CHECK WHICH SEASONS ARE AVAILABLE

SELECT DISTINCT `year`
FROM raw_races
ORDER BY `year`;

-- CREATE CLEAN RACE VIEW FOR SEASONS 2022–2025

CREATE OR REPLACE VIEW clean_races AS
SELECT
    CAST((raceId) AS UNSIGNED) AS race_id,
    CAST((`year`) AS UNSIGNED) AS season,
    CAST((`round`) AS UNSIGNED) AS round_number,
    CAST((circuitId) AS UNSIGNED) AS circuit_id,
    (name) AS race_name,
    STR_TO_DATE((`date`), '%Y-%m-%d') AS race_date
FROM raw_races
WHERE (`year`) BETWEEN 2022 AND 2025
  AND CAST((raceId) AS UNSIGNED) > 0
AND CAST((circuitId) AS UNSIGNED) > 0
  AND STR_TO_DATE((`date`), '%Y-%m-%d') IS NOT NULL;
  
 --  PREVIEW CLEAN RACES AND COUNT THEM BY SEASON
 
SELECT *
FROM clean_races
ORDER BY season ;

SELECT
    season,
    COUNT(*) AS race_count
FROM clean_races
GROUP BY season
ORDER BY season;

--    CREATE CLEAN RESULTS VIEW
--     Keep results linked to races in clean_races.

CREATE OR REPLACE VIEW clean_results AS
SELECT
    CAST((rr.resultId) AS UNSIGNED) AS result_id,
    CAST((rr.raceId) AS UNSIGNED) AS race_id,
    CAST((rr.driverId) AS UNSIGNED) AS driver_id,
    CAST((rr.constructorId) AS UNSIGNED) AS constructor_id,
    CAST((rr.grid) AS UNSIGNED) AS grid_position,

    CASE
        WHEN (rr.position) = '' THEN NULL
        ELSE CAST((rr.position) AS UNSIGNED)
    END AS finish_position,

    CAST((rr.positionOrder) AS UNSIGNED) AS finish_order,
    CAST((rr.points) AS DECIMAL(8,3)) AS points,
    CAST((rr.laps) AS UNSIGNED) AS laps_completed,
    CAST((rr.statusId) AS UNSIGNED) AS status_id

FROM raw_results AS rr
INNER JOIN clean_races AS cr
    ON CAST((rr.raceId) AS UNSIGNED) = cr.race_id;
    
 --  PREVIEW CLEAN RESULTS AND COUNT THEM BY SEASON
 
SELECT *
FROM clean_results
LIMIT 20;

SELECT
    cr.season,
    COUNT(DISTINCT cr.race_id) AS races,
    COUNT(res.result_id) AS result_rows
FROM clean_races AS cr
LEFT JOIN clean_results AS res
    ON cr.race_id = res.race_id
GROUP BY cr.season
ORDER BY cr.season;

SELECT *
FROM raw_results;

--  CREATE CLEAN DRIVER VIEW

CREATE OR REPLACE VIEW clean_drivers AS
SELECT
    CAST((driverId) AS UNSIGNED) AS driver_id,
    (driverRef) AS driver_ref,
    CAST(NULLIF((number), '') AS UNSIGNED) AS driver_number,
    NULLIF((code), '') AS driver_code,
    TRIM(forename) AS first_name,
    TRIM(surname) AS last_name,
    CONCAT_WS(' ', NULLIF((forename), ''), NULLIF((surname), '')) AS driver_name,
    STR_TO_DATE(NULLIF((dob), ''), '%Y-%m-%d') AS date_of_birth,
    (nationality) AS Nationality
FROM raw_drivers
WHERE CAST((driverId) AS UNSIGNED) > 0;

SELECT COUNT(*) AS cleaned_driver_rows
FROM clean_drivers;

SELECT *
FROM clean_drivers
ORDER BY driver_id DESC
LIMIT 10;

SELECT *
FROM raw_drivers;

 -- CREATE CLEAN CONSTRUCTOR (TEAM) VIEW
 
CREATE OR REPLACE VIEW clean_constructors AS
SELECT
    CAST((constructorId) AS UNSIGNED) AS constructor_id,
    (constructorRef) AS constructor_ref,
    (name) AS constructor_name,
    (nationality) AS Nationality
FROM raw_constructors
WHERE CAST((constructorId) AS UNSIGNED) > 0;

SELECT COUNT(*) AS cleaned_constructor_rows
FROM clean_constructors;

SELECT *
FROM clean_constructors
ORDER BY constructor_id
LIMIT 10;

SELECT *
FROM raw_constructors;

--  CREATE CLEAN CIRCUIT VIEW

CREATE OR REPLACE VIEW clean_circuits AS
SELECT
    CAST((circuitId) AS UNSIGNED) AS circuit_id,
    (circuitRef) AS circuit_ref,
    (name) AS circuit_name,
    (location) AS location,
    (country) AS country,
    CAST(NULLIF((lat), '') AS DECIMAL(10,6)) AS latitude,
    CAST(NULLIF((lng), '') AS DECIMAL(10,6)) AS longitude,
    CAST(NULLIF((alt), '') AS SIGNED) AS altitude_meters
FROM raw_circuits
WHERE CAST((circuitId) AS UNSIGNED) > 0;

SELECT COUNT(*) AS cleaned_circuit_rows
FROM clean_circuits;

SELECT *
FROM clean_circuits
ORDER BY country, circuit_name
LIMIT 10;

SELECT *
FROM raw_circuits;

--  CREATE CLEAN RACE STATUS VIEW

CREATE OR REPLACE VIEW clean_status AS
SELECT
    CAST((statusId) AS UNSIGNED) AS status_id,
    (status) AS status_description
FROM raw_status
WHERE CAST((statusId) AS UNSIGNED) > 0;

SELECT COUNT(*) AS cleaned_status_rows
FROM clean_status;

SELECT *
FROM clean_status
ORDER BY status_id
LIMIT 20;

SELECT *
FROM raw_status;

--  CREATE FACT VIEW
--  One row represents one driver's result in one race.

CREATE OR REPLACE VIEW fact_race_results AS
SELECT
    f.result_id,
    f.race_id,
    r.circuit_id,
    f.driver_id,
    f.constructor_id,
    f.status_id,
    f.grid_position,
    f.finish_position,
    f.finish_order,
    f.points,
    f.laps_completed,

    CASE
        WHEN f.finish_position = 1 THEN 1
        ELSE 0
    END AS is_win,

    CASE
        WHEN f.finish_position BETWEEN 1 AND 3 THEN 1
        ELSE 0
    END AS is_podium

FROM clean_results AS f
JOIN clean_races AS r
    ON f.race_id = r.race_id;
    
--  CHECK FACT ROW COUNT AND RESULT ID UNIQUENESS

SELECT
    COUNT(*) AS fact_rows,
    COUNT(DISTINCT result_id) AS unique_result_ids
FROM fact_race_results;

-- PREVIEW FACT ROWS

SELECT *
FROM fact_race_results
LIMIT 20;

--    CHECK FACT-TO-DIMENSION MATCHES
--    Each missing_* value should be zero.

SELECT
    COUNT(*) AS fact_rows,
    SUM(cr.race_id IS NULL) AS missing_race_matches,
    SUM(d.driver_id IS NULL) AS missing_driver_matches,
    SUM(c.constructor_id IS NULL) AS missing_constructor_matches,
    SUM(s.status_id IS NULL) AS missing_status_matches,
    SUM(ci.circuit_id IS NULL) AS missing_circuit_matches
FROM fact_race_results AS f
LEFT JOIN clean_races AS cr
    ON f.race_id = cr.race_id
LEFT JOIN clean_drivers AS d
    ON f.driver_id = d.driver_id
LEFT JOIN clean_constructors AS c
    ON f.constructor_id = c.constructor_id
LEFT JOIN clean_status AS s
    ON f.status_id = s.status_id
LEFT JOIN clean_circuits AS ci
    ON cr.circuit_id = ci.circuit_id;
    
    




