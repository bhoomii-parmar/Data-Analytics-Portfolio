/*
Covid 19 Data Exploration 
Author: Bhoomi Parmar

Skills used: 
- SQL Server
- Joins
- CTEs
- Temporary Tables
- Views
- Stored Procedures
- Window Functions
- Aggregate Functions
- Ranking Functions
- Subqueries
- CASE Statements
- Data Type Conversion
- Running Totals
- Moving Averages
- Time Series Analysis
- Business Intelligence Queries
*/



Select *
From PortfolioProject..CovidDeaths
Where continent is not null 
order by 3,4


-- Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Where continent is not null 
order by 1,2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where location like '%states%'
and continent is not null 
order by 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
--Where location like '%states%'
order by 1,2


-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc


-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc



-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc



-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2



-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3


-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated




-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 


-- Top 10 Countries by Total Cases

SELECT TOP 10
    location,
    MAX(total_cases) AS TotalCases
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalCases DESC;


-- Top 10 Countries by Total Deaths

SELECT TOP 10
    location,
    MAX(CAST(total_deaths AS BIGINT)) AS TotalDeaths
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeaths DESC;



-- Case Fatality Rate (CFR)

SELECT
    location,
    MAX(total_cases) AS TotalCases,
    MAX(CAST(total_deaths AS FLOAT)) AS TotalDeaths,
    ROUND(
        MAX(CAST(total_deaths AS FLOAT))
        /
        NULLIF(MAX(CAST(total_cases AS FLOAT)),0)
        *100,
        2
    ) AS DeathRate
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
HAVING MAX(total_cases) > 0
ORDER BY DeathRate DESC;



-- Risk Category using CASE

SELECT
    location,
    MAX(total_cases) AS Cases,
    MAX(CAST(total_deaths AS FLOAT)) AS Deaths,

    CASE
        WHEN
            MAX(CAST(total_deaths AS FLOAT))
            /
            NULLIF(MAX(CAST(total_cases AS FLOAT)),0)
            *100 > 5
        THEN 'High Risk'

        WHEN
            MAX(CAST(total_deaths AS FLOAT))
            /
            NULLIF(MAX(CAST(total_cases AS FLOAT)),0)
            *100 BETWEEN 2 AND 5
        THEN 'Medium Risk'

        ELSE 'Low Risk'
    END AS RiskCategory

FROM PortfolioProject..CovidDeaths

WHERE continent IS NOT NULL

GROUP BY location

ORDER BY Deaths DESC;


-- Rank Countries by Death Count

WITH DeathCounts AS
(
    SELECT
        location,
        MAX(CAST(total_deaths AS BIGINT)) AS Deaths
    FROM PortfolioProject..CovidDeaths
    WHERE continent IS NOT NULL
    GROUP BY location
)

SELECT
    location,
    Deaths,

    RANK() OVER
    (
        ORDER BY Deaths DESC
    ) AS DeathRank

FROM DeathCounts;



-- Dense Rank Countries by Total Cases

WITH CaseCounts AS
(
    SELECT
        location,
        MAX(total_cases) AS Cases
    FROM PortfolioProject..CovidDeaths
    WHERE continent IS NOT NULL
    GROUP BY location
)

SELECT
    location,
    Cases,

    DENSE_RANK() OVER
    (
        ORDER BY Cases DESC
    ) AS DenseRank

FROM CaseCounts;


-- Row Number for Daily Cases

SELECT
    location,
    date,
    new_cases,

    ROW_NUMBER() OVER
    (
        PARTITION BY location
        ORDER BY date
    ) AS RowNum

FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL;


-- Peak Covid Day for Each Country

WITH PeakDay AS
(
    SELECT
        location,
        date,
        new_cases,

        ROW_NUMBER() OVER
        (
            PARTITION BY location
            ORDER BY new_cases DESC
        ) AS RN

    FROM PortfolioProject..CovidDeaths

    WHERE continent IS NOT NULL
)

SELECT *
FROM PeakDay
WHERE RN = 1;



-- Running Total of New Cases

SELECT
    location,
    date,
    new_cases,

    SUM(new_cases) OVER
    (
        PARTITION BY location
        ORDER BY date
    ) AS RunningCases

FROM PortfolioProject..CovidDeaths

WHERE continent IS NOT NULL;


-- 7-Day Moving Average of New Cases

SELECT
    location,
    date,
    new_cases,

    AVG(new_cases) OVER
    (
        PARTITION BY location
        ORDER BY date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS MovingAverage

FROM PortfolioProject..CovidDeaths

WHERE continent IS NOT NULL;



-- Previous Day Cases using LAG()

SELECT
    location,
    date,
    total_cases,

    LAG(total_cases) OVER
    (
        PARTITION BY location
        ORDER BY date
    ) AS PreviousCases

FROM PortfolioProject..CovidDeaths

WHERE continent IS NOT NULL;



-- Daily Growth Percentage

WITH Growth AS
(
    SELECT
        location,
        date,
        total_cases,

        LAG(total_cases) OVER
        (
            PARTITION BY location
            ORDER BY date
        ) AS PreviousCases

    FROM PortfolioProject..CovidDeaths
)

SELECT
    location,
    date,
    total_cases,
    PreviousCases,

    ROUND
    (
        (total_cases - PreviousCases) * 100.0 /
        NULLIF(PreviousCases,0),
        2
    ) AS GrowthPercent

FROM Growth;



-- Monthly Cases

SELECT
    YEAR(date) AS Year,
    MONTH(date) AS Month,

    SUM(new_cases) AS MonthlyCases

FROM PortfolioProject..CovidDeaths

WHERE continent IS NOT NULL

GROUP BY
    YEAR(date),
    MONTH(date)

ORDER BY
    Year,
    Month;



-- Monthly Deaths

SELECT
    YEAR(date) AS Year,
    MONTH(date) AS Month,

    SUM(CAST(new_deaths AS BIGINT)) AS MonthlyDeaths

FROM PortfolioProject..CovidDeaths

WHERE continent IS NOT NULL

GROUP BY
    YEAR(date),
    MONTH(date)

ORDER BY
    Year,
    Month;



-- Vaccination Percentage

SELECT
    dea.location,
    dea.population,

    MAX(vac.people_vaccinated) AS Vaccinated,

    ROUND
    (
        MAX(vac.people_vaccinated) * 100.0 /
        NULLIF(dea.population,0),
        2
    ) AS VaccinationPercent

FROM PortfolioProject..CovidDeaths dea

JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date

WHERE dea.continent IS NOT NULL

GROUP BY
    dea.location,
    dea.population;



-- Continent Summary

SELECT
    continent,

    SUM(new_cases) AS Cases,

    SUM(CAST(new_deaths AS BIGINT)) AS Deaths

FROM PortfolioProject..CovidDeaths

WHERE continent IS NOT NULL

GROUP BY continent;


-- Countries Above Global Average Cases

SELECT
    location,
    MAX(total_cases) AS Cases

FROM PortfolioProject..CovidDeaths

WHERE continent IS NOT NULL

GROUP BY location

HAVING MAX(total_cases) >
(
    SELECT AVG(total_cases)
    FROM PortfolioProject..CovidDeaths
);



-- Countries Above Global Average Deaths

SELECT
    location,
    MAX(CAST(total_deaths AS BIGINT)) AS Deaths

FROM PortfolioProject..CovidDeaths

WHERE continent IS NOT NULL

GROUP BY location

HAVING MAX(CAST(total_deaths AS BIGINT)) >
(
    SELECT AVG(CAST(total_deaths AS BIGINT))
    FROM PortfolioProject..CovidDeaths
);



-- Stored Procedure

CREATE PROCEDURE GetCountryStats

    @Country VARCHAR(100)

AS
BEGIN

    SELECT *

    FROM PortfolioProject..CovidDeaths

    WHERE location = @Country

    ORDER BY date;

END;



-- Execute Stored Procedure

EXEC GetCountryStats 'India';



-- Create Index

CREATE INDEX idx_location

ON PortfolioProject..CovidDeaths(location);



-- Create Dashboard View

CREATE VIEW CovidDashboard AS

SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    dea.total_cases,
    dea.new_cases,
    dea.total_deaths,
    dea.new_deaths,
    vac.people_vaccinated,
    vac.people_fully_vaccinated,
    vac.new_vaccinations

FROM PortfolioProject..CovidDeaths dea

JOIN PortfolioProject..CovidVaccinations vac

    ON dea.location = vac.location
    AND dea.date = vac.date

WHERE dea.continent IS NOT NULL;



-- View Dashboard Data


SELECT *
FROM CovidDashboard;



-- Top 10 Countries by Vaccination Percentage

SELECT TOP 10

    dea.location,

    dea.population,

    MAX(vac.people_vaccinated) AS Vaccinated,

    ROUND
    (
        MAX(vac.people_vaccinated) * 100.0 /
        NULLIF(dea.population,0),
        2
    ) AS VaccinationPercent

FROM PortfolioProject..CovidDeaths dea

JOIN PortfolioProject..CovidVaccinations vac

    ON dea.location = vac.location
    AND dea.date = vac.date

WHERE dea.continent IS NOT NULL

GROUP BY
    dea.location,
    dea.population

ORDER BY VaccinationPercent DESC;



-- Countries with Lowest Vaccination Percentage

SELECT TOP 10

    dea.location,

    dea.population,

    MAX(vac.people_vaccinated) AS Vaccinated,

    ROUND
    (
        MAX(vac.people_vaccinated) * 100.0 /
        NULLIF(dea.population,0),
        2
    ) AS VaccinationPercent

FROM PortfolioProject..CovidDeaths dea

JOIN PortfolioProject..CovidVaccinations vac

    ON dea.location = vac.location
    AND dea.date = vac.date

WHERE dea.continent IS NOT NULL

GROUP BY
    dea.location,
    dea.population

ORDER BY VaccinationPercent ASC;



-- Total Vaccinations by Continent

SELECT

    dea.continent,

    SUM(CAST(vac.new_vaccinations AS BIGINT)) AS TotalVaccinations

FROM PortfolioProject..CovidDeaths dea

JOIN PortfolioProject..CovidVaccinations vac

    ON dea.location = vac.location
    AND dea.date = vac.date

WHERE dea.continent IS NOT NULL

GROUP BY dea.continent

ORDER BY TotalVaccinations DESC;



-- End of COVID-19 Data Exploration Project