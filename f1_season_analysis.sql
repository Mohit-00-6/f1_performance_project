USE f1_performance_project;

-- 1. DRIVER LEADERBOARD BY SEASON

-- CTE 1: Calculate each driver's season totals.

WITH driver_season_totals AS (
    SELECT
        r.season,
        f.driver_id,
        d.driver_name,
        SUM(f.points) AS season_points,
        SUM(f.is_win) AS wins,
        SUM(f.is_podium) AS podiums,
        COUNT(DISTINCT f.race_id) AS race_starts
    FROM fact_race_results AS f
    JOIN clean_races AS r
        ON f.race_id = r.race_id
    JOIN clean_drivers AS d
        ON f.driver_id = d.driver_id
    GROUP BY
        r.season,
        f.driver_id,
        d.driver_name
),

-- CTE 2: Rank drivers within each season by points.

ranked_drivers AS (
    SELECT
        season,
        driver_id,
        driver_name,
        season_points,
        wins,
        podiums,
        race_starts,
        DENSE_RANK() OVER (
            PARTITION BY season
            ORDER BY season_points DESC
        ) AS season_rank
    FROM driver_season_totals
)

-- Final output: Show the top 10 driver ranks per season.

SELECT
    season,
    season_rank,
    driver_name,
    season_points,
    wins,
    podiums,
    race_starts
FROM ranked_drivers
WHERE season_rank <= 10
ORDER BY season, season_rank, driver_name;

SELECT * 
FROM driver_season_totals;

SELECT * 
FROM ranked_drivers;

-- 2. CONSTRUCTOR (TEAM) LEADERBOARD BY SEASON
-- CTE 1: Add both drivers' results to calculate each team's totals.

WITH constructor_season_totals AS (
    SELECT
        r.season,
        f.constructor_id,
        c.constructor_name,
        SUM(f.points) AS season_points,
        SUM(f.is_win) AS wins,
        SUM(f.is_podium) AS podiums,
        COUNT(DISTINCT f.race_id) AS races_entered
    FROM fact_race_results AS f
    JOIN clean_races AS r
        ON f.race_id = r.race_id
    JOIN clean_constructors AS c
        ON f.constructor_id = c.constructor_id
    GROUP BY
        r.season,
        f.constructor_id,
        c.constructor_name
),

-- CTE 2: Rank teams within each season by points.

ranked_constructors AS (
    SELECT
        season,
        constructor_id,
        constructor_name,
        season_points,
        wins,
        podiums,
        races_entered,
        DENSE_RANK() OVER (
            PARTITION BY season
            ORDER BY season_points DESC
        ) AS season_rank
    FROM constructor_season_totals
)

-- Final output: Show the top 10 team ranks per season.

SELECT
    season,
    season_rank,
    constructor_name,
    season_points,
    wins,
    podiums,
    races_entered
FROM ranked_constructors
WHERE season_rank <= 10
ORDER BY season, season_rank, constructor_name;

SELECT * 
FROM constructor_season_totals;

SELECT * 
FROM ranked_constructors;

-- 3. NON-FINISH RATE BY CIRCUIT
-- CTE 1: Label each driver result as a finish or non-finish.

WITH result_details AS (
    SELECT
        r.season,
        ci.circuit_name,
        ci.country,
        f.result_id,
        CASE
            WHEN s.status_description = 'Finished'
              OR s.status_description LIKE '+%Lap%'
            THEN 0
            ELSE 1
        END AS did_not_finish
    FROM fact_race_results AS f
    JOIN clean_races AS r
        ON f.race_id = r.race_id
    JOIN clean_circuits AS ci
        ON r.circuit_id = ci.circuit_id
    JOIN clean_status AS s
        ON f.status_id = s.status_id
),

-- CTE 2: Calculate the number and percentage of non-finishes per circuit.

circuit_summary AS (
    SELECT
        circuit_name,
        country,
        COUNT(*) AS driver_starts,
        SUM(did_not_finish) AS non_finishes,
        ROUND(100.0 * SUM(did_not_finish) / COUNT(*),1) AS non_finish_rate_pct
    FROM result_details
    GROUP BY circuit_name, country
),

-- CTE 3: Rank circuits from the highest non-finish rate to the lowest.

ranked_circuits AS (
    SELECT
        circuit_name,
        country,
        driver_starts,
        non_finishes,
        non_finish_rate_pct,
        RANK() OVER (
            ORDER BY non_finish_rate_pct DESC
        ) AS circuit_rank
    FROM circuit_summary
)

-- Final output: List circuits ranked by non-finish rate.

SELECT
    circuit_rank,
    circuit_name,
    country,
    driver_starts,
    non_finishes,
    non_finish_rate_pct
FROM ranked_circuits
ORDER BY circuit_rank, circuit_name;

SELECT * 
FROM result_details ;

SELECT * 
FROM  circuit_summary;

SELECT * 
FROM ranked_circuits;

-- 4. RACE STATUS COUNTS BY SEASON

-- CTE 1: Attach each result row to its season and status description.
WITH result_statuses AS (
    SELECT
        r.season,
        s.status_description,
        f.result_id
    FROM fact_race_results AS f
    JOIN clean_races AS r
        ON f.race_id = r.race_id
    JOIN clean_status AS s
        ON f.status_id = s.status_id
),

-- CTE 2: Count result rows for each status in each season.

status_counts AS (
    SELECT
        season,
        status_description,
        COUNT(*) AS result_count
    FROM result_statuses
    GROUP BY
        season,
        status_description
)

-- Final output: Show each status count and its share of that season's results.

SELECT
    season,
    status_description,
    result_count,
    ROUND(100.0 * result_count/ SUM(result_count) OVER (PARTITION BY season), 2) AS percent_of_season
FROM status_counts
ORDER BY season, result_count DESC;

SELECT * 
FROM result_statuses;

SELECT * 
FROM status_counts;