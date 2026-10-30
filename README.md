# 🏎️ Formula 1 Performance Analytics

> An end-to-end analytics project exploring Formula 1 driver, constructor, and circuit performance across the **2022–2025 seasons** with MySQL, SQL, Power Query, DAX, and Power BI.

**Project status:** Analysis and three-page dashboard completed  
**Dataset:** [Formula 1 World Championship on Kaggle](https://www.kaggle.com/datasets/atharvranjan/formula-1-world-championship-1950-present)  
**Analysis period:** 2022–2025  
**Validated result rows:** 1,838

---

## 📚 Contents

- [Business problem](#-business-problem)
- [Technologies and skills](#-technologies-and-skills)
- [Project workflow](#-project-workflow)
- [Data model](#-data-model)
- [SQL analysis questions](#-sql-analysis-questions)
- [Power BI measures](#-power-bi-measures)
- [Dashboard pages](#-dashboard-pages)
- [Findings and recommendation](#-findings-and-recommendation)
- [Reproduce the project](#-reproduce-the-project)
- [Project files](#-project-files)
- [Limitations](#-limitations)

## 🎯 Business problem

Formula 1 teams, analysts, and motorsport fans need a clear way to compare driver and constructor performance and understand where non-finishes occur. This project organizes race-result data into a reporting model and answers questions such as:

- Which drivers and constructors scored the most points, wins, and podiums?
- How did season-level points, wins, podiums, and non-finish rates change from 2022 through 2025?
- Which result statuses account for non-finishes?
- Which circuits had the most non-finishes, and how did circuit non-finish rates change between 2022 and 2025?

The report describes patterns in the available data. It does not establish why a driver retired or prove that a circuit caused a non-finish.

## 🛠️ Technologies and skills

| Technology / skill | Contribution to the project |
|---|---|
| **MySQL 8.0+ and MySQL Workbench** | Stored imported CSV data, created cleaned views and a materialized results table, and ran validation and reporting queries. |
| **SQL** | Used joins, CTEs, aggregates, CASE, and window functions such as DENSE_RANK(), RANK(), ROW_NUMBER(), and SUM() OVER. |
| **Power Query** | Connected Power BI to MySQL and handled report-side data preparation, including text cleanup. |
| **Data modeling** | Organized result rows with race, driver, constructor, circuit, and status lookup tables. |
| **DAX** | Created reusable measures for points, wins, podiums, entries, races, non-finishes, and non-finish rate. |
| **Power BI** | Built three interactive report pages with season slicers, KPI cards, charts, and a detail table. |
| **Data quality** | Checked row counts and ID matches, reviewed status categories, and corrected the Lapped classification. |
| **Data storytelling** | Turned the query results into findings and a recommendation while avoiding unsupported causal claims. |
| **Generative AI** | Used as a learning and troubleshooting aid for SQL, DAX, data modeling, visualization choices, and documentation. Suggestions were reviewed against query results. |

<details>
<summary>🧠 Skills practiced</summary>

- Importing and profiling multi-table CSV data
- Cleaning and converting raw text fields with SQL views
- Validating key relationships and row counts
- Building a fact-and-dimension model for Power BI
- Writing filter-aware DAX measures
- Comparing counts and rates without confusing the two
- Explaining trends and limitations to a business audience
- Using generative AI as an assistant and validating its output

</details>

## 🔄 Project workflow

1. **Import:** Create or select the MySQL schema and import the Kaggle CSV files into raw tables.
2. **Profile:** Check raw row counts, ID ranges, available seasons, statuses, and key matches.
3. **Clean:** Create typed views for races, results, drivers, constructors, circuits, and statuses.
4. **Build the fact data:** Create fact_race_results, with one row per driver's race result, then materialize it into fact_race_results_materialized for faster analysis.
5. **Analyze:** Run the season leaderboard and non-finish insight queries against the materialized table.
6. **Model:** Connect the cleaned lookup tables to the materialized fact table in Power BI.
7. **Measure:** Create DAX measures for performance and reliability KPIs.
8. **Present:** Build the three report pages and use season filters to explore results.
9. **Validate:** Compare Power BI cards with MySQL totals using all seasons selected.

## 🧱 Data model

The Power BI report uses **fact_race_results_materialized** as its central fact table. Its grain is one driver's result in one race.

The fact table contains result, race, circuit, driver, constructor, and status IDs plus positions, points, laps, wins, and podium flags.

<details>
<summary>🔗 View the star-schema relationships</summary>

Create active one-to-many relationships with the cleaned lookup table on the **one** side and the fact table on the **many** side:

- clean_races[race_id] → fact_race_results_materialized[race_id]
- clean_drivers[driver_id] → fact_race_results_materialized[driver_id]
- clean_constructors[constructor_id] → fact_race_results_materialized[constructor_id]
- clean_status[status_id] → fact_race_results_materialized[status_id]

For circuit labels and filters, use the circuit ID available in the fact table and relate it to clean_circuits[circuit_id]. Keep one fact table as the basis for a visual's measures; don't mix measures from both fact_race_results and fact_race_results_materialized.

</details>

### ✅ Status classification update

The raw status table includes both +1 Lap-style statuses and the exact label Lapped. The final clean_status logic classifies both as **Finished (lapped)** and sets is_non_finish = 0. This prevents lapped finishers from inflating the non-finish counts.

## 🔎 SQL analysis questions

The SQL scripts contain data-quality checks, cleaning logic, and reporting queries. The following are the main questions answered by the analysis.

<details>
<summary>🧹 Data import and quality checks in f1_performance.sql</summary>

1. Did each raw CSV table import the expected number of rows?
2. What is the race coverage by season from 2022 through 2025?
3. Do result IDs match the related race, driver, constructor, and status records?
4. How many driver records and unique driver IDs are present, and what is the ID range?
5. Which result rows reference driver IDs that are missing from the driver table?
6. What do sample rows in the raw tables look like?
7. Which are the 10 highest driver IDs when sorted numerically?
8. Which seasons are present in the race table?
9. Which race statuses occur in the analysis period, and how many result rows use each?
10. Do the cleaned views and fact table have the expected row counts and complete dimension matches?

The file also creates the cleaned views and the materialized fact table used by the analysis scripts.

</details>

<details>
<summary>🏆 Season reporting questions in f1_season_analysis.sql</summary>

1. **Driver leaderboard:** Who are the top 10 ranked drivers by points in each season, and how many points, wins, podiums, and race entries did they record?
2. **Constructor leaderboard:** Which constructors rank in the top 10 by season points, wins, podiums, and races entered?
3. **Circuit non-finish analysis:** Which circuits have the highest non-finish rates across the included seasons, considering circuits with at least 40 driver entries?
4. **Status mix by season:** How many result rows belong to each status in each season, and what percentage of that season's results does each status represent?

</details>

<details>
<summary>🏁 Non-finish investigation questions in Non_finish_insights.sql</summary>

1. **How did the non-finish rate change by season?** Report entries, non-finishes, and rate for 2022–2025.
2. **How did the result-status group mix change by season?** Compare each status group's share of all result rows. This describes the mix; it does not prove what caused the non-finish rate to change.
3. **Which individual statuses account for the most non-finishes in each season?** Show the top five per season.
4. **Which circuits had the greatest change in non-finish rate from 2022 to 2025?** Compare circuits present in both seasons and report the percentage-point change.
5. **Do the SQL non-finish totals reconcile with Power BI?** Compare all-season entries, non-finishes, and non-finish rate.

</details>

## 📐 Power BI measures

Create these measures using **fact_race_results_materialized**. The non-finish measures depend on the active relationship from clean_status to the fact table.

~~~DAX
Driver Entries =
COUNTROWS(fact_race_results_materialized)

Total Points =
SUM(fact_race_results_materialized[points])

Race Wins =
SUM(fact_race_results_materialized[is_win])

Podiums =
SUM(fact_race_results_materialized[is_podium])

Races =
DISTINCTCOUNT(fact_race_results_materialized[race_id])

Non-Finishes =
CALCULATE(
    [Driver Entries],
    clean_status[is_non_finish] = 1
)

Non-Finish Rate =
DIVIDE([Non-Finishes], [Driver Entries], 0)
~~~

Format **Non-Finish Rate** as a percentage. With all seasons selected, the validated values are **1,838 entries**, **254 non-finishes**, and **13.82%**.

## 📊 Dashboard pages

### Page 1 — Season Overview

- Season slicer for 2022–2025
- KPI cards for driver entries, podiums, race wins, and total points
- Total points by season
- Race wins and podiums by season
- Season takeaway and questions answered

![DASHBOARD 1](/IMAGES/PAGE%201.png)

### Page 2 — Driver & Team Performance

- Season slicer for comparing performance within a selected season
- KPI cards for entries, podiums, wins, and points
- Top drivers by points
- Constructor points ranking
- Driver standings detail table
- Questions about driver and constructor performance

![DASHBOARD 2](/IMAGES/PAGE%202.png)

### Page 3 — Race & Circuit

- Season slicer and KPI cards for races, entries, non-finishes, and non-finish rate
- Non-finish rate trend by season
- 2025 non-finishes by status
- Non-finish counts by circuit
- Questions about status patterns and circuit results

![DASHBOARD 3](/IMAGES/PAGE%203.png)

## 📈 Findings and recommendation

The following findings use the corrected status logic, including Lapped as a finish.

<details open>
<summary>📊 Findings from 2022–2025</summary>

1. **The non-finish rate fell through 2024, then rose slightly in 2025.** It was 16.8% in 2022, 15.0% in 2023, 11.3% in 2024, and 12.5% in 2025.
2. **Retirements dominated the 2025 non-finishes.** There were 60 non-finishes in 2025; 51 were recorded as Retired, or 85%. The remaining top statuses were Disqualified (6) and Did not start (3).
3. **Circuit rates changed in different directions between 2022 and 2025.** Marina Bay decreased by 30 percentage points, Jeddah by 25 points, and Baku by 20 points. Albert Park increased by 15 points.
4. **Season performance remained strong in 2024–2025.** Podiums increased from 66 in 2022 and 2023 to 72 in 2024 and 2025. Race wins increased from 22 in 2022 and 2023 to 24 in 2024 and 2025. In the combined-period driver ranking, Max Verstappen led with 1,751 points, 51 wins, and 67 podiums.

### 💡 Recommendation

Prioritize a closer review of the **Retired** statuses in 2025 and investigate the circuit-level changes—especially the increase at Albert Park and decreases at Marina Bay, Jeddah, and Baku. Use race context and additional reliability data before proposing actions: these results identify patterns, but do not establish their causes.

</details>

## 🚀 Reproduce the project

1. Download and extract the [Kaggle dataset](https://www.kaggle.com/datasets/atharvranjan/formula-1-world-championship-1950-present).
2. Create/select the f1_performance_project schema in MySQL Workbench.
3. Import the required CSV files as raw tables using the Workbench Table Data Import Wizard. Use the table names expected by the SQL script (for example, raw_races, raw_results, raw_drivers, raw_constructors, raw_circuits, and raw_status).
4. Run the raw-data checks and cleaning/view section in f1_performance.sql. It creates the clean views and fact_race_results.
5. Run the materialization section in f1_performance.sql to create fact_race_results_materialized.
6. Run queries in f1_season_analysis.sql and Non_finish_insights.sql.
7. Connect Power BI Desktop to the MySQL schema and load the materialized fact table and required clean views.
8. Create and validate the one-to-many relationships, then add the DAX measures.
9. Check that slicers filter the intended visuals and compare all-season cards with SQL Q5.
10. Save the Power BI report as F1_PERFORMANCE_DASHBOARD.pbix.

## 📁 Project files

Expected files in the repository:

- f1_performance.sql — raw-data checks, cleaning views, fact view, validation, and materialized fact table.
- f1_season_analysis.sql — season driver/constructor rankings, circuit rates, and status mix.
- Non_finish_insights.sql — seasonal non-finish investigation and SQL-to-Power BI reconciliation.
- F1_PERFORMANCE_DASHBOARD.pbix — three-page Power BI report.
- README.md — project overview, methods, questions, and findings.

Update these filenames or links if your repository uses a different folder layout. CSV source files are not included in the repository; download them from Kaggle.

## ⚠️ Limitations

- This analysis covers only the 2022–2025 seasons and should not be generalized to all Formula 1 history.
- Non-finish rates depend on the status classification in clean_status; the project explicitly treats Lapped and +N Lap(s) as finishes.
- A status label such as Retired describes the recorded result, not the underlying mechanical or operational cause.
- Circuit comparisons use observed rates and do not prove that a circuit caused a retirement. Race conditions, driver behavior, and other factors are not controlled here.
- Kaggle data can change. Record the exact dataset version or download date when publishing for reproducibility.