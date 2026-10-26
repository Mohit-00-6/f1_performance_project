# 🏎️ Formula 1 Performance Analytics

> An end-to-end analytics project exploring Formula 1 driver, constructor, and circuit performance across the **2022–2025 seasons** using **MySQL, SQL, Power Query, DAX, and Power BI**.

**Project status:**  Analysis and three-page dashboard completed  
**Dataset:** [Formula 1 World Championship on Kaggle](https://www.kaggle.com/datasets/atharvranjan/formula-1-world-championship-1950-present)

## 🎯 Business problem

Teams, analysts, and motorsport fans need a clear way to compare season performance and identify where race non-finishes are concentrated. This project answers:

- Which drivers and constructors scored the most points, wins, and podiums?
- How did performance change from 2022 through 2025?
- Which circuits had the highest non-finish rates, and how did those rates change by season?

The report describes patterns in the results data. It does not establish why a driver retired or prove that a circuit caused a non-finish.

## 🛠️ Technologies and skills

| Technology / skill | How it contributed to the project |
|---|---|
|  **MySQL 8.0+ / Workbench** | Staged CSV data, profiled tables, cleaned values, and created reporting views. |
|  **SQL** | Used joins, CTEs, aggregates, `CASE`, and window functions such as `DENSE_RANK()` for season rankings. |
|  **Power Query** | Connected Power BI to MySQL and loaded the reporting data. |
|  **Data modeling** | Built a star schema so race, driver, constructor, circuit, and status filters work across results. |
|  **DAX** | Created reusable measures for points, wins, podiums, entries, races, and non-finish rate. |
|  **Power BI** | Built three interactive report pages with slicers, KPI cards, bar and line charts, and a detail table. |
| **Data quality** | Checked row counts and key matches, handled type and text issues, and defined metric logic. |
|  **Data storytelling** | Turned report patterns into findings and a cautious recommendation. |
|  **Generative AI** | Used as a learning and troubleshooting aid for SQL, DAX, modeling, visual choices, and writing. Suggestions were reviewed and checked against the data. |

<details>
<summary> What I learned</summary>

- How to stage source data before cleaning it.
- How to validate relationships with primary and foreign key checks.
- How fact and dimension tables support a Power BI star schema.
- How DAX measures respond to slicers and visual filters.
- How to explain findings without claiming a cause the data cannot prove.

</details>

## 🔄 Project workflow

1.  **Import:** load source CSVs into raw MySQL tables.
2.  **Profile:** review row counts, IDs, duplicates, date values, and key matches.
3.  **Clean:** trim text, convert data types, parse dates, and focus the analysis on 2022–2025.
4.  **Prepare:** create clean views and `fact_race_results` for reporting.
5.  **Model:** connect dimension tables to the fact table with one-to-many relationships.
6.  **Measure:** create DAX measures for the dashboard KPIs and rates.
7.  **Present:** build three pages and add season slicers.
8.  **Validate:** compare key Power BI totals with MySQL and check slicer behavior.

## 🧱 Data model

The Power BI model centers on **`fact_race_results`**, with one row per driver result in a race.

<details>
<summary> View table relationships</summary>

- `clean_races[race_id]` → `fact_race_results[race_id]`
- `clean_drivers[driver_id]` → `fact_race_results[driver_id]`
- `clean_constructors[constructor_id]` → `fact_race_results[constructor_id]`
- `clean_circuits[circuit_id]` → `fact_race_results[circuit_id]`
- `clean_status[status_id]` → `fact_race_results[status_id]`

Each clean table is on the **one** side; the results table is on the **many** side. The dimensions provide the labels and filters used to analyze the result rows.

</details>

## 📐 Core DAX measures

```DAX
Total Points = SUM(' fact_race_results'[points])

Race Wins = SUM(' fact_race_results'[is_win])

Podiums = SUM(' fact_race_results'[is_podium])

Driver Entries = COUNTROWS(' fact_race_results')

Races = DISTINCTCOUNT(' clean_races'[race_id])

Non-Finish Rate = DIVIDE([Non-Finishes], [Driver Entries], 0)

Non-Finishes = 
COUNTROWS(
    FILTER(
        ' fact_race_results',
        VAR ResultStatus = RELATED(clean_status[status_description])
        RETURN
            ResultStatus <> "Finished"
                && NOT CONTAINSSTRING(ResultStatus, "Lap")
    )
)
```

<details>
<summary> Non-finish definition</summary>

`Non-Finishes` counts result rows whose status is not `Finished` and is not a classified lapped-finish status containing `Lap`. This definition depends on the status descriptions in `clean_status`; use the same definition when comparing results.

</details>

## 📊 Power BI dashboard

###  Page 1 — Season Overview

- Season slicer for 2022–2025
- KPI cards for total points, race wins, podiums, and driver entries
- Total points by season
- Race wins and podiums by season
- Space for a season takeaway and questions answered

![DASHBOARD PAGE 1](/IMAGES/PAGE%201.png)

###  Page 2 — Driver & Team

- Season slicer and KPI cards
- Top drivers by points
- Constructor points ranking
- Driver standings detail table
- Top drivers by wins visual

![DASHBOARD PAGE 2](/IMAGES/PAGE%202.png)

###  Page 3 — Race & Circuit

- Season slicer and KPI cards for races, entries, non-finishes, and non-finish rate
- Non-finish rate by circuit
- Non-finish rate trend by season
- Questions about circuit rankings and seasonal changes

![DASHBOARD PAGE 3](/IMAGES/PAGE%203.png)

## 🔎 Preliminary findings

The following are from the Power BI report with **All seasons** selected.

<details open>
<summary>📈 Findings from 2022–2025</summary>

1. **Points peaked in 2024.** The season chart shows 2024 slightly ahead of 2025.
2. **Wins and podiums were higher in the last two seasons.** Podiums were 66 in both 2022 and 2023, then 72 in both 2024 and 2025. Wins were 22 in each of 2022 and 2023, then 24 in 2024 and 2025.
3. **Max Verstappen led the combined-period driver standings.** The report shows 1,751 points, 51 wins, and 67 podiums. Red Bull leads the constructor points ranking.
4. **The non-finish rate trended down.** It is approximately 21% in 2022 and 15% in 2025, while the all-period card shows about 14%.

### 💡 Recommendation

Use the circuit-level non-finish-rate chart to select locations for closer review. Then examine status categories and race context before proposing an intervention. The seasonal decline is descriptive; this dataset alone does not explain its cause.

</details>

## 🚀 Reproduce the project

- [ ]  Download and extract the Kaggle dataset.
- [ ]  Open [`sql/00_setup_and_import.sql` ](<f1 new - tables>) in MySQL Workbench.
- [ ]  Use the Workbench Table Data Import Wizard. 
- [ ]  Run the cleaning and analysis SQL scripts to create the clean views and `fact_race_results`.
- [ ]  Connect Power BI Desktop to MySQL and load the fact table and required clean views.
- [ ]  Confirm the one-to-many relationships and create the DAX measures.
- [ ]  Check that season slicers update the cards, charts, and tables.
- [ ]  Compare key Power BI totals with the MySQL results before publishing.

## 📁 Project files

- [`sql/00_setup_and_import.sql` ](<f1 new - tables>)— database, raw-table setup, and example CSV import statements.
- `f1_performance.sql` — cleaning and reporting views, currently stored outside this project folder.
- `f1_season_analysis.sql` — season-analysis queries, currently stored outside this project folder.
- `F1_PERFORMANCE_DASHBOARD.pbix` — Power BI report, currently stored outside this project folder.

For a fully reproducible portfolio repository, copy the two SQL scripts and the `.pbix` report into this project folder. The setup script’s CSV path is a placeholder and needs to point to your extracted dataset folder.

## ⚠️ Limitations

- This report focuses on 2022–2025; do not generalize its findings to every Formula 1 season.
- The non-finish rate depends on the status classification defined above.
- A non-finish count or rate does not identify a cause; the report is descriptive, not causal.
- Kaggle data may be updated. Record the exact version used when publishing so results can be reproduced.

---

