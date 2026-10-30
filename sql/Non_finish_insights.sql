-- Non_finish_insights
-- Purpose: answer WHAT changed behind the falling non-finish rate,
-- so the README findings go beyond "the rate dropped".
-- Run each query, then write the result into README "Findings".
USE f1_performance_project;
-- Q1. Non-finish rate by season (headline number)
SELECT
    r.season,
    COUNT(*) AS driver_entries,
    SUM(s.is_non_finish) AS non_finishes,
    ROUND(
        100.0 * SUM(s.is_non_finish) / COUNT(*),
        1
    ) AS non_finish_rate_pct
FROM fact_race_results_materialized AS f
JOIN clean_races AS r
    ON f.race_id = r.race_id
JOIN clean_status AS s
    ON f.status_id = s.status_id
GROUP BY r.season
ORDER BY r.season;


-- Q2. How did the result-status group mix change by season?
--     Compare 2022 vs 2025 for each status_group.
    SELECT
        r.season,
        s.status_group,
        COUNT(*) AS result_count,
		ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY r.season), 1)     AS pct_of_season
    FROM fact_race_results_materialized AS f
    JOIN clean_races AS r
        ON f.race_id = r.race_id
    JOIN clean_status AS s
        ON f.status_id = s.status_id
    GROUP BY
        r.season,
        s.status_group
	ORDER BY season, result_count DESC;

-- Q3. Top individual non-finish statuses per season (what exactly retired cars?)

WITH non_finish_counts AS (
    SELECT
        r.season,
        s.status_description,
        COUNT(*) AS non_finish_count
    FROM fact_race_results_materialized AS f
    JOIN clean_races AS r
        ON f.race_id = r.race_id
    JOIN clean_status AS s
        ON f.status_id = s.status_id
    WHERE s.is_non_finish = 1
    GROUP BY
        r.season,
        s.status_description
),
ranked_non_finish_statuses AS (
    SELECT
        season,
        status_description,
        non_finish_count,
        ROW_NUMBER() OVER (
            PARTITION BY season
            ORDER BY non_finish_count DESC
        ) AS rank_in_season
    FROM non_finish_counts
)
SELECT
    season,
    rank_in_season,
    status_description,
    non_finish_count
FROM ranked_non_finish_statuses
WHERE rank_in_season <= 5
ORDER BY season, rank_in_season;

-- Q4. Circuit change 2022 -> 2025: where did the rate move most?
--     Only circuits that hosted a race in BOTH seasons.

WITH circuit_season_rates AS (
    SELECT
        ci.circuit_id,
        ci.circuit_name,
        ci.country,
        r.season,
        COUNT(*) AS driver_entries,
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
    WHERE r.season IN (2022, 2025)
    GROUP BY
        ci.circuit_id,
        ci.circuit_name,
        ci.country,
        r.season
)
SELECT
    a.circuit_name,
    a.country,
    a.non_finish_rate_pct AS rate_2022_pct,
    b.non_finish_rate_pct AS rate_2025_pct,
    ROUND(
        b.non_finish_rate_pct - a.non_finish_rate_pct,
        1
    ) AS change_percentage_points
FROM circuit_season_rates AS a
JOIN circuit_season_rates AS b
    ON a.circuit_id = b.circuit_id
WHERE a.season = 2022
  AND b.season = 2025
ORDER BY ABS(change_percentage_points) DESC, a.circuit_name;

-- Q5. Reconciliation: this total must equal the Power BI "Non-Finishes" card
--     with all seasons selected. Write both numbers in the README.
SELECT
    COUNT(*) AS driver_entries,
    SUM(s.is_non_finish) AS non_finishes,
    ROUND(
        100.0 * SUM(s.is_non_finish) / COUNT(*),
        2
    ) AS non_finish_rate_pct
FROM fact_race_results_materialized AS f
JOIN clean_status AS s
    ON f.status_id = s.status_id;