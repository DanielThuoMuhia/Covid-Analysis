-- Retrieve all records from the CovidDeaths table
SELECT *
FROM [Portfolio Project]..CovidDeaths
ORDER BY 3, 4;  -- Sort by columns 3 and 4 (likely date and location)

-- Uncomment to retrieve all records from the CovidVaccinations table
-- SELECT *
-- FROM [Portfolio Project]..CovidVaccinations
-- ORDER BY 3, 4;  -- Sort by columns 3 and 4 (likely date and location)

-- Retrieve key COVID-19 statistics ordered by location and date
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM [Portfolio Project]..CovidDeaths
ORDER BY location, date;

-- Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract COVID-19 in Kenya
SELECT 
    location, 
    date, 
    total_cases, 
    total_deaths, 
    (CAST(total_deaths AS FLOAT) / CAST(total_cases AS FLOAT)) * 100 AS Death_Percentage
FROM [Portfolio Project]..CovidDeaths
WHERE location = 'Kenya'
ORDER BY location, date;

-- Total Cases vs Population
-- Shows the percentage of the population infected in Kenya
SELECT 
    location, 
    date, 
    total_cases, 
    population, 
    (CAST(total_cases AS FLOAT) / CAST(population AS FLOAT)) * 100 AS Population_Infected_Percentage
FROM [Portfolio Project]..CovidDeaths
WHERE location = 'Kenya'
ORDER BY location, date;

-- Countries with the highest infection rate compared to Population
SELECT 
    location, 
    population,
    MAX(total_cases) AS Highest_Infection_Count,
    CAST(MAX(total_cases) AS FLOAT) / CAST(population AS FLOAT) * 100 AS Population_Infected
FROM [Portfolio Project]..CovidDeaths
GROUP BY location, population
ORDER BY Population_Infected DESC;

-- Countries with the highest death count per population
SELECT 
    location,
    MAX(total_deaths) AS Highest_Death_Count
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY Highest_Death_Count DESC;

-- Breakdown by Continent
-- Continent with the highest death count
SELECT 
    continent,
    MAX(total_deaths) AS Highest_Death_Count
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY Highest_Death_Count DESC;

-- Global Numbers
-- Calculating global total cases, deaths, and death percentage
SELECT 
    SUM(new_cases) AS Total_Cases,
    SUM(new_deaths) AS Total_Deaths,
    CAST(SUM(new_deaths) AS FLOAT) / CAST(SUM(new_cases) AS FLOAT) * 100 AS Death_Percentage
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;

-- Total Population vs Vaccinations by Continent and Country
SELECT 
    dea.continent,
    dea.location, 
    dea.date, 
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
FROM [Portfolio Project]..CovidDeaths dea
JOIN [Portfolio Project]..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3;

-- Use Common Table Expression (CTE) for Population vs Vaccination Analysis
WITH PopvsVac (Continent, Location, Date, Population, new_vaccinations, Rolling_People_Vaccinated) AS (
    SELECT 
        dea.continent,
        dea.location, 
        dea.date, 
        dea.population,
        vac.new_vaccinations,
        SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
    FROM [Portfolio Project]..CovidDeaths dea
    JOIN [Portfolio Project]..CovidVaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT *, (CAST(Rolling_People_Vaccinated AS FLOAT) / Population) * 100 AS Percent_Vaccinated
FROM PopvsVac;

-- Temporary Table for Percent Population Vaccinated Analysis
CREATE TABLE #PercentPopulationVaccinated (
    continent NVARCHAR(255),
    location NVARCHAR(255),
    date DATETIME,
    population NUMERIC,
    new_vaccinations NUMERIC,
    Rolling_People_Vaccinated NUMERIC
);

INSERT INTO #PercentPopulationVaccinated
SELECT 
    dea.continent,
    dea.location, 
    dea.date, 
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
FROM [Portfolio Project]..CovidDeaths dea
JOIN [Portfolio Project]..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT *, (CAST(Rolling_People_Vaccinated AS FLOAT) / Population) * 100 AS Percent_Vaccinated
FROM #PercentPopulationVaccinated;

-- Creating a View to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS 
SELECT 
    dea.continent,
    dea.location, 
    dea.date, 
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
FROM [Portfolio Project]..CovidDeaths dea
JOIN [Portfolio Project]..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

-- Retrieve data from the created view
SELECT *
FROM PercentPopulationVaccinated;
