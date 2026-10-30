-- f1_season_analysis
-- Purpose: reporting queries that reproduce the dashboard numbers.
-- Each query is self-contained. (CTEs only exist inside their own statement,
-- so "SELECT * FROM <cte_name>;" after a query does not work and was removed.
-- To inspect a CTE, put "SELECT * FROM <cte_name>" at the end of that same query.)

USE f1_performance_project;


-- 1. DRIVER SEASON LEADERBOARD
-- Summarize each driver's points, wins, podiums, and race starts
-- for each season, then rank drivers by season points.
-- ============================================================

-- CTE 1: Aggregate each driver's results into season totals.

WITH driver_season_totals AS (
    SELECT
        r.season,
        f.driver_id,
        d.driver_name,
        SUM(f.points) AS season_points,
        SUM(f.is_win) AS wins,
        SUM(f.is_podium) AS podiums,
        COUNT(DISTINCT f.race_id) AS race_entries
    FROM fact_race_results_materialized AS f
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
        race_entries,
        DENSE_RANK() OVER (
            PARTITION BY season
            ORDER BY season_points DESC
        ) AS season_rank
    FROM driver_season_totals
)

-- Final output: Return the top 10 ranks for each season.
SELECT
    season,
    season_rank,
    driver_name,
    season_points,
    wins,
    podiums,
    race_entries
FROM ranked_drivers
WHERE season_rank <= 10
ORDER BY season, season_rank, driver_name;


-- 2. CONSTRUCTOR SEASON LEADERBOARD
-- Combine the results of a team's drivers to calculate the
-- constructor's season points, wins, podiums, and races entered.
-- ============================================================

-- CTE 1: Aggregate driver results into constructor season totals.

WITH constructor_season_totals AS (
    SELECT
        r.season,
        f.constructor_id,
        c.constructor_name,
        SUM(f.points) AS season_points,
        SUM(f.is_win) AS wins,
        SUM(f.is_podium) AS podiums,
        COUNT(DISTINCT f.race_id) AS races_entered
    FROM fact_race_results_materialized AS f
    JOIN clean_races AS r
        ON f.race_id = r.race_id
    JOIN clean_constructors AS c
        ON f.constructor_id = c.constructor_id
    GROUP BY
        r.season,
        f.constructor_id,
        c.constructor_name
),
-- CTE 2: Rank constructors within each season by points.
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

-- Final output: Return the top 10 constructor ranks per season.
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


-- 3. CIRCUIT NON-FINISH ANALYSIS
-- Calculate driver starts, non-finishes, and non-finish rate
-- for each circuit across all included seasons.
-- ============================================================

-- CTE: Summarize results by circuit and keep circuits with at
-- least 40 driver starts for a more comparable rate.

WITH circuit_summary AS (
 
    SELECT
        ci.circuit_id,
        ci.circuit_name,
        ci.country,
        COUNT(*) AS driver_entries,
        SUM(s.is_non_finish) AS non_finishes,
        ROUND(
            100.0 * SUM(s.is_non_finish) / COUNT(*),
            1
        ) AS non_finish_rate_pct
    FROM fact_race_results_materialized AS f
    JOIN clean_races AS r
        ON f.race_id = r.race_id
    JOIN clean_circuits AS ci
        ON r.circuit_id = ci.circuit_id
    JOIN clean_status AS s
        ON f.status_id = s.status_id
    GROUP BY
        ci.circuit_id,
        ci.circuit_name,
        ci.country
    HAVING COUNT(*) >= 40
)

-- Final output: Rank circuits from the highest non-finish rate.
SELECT
    RANK() OVER (
        ORDER BY non_finish_rate_pct DESC
    ) AS circuit_rank,
    circuit_name,
    country,
    driver_entries,
    non_finishes,
    non_finish_rate_pct
FROM circuit_summary
ORDER BY circuit_rank, circuit_name;


-- 4. RESULT STATUS MIX BY SEASON
-- Count each result status in each season and calculate its
-- percentage share of that season's result rows.
-- ============================================================

-- CTE: Count results for each status and season.
WITH status_counts AS (
    SELECT
        r.season,
        s.status_description,
        COUNT(*) AS result_count
    FROM fact_race_results_materialized AS f
    JOIN clean_races AS r
        ON f.race_id = r.race_id
    JOIN clean_status AS s
        ON f.status_id = s.status_id
    GROUP BY
        r.season,
        s.status_description
)

-- Final output: Show status counts and percentage of season total.
SELECT
    season,
    status_description,
    result_count,
    ROUND(
        100.0 * result_count
        / SUM(result_count) OVER (PARTITION BY season),
        2
    ) AS percent_of_season
FROM status_counts
ORDER BY season, result_count DESC;
