# SQL — Covid-19 Data Exploration

End-to-end SQL Server portfolio project analyzing global COVID-19 case, death, and vaccination data.

**Skills demonstrated:** Joins, CTEs, temporary tables, views, stored procedures, window functions, ranking functions (`RANK`, `DENSE_RANK`, `ROW_NUMBER`), running totals, moving averages, `LAG()`, subqueries, `CASE` statements, and data type conversion.

### Files
- `Covid_Portfolio_Project.sql` — full SQL script (queries for death %, infection %, vaccination rollups, risk categorization, top-10 rankings, monthly trends, and dashboard views).
- `CovidDeaths.xlsx` — source dataset (cases & deaths by country/date).
- `CovidVaccinations.xlsx` — source dataset (vaccination rollout by country/date).

### Highlights
- Calculates death % and infection % by country over time.
- Ranks countries by total cases, deaths, and vaccination %.
- Uses window functions for rolling vaccination totals and 7-day moving averages of new cases.
- Builds a `CovidDashboard` view for downstream BI tools (e.g., Power BI/Tableau).

> Note: To run this script, load `CovidDeaths.xlsx` and `CovidVaccinations.xlsx` into a SQL Server database named `PortfolioProject`.
