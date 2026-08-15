CREATE OR REPLACE VIEW coviddeaths_clean AS
SELECT
    iso_code,
    continent,
    location,
    date,
    CAST(NULLIF(total_cases, '') AS SIGNED) AS total_cases,
    CAST(NULLIF(total_deaths, '') AS SIGNED) AS total_deaths,
    CAST(NULLIF(population, '') AS SIGNED) AS population,
    CAST(NULLIF(new_cases, '') AS SIGNED) AS new_cases,
    CAST(NULLIF(new_deaths, '') AS SIGNED) AS new_deaths
FROM coviddeaths;

CREATE OR REPLACE VIEW covidvaccinations_clean AS
SELECT
    location,
    COALESCE(
        STR_TO_DATE(NULLIF(TRIM(`date`), ''), '%Y/%c/%e'),
        STR_TO_DATE(NULLIF(TRIM(`date`), ''), '%Y-%m-%d')
    ) AS date,
    CAST(NULLIF(new_vaccinations, '') AS SIGNED) AS new_vaccinations
FROM covidvaccinations;

SELECT 
    location,
    date,
    total_cases,
    total_deaths,
    (total_deaths / NULLIF(total_cases, 0)) * 100 AS DeathPercentage
FROM coviddeaths_clean
WHere location like '%states%'
ORDER BY 1, 2;

SELECT 
    location,
    date,
    population,
    total_cases,
    (total_cases/population) * 100 AS PercentPopulationInfected
FROM coviddeaths_clean
WHere location like '%states%'
ORDER BY 1, 2;

SELECT 
    location,
    population,
    max(total_cases) as HighestInfectionCount,
    max((total_cases/population))* 100 AS PercentPopulationInfected
FROM coviddeaths_clean
group by location, population
ORDER BY PercentPopulationInfected desc;

SELECT 
    location,
    MAX(total_deaths) AS TotalDeathCount
FROM coviddeaths_clean
WHERE TRIM(continent) <> ''
GROUP BY location
ORDER BY TotalDeathCount DESC;

SELECT 
    continent,
    MAX(total_deaths) AS TotalDeathCount
FROM coviddeaths_clean
WHERE TRIM(continent) <> ''
GROUP BY continent
ORDER BY TotalDeathCount DESC;

SELECT 
    date,
    sum(new_cases) as total_cases,
    sum(new_deaths) as total_deaths,
    sum(new_deaths)/sum(new_cases) *100 AS DeathPercentage
FROM coviddeaths_clean
WHERE TRIM(continent) <> ''
Group by date
ORDER BY 1, 2;

With PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as (
SELECT 
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    sum(new_vaccinations) over (PARTITION BY dea.location order by location, date) as RollingPeopleVaccinated
FROM coviddeaths_clean dea
Join covidvaccinations_clean vac 
on dea.location=vac.location 
and dea.date=vac.date
WHERE TRIM(continent) <> ''
)
SELECT *, RollingPeopleVaccinated/population*100
from PopvsVac;

CREATE TEMPORARY TABLE PercentPopulationVaccinated
(
    continent VARCHAR(255),
    location VARCHAR(255),
    date DATE,
    population BIGINT,
    new_vaccinations BIGINT,
    RollingPeopleVaccinated BIGINT
);

INSERT INTO PercentPopulationVaccinated
SELECT 
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (
        PARTITION BY dea.location 
        ORDER BY dea.date
    ) AS RollingPeopleVaccinated
FROM coviddeaths_clean dea
JOIN covidvaccinations_clean vac 
    ON dea.location = vac.location 
    AND dea.date = vac.date;

SELECT *,
       RollingPeopleVaccinated / population * 100 AS PercentPopulationVaccinated
FROM PercentPopulationVaccinated;

Create View PercentPopulationVaccinated AS
SELECT 
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (
        PARTITION BY dea.location 
        ORDER BY dea.date
    ) AS RollingPeopleVaccinated
FROM coviddeaths_clean dea
JOIN covidvaccinations_clean vac 
    ON dea.location = vac.location 
    AND dea.date = vac.date
WHERE TRIM(continent) <> '';